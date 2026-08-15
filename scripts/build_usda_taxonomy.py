#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ajoute groupe/sous_groupe/pictogramme/score_nova_estime/nom_generique à
assets/usda_foods.csv (déjà extrait par build_usda_foods.py), même principe
que scripts/build_food_taxonomy.py pour CIQUAL — mais mots-clés en ANGLAIS
(la base USDA garde ses noms natifs, décision d'Alex du 11/08/2026).

Leçons du pipeline CIQUAL directement appliquées dès le départ plutôt que
redécouvertes un aliment à la fois :
  - correspondance sur mot ENTIER (pas de sous-chaîne, "vin" ne doit pas
    matcher "vinegar")
  - un ingrédient cité dans un plat composé ne doit jamais remplacer le
    picto du plat lui-même (verrouillage par catégorie, comme "entrées et
    plats composés" côté CIQUAL)
  - un "contenant" (boisson, céréales petit-déj, laitier frais) ne doit
    jamais être remplacé par le parfum/ingrédient qu'il contient
  - jamais réutiliser l'emoji d'un aliment précis différent (mieux vaut le
    défaut neutre de la catégorie que "mentir" visuellement)

Produit : assets/usda_foods.csv mis à jour en place (mêmes lignes/macros,
colonnes taxonomie ajoutées à la fin).
"""
import csv
import re
import unicodedata

SRC = 'assets/usda_foods.csv'

# ───────────────────────── 1. Défaut par catégorie USDA ─────────────────────────
# groupe (bucket large, cohérent avec les groupes CIQUAL) + sous_groupe
# (catégorie USDA native) + (icône, nova) par défaut.
CATEGORY_INFO = {
    'Dairy and Egg Products':            ('produits laitiers et oeufs', '🥛', 2),
    'Spices and Herbs':                  ('aides culinaires', '🌿', 1),
    'Baby Foods':                        ('aliments infantiles', '🍼', 4),
    'Fats and Oils':                     ('matières grasses', '🧴', 2),
    'Poultry Products':                  ('viandes', '🍗', 1),
    'Soups, Sauces, and Gravies':        ('aides culinaires', '🍜', 3),
    'Sausages and Luncheon Meats':       ('charcuterie', '🍖', 4),
    'Breakfast Cereals':                 ('céréales', '🥣', 4),
    'Fruits and Fruit Juices':           ('fruits', '🍎', 1),
    'Pork Products':                     ('viandes', '🥓', 1),
    'Vegetables and Vegetable Products': ('légumes', '🥦', 1),
    'Nut and Seed Products':             ('fruits à coque et graines', '🥜', 1),
    'Beef Products':                     ('viandes', '🥩', 1),
    'Beverages':                         ('boissons', '🥤', 3),
    'Finfish and Shellfish Products':    ('poissons et fruits de mer', '🐟', 1),
    'Legumes and Legume Products':       ('légumineuses', '🫘', 1),
    'Lamb, Veal, and Game Products':     ('viandes', '🐑', 1),
    'Baked Products':                    ('produits céréaliers', '🍞', 4),
    'Sweets':                            ('produits sucrés', '🍬', 4),
    'Cereal Grains and Pasta':           ('produits céréaliers', '🍝', 1),
    'Fast Foods':                        ('plats composés', '🍔', 4),
    'Restaurant Foods':                  ('plats composés', '🍽️', 4),
    'Meals, Entrees, and Side Dishes':   ('plats composés', '🍲', 4),
    'Snacks':                            ('produits sucrés', '🍿', 4),
    'American Indian/Alaska Native Foods': ('plats composés', '🍽️', 3),
    'Alcoholic Beverages':               ('boissons', '🍷', 3),
}
DEFAULT_ICON, DEFAULT_NOVA = '🍽️', 3

# Catégories "contenant" : le parfum/ingrédient ne doit jamais remplacer
# l'icône du contenant lui-même (même principe que CIQUAL boissons/céréales
# petit-déj/laitiers frais).
CONTAINER_LOCK_CATEGORIES = {
    'Breakfast Cereals': None,   # verrouillage total (bol, quel que soit le parfum)
    # 🍷/🍺 ajoutés (13/08/2026, sweep systématique) : "Beverages" englobe
    # aussi les boissons alcoolisées côté USDA (contrairement à CIQUAL qui a
    # un sous-groupe séparé) — sans ça, "wine"/"beer" matchaient bien leur
    # mot-clé mais étaient aussitôt écrasés par le verrouillage récipient,
    # ramenés à un gobelet générique 🥤.
    'Beverages': {'🥤', '🧃', '☕', '🍵', '🍷', '🍺'},  # icônes de récipient encore autorisées
}
# Catégories "plat composé" : seuls les mots-clés qui désignent le plat
# lui-même restent autorisés, un ingrédient cité ne doit jamais l'emporter.
COMPOSED_DISH_CATEGORIES = {'Fast Foods', 'Meals, Entrees, and Side Dishes',
                             'American Indian/Alaska Native Foods',
                             'Soups, Sauces, and Gravies'}
COMPOSED_DISH_ALLOWED_KEYWORDS = {
    'sandwich', 'pizza', 'burger', 'cheeseburger', 'hamburger', 'hot dog',
    'taco', 'burrito', 'soup', 'stew', 'casserole', 'salad', 'lasagna',
    'quiche', 'chowder', 'noodle', 'pasta',
}

# ───────────────────────── 2. Mots-clés (priorité absolue) ─────────────────────────
TOP_PRIORITY_OVERRIDES = [
    ('french fries', '🍟'), ('fries', '🍟'), ('fried', None),  # 'fried' seul: pas d'icone dediee, laisse tomber au mot suivant
]
TOP_PRIORITY_OVERRIDES = [(k, v) for k, v in TOP_PRIORITY_OVERRIDES if v]

# ───────────────────────── 3. Mots-clés ordinaires ─────────────────────────
# Plats composites d'abord (comme CIQUAL) : un ingrédient cité plus loin
# dans le nom ne doit jamais l'emporter sur le plat lui-même.
KEYWORD_OVERRIDES = [
    ('sandwich', '🥪'), ('cheeseburger', '🍔'), ('hamburger', '🍔'), ('burger', '🍔'),
    ('pizza', '🍕'), ('hot dog', '🌭'), ('taco', '🌮'), ('burrito', '🌯'),
    ('quiche', '🥧'), ('lasagna', '🍝'), ('chowder', '🍜'), ('stew', '🍲'),

    # Fruits
    ('banana', '🍌'), ('orange', '🍊'), ('tangerine', '🍊'), ('mandarin', '🍊'),
    ('clementine', '🍊'), ('grapefruit', '🍊'), ('lemon', '🍋'), ('lime', '🍋'),
    ('strawberry', '🍓'), ('strawberries', '🍓'), ('grape', '🍇'), ('raisin', '🍇'),
    ('sweet potato', '🍠'), ('sweetpotato', '🍠'), ('potato', '🥔'),
    ('watermelon', '🍉'), ('cantaloupe', '🍈'), ('honeydew', '🍈'), ('melon', '🍈'),
    ('pear', '🍐'), ('peach', '🍑'), ('nectarine', '🍑'), ('plum', '🍑'), ('apricot', '🍑'),
    ('cherry', '🍒'), ('cherries', '🍒'), ('kiwifruit', '🥝'), ('kiwi', '🥝'),
    ('pineapple', '🍍'), ('mango', '🥭'), ('papaya', '🥭'),
    ('coconut', '🥥'), ('avocado', '🥑'), ('apple', '🍎'),
    ('date', '🌴'), ('dates,', '🌴'),
    ('blueberry', '🫐'), ('blueberries', '🫐'), ('raspberry', '🫐'), ('raspberries', '🫐'),
    ('blackberry', '🫐'), ('blackberries', '🫐'), ('cranberry', '🫐'), ('cranberries', '🫐'),
    ('gooseberry', '🫐'), ('currant', '🫐'), ('boysenberry', '🫐'),
    # Même correctif que côté CIQUAL (13/08/2026, retour d'Alex) : aucun
    # emoji figue n'existe, sans mot-clé "Figs, dried" retombait sur le
    # défaut 🍎 (pomme) — rond violet, même convention que côté français.
    ('fig,', '🟣'), ('figs,', '🟣'),

    # Légumes
    ('tomato', '🍅'), ('carrot', '🥕'), ('corn', '🌽'), ('maize', '🌽'),
    ('eggplant', '🍆'), ('aubergine', '🍆'),
    ('bell pepper', '🫑'), ('sweet pepper', '🫑'), ('chili pepper', '🌶️'),
    ('chile pepper', '🌶️'), ('jalapeno', '🌶️'), ('cayenne', '🌶️'),
    ('broccoli', '🥦'), ('mushroom', '🍄'), ('onion', '🧅'), ('shallot', '🧅'),
    ('leek', '🧅'), ('garlic', '🧄'), ('cucumber', '🥒'), ('zucchini', '🥒'),
    ('courgette', '🥒'), ('pickle', '🥒'),
    ('spinach', '🥬'), ('lettuce', '🥬'), ('cabbage', '🥬'), ('kale', '🥬'),
    ('endive', '🥬'), ('chicory', '🥬'), ('arugula', '🥬'), ('watercress', '🥬'),
    ('bok choy', '🥬'), ('collard', '🥬'), ('chard', '🥬'), ('celery', '🥬'),
    ('artichoke', '🍃'), ('asparagus', '🌱'),
    ('green bean', '🫛'), ('snap bean', '🫛'), ('pea,', '🫛'), ('peas,', '🫛'), ('snow pea', '🫛'),
    ('pumpkin', '🎃'), ('squash', '🎃'), ('zucchini', '🥒'),
    ('bamboo', '🎋'), ('seaweed', '🌊'), ('kelp', '🌊'), ('nori', '🌊'),
    ('sunflower seed', '🥜'), ('sunflower', '🥜'),

    # Fruits à coque / graines
    ('peanut', '🥜'), ('almond', '🌰'), ('walnut', '🌰'), ('hazelnut', '🌰'),
    ('chestnut', '🌰'), ('pecan', '🌰'), ('cashew', '🌰'), ('pistachio', '🌰'),
    ('macadamia', '🌰'), ('pine nut', '🌰'), ('brazil nut', '🌰'),

    # Viandes / volailles / gibier — même variété qu'apportée à CIQUAL cette
    # session (ne jamais laisser une espèce sans mot-clé propre retomber sur
    # le défaut boeuf).
    ('chicken', '🍗'), ('turkey', '🍗'), ('duck', '🦆'), ('goose', '🦆'),
    ('quail', '🍗'), ('pheasant', '🍗'), ('guinea hen', '🍗'), ('squab', '🍗'),
    ('poultry', '🍗'),
    ('beef', '🥩'), ('veal', '🥩'), ('lamb', '🐑'), ('mutton', '🐑'), ('goat', '🐐'),
    ('venison', '🦌'), ('deer', '🦌'), ('elk', '🦌'), ('moose', '🦌'),
    ('bison', '🥩'), ('buffalo', '🥩'), ('horse', '🐴'), ('rabbit', '🐇'), ('hare', '🐇'),
    ('boar', '🐗'), ('pork', '🥓'), ('ham', '🍖'), ('bacon', '🥓'),
    ('sausage', '🌭'), ('frankfurter', '🌭'), ('bologna', '🍖'), ('salami', '🍖'),
    ('pepperoni', '🍖'), ('pate', '🍖'), ('pâté', '🍖'),

    # Poissons / fruits de mer
    ('shrimp', '🦐'), ('prawn', '🦐'), ('crab', '🦀'), ('lobster', '🦞'),
    ('crayfish', '🦞'), ('oyster', '🦪'), ('mussel', '🦪'), ('clam', '🦪'),
    ('scallop', '🦪'), ('salmon', '🐟'), ('tuna', '🐟'), ('cod', '🐟'),
    ('sardine', '🐟'), ('anchovy', '🐟'), ('herring', '🐟'), ('mackerel', '🐟'),
    ('trout', '🐟'), ('halibut', '🐟'), ('tilapia', '🐟'), ('catfish', '🐟'),
    ('bass,', '🐟'), ('snapper', '🐟'), ('flounder', '🐟'), ('sole,', '🐟'),
    ('squid', '🦑'), ('calamari', '🦑'), ('octopus', '🐙'), ('snail', '🐌'),
    ('escargot', '🐌'), ('frog', '🐸'), ('surimi', '🦀'),

    # Laitiers / oeufs
    ('cheese', '🧀'), ('yogurt', '🥛'), ('yoghurt', '🥛'), ('butter', '🧈'),
    ('egg,', '🥚'), ('eggs,', '🥚'), ('omelet', '🥚'),

    # Féculents / céréales / boulangerie
    ('rice,', '🍚'), ('noodle', '🍜'), ('pasta', '🍝'), ('spaghetti', '🍝'),
    ('macaroni', '🍝'), ('bread,', '🍞'), ('baguette', '🥖'), ('croissant', '🥐'),
    ('bagel', '🥯'), ('muffin', '🧁'), ('pancake', '🥞'), ('waffle', '🧇'),
    ('tortilla', '🫓'), ('pretzel', '🥨'),

    # Sucré / snacks
    ('chocolate', '🍫'), ('cocoa', '🍫'), ('honey', '🍯'), ('jam,', '🍯'),
    ('jelly,', '🍯'), ('preserve', '🍯'), ('cookie', '🍪'), ('biscuit', '🍪'),
    ('cake,', '🍰'), ('cakes,', '🍰'), ('pie,', '🥧'), ('pies,', '🥧'),
    ('candy', '🍬'), ('candies', '🍬'), ('popcorn', '🍿'),
    ('chip,', '🍟'), ('chips,', '🍟'), ('pretzel', '🥨'),
    ('ice cream', '🍦'), ('sorbet', '🍧'), ('gelatin', '🍮'),

    # Boissons
    ('coffee', '☕'), ('espresso', '☕'), ('tea,', '🍵'), ('wine', '🍷'),
    ('beer', '🍺'), ('cocktail', '🍸'), ('soda', '🥤'), ('cola', '🥤'), ('juice', '🧃'),
]

# ───────────────────────── 4. Exclusions (faux-amis) ─────────────────────────
KEYWORD_EXCLUSIONS = {
    'wine': ['vinegar'],  # "wine" != "vinegar" (même piège qu'en français vin/vinaigre)
    # "Oyster crackers" (variété de biscuit salé) et la découpe boucherie
    # "oyster" (petit morceau de volaille près du dos, ex. "Emu, oyster,
    # raw"/"Ostrich, oyster, cooked") n'ont rien à voir avec le coquillage —
    # même piège que "fruits à coque"/coque en français.
    'oyster': ['oyster cracker', 'includes oyster', 'emu, oyster', 'ostrich, oyster'],
    # Même casse-tête sur les biscuits salés : "soda crackers" désigne une
    # autre variété de biscuit, pas la boisson gazeuse.
    'soda': ['includes oyster'],
}

NOVA_UP = ['formulated', 'imitation', 'restructured', 'textured', 'hydrolyzed',
           'reconstituted', 'fortified', 'enriched with', 'artificial']
NOVA_MID = [
    'smoked', 'cured', 'salted', 'pickled', 'canned', 'fermented',
    # Charcuterie : intrinsèquement transformée même sans mention explicite
    # "cured"/"smoked" dans le nom ("HORMEL, Cure 81 Ham" ou "HORMEL Canadian
    # Style Bacon" retombaient sinon sur le défaut catégorie NOVA 1, faute
    # de mot-clé — un jambon ou du bacon n'est jamais un aliment brut.
    'ham', 'bacon', 'sausage', 'salami', 'pepperoni', 'bologna', 'frankfurter',
]
NOVA_DOWN = ['raw', 'fresh']


def norm(s):
    s = s.lower()
    nfkd = unicodedata.normalize('NFKD', s)
    return ''.join(c for c in nfkd if not unicodedata.combining(c))


def kw_in(kw, text, full_text=None):
    if kw in KEYWORD_EXCLUSIONS:
        excl_text = full_text if full_text is not None else text
        if any(norm(e) in excl_text for e in KEYWORD_EXCLUSIONS[kw]):
            return False
    nkw = norm(kw)
    # USDA écrit très majoritairement au pluriel en tête de nom ("Almonds,",
    # "Artichokes,", "Tomatoes, grape, raw"...) — contrairement à CIQUAL. Un
    # mot-clé simple (un seul mot, sans virgule de désambiguïsation) autorise
    # donc "s" OU "es" en fin de mot (l'anglais pluralise "-o" en "-oes" :
    # tomato -> tomatoes, potato -> potatoes ; un simple "+s" ratait ces
    # deux-là malgré leur fréquence), plutôt que dupliquer chaque entrée en
    # singulier ET pluriel dans la liste.
    suffix = r'(es|s)?' if (' ' not in nkw and not nkw.endswith(',')) else ''
    return re.search(r'(?<![a-z0-9])' + re.escape(nkw) + suffix + r'(?![a-z0-9])', text) is not None


def pick_icon_nova(name, category):
    groupe, icon, nova = CATEGORY_INFO.get(category, ('autres', DEFAULT_ICON, DEFAULT_NOVA))
    head = name.split(',')[0].strip()
    n_head, n_full = norm(head), norm(name)

    for kw, ic in TOP_PRIORITY_OVERRIDES:
        if kw_in(kw, n_full, full_text=n_full):
            icon = ic
            break
    else:
        is_composed = category in COMPOSED_DISH_CATEGORIES
        for kw, ic in KEYWORD_OVERRIDES:
            if is_composed and kw not in COMPOSED_DISH_ALLOWED_KEYWORDS:
                continue
            if kw_in(kw, n_head, full_text=n_full):
                icon = ic
                break
        else:
            for kw, ic in KEYWORD_OVERRIDES:
                if is_composed and kw not in COMPOSED_DISH_ALLOWED_KEYWORDS:
                    continue
                if kw_in(kw, n_full, full_text=n_full):
                    icon = ic
                    break

    if category in CONTAINER_LOCK_CATEGORIES:
        allowed = CONTAINER_LOCK_CATEGORIES[category]
        if allowed is None or icon not in allowed:
            icon = CATEGORY_INFO[category][1]

    for kw in NOVA_UP:
        if kw_in(kw, n_full, full_text=n_full):
            nova = max(nova, 4)
            break
    else:
        for kw in NOVA_MID:
            if kw_in(kw, n_full, full_text=n_full):
                nova = max(nova, 3)
                break
        else:
            for kw in NOVA_DOWN:
                if kw_in(kw, n_full, full_text=n_full):
                    nova = min(nova, 1) if nova <= 2 else nova
                    break

    return groupe, icon, nova


def main():
    with open(SRC, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    icon_counter = {}
    for row in rows:
        # Ré-exécutable : la 1re passe renomme 'usda_category' en 'sous_groupe'
        # (voir plus bas) et retire la colonne d'origine — une 2e exécution
        # (ex. après une correction de mots-clés) doit donc relire depuis
        # 'sous_groupe' si 'usda_category' n'existe plus.
        category = row.get('usda_category') or row['sous_groupe']
        groupe, icon, nova = pick_icon_nova(row['nom'], category)
        # Retour d'Alex (11/08/2026, 2e passe) : plus de "cheat meal"/groupe à
        # part — la famille alimentaire normale (viandes/plats composés/...)
        # et son picto restent inchangés, seule la colonne source_type
        # (déjà posée par build_usda_foods.py : generic/marque/restaurant)
        # permet à l'app de filtrer/afficher une mention "Marque"/
        # "Restaurant" si besoin. Le NOVA suit la même estimation par
        # mot-clé que le reste — déjà réaliste ici, les catégories Fast
        # Foods/Restaurant Foods/Meals défaultent déjà à 4 (voir
        # CATEGORY_INFO), sans avoir besoin d'un forçage en plus.
        row['groupe'] = groupe
        row['sous_groupe'] = category
        row['pictogramme'] = icon
        row['score_nova_estime'] = str(nova)
        row['nom_generique'] = row['nom']
        icon_counter[icon] = icon_counter.get(icon, 0) + 1

    # 'source'/'source_type'/'brand' gardés tout à la fin, utiles côté app.
    # Ré-exécutable : exclut aussi les colonnes de taxonomie elles-mêmes de
    # la liste "gardée telle quelle" avant de les rajouter — sans ça, une 2e
    # exécution sur un fichier déjà traité dupliquait
    # groupe/sous_groupe/pictogramme/score_nova_estime/nom_generique (bug
    # trouvé le 13/08/2026 en ré-exécutant après correctif de mots-clés).
    _regenerated_cols = ('usda_category', 'source', 'source_type', 'brand',
                          'groupe', 'sous_groupe', 'pictogramme', 'score_nova_estime', 'nom_generique')
    new_fieldnames = [c for c in fieldnames if c not in _regenerated_cols] + \
        ['groupe', 'sous_groupe', 'pictogramme', 'score_nova_estime', 'nom_generique',
         'source', 'source_type', 'brand']

    with open(SRC, 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=new_fieldnames)
        w.writeheader()
        for row in rows:
            w.writerow({k: row.get(k, '') for k in new_fieldnames})

    print(f'OK -> {len(rows)} lignes, taxonomie ajoutée.')
    default_count = icon_counter.get(DEFAULT_ICON, 0)
    print(f'Sur défaut générique {DEFAULT_ICON} : {default_count} ({default_count/len(rows)*100:.1f}%)')


if __name__ == '__main__':
    main()
