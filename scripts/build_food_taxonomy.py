#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ajoute 4 colonnes à assets/foods.csv à partir des 3490 lignes existantes,
sans jamais modifier une colonne/valeur existante :

  - groupe / sous_groupe   : jointure sur assets/Table Ciqual 2025.csv (officiel ANSES),
                              6 aliments hors-CIQUAL (90001-90006) classés manuellement.
  - pictogramme            : emoji par défaut au niveau du sous-groupe + surcharges par
                              mot-clé pour les aliments les plus reconnaissables.
  - score_nova_estime      : 1-4, ESTIMATION TOTUM (CIQUAL ne fournit pas nativement le
                              NOVA) — règle par sous-groupe + mots-clés. Jamais présentée
                              comme une donnée officielle.
  - nom_generique          : libellé court dérivé par règles (cf. cahier des charges
                              tasks/2026-08-10_Refonte foods.csv...).

Produit :
  - assets/foods.csv (mis à jour, UTF-8, même ordre de lignes)
  - assets/foods.csv.backup_avant_taxonomie (sauvegarde de l'original)
  - scripts/_taxonomy_report.md (rapport de vérification : diff, échantillons)
"""
import csv
import re
import shutil
from collections import Counter, defaultdict

SRC_FOODS = 'assets/foods.csv'
SRC_OFFICIAL = 'assets/Table Ciqual 2025.csv'
BACKUP = 'assets/foods.csv.backup_avant_taxonomie'
REPORT = 'scripts/_taxonomy_report.md'

# ───────────────────────── 1. Classement officiel ANSES ─────────────────────────

def load_official_groups():
    with open(SRC_OFFICIAL, encoding='utf-8-sig', newline='') as f:
        r = csv.DictReader(f)
        m = {}
        for row in r:
            code = row['alim_code'].strip()
            g = row['alim_grp_nom_fr'].strip()
            sg = row['alim_ssgrp_nom_fr'].strip()
            m[code] = (g, sg)
    return m

# Aliments hors-CIQUAL (ajoutés lors de l'audit nutriments précédent) + 2 cas
# CIQUAL avec groupe/sous-groupe vide dans la table officielle.
MANUAL_GROUPS = {
    '90001': ('produits sucrés', 'compléments protéinés'),   # Whey isolat
    '90002': ('produits sucrés', 'compléments protéinés'),   # Whey boisson
    '90003': ('produits sucrés', 'compléments protéinés'),   # Protéine de soja isolat
    '90004': ('produits sucrés', 'compléments protéinés'),   # Protéine de soja boisson
    '90005': ('produits sucrés', 'compléments protéinés'),   # Blanc d'oeuf déshydraté
    '90006': ('fruits, légumes, légumineuses et oléagineux', 'légumineuses'),  # Natto (soja fermenté)
    '24999': ('produits sucrés', 'gâteaux et pâtisseries'),   # "Dessert (aliment moyen)" — groupe vide dans la table officielle
    '39500': ('glaces et sorbets', 'sorbets'),                 # sous-groupe "-" dans la table officielle
}

# ───────────────────────── 2. Pictogramme + NOVA par sous-groupe ─────────────────────────
# clé = (groupe, sous_groupe) exactement comme dans la table officielle ANSES.

SUBGROUP_ICON_NOVA = {
    # 15e audit (13/08/2026, sweep systématique de TOUS les sous-groupes —
    # rejeu de pick_icon_nova() sur la base entière, sous-groupe par sous-
    # groupe) : 🧂 (sel) comme défaut de "aides culinaires" peignait en sel
    # du bicarbonate de soude, de la gélatine, de la levure chimique, du
    # bouillon déshydraté, de l'extrait de levure, du pollen, du son
    # d'avoine/de blé, de la vanille en extrait... — AUCUN de ces 41 aliments
    # n'est réellement du sel (le sel lui-même vit dans le sous-groupe "sels"
    # séparé, juste en dessous). Même contresens que condiments/ail :
    # 🥄 (cuillère, neutre "ingrédient/additif de cuisine") remplace 🧂.
    ('aides culinaires et ingrédients divers', 'aides culinaires'): ('🥄', 2),
    # 8e audit (11/08/2026, "je veux une bibliothèque ultra pertinente") :
    # les algues sont des plantes MARINES, pas des herbes de jardin — 🌊
    # distingue ce rayon du rayon "herbes" (basilic, thym...) qui garde 🌿.
    ('aides culinaires et ingrédients divers', 'algues'): ('🌊', 1),
    # Re-audit NOVA (10/08/2026, retour d'Alex) : cornichons/câpres sont mis en
    # bocal (vinaigre/saumure), ce n'est pas un simple ingrédient culinaire
    # comme le sel ou l'huile (groupe 2) — c'est un aliment conservé (groupe 3),
    # cohérent avec la définition NOVA. Corrigé de 2 → 3.
    # 14e audit (13/08/2026, retour d'Alex — "pour le vinaigre de cidre, j'ai
    # le logo d'un ail") : 🧄 (ail) était le défaut de TOUT le sous-groupe
    # "condiments" alors qu'aucun des 17 aliments qu'il contient n'est
    # réellement de l'ail — vinaigres (4), moutardes (2), miso, cornichons
    # (2), câpres héritaient tous d'un ail par défaut. Même contresens que
    # huile d'olive/tournesol au 8e audit : 🫙 (bocal, neutre) remplace 🧄
    # comme défaut ; 🧄 lui-même n'a plus aucune raison d'apparaître ici
    # (aucun aliment "ail" dans ce sous-groupe).
    ('aides culinaires et ingrédients divers', 'condiments'): ('🫙', 3),
    ('aides culinaires et ingrédients divers', 'denrées destinées à une alimentation particulière'): ('🏥', 4),
    ('aides culinaires et ingrédients divers', 'herbes'): ('🌿', 1),
    ('aides culinaires et ingrédients divers', 'ingrédients pour végétariens'): ('🌱', 3),
    ('aides culinaires et ingrédients divers', 'sauces'): ('🥫', 4),
    ('aides culinaires et ingrédients divers', 'sels'): ('🧂', 1),
    # 14e audit (13/08/2026) : 🥑 (avocat) n'est fidèle que pour le guacamole
    # (1 aliment sur 7 de ce sous-groupe) — houmous, caviar de tomates,
    # tzatziki, ktipiti héritaient tous d'un avocat par défaut. 🫙 (bocal,
    # même neutre que "condiments" juste au-dessus, même famille "produit
    # préemballé en pot") ; "guacamole" récupère 🥑 explicitement via
    # mot-clé dédié ci-dessous, pour rester fidèle sur ce cas précis.
    ('aides culinaires et ingrédients divers', 'tartinables végétariens'): ('🫙', 3),
    # 8e audit : 🌶️ (piment) comme défaut de TOUTE la famille "épices"
    # peignait la cannelle, la cardamome, le curcuma, la vanille... en piment
    # — vrai contresens visuel. 🌿 (déjà utilisé pour les herbes) est un
    # repère neutre "assaisonnement végétal" ; 🌶️ reste réservé au piment/
    # poivre de Cayenne via mot-clé dédié.
    ('aides culinaires et ingrédients divers', 'épices'): ('🌿', 1),

    ('aliments infantiles', 'céréales et biscuits infantiles'): ('🍼', 4),
    ('aliments infantiles', 'desserts infantiles'): ('🍼', 4),
    ('aliments infantiles', 'laits et boissons infantiles'): ('🍼', 4),
    ('aliments infantiles', 'petits pots salés et plats infantiles'): ('🍼', 3),

    # 15e audit (13/08/2026) : 🍷 (verre de vin) comme défaut de TOUTE la
    # famille "boisson alcoolisées" peignait en vin le cidre (6 aliments), le
    # rhum, le whisky, la vodka, le gin, le pastis, le saké, les eaux-de-vie
    # (calvados, armagnac...), les liqueurs, le marsala, la sangria et tous
    # les cocktails — 36 aliments sur 50 (72%), le même contresens que huile
    # d'olive/ail déjà corrigés, à plus grande échelle. 🥃 (verre tumbler,
    # sans pied ni forme de ballon — contrairement à 🍷 qui EST visuellement
    # un verre à vin) est le repère le plus neutre disponible pour "une
    # boisson alcoolisée quelconque" ; 🍷 reste réservé au vin lui-même
    # (mot-clé "vin" déjà présent), 🍺 à la bière.
    ('eaux et autres boissons', 'boisson alcoolisées'): ('🥃', 3),
    ('eaux et autres boissons', 'boissons sans alcool'): ('🥤', 4),
    ('eaux et autres boissons', 'eaux'): ('💧', 1),

    # 15e audit : 🥐 (croissant) comme défaut de "feuilletées et autres
    # entrées" peignait en croissant le beignet de viande, la bouchée à la
    # reine, le brick à l'oeuf, le cake salé, le feuilleté/friand au
    # fromage/à la viande/aux escargots... — 26 aliments sur 26 (100%),
    # AUCUN n'est un croissant (ce sont tous des entrées salées, jamais de la
    # viennoiserie). 🥟 (chausson/beignet fourré, neutre "bouchée salée
    # enveloppée") remplace 🥐, plus fidèle à ce que couvre réellement ce
    # sous-groupe (bricks, feuilletés, friands, bouchées à la reine).
    ('entrées et plats composés', 'feuilletées et autres entrées'): ('🥟', 4),
    # 15e audit : 🍕 (pizza) comme défaut de "pizzas, TARTES ET CRÊPES
    # SALÉES" peignait en pizza les crêpes/galettes (béchamel, jambon,
    # fromage, poisson, noix de Saint-Jacques...), les tartes flambées, les
    # burritos, fajitas et pastillas — 47 aliments sur 49 (96%). La vraie
    # pizza garde 🍕 via son propre mot-clé (déjà présent, prioritaire) ;
    # 🫓 (pain plat, neutre "pâte/galette salée") remplace 🍕 comme défaut,
    # bien plus fidèle pour une crêpe, une tarte ou un burrito.
    ('entrées et plats composés', 'pizzas, tartes et crêpes salées'): ('🫓', 4),
    ('entrées et plats composés', 'plats composés'): ('🍲', 4),
    ('entrées et plats composés', 'salades composées et crudités'): ('🥗', 3),
    ('entrées et plats composés', 'sandwichs'): ('🥪', 4),
    ('entrées et plats composés', 'soupes'): ('🍜', 3),

    ('fruits, légumes, légumineuses et oléagineux', 'fruits'): ('🍎', 1),
    ('fruits, légumes, légumineuses et oléagineux', 'fruits à coque et graines oléagineuses'): ('🥜', 1),
    ('fruits, légumes, légumineuses et oléagineux', 'légumes'): ('🥦', 1),
    ('fruits, légumes, légumineuses et oléagineux', 'légumineuses'): ('🫘', 1),
    ('fruits, légumes, légumineuses et oléagineux', 'pommes de terre et autres tubercules'): ('🥔', 1),

    ('glaces et sorbets', 'desserts glacés'): ('🍨', 4),
    ('glaces et sorbets', 'glaces'): ('🍦', 4),
    ('glaces et sorbets', 'sorbets'): ('🍧', 4),

    # 15e audit (13/08/2026) : "autres matières grasses" contient 6 aliments —
    # graisse d'oie/de canard/de dinde/de poulet (déjà couvertes par leurs
    # mots-clés animaliers respectifs) MAIS aussi "Lard gras, cru" et
    # "Saindoux", qui tombaient sur le défaut 🧈 (beurre, un corps gras
    # LAITIER) alors que le lard/saindoux est un corps gras PORCIN — faux-ami
    # nutritionnel direct (laitier vs viande), pas juste visuel. 🥓 (bacon,
    # déjà le repère "porc" établi ailleurs dans ce fichier) remplace 🧈.
    ('matières grasses', 'autres matières grasses'): ('🥓', 2),
    ('matières grasses', 'beurres'): ('🧈', 2),
    # 13e audit (11/08/2026, "c'est le poisson qui est dessiné, pas l'huile") :
    # même contresens que l'huile d'olive au 8e audit — l'huile de foie de
    # morue/de hareng affichait le poisson d'origine plutôt qu'un flacon,
    # alors que TOUTES les autres huiles (végétales) montrent déjà 🧴.
    ('matières grasses', 'huiles de poissons'): ('🧴', 2),
    # 8e audit : 🫒 (olive) comme défaut de TOUTE la famille "huiles" peignait
    # l'huile de colza, de lin, de sésame, de tournesol... en huile d'olive —
    # contresens direct. 🧴 (flacon) est un repère neutre "corps gras
    # liquide" ; 🫒 reste réservé à l'huile d'olive elle-même via mot-clé.
    ('matières grasses', 'huiles et graisses végétales'): ('🧴', 2),
    # 15e audit : "margarines" (100% "Matière grasse tartinable...", aucun
    # aliment nommé "margarine" littéralement) affichait 🧈 (beurre) — un
    # corps gras LAITIER — pour un produit à base d'huiles VÉGÉTALES,
    # exactement le même faux-ami nutritionnel que lard/saindoux ci-dessus,
    # à front renversé. 🧴 (flacon neutre, déjà le repère "corps gras
    # végétal" établi pour les huiles ci-dessus) remplace 🧈.
    ('matières grasses', 'margarines'): ('🧴', 4),

    ('produits céréaliers', 'biscuits apéritifs'): ('🍘', 4),
    ('produits céréaliers', 'farines'): ('🌾', 1),
    ('produits céréaliers', 'pains et assimilés'): ('🍞', 3),
    ('produits céréaliers', 'pâtes à tarte'): ('🥧', 4),
    # 15e audit : 🍝 (pâtes) comme défaut de "pâtes, RIZ ET CÉRÉALES"
    # peignait en pâtes l'amarante, l'avoine, le blé, le boulgour,
    # l'épeautre, le millet, l'orge, le quinoa, le sarrasin, le seigle, le
    # sorgho... — aucun rapport visuel avec des spaghettis, ce sont des
    # graines/céréales brutes. 🌾 (épi, déjà le repère "céréale" des
    # farines) remplace 🍝 comme défaut ; "pates"/"pâtes" récupère 🍝 via
    # mot-clé dédié ci-dessous (verrouillé à ce seul sous-groupe, pour ne
    # jamais interférer avec "pâté"/"pâte à tarte" ailleurs dans la base).
    ('produits céréaliers', 'pâtes, riz et céréales'): ('🌾', 1),

    ('produits laitiers', 'crèmes et spécialités à base de crème'): ('🥛', 2),
    ('produits laitiers', 'fromages et alternatives végétales'): ('🧀', 3),
    ('produits laitiers', 'laits'): ('🥛', 1),
    ('produits laitiers', 'produits laitiers frais et alternatives végétales'): ('🥛', 3),

    # 15e audit : 🍫 (chocolat) comme défaut de "barres céréalières"
    # peignait en barre chocolatée la "Barre céréalière aux fruits" et la
    # "Barre céréalière diététique hypocalorique" (aucun chocolat), 8/8
    # aliments retombant sur ce défaut. 🌾 (épi, même repère "céréale" que
    # farines/pâtes-riz-céréales ci-dessus) remplace 🍫 ; le chocolat garde
    # son mot-clé dédié pour les vraies barres chocolatées.
    ('produits sucrés', 'barres céréalières'): ('🌾', 4),
    ('produits sucrés', 'biscuits sucrés'): ('🍪', 4),
    ('produits sucrés', 'chocolats et produits à base de chocolat'): ('🍫', 4),
    ('produits sucrés', 'confiseries non chocolatées'): ('🍬', 4),
    # 15e audit : 🍯 (pot de miel) comme défaut de "confitures et assimilés"
    # affichait un miel sur la crème de pruneaux, la gelée générique, la
    # marmelade d'agrumes mélangés, les "préparations de fruits divers" —
    # aucun de ces aliments n'est du miel (le miel a son propre sous-groupe
    # "sucres, miels et assimilés" séparé, qui garde 🍯). 🫙 (bocal, même
    # repère neutre que condiments/tartinables) remplace 🍯 comme défaut ;
    # les mots-clés "confiture"/"miel" continuent d'afficher 🍯 pour les
    # aliments qui le nomment explicitement.
    ('produits sucrés', 'confitures et assimilés'): ('🫙', 3),
    ('produits sucrés', 'céréales de petit-déjeuner'): ('🥣', 4),
    ('produits sucrés', 'gâteaux et pâtisseries'): ('🍰', 4),
    ('produits sucrés', 'sucres, miels et assimilés'): ('🍯', 2),
    ('produits sucrés', 'viennoiseries'): ('🥐', 4),
    ('produits sucrés', 'compléments protéinés'): ('🥤', 4),

    ('viandes, oeufs, poissons', 'autres produits à base de viande'): ('🍖', 4),
    # 15e audit : 🥓 (bacon) comme défaut de "charcuteries et alternatives
    # végétales" peignait en bacon l'andouille, l'andouillette, le boudin
    # blanc/noir, le bresaola... — 84 aliments sur 176 (48%), aucun d'entre
    # eux n'est du bacon. 🍖 (viande sur l'os, déjà le repère "charcuterie/
    # viande générique" établi pour jambon/saucisson dans ce fichier)
    # remplace 🥓 ; le bacon garde son propre mot-clé pour les vrais produits
    # de bacon.
    ('viandes, oeufs, poissons', 'charcuteries et alternatives végétales'): ('🍖', 4),
    ('viandes, oeufs, poissons', 'mollusques et crustacés crus'): ('🦐', 1),
    ('viandes, oeufs, poissons', 'mollusques et crustacés cuits'): ('🦐', 1),
    ('viandes, oeufs, poissons', 'oeufs'): ('🥚', 1),
    ('viandes, oeufs, poissons', 'poissons crus'): ('🐟', 1),
    ('viandes, oeufs, poissons', 'poissons cuits'): ('🐟', 1),
    # 13e audit : 🦞 (homard, un crustacé minoritaire dans ce sous-groupe)
    # comme défaut peignait le hareng, la morue... en homard — la grande
    # majorité des aliments de ce sous-groupe sont des poissons, pas des
    # crustacés (déjà distingués par mot-clé : crevette/crabe/homard...).
    ('viandes, oeufs, poissons', 'produits à base de poissons et produits de la mer'): ('🐟', 3),
    ('viandes, oeufs, poissons', 'viandes crues'): ('🥩', 1),
    ('viandes, oeufs, poissons', 'viandes cuites'): ('🥩', 1),
}

DEFAULT_ICON, DEFAULT_NOVA = '🍽️', 3

# Priorité absolue : cherché sur le nom ENTIER avant même la logique tête/texte
# complet des autres mots-clés — jamais bloqué par un autre mot-clé trouvé plus
# tôt dans le nom (ex. "pomme de terre" ne doit jamais empêcher "préfrite" de
# gagner, même si "préfrite" est seulement dans le 2e segment du nom).
ICON_TOP_PRIORITY_OVERRIDES = [
    ('frite', '🍟'), ('frites', '🍟'), ('préfrite', '🍟'), ('préfrites', '🍟'),
]

# Surcharges pictogramme par mot-clé (prioritaires sur le défaut du sous-groupe).
# Ordre = ordre de test ; le premier mot-clé trouvé dans le nom (insensible casse/accents) gagne.
ICON_KEYWORD_OVERRIDES = [
    # Plats composites d'abord : sinon un ingrédient cité dans le nom (ex. "saucisson"
    # dans "Sandwich ... saucisson ...") gagnerait à tort sur le plat lui-même.
    ('sandwich', '🥪'), ('pizza', '🍕'), ('burger', '🍔'), ('quiche', '🥧'),
    ('soupe', '🍜'), ('salade composée', '🥗'),
    # 12e audit (11/08/2026, vérif systématique "un mot-clé qui ne matche
    # jamais rien" — a débusqué la coquille "pourpire" du round précédent) :
    # "lasagne" (singulier) ne matchait jamais — CIQUAL écrit toujours
    # "Lasagnes" (pluriel). Les 5 lasagnes retombaient sur le défaut
    # générique "plats composés" (🍲) au lieu de 🍝.
    ('lasagne', '🍝'), ('lasagnes', '🍝'),

    ('banane', '🍌'), ('orange', '🍊'), ('mandarine', '🍊'), ('clementine', '🍊'),
    ('pamplemousse', '🍊'), ('citron', '🍋'), ('fraise', '🍓'), ('raisin', '🍇'),
    # 2e passe d'audit (10/08/2026, retour d'Alex — "trop d'incohérences") :
    # "pomme de terre" DOIT être testé avant "pomme" isolé, sinon toutes les
    # pommes de terre héritaient de l'emoji pomme 🍎 (faux-ami classique).
    ('pomme de terre', '🥔'), ('pommes de terre', '🥔'), ('patate douce', '🍠'),
    ('pasteque', '🍉'), ('melon', '🍈'), ('poire', '🍐'), ('peche', '🍑'),
    ('cerise', '🍒'), ('kiwi', '🥝'), ('ananas', '🍍'), ('mangue', '🥭'),
    # 15e audit (13/08/2026) : "Ceriser, chair et peau, sans noyau, crue"
    # (code 13008) ne matchait pas "cerise" (mot entier requis, "ceriser"
    # a une lettre de plus) — vérifié dans la table CIQUAL officielle : la
    # colonne nom scientifique de cette ligne indique bien "Prunus avium L."
    # (le cerisier doux), donc une vraie cerise malgré la coquille dans le
    # nom français officiel ANSES. Même défaut de mot entier que "lasagne"/
    # "nouille" déjà corrigés (12e audit) — pas une régression, un gap.
    ('ceriser', '🍒'),
    # 13e audit (11/08/2026, "c'est une noix de coco au lieu d'avoir du
    # lait") : testé avant "coco"/"noix de coco" ci-dessous — "lait de coco"
    # EST un lait (végétal), pas la noix elle-même, même logique que les
    # boissons végétales déjà corrigées (contenant avant ingrédient).
    ('lait de coco', '🥛'),
    ('noix de coco', '🥥'), ('coco', '🥥'), ('avocat', '🥑'),
    # 15e audit (13/08/2026) : ces 5 fruits antillais nommés "Pomme ..."
    # (Pomme cajou/cannelle/d'eau/malaca/liane) ne sont PAS des pommes —
    # même contresens visuel que le reste du sweep exotique ci-dessous, mais
    # ceux-ci passaient inaperçus car "pomme" (mot-clé générique 🍎, juste en
    # dessous) les capturait sans qu'on les remarque. Testés AVANT "pomme"
    # pour gagner la priorité (même principe que "pomme de terre" plus haut).
    # Pomme cajou (fruit de l'anacardier, peau rouge-orangé) et Pomme liane
    # (Passiflora laurifolia, cousin du fruit de la passion, jaune-orangé à
    # maturité — vérifié) partagent 🟠 avec les fruits oranges du sweep plus
    # bas. Pomme cannelle (Annona squamosa, même famille botanique que
    # l'anone/chérimole ci-dessous, peau bosselée vert pâle) reprend le même
    # 🟢. Pomme d'eau/pomme malaca (Syzygium samarangense, "wax apple", peau
    # rouge/rose caractéristique) reprend le 🔴 de grenade/rhubarbe plus bas.
    ('pomme cajou', '🟠'), ('pomme cannelle', '🟢'),
    ("pomme d'eau", '🔴'), ('pomme malaca', '🔴'), ('pomme liane', '🟠'),
    # Caïmite (star apple) est nommée dans CIQUAL "Caïmite (ou pomme étoile
    # ou pomme de lait)..." — le nom CONTIENT littéralement "pomme" deux
    # fois (pomme étoile, pomme de lait) : sans cette priorité, le mot-clé
    # générique "pomme" juste en dessous gagnait la course avant même
    # d'atteindre "caimite" plus loin dans la liste (voir 15e audit,
    # sweep exotique plus bas, pour le choix de couleur).
    ('caimite', '🟣'),
    ('pomme', '🍎'),
    # 14e audit : "guacamole" gagnait déjà par coïncidence (défaut du
    # sous-groupe "tartinables végétariens" = avocat) — maintenant que ce
    # défaut passe à un bocal neutre (voir SUBGROUP_ICON_NOVA plus haut), le
    # guacamole a besoin de son propre mot-clé explicite pour garder l'avocat,
    # seul cas où c'est réellement fidèle dans ce sous-groupe.
    ('guacamole', '🥑'),
    # "Houmous" (purée de pois chiches) héritait aussi de l'avocat par
    # défaut — 🫘 (légumineuses), même repère que les autres pois chiches/
    # légumineuses du reste de la base.
    ('houmous', '🫘'), ('hummus', '🫘'),
    # "Ti nain" (petite banane verte, terme créole martiniquais) tombait sur
    # le défaut légumes (🥦, brocoli) faute de mot-clé — c'est une variété de
    # banane, même repère que "banane" ci-dessus.
    ('ti nain', '🍌'),
    ('abricot', '🍑'),
    # 14e audit (13/08/2026, retour d'Alex — "au lieu d'une figue, j'ai le
    # logo d'une pomme") : le 10e audit avait retiré tout repère pour "figue"
    # (aucun emoji figue n'existe) et laissé retomber sur le défaut du
    # sous-groupe fruits (🍎) — en pratique ça AFFICHE une pomme sur une
    # figue, pas juste "un fruit générique" comme espéré. Même correctif que
    # navet/betterave/radis (aucun emoji dédié → rond de couleur neutre
    # plutôt que l'emoji d'un fruit différent) : violet, couleur dominante de
    # la figue mûre. Couvre aussi "Figue de Barbarie" (fruit de cactus,
    # different botaniquement mais même couleur dominante, sans meilleure
    # option). "Prune"/"pruneau" n'avaient eux non plus AUCUN mot-clé (gap
    # jamais comblé, pas une régression) — 7 aliments (prune fraîche,
    # mirabelle, reine-claude, violette, pruneau cuit/sec) montraient 🍎 pour
    # la même raison. Marron/brun, pour distinguer visuellement de la figue.
    ('figue', '🟣'),
    ('prune', '🟤'), ('pruneau', '🟤'),
    # Petits fruits ronds additionnels de la même famille visuelle que la
    # cerise/litchi déjà établie (10e audit) — griotte (cerise acide),
    # longane et ramboutan (cousins du litchi, même forme/taille) n'avaient
    # aucun mot-clé propre.
    ('griotte', '🍒'), ('longane', '🍒'), ('longan', '🍒'),
    ('ramboutan', '🍒'), ('rambutan', '🍒'),
    # "Mango" (orthographe créole/anglaise utilisée par endroits dans CIQUAL,
    # ex. "Mango bassignac, ... prélevé à la Martinique") ne matchait pas le
    # mot-clé français "mangue".
    ('mango', '🥭'),
    ('datte', '🌴'), ('litchi', '🍒'),
    # 3e audit (11/08/2026, retour approfondi d'Alex — "plus de variété, tout
    # doit être cohérent") : "myrtille"/"framboise"/"cassis" servaient déjà à
    # détecter le parfum mais n'avaient jamais de pictogramme dédié (oubli).
    ('framboise', '🫐'), ('myrtille', '🫐'), ('cassis', '🫐'), ('groseille', '🫐'),
    ('mure', '🫐'), ('sureau', '🫐'), ('canneberge', '🫐'), ('cranberry', '🫐'),
    ('baie de goji', '🫐'), ('coing', '🍐'), ('kumquat', '🍊'),
    ('nectarine', '🍑'), ('brugnon', '🍑'), ('papaye', '🥭'),
    # 15e audit (13/08/2026, retour d'Alex — sweep systématique du sous-
    # groupe "fruits" : rejeu de pick_icon_nova() sur les 3490 aliments
    # CIQUAL pour lister tout ce qui retombe encore sur le défaut brut 🍎)
    # a débusqué 14 fruits exotiques + la rhubarbe sans AUCUN mot-clé —
    # ils affichaient donc tous une pomme, le même contresens que la figue
    # corrigée plus haut. Chaque emoji Unicode a été vérifié individuellement
    # (recherche ciblée, versions 9.0 à 16.0, 2016-2024) : AUCUN de ces
    # fruits n'a d'emoji dédié dans le standard (contrairement à mangue/
    # avocat/noix de coco/myrtille/gingembre ajoutés ces dernières années —
    # rien de nouveau côté fruits exotiques depuis 🫚 gingembre, Unicode
    # 15.0/2022 ; la grenade en particulier n'existe toujours pas malgré une
    # pétition Unicode Consortium en ce sens, vérifiée active). Même
    # correctif que figue/prune/racines pâles : un rond de la VRAIE couleur
    # dominante du fruit remplace 🍎, jamais l'emoji d'un fruit différent.
    ('anone', '🟢'), ('cherimole', '🟢'),
    # Caïmite (star apple) : voir plus haut, testé avant "pomme" — les 2
    # cultivars existent réellement (peau verte OU violette selon la
    # variété, vérifié), mais la variété violette est la plus commercialisée/
    # représentée — 🟣 rejoint donc la figue par vraie coïncidence de
    # couleur, pas par facilité de recopiage.
    ('carambole', '🟡'),
    ('chadeque', '🟡'),
    ('dourian', '🟤'), ('durian', '🟤'),
    ('feijoa', '🟢'),
    # "maracudja" (orthographe CIQUAL la plus fréquente) et sa variante
    # "maracuja" (1 occurrence : "Nectar de fruit de la passion ou
    # maracuja") : aux Antilles/à la Réunion, ce nom désigne la variété
    # jaune-orangé (Passiflora edulis f. flavicarpa), distincte du fruit de
    # la passion pourpre (f. edulis) — vérifié, d'où 🟠 plutôt que violet.
    ('fruit de la passion', '🟠'), ('maracudja', '🟠'), ('maracuja', '🟠'),
    # "jacque" seul est IMPOSSIBLE à utiliser comme mot-clé : il matcherait
    # à tort "Coquille Saint-Jacques" et ses 6 dérivés (crêpe/tarte/terrine
    # aux noix de Saint-Jacques) — vérifié sur toute la base. "jacquier"
    # seul suffit, déjà présent dans les 2 noms CIQUAL du fruit ("Fruit du
    # jacquier ou jacque...").
    ('jacquier', '🟡'),
    ('goyave', '🟢'),
    ('grenade', '🔴'),
    ('kaki', '🟠'),
    ('nefle', '🟡'),
    ('tamarin', '🟤'),
    # Rhubarbe (tige) : classée "fruit" par CIQUAL bien que botaniquement un
    # légume à tige, traité culinairement comme un fruit — même défaut 🍎
    # que les autres. Couvre aussi "Compote de rhubarbe" (1 des 3
    # occurrences) : le mot-clé du fruit gagne sur le défaut du contenant
    # "compote"/"confiture", précédent déjà établi dans ce fichier
    # ("Confiture d'abricot" affiche déjà 🍑 via "abricot", testé avant
    # "confiture" dans cette même liste).
    ('rhubarbe', '🔴'),

    # 14e audit : "tomate" (singulier) ne matchait pas "Caviar de TOMATES"
    # (pluriel) — même bug de pluriel que lasagne/nouille/haricot/olive/
    # pomme de terre/petits pois déjà vus 3 audits plus tôt.
    ('tomate', '🍅'), ('tomates', '🍅'), ('carotte', '🥕'), ('mais', '🌽'), ('aubergine', '🍆'),
    ('poivron', '🫑'), ('piment', '🌶️'), ('brocoli', '🥦'), ('champignon', '🍄'),
    ('oignon', '🧅'), ('echalote', '🧅'), ('ail', '🧄'), ('concombre', '🥒'),
    ('courgette', '🥒'), ('epinard', '🥬'), ('laitue', '🥬'), ('chou', '🥬'),
    # 14e audit : cornichon (petit concombre à confire) et câpre n'avaient
    # aucun mot-clé — les deux tombaient sur le défaut du sous-groupe
    # "condiments", désormais un bocal neutre plutôt que l'ail d'avant.
    # Cornichon = même famille visuelle que concombre/courgette.
    ('cornichon', '🥒'), ('capre', '🥒'), ('capres', '🥒'),
    # 6e audit (11/08/2026, "j'ai vu une feuille de partout") : artichaut/
    # asperge partageaient 🌿 avec tout le rayon herbes/algues (basilic, thym,
    # laitue de mer...) — dilué, peu reconnaissable. Dissociés.
    ('artichaut', '🍃'), ('asperge', '🌱'), ('haricot vert', '🫛'),
    ('petit pois', '🫛'), ('petits pois', '🫛'),
    ('pois mange-tout', '🫛'), ('pois gourmand', '🫛'), ('pois d\'angole', '🫘'),
    # 9e audit (11/08/2026, "un brocoli sur un haricot") : les variétés de
    # haricot autres que "vert" (beurre, plat, purée...) n'avaient aucun
    # mot-clé propre — elles retombaient sur le défaut du sous-groupe
    # "légumes" (🥦, brocoli) faute de mieux. "haricot vert"/"petit pois" ci-
    # dessus, testés avant dans la liste, continuent à gagner sur leurs cas
    # précis ; celui-ci ne rattrape que le reste (beurre, plat, purée...).
    ('haricot', '🫘'), ('haricots', '🫘'),
    # 10e audit (11/08/2026, "navet, radis, betterave, mauvais logo") :
    # betterave (rouge/violet foncé) et radis (rouge/blanc) peints en 🥕
    # (carotte, orange) — même faux-ami visuel que navet/rutabaga déjà
    # corrigé plus bas. Aucun emoji dédié n'existe pour l'un ou l'autre :
    # repli sur le légume générique plutôt que sur un légume différent et
    # trompeur (même principe que navet/rutabaga/panais ci-dessous).
    # Courges/citrouilles (famille visuellement très reconnaissable) :
    ('citrouille', '🎃'), ('potiron', '🎃'), ('potimarron', '🎃'),
    ('giraumon', '🎃'), ('courge', '🎃'), ('chayote', '🎃'), ('christophine', '🎃'),
    ('chouchou', '🎃'),
    # Salades/feuillus verts (au-delà de "laitue" déjà présent) :
    ('endive', '🥬'), ('chicoree', '🥬'), ('scarole', '🥬'), ('mache', '🥬'),
    ('pissenlit', '🥬'), ('roquette', '🥬'), ('mesclun', '🥬'), ('batavia', '🥬'),
    ('cresson', '🥬'), ('oseille', '🥬'), ('tetragone', '🥬'),
    # 11e audit (11/08/2026, "navet/radis/betterave, c'est un brocoli à
    # chaque fois — dissocie les légumes") : "pourpire" était une COQUILLE
    # (transposition de lettres) pour "pourpier" — le mot-clé ne matchait
    # donc jamais rien depuis sa création.
    ('pourpier', '🥬'),
    ('celeri', '🥬'),
    # "Bette ou blette" est un légume-feuille (fane comestible), pas un
    # légume générique — même famille visuelle que les salades/feuillus.
    ('bette', '🥬'), ('blette', '🥬'),
    # Légumes racines blancs/beiges/rouges (navet, rutabaga, panais,
    # salsifis, crosne, betterave, radis) : la Priorité 32 avait juste retiré
    # 🥕 (carotte, faux-ami de couleur) SANS rien mettre à la place — au
    # final, 20 aliments totalement différents (une racine blanche, une
    # racine rouge foncé, un radis noir...) partageaient tous 🥦, exactement
    # le défaut signalé par Alex ("c'est un brocoli à chaque fois"). Aucun
    # emoji dédié n'existe pour aucun d'entre eux dans tout Unicode — plutôt
    # que de mentir en réutilisant l'emoji d'un légume différent (le piège
    # qu'on a corrigé partout ailleurs ce round), un rond de couleur neutre
    # DISSOCIE réellement par la couleur réelle du légume, sans jamais
    # prétendre être un aliment différent :
    #   ⚪ racines pâles (navet, rutabaga, panais, salsifis, crosne)
    #   🟣 betterave (rouge violacé foncé)
    #   ⚫ variétés "noires" (radis noir, salsifis noir — la peau est
    #      spécifiquement noire, c'est littéralement dans leur nom)
    #   🔴 radis (rouge/rose, la variété la plus courante)
    ('radis noir', '⚫'), ('salsifis noir', '⚫'),
    ('betterave', '🟣'),
    ('radis', '🔴'),
    ('navet', '⚪'), ('rutabaga', '⚪'), ('panais', '⚪'),
    ('salsifis', '⚪'), ('crosne', '⚪'),
    # Cardon : famille du chardon/artichaut, même repère visuel.
    ('cardon', '🍃'),
    # "Topinambour, pulpe..." (1 aliment, classé à part en sous-groupe
    # "légumes" par CIQUAL) restait sans mot-clé alors que tous ses autres
    # variantes (sous-groupe "pommes de terre et autres tubercules") ont déjà
    # 🥔 par défaut — cohérence entre les deux classements CIQUAL.
    ('topinambour', '🥔'),
    ('fruit a pain', '🍞'),
    ('feuille de chene', '🥬'),
    ('fenouil', '🍃'), ('gombo', '🌿'), ('moringa', '🌿'), ('salicorne', '🌊'),
    ('coeur de palmier', '🌴'), ('bambou', '🎋'),
    # Tubercules tropicaux (famille patate douce) :
    ('igname', '🍠'), ('dachine', '🍠'), ('manioc', '🍠'), ('kamanioc', '🍠'),
    ('massissi', '🍠'),
    ('graine germee', '🌱'), ('pousse de soja', '🌱'), ('germe', '🌱'),
    # 7e audit (11/08/2026) : "Graine de tournesol" avec 🌻 se lisait comme LA
    # FLEUR entière, pas la graine ("c'est un tournesol, c'est pas des
    # graines") — retour au même repère que chia/lin/sésame/luzerne (🥜).
    ('tournesol', '🥜'), ('poireau', '🧅'),
    # "Salade verte" retombait sur le défaut légumes 🥦 (brocoli) faute de
    # mot-clé dédié — confusion directe signalée par Alex.
    ('salade verte', '🥬'), ('salade sucrine', '🥬'),

    ('crevette', '🦐'), ('crabe', '🦀'), ('homard', '🦞'), ('langouste', '🦞'),
    ('huitre', '🦪'), ('moule', '🦪'), ('saumon', '🐟'), ('thon', '🐟'),
    ('sardine', '🐟'), ('cabillaud', '🐟'), ('maquereau', '🐟'), ('anchois', '🐟'),
    ('calmar', '🦑'), ('encornet', '🦑'), ('poulpe', '🐙'), ('escargot', '🐌'),
    # 8e audit : "Grenouille" héritait de 🦐 (crevette, défaut du sous-groupe
    # mollusques/crustacés où CIQUAL la classe) — franchement trompeur, un
    # vrai emoji grenouille existe. "Clam"/"Coque" (mollusques bivalves comme
    # l'huître) rejoignent 🦪 plutôt que 🦐 (crustacé, famille différente).
    ('grenouille', '🐸'), ('clam', '🦪'), ('coque', '🦪'),
    # 15e audit (13/08/2026) : ces mollusques/crustacés sans mot-clé propre
    # retombaient sur le défaut 🦐 (crevette) du sous-groupe — repère
    # raisonnable pour la majorité (13e audit), mais franchement trompeur
    # pour ceux-ci qui ont un emoji ou un cousin déjà établi plus fidèle.
    # Bigorneau/bulot sont des escargots DE MER — rejoignent 🐌 (déjà
    # "escargot" ci-dessus). Ormeau (abalone, coquillage à une valve) rejoint
    # 🦪 (déjà huître/moule/clam/coque ci-dessus). Seiche (céphalopode,
    # cousine directe du calmar/encornet) rejoint 🦑. Araignée de mer EST une
    # espèce de crabe — rejoint 🦀 (déjà "crabe" ci-dessus).
    ('bigorneau', '🐌'), ('bulot', '🐌'), ('ormeau', '🦪'),
    ('seiche', '🦑'), ('araignee de mer', '🦀'),
    # Huile d'olive explicite (🫒), gardée du défaut retiré des autres huiles.
    ('huile d\'olive', '🫒'), ('olive', '🫒'), ('olives', '🫒'), ('chataigne', '🌰'),

    ('poulet', '🍗'), ('dinde', '🍗'), ('canard', '🦆'), ('caille', '🍗'),
    ('boeuf', '🥩'), ('veau', '🥩'), ('agneau', '🐑'), ('mouton', '🐑'),
    ('porc', '🥓'),
    ('jambon', '🍖'), ('bacon', '🥓'), ('saucisse', '🌭'), ('saucisson', '🍖'),
    ('lapin', '🐇'),
    # 13e audit (11/08/2026, "foie de volaille, c'est un boeuf au lieu d'une
    # volaille") : le sous-groupe "viandes crues"/"viandes cuites" défaut sur
    # 🥩 (boeuf/veau) — correct pour la grande majorité (boeuf/veau ont déjà
    # leur mot-clé), mais toute autre espèce sans mot-clé propre héritait à
    # tort du boeuf. Espèces avec un emoji Unicode dédié et fidèle :
    ('cerf', '🦌'), ('chevreuil', '🦌'), ('cheval', '🐴'), ('chevreau', '🐐'),
    ('sanglier', '🐗'), ('lievre', '🐇'),
    # Volailles/gibier à plumes sans mot-clé propre (chapon/faisan/pigeon/
    # pintade/poule) : famille "poulet" (🍗). "Oie" rejoint 🦆 (déjà utilisé
    # pour canard, autre palmipède, plus proche visuellement qu'un boeuf).
    ('chapon', '🍗'), ('faisan', '🍗'), ('pigeon', '🍗'), ('pintade', '🍗'),
    ('poule', '🍗'), ('oie', '🦆'),
    # Mentions génériques ("Foie, volaille, cru", "Viande blanche, cuite") :
    # "volaille"/"viande blanche" désignent TOUJOURS de la volaille par
    # définition, jamais du boeuf.
    ('volaille', '🍗'), ('viande blanche', '🍗'),

    ('fromage', '🧀'), ('yaourt', '🥛'), ('beurre', '🧈'), ('oeuf', '🥚'),
    # "lait"/"crème" retirés (2e audit) : ces mots apparaissent dans énormément
    # de noms d'aliments qui NE SONT PAS du lait/de la crème (fromages "au lait
    # cru", chocolats "au lait", sauces "à la crème", pâtisseries...) — le sous-
    # groupe porte déjà le bon pictogramme par défaut (🧀 fromages, 🥛 laits).
    # Un mot-clé aussi fréquent écrasait ce défaut à tort sur ~80 aliments.

    ('pizza', '🍕'),
    # 12e audit : "nouille" (singulier) ne matchait jamais — CIQUAL écrit
    # toujours "Nouilles" (pluriel), même bug de pluriel que lasagne/haricot/
    # pomme de terre/petits pois/olive déjà vus. Les "Nouilles asiatiques..."
    # (plats composés) retombaient sur le pot générique 🍲 au lieu du bol de
    # nouilles 🍜, plus reconnaissable.
    ('nouille', '🍜'), ('nouilles', '🍜'),
    ('riz', '🍚'),
    # "pate" (singulier) reste banni globalement — matcherait à tort "pâté"/
    # "pâte à tarte" (charcuterie/pâtisserie, faux-amis déjà identifiés).
    # 15e audit : maintenant que le défaut de "pâtes, riz et céréales" est
    # devenu 🌾 (neutre, voir SUBGROUP_ICON_NOVA) pour ne plus peindre en
    # pâtes l'avoine/le quinoa/l'orge..., "pates" (PLURIEL — CIQUAL écrit
    # toujours "Pâtes fraîches"/"Pâtes sèches") est réintroduit mais
    # verrouillé au seul sous-groupe "pâtes, riz et céréales" (voir
    # ICON_KEYWORD_SUBGROUP_ONLY plus bas) : il ne peut donc jamais matcher
    # "pâté"/"pâte à tarte", qui vivent dans d'autres sous-groupes. "vermicelle"
    # (soja/riz) n'avait aucun mot-clé — testé après "riz" pour que "Vermicelle
    # de riz" garde 🍚 (déjà correct), seul "Vermicelle de soja" (sans "riz"
    # dans le nom) bascule sur 🍜, plus fidèle que le défaut céréale brute.
    ('pates', '🍝'), ('vermicelle', '🍜'),
    # "pain" retiré (écrasait à tort les viennoiseries 🥐/gâteaux 🍰).
    ('baguette', '🥖'), ('croissant', '🥐'), ('brioche', '🥐'),
    ('gateau', '🍰'), ('tarte', '🥧'), ('biscuit', '🍪'), ('chocolat', '🍫'),
    ('glace', '🍦'), ('sorbet', '🍧'), ('miel', '🍯'), ('confiture', '🍯'),
    ('cafe', '☕'), ('the', '🍵'), ('vin', '🍷'), ('biere', '🍺'), ('jus', '🧃'),
    # 15e audit : "champagne" n'avait aucun mot-clé propre — retombait sur
    # 🍷 (verre de vin, ancien défaut de "boisson alcoolisées") par un
    # contresens désormais corrigé (voir SUBGROUP_ICON_NOVA) ; 🍾 (bouteille
    # qui saute) est plus fidèle et reconnaissable pour le champagne lui-même.
    ('champagne', '🍾'),
    ('soupe', '🍜'), ('sandwich', '🥪'), ('burger', '🍔'),
    # 15e audit : "amande"/"noisette" (singulier) ne matchaient jamais les
    # noms CIQUAL au pluriel ("Barre céréalière aux AMANDES ou NOISETTES")
    # — même bug de mot entier que lasagne/nouille/ceriser déjà vus. Cette
    # barre (sans chocolat) retombait donc sur le défaut chocolat 🍫 de
    # "barres céréalières" plutôt que sur 🌰. Formes plurielles ajoutées.
    ('noix', '🌰'), ('amande', '🌰'), ('amandes', '🌰'),
    ('noisette', '🌰'), ('noisettes', '🌰'), ('cacahuete', '🥜'),
    # "salade" retiré (écrasait le 🥗 correct des salades composées de pâtes/
    # riz/thon/pommes de terre par un 🥬 laitue trompeur) — remplacé par
    # "laitue" (déjà présent ci-dessus), plus précis.
]

# Exclusions ciblées : un mot-clé légitime qui matche à tort à l'intérieur
# d'un nom composé sans rapport (faux-amis découverts au 2e audit).
ICON_KEYWORD_EXCLUSIONS = {
    'chou': ['a la creme'],       # "Chou à la crème" = pâtisserie, pas un chou
    # 9e audit : "Chou romanesco ou brocoli à pomme" affichait 🍎 (pomme, le
    # fruit) — "à pomme" est un terme botanique pour une tête compacte
    # (comme "pomme de chou"), sans aucun rapport avec le fruit.
    'pomme': ['a pomme'],
    # 9e audit : "maïs" (le mot-clé) et "mais" (la conjonction "but") sont
    # identiques une fois les accents retirés pour la comparaison — "mélange
    # de fruits... MAIS toujours avec un autre ingrédient" affichait donc
    # 🌽 (maïs) sur une spécialité de fruits qui n'en contient pas.
    'mais': ['mais toujours'],
    # 15e audit (13/08/2026, scan systématique des clés de dict dupliquées —
    # même bug que 'noix' trouvé plus bas dans ce même dict) : 'coco' était
    # défini DEUX FOIS ici (cette entrée, et une 2e fois plus bas avec
    # ['enrobee de chocolat']) — la 2e écrasait silencieusement la 1re,
    # perdant la protection "Haricot coco" depuis sa création. Fusionné.
    'coco': ['haricot coco', 'enrobee de chocolat'],
    'beurre': ['haricot beurre'], # "Haricot beurre" = variété de haricot (wax bean)
    'peche': ['lieu de peche'],   # "tout lieu de pêche" = zone de pêche, pas le fruit
    # 4e audit (11/08/2026) : "Courge, graine, séchée" héritait de 🎃 (courge
    # légume) au lieu de 🥜 (graine, comme chia/lin/tournesol/sésame) — un
    # pépin de courge n'a pas grand-chose à voir visuellement avec la courge
    # entière.
    'courge': ['graine'],
    # 8e audit : "coque" (mollusque bivalve) ne doit pas matcher "Oeuf à la
    # coque" (juste un mode de cuisson de l'oeuf, sans rapport).
    # 9e audit : ni "Spécialité fromagère... en coque" (terme de fromagerie —
    # croûte non affinée — sans rapport avec le coquillage).
    # 10e audit : ni "fruits à coque" — le terme FRANÇAIS STANDARD pour les
    # fruits à écale (amande, noisette, noix...), sans AUCUN rapport avec le
    # coquillage. Trouvé sur 13 aliments (biscuits, céréales, gâteaux...)
    # affichant 🦪 (huître) au lieu de leur vraie nature.
    'coque': ['oeuf', 'fromage', 'fruits a coque'],
    # 9e audit (11/08/2026, "tu me mets l'aliment dedans, mais ça reste une
    # boisson") : "tournesol" (🥜, la graine qu'on mange) ne doit pas matcher
    # une huile ou un poisson conservé à l'huile de tournesol — l'huile n'est
    # qu'un ingrédient secondaire, pas le sujet de l'aliment.
    'tournesol': ['huile'],
    # 10e audit (11/08/2026, "on tourne en rond, fais une passe une bonne
    # fois pour toutes") — faux-amis linguistiques trouvés en auditant
    # l'intégralité du fichier plutôt qu'au cas par cas :
    'biere': ['levure de biere'],   # "Levure de bière" = complément alimentaire, pas de l'alcool
    'laitue': ['laitue de mer'],    # "Laitue de mer" (Ulva sp.) = une ALGUE, pas la salade
    # Phrase précise (pas juste "olive") : un simple "olive" quelque part dans
    # le nom excluait à tort "Anchois... à l'huile D'OLIVE" (l'anchois est
    # bien le sujet, l'huile n'est que le mode de conservation) — régression
    # trouvée en re-vérifiant après le 10e audit.
    'anchois': ['anchois, poivrons'],  # "Olives... (anchois, poivrons, etc.)" = anchois cité en exemple de garniture
    'riz': ['alcool de riz', 'sake'],  # "Saké ou alcool de riz" = une boisson alcoolisée, pas un féculent
    'cerise': ['tomate'],           # "Tomate cerise" = une tomate, pas une cerise
    'glace': ['marron glace'],      # "Marron glacé" (confiserie) : "glacé" = confit/glazed, pas de la glace
    'fromage': ['fromage de tete'], # "Fromage de tête" = charcuterie (tête de porc en gelée), aucun rapport avec le fromage
    # "Oeuf de caille"/"Oeuf de dinde" affichaient l'oiseau (🍗, mots-clés
    # caille/dinde testés avant "oeuf" dans la liste) au lieu de l'oeuf lui-
    # même (🥚) — un oeuf reste un oeuf quelle que soit l'espèce.
    'caille': ['oeuf de caille'],
    'dinde': ['oeuf de dinde'],
    # 13e audit (11/08/2026) : "Pain au chocolat" est une viennoiserie (🥐,
    # comme croissant/brioche), pas une tablette de chocolat.
    'chocolat': ['pain au chocolat'],
    # "Barre à la noix de coco, enrobée de chocolat" est un produit
    # chocolaté (déjà 🍫 par défaut du sous-groupe) — la noix de coco n'est
    # qu'une garniture, pas le sujet de la barre. (Fusionné avec l'exclusion
    # 'coco' plus haut dans ce dict — voir commentaire là-bas.)
    'noix de coco': ['enrobee de chocolat'],
    # "noix de coco" contient le mot "noix" tout seul — sans cette exclusion,
    # bloquer "coco" faisait retomber le match sur "noix" (🌰, châtaigne/noix
    # classique) au lieu du défaut chocolat 🍫. Vérifié : aucun autre aliment
    # "noix ... enrobée de chocolat" n'existe (seule la cacahuète, qui a son
    # propre mot-clé, et une gaufrette sans "noix").
    # 15e audit (13/08/2026, sweep systématique) : BUG DE CLÉ DE DICTIONNAIRE
    # DÉCOUVERT ICI — 'noix' était défini DEUX FOIS dans ce dict (ici, et une
    # 2e fois plus haut avec ['muscade', 'saint-jacques', 'pecten',
    # 'petoncle', 'peigne du']) ; en Python, la 2e affectation d'une même clé
    # de dict litéral écrase silencieusement la 1re, sans erreur. Résultat
    # réel vérifié : "Coquille Saint-Jacques" (3 aliments), "Pecten
    # d'Amérique ou peigne du Canada" et "Noix de muscade" affichaient tous
    # 🌰 (châtaigne/noix) au lieu de leur véritable icône (🦐 fruits de mer /
    # 🌿 épice) — la protection "saint-jacques"/"muscade"/"pecten"/
    # "petoncle"/"peigne du" n'avait donc JAMAIS été appliquée depuis son
    # ajout. Fusionné en une seule liste ci-dessous, aucune des deux
    # protections n'est plus perdue.
    'noix': ['enrobee de chocolat', 'muscade', 'saint-jacques', 'pecten', 'petoncle', 'peigne du'],
}

# 9e audit : certains mots-clés ne doivent s'appliquer QUE dans leur sous-
# groupe d'origine — sinon ils re-hijackent un plat composé qui les cite
# juste comme ingrédient parmi d'autres (ex. "Salade César... (salade verte,
# fromage, croûtons, sauce)" retombait sur 🥬 alors que "salades composées et
# crudités" a déjà son propre défaut correct, 🥗).
ICON_KEYWORD_SUBGROUP_ONLY = {
    'salade verte': {'légumes'},
    'salade sucrine': {'légumes'},
    # 15e audit : "pates" (pluriel) verrouillé au seul sous-groupe où il
    # désigne vraiment des pâtes alimentaires — sans ce verrou, il matcherait
    # aussi (via norm(), accents retirés) n'importe quel nom contenant
    # "pâtes" ailleurs dans la base hors de ce rayon.
    'pates': {'pâtes, riz et céréales'},
    # "Haricot de mer" (Himanthalia elongata) est une algue, pas une variété
    # de haricot — le mot-clé générique "haricot" ajouté pour rattraper
    # beurre/plat/purée ne doit pas déborder sur le rayon algues.
    'haricot': {'légumes', 'légumineuses'},
    'haricots': {'légumes', 'légumineuses'},
    # 10e audit : "chouchou" désigne à la fois la chayote (légume, 🎃) ET une
    # confiserie foraine (cacahuètes caramélisées) — "Cacahuète caramélisée
    # ou chouchou" affichait 🎃 (courge) sur un bonbon. Restreint au rayon
    # légumes, seul endroit où "chouchou" désigne vraiment la chayote.
    'chouchou': {'légumes'},
    # Idem "glace" (🍦) : "Marron glacé" (glacé = confit, pas de la glace) est
    # déjà couvert par une exclusion ci-dessus, mais on verrouille aussi le
    # mot-clé à son propre rayon pour éviter toute autre collision du même
    # type non encore observée.
    'glace': {'desserts glacés', 'glaces', 'sorbets'},
}

# 10e audit (11/08/2026, "un ananas sur une salade composée, on tourne en
# rond, fais une passe une bonne fois pour toutes") : la protection "plats
# composites d'abord" en tête de ICON_KEYWORD_OVERRIDES ne suffisait pas —
# elle gagne la passe "tête", mais un ingrédient cité PLUS LOIN dans le nom
# ("Salade Alaska au surimi, ananas, carottes...") est quand même retrouvé
# ensuite par la passe "texte complet" et gagne à sa place. Plutôt que de
# corriger encore un aliment à la fois, verrouillage au niveau du GROUPE
# entier "entrées et plats composés" (sandwichs, pizzas/tartes/crêpes
# salées, plats composés, salades composées et crudités, soupes) : chaque
# sous-groupe a déjà un défaut pertinent (🥪🍕🍲🥗🍜) et un ingrédient cité
# dans le nom ne doit plus jamais le remplacer. Seuls les mots-clés qui
# désignent le PLAT lui-même (déjà en tête de la liste ci-dessus) restent
# autorisés à l'intérieur de ce groupe — ils renforcent/affinent le bon
# picto (ex. "pizza" au sein de "plats composés") au lieu de le détourner.
ENTREES_PLATS_COMPOSES_GROUPE = 'entrées et plats composés'
ENTREES_PLATS_COMPOSES_ALLOWED_KEYWORDS = {
    'sandwich', 'pizza', 'burger', 'quiche', 'soupe', 'salade composée',
    'lasagne', 'lasagnes', 'nouille', 'nouilles',
}

# Surcharges NOVA par mot-clé — plus spécifiques que le défaut du sous-groupe.
# Re-audit du 10/08/2026 (retour d'Alex) : 3 paliers au lieu de 2, pour distinguer
# une simple cuisson/salaison artisanale (reste groupe 3 au maximum) d'une vraie
# marque de formulation industrielle (additifs, texturation, arômes → groupe 4).
NOVA_KEYWORD_OVERRIDES_UP = [  # pousse vers NOVA 4 (additifs / formulation industrielle)
    'preemballe', 'industriel', 'extrude', 'nugget', 'aromatise', 'edulcorant',
    'enrichi en vitamines et mineraux', 'restauree en vitamine', 'reconstitue',
    'sirop', 'nappe de chocolat', 'fourre', 'texturee', 'colorant', 'conservateur',
    'exhausteur de gout', 'emulsifiant', 'bouillon',
]
NOVA_KEYWORD_OVERRIDES_MID = [  # pousse vers 3 minimum (conservation/salaison — jamais "brut")
    'fume', 'fumee', 'fumees', 'fumes', 'marine', 'marinee', 'marinees', 'marines',
    'sale', 'salee', 'salees', 'sales', 'saumure', 'salaison',
]
NOVA_KEYWORD_OVERRIDES_DOWN = [  # ramène vers NOVA 1 (aliment brut/peu transformé)
    'cru', 'crue', 'crus', 'crues', 'nature', 'frais', 'fraiche', 'sans sel ajoute',
    'sans sucres ajoutes', 'bouilli', 'bouillie', "cuit a l'eau", "cuite a l'eau",
]

# ───────────────────────── 3. Génération du nom générique ─────────────────────────
# 4e retour d'Alex (11/08/2026) : le nom générique "recomposé" (charte à 5
# repères) créait par endroits plus de confusion que le nom CIQUAL officiel,
# et il aurait fallu tout revérifier aliment par aliment pour en être sûr —
# refusé explicitement ("je veux pas avoir à regarder tous les aliments un
# par un"). Décision : on repart du nom CIQUAL tel quel, jugé plus fiable,
# SAUF pour un vrai défaut structurel confirmé : quand CIQUAL écrit
# "Espèce, graine" (ex. "Courge, graine, séchée"), le mot "graine" — qui
# définit vraiment la catégorie de recherche (dissocier une graine du légume
# dont elle vient) — est relégué en 2e position et invisible en tri/recherche
# par mot-clé. On le remet en tête : "Graine, Courge, séchée" — un simple
# échange de position, jamais de reformulation.
#
# 5e retour d'Alex (11/08/2026) : l'extension à coeur/fond/feuille/racine/
# écorce/zeste/tige/pulpe/germe a été explicitement annulée — "ça me pose
# aucun problème d'avoir artichaut, virgule, coeur" — SEULE la graine est
# une exception valable pour dissocier visuellement une graine de son légume.
PART_REORDER_WORDS = ['graines?']
PART_REORDER_RE = re.compile(r'^(' + '|'.join(PART_REORDER_WORDS) + r')\b', re.IGNORECASE)

# Toujours utile pour la passe de dédoublonnage (3bis, plus bas) : ces mentions
# sont reléguées en tout dernier recours plutôt que comme candidat prioritaire.
TRAILING_NOISE = [
    '(aliment moyen)', 'sans précision', 'sans sel ajouté', 'sans sucres ajoutés',
    'non enrichie', 'non enrichi', 'préemballée', 'préemballé', 'préemballés', 'préemballées',
]


def strip_parenthetical(s: str) -> str:
    return re.sub(r'\s*\([^)]*\)\s*', ' ', s).strip()


def split_top_level_commas(s: str):
    """Découpe sur les virgules, mais jamais celles à l'intérieur de parenthèses
    (ex. "Ao-nori (Ulva sp., ex Enteromorpha sp.), séchée" → 2 champs, pas 3)."""
    fields, buf, depth = [], [], 0
    for ch in s:
        if ch == '(':
            depth += 1
            buf.append(ch)
        elif ch == ')':
            depth = max(0, depth - 1)
            buf.append(ch)
        elif ch == ',' and depth == 0:
            fields.append(''.join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    fields.append(''.join(buf).strip())
    return fields


def build_nom_generique(nom: str, groupe: str, sous_groupe: str) -> str:
    fields = split_top_level_commas(nom)
    if len(fields) >= 2 and PART_REORDER_RE.match(fields[1].strip()):
        swapped = [fields[1].strip(), fields[0].strip()] + list(fields[2:])
        result = ', '.join(swapped)
        return result[0].upper() + result[1:] if result else nom
    return nom


def norm(s: str) -> str:
    import unicodedata
    s = s.lower().replace('œ', 'oe').replace('æ', 'ae')
    nfkd = unicodedata.normalize('NFKD', s)
    return ''.join(c for c in nfkd if not unicodedata.combining(c))


def _kw_in(kw: str, text: str, full_text: str = None) -> bool:
    """Correspondance sur mot entier (évite ex. 'vin' dans 'vinaigre'). Les
    exclusions sont vérifiées sur le nom COMPLET, pas seulement sur le
    segment en cours de test — sinon "Courge, graine, séchée" gardait 🎃
    (courge) pendant la passe "tête" (juste "Courge", qui ne contient pas
    "graine") et l'exclusion n'était testée qu'en repli, trop tard."""
    if kw in ICON_KEYWORD_EXCLUSIONS:
        excl_text = full_text if full_text is not None else text
        if any(_kw_in_phrase(excl, excl_text) for excl in ICON_KEYWORD_EXCLUSIONS[kw]):
            return False
    return re.search(r'(?<![a-z0-9])' + re.escape(norm(kw)) + r'(?![a-z0-9])', text) is not None


def _kw_in_phrase(phrase: str, text: str) -> bool:
    return norm(phrase) in text


# Icônes "récipient de boisson" légitimes à garder telles quelles dans
# "boissons sans alcool" — elles ne représentent jamais un aliment solide
# (contrairement à 🌰/🥥/🍊/🥕/🥬... qui donnent l'impression qu'on mange
# l'ingrédient au lieu de le boire).
_DRINK_CONTAINER_ICONS = {'🥤', '🧃', '☕', '🍵'}


def pick_icon_nova(nom: str, groupe: str, sous_groupe: str):
    icon, nova = SUBGROUP_ICON_NOVA.get((groupe, sous_groupe), (DEFAULT_ICON, DEFAULT_NOVA))

    head = split_top_level_commas(nom)[0]
    n_head, n_full = norm(head), norm(nom)

    # Priorité absolue, cherchée sur le nom ENTIER avant même la logique
    # tête/texte complet ci-dessous : "Pomme de terre sautée/poêlée/rissolée,
    # préfrite, surgelée" affichait 🥔 (patate crue) au lieu de 🍟, parce que
    # "pomme de terre" est dans le 1er segment (gagne la passe "tête") et
    # "préfrite" seulement dans le 2e (jamais atteint). Une frite est un plat
    # transformé, pas juste "de la pomme de terre" — mérite de gagner toujours.
    for kw, ic in ICON_TOP_PRIORITY_OVERRIDES:
        if _kw_in(kw, n_full, full_text=n_full):
            icon = ic
            break
    else:
        # Le mot-clé est cherché en priorité dans le segment principal (avant la
        # première virgule) : un ingrédient cité en exemple plus loin dans le nom
        # ("...fourré aux fruits (ex : orange, cerise…)...") ne doit jamais
        # l'emporter sur la catégorie réelle de l'aliment ("Biscuit").
        is_plat_compose = groupe == ENTREES_PLATS_COMPOSES_GROUPE
        for kw, ic in ICON_KEYWORD_OVERRIDES:
            allowed = ICON_KEYWORD_SUBGROUP_ONLY.get(kw)
            if allowed is not None and sous_groupe not in allowed:
                continue
            if is_plat_compose and kw not in ENTREES_PLATS_COMPOSES_ALLOWED_KEYWORDS:
                continue
            if _kw_in(kw, n_head, full_text=n_full):
                icon = ic
                break
        else:
            for kw, ic in ICON_KEYWORD_OVERRIDES:
                allowed = ICON_KEYWORD_SUBGROUP_ONLY.get(kw)
                if allowed is not None and sous_groupe not in allowed:
                    continue
                if is_plat_compose and kw not in ENTREES_PLATS_COMPOSES_ALLOWED_KEYWORDS:
                    continue
                if _kw_in(kw, n_full, full_text=n_full):
                    icon = ic
                    break

    # 9e audit : deux sous-groupes "contenant" où le contenu (parfum, fruit,
    # ingrédient cité) ne doit jamais remplacer le pictogramme du contenant
    # lui-même — retour d'Alex : "une boisson aux amandes, on ne met pas le
    # logo d'une amande, on met le logo d'une boisson", et même logique pour
    # les desserts lactés frais (déjà dit par Alex : le laitier n'a pas
    # besoin de distinction fine par parfum, contrairement aux légumes/
    # viandes/graines).
    if (groupe, sous_groupe) == ('eaux et autres boissons', 'boissons sans alcool'):
        if icon not in _DRINK_CONTAINER_ICONS:
            icon = SUBGROUP_ICON_NOVA[(groupe, sous_groupe)][0]
    elif (groupe, sous_groupe) == ('produits laitiers', 'produits laitiers frais et alternatives végétales'):
        icon = SUBGROUP_ICON_NOVA[(groupe, sous_groupe)][0]
    # 10e audit : même principe pour les huiles — "Huile d'avocat", "Huile de
    # germe de blé", "Huile de noyaux d'abricot", "Huile de pépins de
    # raisin", "Huile de son de riz" affichaient l'ingrédient d'origine
    # (🥑🌱🍑🍇🍚) au lieu du flacon neutre 🧴, exactement le défaut que le 8e
    # audit avait corrigé pour l'huile d'olive générique — seule "huile
    # d'olive" elle-même (🫒) reste une exception assumée et reconnaissable.
    elif (groupe, sous_groupe) == ('matières grasses', 'huiles et graisses végétales'):
        if icon not in ('🧴', '🫒'):
            icon = SUBGROUP_ICON_NOVA[(groupe, sous_groupe)][0]
    # 13e audit (11/08/2026, "une barre chocolatée, c'est pas un bol de
    # céréales") : même principe "contenant" que boissons/laitiers frais —
    # le parfum (chocolat/miel/maïs/riz) ne doit pas remplacer le bol de
    # céréales par une barre chocolatée ou un épi de maïs.
    elif (groupe, sous_groupe) == ('produits sucrés', 'céréales de petit-déjeuner'):
        icon = SUBGROUP_ICON_NOVA[(groupe, sous_groupe)][0]
    # 14e audit (13/08/2026, "vinaigre de cidre... logo d'un ail") : même
    # principe "contenant" — un ingrédient d'ORIGINE cité dans le nom
    # ("Vinaigre DE VIN rouge", "Vinaigre de CIDRE") n'est pas ce qu'EST
    # l'aliment (un vinaigre reste un condiment, pas le vin/la pomme dont il
    # est issu) — exactement le même contresens que les huiles aromatisées
    # au 10e audit. Seuls les mots-clés qui désignent vraiment le condiment
    # lui-même (cornichon/câpre, oignon, olive, ail) restent autorisés à
    # dépasser le bocal neutre par défaut.
    elif (groupe, sous_groupe) == ('aides culinaires et ingrédients divers', 'condiments'):
        if icon not in ('🥒', '🧅', '🫒', '🧄'):
            icon = SUBGROUP_ICON_NOVA[(groupe, sous_groupe)][0]

    for kw in NOVA_KEYWORD_OVERRIDES_UP:
        if _kw_in(kw, n_full, full_text=n_full):
            nova = max(nova, 4)
            break
    else:
        for kw in NOVA_KEYWORD_OVERRIDES_MID:
            if _kw_in(kw, n_full, full_text=n_full):
                nova = max(nova, 3)
                break
        else:
            for kw in NOVA_KEYWORD_OVERRIDES_DOWN:
                if _kw_in(kw, n_full, full_text=n_full):
                    nova = min(nova, 1) if nova <= 2 else nova
                    break

    return icon, nova


# ───────────────────────── 3bis. Garantie zéro doublon ─────────────────────────
# Retour d'Alex (11/08/2026) : "Aucun doublon possible !" — les 5 catégories de
# repères (parfum/%MG/partie/forme/cuisson) ne couvrent pas tout ce qui peut
# distinguer deux aliments CIQUAL (grades "choix"/"supérieur", "concentré" vs
# "purée" pour une tomate, l'âge d'un petit pot bébé, le type de biscuit...).
# Plutôt que d'énumérer sans fin de nouvelles catégories, cette passe reprend
# CHAQUE groupe de noms génériques encore en collision et pioche, un par un,
# les fragments du nom CIQUAL d'origine pas encore utilisés — jusqu'à unicité
# garantie. Les 3490 noms CIQUAL d'origine sont déjà tous distincts (vérifié),
# donc l'unicité est mathématiquement atteignable sans jamais inventer de mot.

_NOISE_FIELDS = {n.lower() for n in TRAILING_NOISE} | {'sans précision', 'aliment moyen'}


def _remaining_candidates(nom: str, generic: str):
    """Fragments du nom CIQUAL d'origine pas encore présents dans le nom
    générique, dans l'ordre où ils apparaissent. Le contenu entre parenthèses
    (souvent la SEULE info distinctive, ex. "Base de pizza (pâte et sauce à la
    crème)" vs "(... à la tomate)", "(teneur en fruits < 10%)" vs "(>= 10%)")
    est cherché en priorité basse — sinon il était jeté avec le reste du bruit
    parenthétique et forçait un recours inutile au filet numéroté."""
    fields = split_top_level_commas(nom)
    used = norm(generic)
    out, paren_out, noise_out = [], [], []
    for i, f in enumerate(fields):
        for p in re.findall(r'\(([^)]*)\)', f):
            p = p.strip()
            if p and norm(p) not in used:
                (noise_out if p.lower() in _NOISE_FIELDS else paren_out).append(p)
        if i == 0:
            continue  # le champ 0 devient déjà la base, jamais réutilisé tel quel
        frag = strip_parenthetical(f).strip()
        if not frag or norm(frag) in used:
            continue
        # Les mentions "préemballé"/"sans sel ajouté"/... sont volontairement
        # reléguées en tout dernier recours (3e priorité) : bruit dans 99% des
        # cas, mais parfois la SEULE différence entre deux aliments CIQUAL —
        # mieux vaut les afficher que de retomber sur un simple "(1)"/"(2)".
        (noise_out if frag.lower() in _NOISE_FIELDS else out).append(frag)
    return out + paren_out + noise_out


_WORD_RE = r"[a-zà-öø-ÿ]+(?:'[a-zà-öø-ÿ]+)?"


def _residual_words(candidate: str, current_generic: str) -> str:
    """Retire du candidat les mots déjà présents dans le nom généré, pour ne
    jamais produire de répétition — 2 bugs trouvés et corrigés ici :
    1) "..., jambon, jambon emmental" ("jambon" déjà là via le parfum) ;
    2) "..., bouillie/cuite à l'eau, viande bouillie/cuite" (le "/" cassait la
       comparaison : "bouillie/cuite" en un seul bloc ne matchait jamais les
       mots "bouillie"+"cuite" déjà présents séparément). Les DEUX côtés sont
       maintenant décomposés avec la même regex (le "/" n'est plus un piège)."""
    used = {norm(w) for w in re.findall(_WORD_RE, current_generic.lower())}
    tokens = re.findall(_WORD_RE, candidate.lower())
    kept = [w for w in tokens if len(w) > 2 and norm(w) not in used]
    return ' '.join(kept).strip()


def dedupe_generic_names(items):
    """items : liste de dicts avec au moins 'nom' (original) et 'generic'
    (nom généré) — modifie 'generic' en place pour garantir l'unicité."""
    groups = defaultdict(list)
    for it in items:
        groups[it['generic']].append(it)

    for name, members in groups.items():
        if len(members) <= 1:
            continue
        for it in members:
            it['_cand'] = _remaining_candidates(it['nom'], it['generic'])
            it['_cursor'] = 0

        while True:
            current = defaultdict(list)
            for it in members:
                current[it['generic']].append(it)
            conflicts = [g for g in current.values() if len(g) > 1]
            if not conflicts:
                break
            progressed = False
            for g in conflicts:
                for it in g:
                    # Avance jusqu'au prochain candidat qui apporte vraiment
                    # une info nouvelle (pas déjà présente mot pour mot).
                    while it['_cursor'] < len(it['_cand']):
                        raw = it['_cand'][it['_cursor']]
                        it['_cursor'] += 1
                        residual = _residual_words(raw, it['generic'])
                        if residual:
                            it['generic'] = f"{it['generic']}, {residual}"
                            progressed = True
                            break
            if not progressed:
                break

        # Filet de sécurité théorique (ne devrait jamais servir : les noms
        # CIQUAL d'origine sont déjà tous distincts) — jamais un mot inventé,
        # juste un repère numéroté déterministe et traçable.
        final = defaultdict(list)
        for it in members:
            final[it['generic']].append(it)
        for g in final.values():
            if len(g) > 1:
                for i, it in enumerate(sorted(g, key=lambda x: x['nom']), start=1):
                    it['generic'] = f"{it['generic']} ({i})"

    for it in items:
        it.pop('_cand', None)
        it.pop('_cursor', None)


# ───────────────────────── 4. Pipeline principal ─────────────────────────

def main():
    official = load_official_groups()

    with open(SRC_FOODS, encoding='utf-8-sig', newline='') as f:
        r = csv.reader(f)
        header = next(r)
        rows = list(r)

    shutil.copyfile(SRC_FOODS, BACKUP)

    name_idx = header.index('nom')
    code_idx = header.index('ciqual_code')

    new_header = header + ['groupe', 'sous_groupe', 'pictogramme', 'score_nova_estime', 'nom_generique']
    missing_group = []
    nova_counter = Counter()
    subgroup_counter = Counter()
    items = []

    for row in rows:
        code = row[code_idx].strip()
        nom = row[name_idx].strip()

        if code in MANUAL_GROUPS:
            groupe, sous_groupe = MANUAL_GROUPS[code]
        elif code in official:
            groupe, sous_groupe = official[code]
        else:
            groupe, sous_groupe = ('', '')
            missing_group.append((code, nom))

        icon, nova = pick_icon_nova(nom, groupe, sous_groupe)
        generic = build_nom_generique(nom, groupe, sous_groupe)

        nova_counter[nova] += 1
        subgroup_counter[(groupe, sous_groupe)] += 1

        items.append({
            'row': row, 'nom': nom, 'groupe': groupe, 'sous_groupe': sous_groupe,
            'icon': icon, 'nova': nova, 'generic': generic,
        })

    dupes_before = len(items) - len({it['generic'] for it in items})
    dedupe_generic_names(items)
    dupes_after = len(items) - len({it['generic'] for it in items})

    new_rows = [
        it['row'] + [it['groupe'], it['sous_groupe'], it['icon'], str(it['nova']), it['generic']]
        for it in items
    ]

    with open(SRC_FOODS, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(new_header)
        w.writerows(new_rows)

    # ─── Rapport de vérification ───
    lines = []
    lines.append('# Rapport — ajout groupe/sous_groupe/pictogramme/score_nova_estime/nom_generique\n')
    lines.append(f'- Lignes traitées : {len(new_rows)}')
    lines.append(f'- Lignes sans groupe (devrait être 0) : {len(missing_group)}')
    for c, n in missing_group:
        lines.append(f'  - {c} {n}')
    lines.append(f'- Doublons de nom_generique avant dédoublonnage : {dupes_before}')
    lines.append(f'- Doublons de nom_generique après dédoublonnage (doit être 0) : {dupes_after}')
    lines.append(f'\n## Répartition score_nova_estime\n')
    for k in sorted(nova_counter):
        lines.append(f'- NOVA {k} : {nova_counter[k]} aliments')
    lines.append(f'\n## Échantillon nom_generique (20 lignes espacées régulièrement)\n')
    step = max(1, len(new_rows) // 20)
    for i in range(0, len(new_rows), step):
        row = new_rows[i]
        groupe_v, sous_groupe_v, icon_v, nova_v, generic_v = row[-5], row[-4], row[-3], row[-2], row[-1]
        lines.append(
            f'- `{row[name_idx]}` → **{generic_v}** '
            f'({groupe_v} > {sous_groupe_v}, pictogramme {icon_v}, NOVA {nova_v})'
        )
    with open(REPORT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f'OK — {len(new_rows)} lignes écrites, {len(missing_group)} sans groupe.')
    print(f'Doublons : {dupes_before} avant dédoublonnage, {dupes_after} après (doit être 0).')
    print('Rapport :', REPORT)


if __name__ == '__main__':
    main()
