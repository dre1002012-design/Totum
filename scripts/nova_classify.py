# -*- coding: utf-8 -*-
"""
Estimation du score NOVA (degré de transformation, 1-4) des bases CIQUAL
(assets/foods.csv) et USDA (assets/usda_foods.csv) — colonne
score_nova_estime. Remplace (31/10/2026) l'estimation « défaut par
sous-groupe + quelques mots-clés » de build_food_taxonomy.py, qui classait
par exemple les flocons d'avoine, le café ou le tofu nature en NOVA 4
(retour d'Alex).

Référentiel : définition et exemples de Monteiro et al., « Ultra-processed
foods: what they are and how to identify them », Public Health Nutrition
2019 ; FAO, « Ultra-processed foods, diet quality, and health using the
NOVA classification system », 2019.
  1 = brut ou peu transformé : frais, séché, moulu, réfrigéré, surgelé,
      pasteurisé, fermenté sans alcool, cuit (céréales, flocons, farines,
      pâtes faites de farine et d'eau, lait, yaourt nature, œufs, viandes,
      poissons, légumes, fruits, jus sans sucre ajouté, café, thé…)
  2 = ingrédient culinaire transformé : huiles, beurre, crème, saindoux,
      sucre, miel, sirop d'érable, sel, vinaigre, amidons…
  3 = aliment transformé : conserves, fromages, pains artisanaux, fruits
      au sirop, oléagineux salés, viandes/poissons salés, fumés, séchés ;
      bière, vin, cidre ; préparations faites maison/artisanales
  4 = ultra-transformé : formulations industrielles (sodas, biscuits,
      confiseries, céréales du petit-déjeuner sucrées/extrudées, pains
      industriels préemballés, margarines, desserts lactés, plats préparés,
      saucisses et produits de viande reconstitués, nuggets, produits
      « allégés » reformulés, édulcorants, laits infantiles, poudres
      protéinées, alcools distillés…)

Règles ORDONNÉES par sous-groupe sur le nom (la 1re qui s'applique
gagne), documentées dans le code. C'est une ESTIMATION (l'app l'affiche
comme telle) : seul le NOVA d'un produit scanné (Open Food Facts) est
officiel.

Usage : python scripts/nova_classify.py .   (réécrit uniquement la colonne
score_nova_estime des deux CSV, en conservant tout le reste à l'octet près)
"""
import csv
import io
import re
import sys
import unicodedata
from collections import Counter, defaultdict


def norm(s):
    s = unicodedata.normalize('NFKD', s.lower())
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return s.replace('œ', 'oe').replace('’', "'")


def has(n, *words):
    return any(w in n for w in words)


HOMEMADE = ('fait maison', 'faite maison', 'faits maison', 'faites maison', 'artisanal', 'artisanale',
            'de boulangerie', 'boulangerie traditionnelle', 'patisserie traditionnelle')
UPF_MARKERS = ('edulcorant', 'aspartame', 'aromatise', 'reconstitue', 'nugget', 'cordon bleu', 'surimi',
               'enrichi en vitamines', 'enrichie en vitamines', 'enrichis en vitamines', 'enrichies en vitamines')


# ─────────────────────────────── CIQUAL ────────────────────────────────

def nova_ciqual(name, groupe, sg):
    n = norm(name)
    home = has(n, *HOMEMADE)
    # « sans sucres ajoutés » ne doit jamais déclencher une règle « sucré »
    # (café, thé, compotes, boissons végétales…).
    n_plain = n.replace('sans sucres ajoutes', '').replace('sans sucre ajoute', '')

    if sg == 'eaux':
        return 4 if has(n, 'aromatis', 'sucre', 'edulcor') else 1
    if sg == 'sels':
        return 2
    if sg in ('herbes', 'épices', 'algues'):
        return 3 if has(n, 'tartare', 'preemball', 'marine') else 1
    if sg == 'farines':
        return 2 if has(n, 'amidon', 'fecule', 'maizena') else 1

    if sg == 'pâtes, riz et céréales':
        if has(n, 'instantan', 'assaisonn', 'cuisine', 'farci', 'aux legumes', 'preemballe') and not has(n, 'nature'):
            return 4
        return 1
    if sg == 'légumineuses':
        return 3 if has(n, 'appertis', 'en conserve', 'cuisine') else 1
    if sg == 'légumes':
        if has(n, 'chips'):
            return 3 if has(n, 'preleve') else 4
        if has(n, 'appertis', 'en conserve', 'au vinaigre', 'marine', 'lactofermente', 'saumure'):
            return 3
        if has(n, 'cuisine', 'a la creme', 'gratin', 'preemballe') and not has(n, 'surgele'):
            return 4 if has(n, 'preemballe') else 3
        return 1
    if sg == 'pommes de terre et autres tubercules':
        if has(n, 'chips', 'flocons', 'dauphine', 'duchesse', 'noisette', 'croquette', 'rosti', 'pommes de terre sautees, preemball'):
            return 4
        if has(n, 'frite', 'prefrit', 'puree', 'gratin', 'appertis'):
            return 3
        return 1
    if sg == 'fruits':
        if has(n, 'confit', 'pate de fruit'):
            return 4
        if re.search(r'\bnectar\b', n):
            return 3
        if has(n, 'au sirop', 'sucre', 'appertis', 'compote', 'confiture') and not has(n, 'sans sucres ajoutes', 'sans sucre ajoute', 'au jus d'):
            return 3
        return 1
    if sg == 'fruits à coque et graines oléagineuses':
        if has(n, 'caramelis', 'enrobe', 'chocolat', 'miel', 'pralin', 'nougat'):
            return 4
        if has(n, 'aromatis'):
            return 4
        if has(n, 'sale', 'fume', 'beurre de', 'pate d\'arachide', 'pate de', 'chouchou'):
            return 3
        return 1

    if sg in ('viandes crues', 'viandes cuites'):
        if has(n, 'pane', 'cordon', 'nugget', 'reconstitue', 'hache prepare', 'farce'):
            return 4
        if has(n, 'marine', 'sale', 'fume', 'confit'):
            return 3
        return 1
    if sg in ('poissons crus', 'poissons cuits', 'mollusques et crustacés crus', 'mollusques et crustacés cuits'):
        if has(n, 'pane', 'beignet', 'a la romaine', 'nugget', 'surimi'):
            return 4
        if has(n, 'fume', 'sale', 'seche', 'marine', 'appertis', 'en conserve', 'saumure', 'semi-conserve'):
            return 3
        return 1
    if sg == 'produits à base de poissons et produits de la mer':
        if has(n, 'surimi', 'pane', 'beignet', 'accra', 'nugget', 'croquette', 'quenelle', 'tarama', 'mousse', 'terrine',
               'a la romaine', 'pate ', 'pate,', 'rillettes', 'farci', 'preemballe, cuit') and not has(n, 'au naturel'):
            return 4
        return 3
    if sg == 'oeufs':
        if has(n, 'preemball'):
            return 4
        if has(n, 'poudre', 'en conserve'):
            return 3
        return 1

    if sg == 'charcuteries et alternatives végétales':
        if has(n, 'vegetal', 'vegetarien', 'vegane', 'vegan', 'soja', 'proteine', 'tofu', 'seitan', 'ble)'):
            return 4
        if has(n, 'jambon de porc a cuire', 'jambon a rotir', 'a rotir/cuire'):
            return 1
        if has(n, 'jambon de poulet', 'jambon de dinde', 'blanc de poulet', 'blanc de dinde', 'reconstitue', 'emince'):
            return 4
        whole_cured = ('jambon cru', 'jambon sec', 'jambon de bayonne', 'jambon de parme', 'jambon serrano', 'jambon d\'auvergne',
                       'jambon de savoie', 'jambon de vendee', 'bresaola', 'viande des grisons', 'viande sechee', 'coppa', 'lonzo',
                       'magret', 'lard', 'poitrine', 'bacon', 'pancetta', 'jambon cuit', 'jambon superieur', 'jambonneau',
                       'epaule cuite', 'jambon a l\'os', 'jambon blanc', 'jambon persille', 'jambon fume', 'rillettes', 'foie gras',
                       'confit', 'gesier')
        if has(n, *whole_cured) and not has(n, 'pate ', 'pate,', 'mousse', 'terrine', 'saucisse'):
            return 3
        return 4
    if sg == 'autres produits à base de viande':
        return 4

    if sg == 'laits':
        if has(n, 'aromatis', 'chocolat', 'fraise', 'vanille', 'cafe'):
            return 4
        if has(n, 'concentre sucre'):
            return 3
        return 1
    if sg == 'produits laitiers frais et alternatives végétales':
        if home:
            return 3
        if has(n, 'soja', 'vegetal', 'avoine', 'amande', 'coco', 'riz)'):
            return 4
        dessert = ('creme dessert', 'flan', 'mousse', 'liegeois', 'riz au lait', 'semoule au lait', 'entremets',
                   'creme brulee', 'creme caramel', 'ile flottante', 'tiramisu', 'panna cotta', 'dessert', 'fromage blanc et creme',
                   'creme fouettee', 'chantilly', 'gelifie', 'pot de creme', 'creme anglaise', 'fondant', 'clafoutis', 'cheesecake',
                   'profiterole', 'eclair', 'creme patissiere', 'instantan', 'reconstitu')
        if has(n, *dessert):
            return 4
        # Lait égoutté/concentré nature (skyr, yaourt grec, spécialité riche
        # en protéines « nature ») : peu transformé, comme le yaourt nature.
        if has(n, 'riche en proteines', 'grecque', 'skyr') and has(n, 'nature') and not has(n_plain, 'sucre', 'aromat', 'fruit'):
            return 1
        if has(n, 'aromatis', 'arome', 'edulcor', 'aux fruits', 'sur lit de', 'fruits', 'chocolat', 'vanille', 'cafe',
               'a boire', 'riche en proteines', 'allege', 'miel', 'confiture', 'cereales', 'caramel', 'pulpe'):
            return 4
        if has(n, 'sucre'):
            return 3
        return 1
    if sg == 'fromages et alternatives végétales':
        if has(n, 'fondu', 'a tartiner', 'specialite fromagere', 'vegetal', 'cajou', 'soja', 'aromatis', 'pour hamburger',
               'en tranches, allege', 'cheddar fondu', 'type kiri', 'apericube', 'crème de', 'creme de'):
            return 4
        return 3
    if sg == 'crèmes et spécialités à base de crème':
        if has(n, 'chantilly', 'specialite', 'arome', 'aromatis'):
            return 4
        return 2
    if sg == 'beurres':
        if has(n, 'leger', 'allege', 'teneur reduite', 'matiere grasse laitiere', 'tartinable') and \
                not has(n, 'ou non', 'sans precision'):
            return 4
        return 2
    if sg in ('huiles et graisses végétales', 'huiles de poissons', 'autres matières grasses'):
        return 4 if has(n, 'margarine', 'tartinable', 'solide (type margarine)') else 2
    if sg == 'margarines':
        return 4

    if sg == 'sucres, miels et assimilés':
        if has(n, 'edulcor', 'aspartame', 'saccharine', 'stevia', 'sucralose', 'vermicelles', 'nappage', 'caramel liquide'):
            return 4
        return 2
    if sg == 'confitures et assimilés':
        if has(n, 'creme de marron', 'pate a tartiner', 'edulcor'):
            return 4
        return 3
    if sg == 'chocolats et produits à base de chocolat':
        if has(n, 'noir') and has(n, '70', '85', '90', '99', 'degustation', '50 %', '40%') and not has(
                n, 'fourre', 'fourrage', 'aux fruits', 'pralin', 'menthe', 'edulcor', 'sans sucres ajoutes', 'riz souffle', 'biscuit'):
            return 3
        return 4
    if sg in ('confiseries non chocolatées', 'barres céréalières', 'biscuits apéritifs', 'glaces', 'sorbets',
              'desserts glacés', 'margarines', 'compléments protéinés', 'denrées destinées à une alimentation particulière',
              'laits et boissons infantiles', 'céréales et biscuits infantiles', 'desserts infantiles', 'autres produits à base de viande'):
        if sg in ('desserts infantiles',) and has(n, 'compote', 'puree de fruits', 'fruits'):
            return 3
        if sg == 'compléments protéinés' and has(n, 'natto'):
            return 1
        return 3 if home else 4
    if sg == 'petits pots salés et plats infantiles':
        return 3
    if sg == 'céréales de petit-déjeuner':
        if has(n, 'flocons d\'avoine', 'son d\'avoine', 'son de ble') or (has(n, 'flocons de cereales') and has(n, 'nature') and not has(n, 'enrichi')):
            return 1
        if has(n, 'souffle') and has(n, 'complet') and not has(n, 'miel', 'chocolat', 'caramel', 'enrichi'):
            return 1
        if has(n, 'muesli') and not has(n, 'croustillant', 'enrichi', 'chocolat'):
            return 1 if has(n, 'sans sucres ajoutes') else 3
        if has(n, 'nature', 'sans sucres ajoutes') and not has(n, 'enrichi', 'sucre'):
            return 3
        return 4

    if sg == 'pains et assimilés':
        if has(n, 'galette de riz', 'galette de mais', 'galette de sarrasin souffle') and not has(n, 'chocolat', 'nappe'):
            return 1
        if has(n, 'pain de mie', 'biscotte', 'pain grille', 'brioche', 'pain au lait', 'burger', 'hot dog', 'tortilla',
               'wrap', 'cracker', 'crouton', 'preemballe', 'pain d\'epices', 'petit pain grille', 'sans gluten', 'gressin',
               'blinis', 'pain viennois'):
            return 4
        return 3
    if sg == 'viennoiseries':
        return 3 if home else 4
    if sg == 'gâteaux et pâtisseries':
        return 3 if home else 4
    if sg == 'biscuits sucrés':
        return 3 if home else 4
    if sg == 'pâtes à tarte':
        return 3 if home else 4

    if sg == 'boissons sans alcool':
        if has(n, 'cafe au lait', 'cappuccino', 'cafe latte', 'cafe frappe', 'boisson au cafe', 'cafe glace'):
            return 4
        if (has(n, 'cafe', 'the ', 'the,', 'the noir', 'the vert', 'tisane', 'infusion', 'chicoree', 'mate', 'rooibos')
                and not has(n_plain, 'sucre', 'aromatis', 'boisson au the', 'the glace', 'edulcor')):
            return 1
        if has(n, 'cacao, sans sucres ajoutes'):
            return 1
        if re.search(r'\bnectar\b', n):
            return 3
        if has(n, 'jus') and not has(n, 'multivitamin', 'boisson', 'sucre', 'edulcor', 'aromatis', 'enrichi'):
            return 1
        if has(n, 'jus') and has(n, 'multivitamin', 'enrichi'):
            return 3
        if has(n, 'boisson au soja') and has(n, 'nature') and has(n, 'non enrichi'):
            return 1
        if has(n, 'boisson a l\'amande', 'boisson a l\'avoine', 'boisson au riz', 'boisson a la noisette', 'boisson au soja') and \
                has(n, 'nature') and has(n, 'sans sucres ajoutes') and has(n, 'non enrichi'):
            return 3
        return 4
    if sg == 'boisson alcoolisées':
        if has(n, 'aromatis', 'panache preemball', 'punch', 'cocktail', 'pastis', 'gin', 'vodka', 'whisky', 'rhum', 'liqueur',
               'eau de vie', 'eau-de-vie', 'calvados', 'cognac', 'armagnac', 'alcool pur', 'creme de cassis', 'kir',
               'anise', 'tequila', 'apéritif à base de vin', 'aperitif a base de vin', 'vermouth', 'panache'):
            if has(n, 'sangria') and home:
                return 3
            return 4
        return 3

    if sg == 'aides culinaires':
        if has(n, 'bouillon', 'fond de', 'fumet', 'court-bouillon', 'base de pizza', 'sauce tomate cuisinee', 'extrait de levure',
               'gelee au madere'):
            return 4
        if has(n, 'son d', 'son de', 'germe de ble', 'levure de boulanger fraiche', 'pollen', 'gelee royale', 'lait de coco'):
            return 1
        if has(n, 'tapenade', 'vin cuisine', 'alcool fort'):
            return 3
        return 2
    if sg == 'condiments':
        return 3
    if sg == 'ingrédients pour végétariens':
        if has(n, 'isolat', 'texture', 'preparation culinaire', 'seitan', 'steak', 'galette', 'nugget', 'hache'):
            return 4
        if has(n, 'fume', 'mariné', 'marine', 'aromatis'):
            return 3
        if has(n, 'tofu', 'tempeh', 'natto'):
            return 1
        return 3
    if sg == 'tartinables végétariens':
        if has(n, 'guacamole', 'ktipiti'):
            return 4
        return 3

    if sg == 'sauces':
        if home:
            return 3
        if has(n, 'sauce soja', 'soja sucree') and not has(n, 'sucree'):
            return 3
        if has(n, 'nuoc', 'harissa', 'coulis', 'sauce tomate, preemballee', 'sauce tomate (aliment moyen)') and not has(n, 'au fromage', 'a la viande'):
            return 3
        return 4
    if sg == 'soupes':
        if home:
            return 3
        if has(n, 'deshydrat', 'instantan', 'preemball', 'brique', 'appertis', 'en conserve', 'surgele'):
            return 4
        return 3
    if sg in ('plats composés', 'sandwichs', 'pizzas, tartes et crêpes salées', 'feuilletées et autres entrées'):
        return 3 if home else 4
    if sg == 'salades composées et crudités':
        if home:
            return 3
        if has(n, 'sans assaisonnement', 'sans sauce', 'nature'):
            return 1
        return 4 if has(n, 'preemball', 'avec sauce', 'mayonnaise', 'vinaigrette') else 3
    return 3



def plant_milk_nova(n):
    """Boissons végétales USDA : aromatisées/sucrées ou enrichies (additifs,
    vitamines de synthèse) = 4 ; « original »/non sucrée/non enrichie = 1
    (soja) ou 3 (autres : huile, sel ajoutés)."""
    n2 = n.replace('unfortified', '').replace('unsweetened', '')
    if has(n2, 'vanilla', 'chocolate', 'flavor', 'sweetened', 'fortified', 'added calcium', 'with added', 'light'):
        return 4
    return 1 if 'soymilk' in n else 3


# ──────────────────────────────── USDA ─────────────────────────────────

def nova_usda(name, sg):
    n = norm(name)
    home = has(n, 'prepared from recipe', 'home-prepared', 'homemade', 'home prepared')
    if sg == 'Spices and Herbs':
        if has(n, 'imitation'):
            return 4
        if has(n, 'salt, table', 'salt,'):
            return 2
        if has(n, 'vinegar', 'vanilla extract'):
            return 2
        return 1
    if sg == 'Fats and Oils':
        if has(n, 'margarine', 'spread', 'shortening', 'dressing', 'mayonnaise', 'imitation', 'substitute', 'blend',
               'whipped topping', 'creamer', 'sandwich spread'):
            return 4
        return 2
    if sg == 'Beverages':
        if has(n, 'alcoholic beverage'):
            if has(n, 'distilled', 'whiskey', 'gin', 'rum', 'vodka', 'liqueur', 'cordial', 'creme de', 'daiquiri', 'pina colada',
                   'tequila', 'cocktail', 'malt beverage', 'mixed'):
                return 4
            return 3
        if has(n, 'coffee, brewed', 'coffee, espresso', 'tea, brewed', 'tea, herb', 'tea, green, brewed', 'tea, black, brewed',
               'water, bottled', 'water, tap', 'water, municipal', 'water, well', 'coffee, instant, regular, prepared'):
            if not has(n, 'sweetened', 'flavored', 'with sugar', 'decaffeinated, prepared with'):
                return 1
        if has(n, 'juice') and not has(n, 'drink', 'cocktail', 'beverage', 'sweetened', 'added sugar', 'with sugar', 'punch',
                                     'lemonade', 'limeade', 'orangeade', 'blend', 'smoothie', 'fortified with'):
            return 1
        if re.search(r'\bnectar\b', n):
            return 3
        if has(n, 'soymilk', 'almond milk', 'oat milk', 'rice milk', 'coconut milk beverage'):
            return plant_milk_nova(n)
        return 4
    if sg == 'Breakfast Cereals':
        if home:
            return 3
        if has(n, 'ready-to-eat', 'ready to eat') and not has(n, 'muesli'):
            return 4
        if has(n, 'oats, regular', 'oats, instant, fortified, plain, dry', 'rolled', 'oat bran', 'wheat germ', 'farina, unenriched',
               'oats, regular and quick', 'whole grain oats', 'steel cut') and not has(n, 'flavored', 'sweetened', 'maple', 'brown sugar',
                                                                                   'fruit', 'honey', 'apple', 'cinnamon'):
            return 1
        if has(n, 'muesli') and not has(n, 'with added sugar'):
            return 3
        return 4
    if sg == 'Dairy and Egg Products':
        if has(n, 'egg substitute', 'eggnog', 'imitation', 'pasteurized process', 'process cheese', 'cheese food', 'cheese spread',
               'cheese sauce', 'ice cream', 'frozen yogurt', 'pudding', 'dessert', 'creamer', 'whipped topping', 'flavored',
               'chocolate', 'strawberry', 'vanilla', 'fruit', 'sweetened', 'beverage', 'nondairy',
               'cheese product', 'cheese, low fat, cheddar or colby', 'mexican blend', 'substitute', 'american',
               'frozen mixture'):
            return 4
        if has(n, 'cheese', 'cottage', 'ricotta', 'cream cheese', 'feta', 'parmesan', 'mozzarella'):
            return 3
        if has(n, 'butter'):
            return 2
        if has(n, 'cream,', 'cream, fluid', 'sour cream', 'half and half'):
            return 2
        if has(n, 'milk', 'yogurt', 'kefir', 'buttermilk', 'egg', 'whey, acid, fluid', 'whey, sweet, fluid'):
            if has(n, 'condensed, sweetened'):
                return 3
            if has(n, 'dried', 'dry', 'powder') and not has(n, 'egg'):
                return 1 if has(n, 'milk, dry', 'milk, nonfat, dry', 'milk, dry, whole') else 4
            return 1
        return 3
    if sg == 'Fruits and Fruit Juices':
        if has(n, 'pie filling', 'candied', 'maraschino', 'fruit snacks', 'leather', 'drink'):
            return 4
        if has(n, 'syrup', 'sweetened', 'with sugar', 'sugar added', 'canned') and not has(n, 'unsweetened', 'juice pack', 'water pack',
                                                                                     'without sugar', 'no sugar', 'extra light syrup'):
            return 3
        if re.search(r'\bnectar\b', n):
            return 3
        return 1
    if sg == 'Vegetables and Vegetable Products':
        if has(n, 'chips', 'dehydrated flakes', 'mashed, dehydrated', 'au gratin, dry mix', 'scalloped, dry mix', 'fast food',
               'battered', 'breaded', 'puffs', 'nuggets', 'hash brown, frozen, with butter sauce',
               'creamed', 'with cheese sauce', 'with butter sauce', 'in butter sauce', 'in cheese sauce', 'soup'):
            return 4
        if has(n, 'canned', 'pickled', 'pickles', 'sauerkraut', 'french fries', 'french fried', 'home-fries', 'hash brown',
               'salted', 'with salt') and not has(n, 'without salt', 'no salt added'):
            return 3
        if has(n, 'canned'):
            return 3
        return 1
    if sg == 'Legumes and Legume Products':
        if has(n, 'meatless', 'vegetarian', 'meat extender', 'imitation', 'bacon bits', 'textured', 'protein isolate',
               'soy protein concentrate', 'soy protein isolate', 'chili with beans', 'refried', 'baked beans', 'frankfurter',
               'burger', 'sausage', 'nuggets', 'tofu yogurt', 'frozen dessert', 'chocolate', 'honey roast', 'peanut spread',
               'reduced fat'):
            return 4
        if has(n, 'peanut butter', 'hummus', 'soy sauce', 'miso', 'canned', 'salted', 'with salt', 'fried', 'dry roasted, with salt',
               'oil-roasted, with salt', 'tofu, fried', 'tofu, salted', 'pickled'):
            return 3
        if has(n, 'soymilk'):
            return plant_milk_nova(n)
        return 1
    if sg == 'Nut and Seed Products':
        if has(n, 'honey roast', 'chocolate', 'candied', 'yogurt covered', 'sweetened', 'trail mix', 'formulated'):
            return 4
        if has(n, 'with salt', 'salted', 'butter, with salt', 'oil roasted', 'smoked', 'flavored', 'oil-roasted') and not has(n, 'without salt'):
            return 3
        if has(n, 'butter', 'paste') and not has(n, 'without salt'):
            return 3
        return 1
    if sg in ('Beef Products', 'Lamb, Veal, and Game Products', 'Pork Products', 'Poultry Products'):
        if has(n, 'breaded', 'nuggets', 'patties, breaded', 'frankfurter', 'sausage', 'bologna', 'luncheon', 'salami', 'loaf',
               'roll, light meat', 'deli', 'restructured', 'formed', 'meatballs, frozen', 'imitation', 'pate', 'spread',
               'canned, chunk', 'chicken roll', 'turkey roll', 'pastrami, turkey', 'turkey ham', 'smoked turkey sausage'):
            return 4
        if has(n, 'cured', 'ham', 'bacon', 'smoked', 'corned', 'salt pork', 'jerky', 'dried', 'pickled', 'canned',
               'added solution', 'enhanced', 'marinated', 'brine', 'pastrami'):
            return 3
        return 1
    if sg == 'Sausages and Luncheon Meats':
        if has(n, 'ham,') and has(n, 'sliced, regular', 'sliced, extra lean', 'canned') and not has(n, 'chopped', 'minced', 'patties', 'turkey', 'chicken'):
            return 3
        if has(n, 'bacon') and not has(n, 'turkey', 'meatless', 'bits'):
            return 3
        return 4
    if sg == 'Finfish and Shellfish Products':
        if has(n, 'breaded', 'fish sticks', 'surimi', 'imitation', 'battered', 'fish portions', 'fish fillet, battered', 'gefiltefish'):
            return 4
        if has(n, 'canned', 'smoked', 'salted', 'dried', 'pickled', 'kippered', 'in oil', 'in water', 'roe') and not has(n, 'fresh'):
            return 3
        return 1
    if sg == 'Cereal Grains and Pasta':
        if has(n, 'protein-fortified'):
            return 4
        if has(n, 'instant', 'ramen', 'chow mein', 'with sauce', 'mix', 'seasoned', 'flavored'):
            return 4
        if has(n, 'corn starch', 'cornstarch', 'starch'):
            return 2
        return 1
    if sg == 'Baked Products':
        if home:
            return 3
        if has(n, 'tortillas, ready-to-bake or -fry, corn', 'tortilla, corn', 'pita', 'bagels, plain', 'french or vienna',
               'italian', 'sourdough', 'rye bread'):
            return 3
        return 4
    if sg == 'Sweets':
        if n.startswith(('sugars, ', 'sugar, ', 'honey', 'syrups, maple', 'molasses', 'syrup, cane',
                         'sweetener, syrup, agave')):
            return 2
        if has(n, 'cocoa, dry powder, unsweetened'):
            return 1
        if has(n, 'baking chocolate, unsweetened', 'chocolate, dark, 70', 'chocolate, dark, 85'):
            return 3
        return 4
    if sg == 'Snacks':
        if has(n, 'popcorn, air-popped') and not has(n, 'microwave', 'oil', 'caramel', 'cheese'):
            return 1
        if has(n, 'rice cakes, brown rice, plain', 'rice cake, plain') and not has(n, 'flavor', 'cheese', 'corn'):
            return 1
        return 4
    if sg in ('Soups, Sauces, and Gravies',):
        if home:
            return 3
        if has(n, 'soy sauce', 'fish sauce', 'salsa', 'vinegar', 'tomato sauce, canned',
               'sauce, ready-to-serve, pepper or hot', 'hot sauce'):
            return 3
        return 4
    if sg in ('Fast Foods', 'Restaurant Foods', 'Meals, Entrees, and Side Dishes'):
        return 3 if home else 4
    if sg == 'Baby Foods':
        if has(n, 'infant formula', 'cereal', 'cookies', 'teething', 'biscuits', 'pretzels', 'puffs', 'dessert', 'pudding',
               'juice drink', 'yogurt', 'cookie', 'snack', 'toddler'):
            return 4
        return 3
    if sg == 'American Indian/Alaska Native Foods':
        if has(n, 'frybread', 'fry bread', 'piki bread', 'tortilla', 'canned', 'with salt', 'commercial'):
            return 3
        if has(n, 'smoked', 'dried', 'jerky', 'oil', 'fermented', 'pickled'):
            return 3
        return 1
    return 3


# ─────────────────────────────── I/O ───────────────────────────────────

def rewrite(path, compute):
    raw = open(path, 'rb').read().decode('utf-8')
    nl = '\r\n' if '\r\n' in raw else '\n'
    lines = raw.split(nl)
    header = next(csv.reader([lines[0]]))
    ni = header.index('score_nova_estime')
    out = [lines[0]]
    trans = Counter()
    samples = defaultdict(list)
    dist = Counter()
    for line in lines[1:]:
        if not line:
            out.append(line)
            continue
        cells = next(csv.reader([line]))
        row = dict(zip(header, cells))
        new = str(compute(row))
        old = cells[ni]
        dist[new] += 1
        if new != old:
            trans[(old, new)] += 1
            if len(samples[(old, new)]) < 12:
                samples[(old, new)].append(row.get('nom', '')[:60])
            cells[ni] = new
            buf = io.StringIO()
            csv.writer(buf, lineterminator='').writerow(cells)
            line = buf.getvalue()
            assert next(csv.reader([line])) == cells
        out.append(line)
    open(path, 'wb').write(nl.join(out).encode('utf-8'))
    print(f'\n== {path} : distribution {dict(sorted(dist.items()))}')
    for (o, nw), c in sorted(trans.items(), key=lambda x: -x[1]):
        print(f'  {o} -> {nw} : {c}   ex. {samples[(o, nw)]}')


if __name__ == '__main__':
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    rewrite(f'{root}/assets/foods.csv', lambda r: nova_ciqual(r['nom'], r['groupe'], r['sous_groupe']))
    rewrite(f'{root}/assets/usda_foods.csv', lambda r: nova_usda(r['nom'], r['sous_groupe']))
