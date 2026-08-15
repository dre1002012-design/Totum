#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Construit assets/usda_foods.csv à partir des jeux de données officiels USDA
FoodData Central téléchargés en local (scripts/usda_raw/) :

  - Foundation Foods (avril 2026) : 469 aliments, analyses de laboratoire,
    le jeu le plus rigoureux et le plus récent.
  - SR Legacy (avril 2018, figé, ne sera plus mis à jour) : 7793 aliments,
    l'ancienne base de référence USDA, structure proche de CIQUAL.

Volontairement EXCLUS : "Branded Foods" (300 000+ produits de marque
américains, déjà couvert par le scan Open Food Facts) et "Survey (FNDDS)"
(moins complet en nutriments) — seuls les deux jeux "génériques" et les plus
complets en macro/micronutriments sont retenus, comme demandé.

Sortie : mêmes colonnes que assets/foods.csv (macros/micros identiques,
mêmes noms de colonnes) + groupe/sous_groupe/pictogramme/score_nova_estime/
nom_generique — pour que le code Dart existant (FoodItem, microsFor...)
fonctionne sans aucune distinction entre les deux bases.

Noms d'aliments conservés en ANGLAIS (langue native de la base), décision
d'Alex (11/08/2026) : traduire fidèlement 8000+ noms serait un chantier à
part entière et risqué (faux-sens culinaires) ; les garder en anglais sert
aussi de première brique pour une future version internationale de l'app.
"""
import csv
import re
import unicodedata
from collections import defaultdict

RAW = 'scripts/usda_raw'
OUT = 'assets/usda_foods.csv'

FOUNDATION_DIR = f'{RAW}/foundation/FoodData_Central_foundation_food_csv_2026-04-30'
SR_DIR = f'{RAW}/sr_legacy/FoodData_Central_sr_legacy_food_csv_2018-04'

# ───────────────────────── 1. Chargement des tables sources ─────────────────────────

def load_categories():
    cats = {}
    with open(f'{FOUNDATION_DIR}/food_category.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            cats[row['id']] = row['description']
    return cats


def _is_upper_heavy(candidate: str) -> bool:
    """>= 80% des lettres en MAJUSCULE (pas 100% : "McDONALD'S" a un 'c'
    minuscule et échapperait à un test strict égal à l'upper())."""
    letters = [c for c in candidate if c.isalpha()]
    if len(letters) < 3:
        return False
    return sum(1 for c in letters if c.isupper()) / len(letters) >= 0.8


def extract_brand(description):
    """Extrait le nom de marque/enseigne dans le nom USDA. Retour d'Alex
    (11/08/2026, 3e passe) : les marques de compléments/protéines n'étaient
    pas toujours repérées quand le nom de marque n'est pas en tête, ex.
    "Beverages, ABBOTT, EAS whey protein powder" (ABBOTT en 2e segment).
    On scanne donc TOUS les segments séparés par virgule (pas seulement le
    1er) et on retient le premier très majoritairement en MAJUSCULES ;
    repli sur la suite de mots en tête qui le sont si aucune virgule
    ("McDONALD'S Bacon Ranch Salad..." n'a pas de virgule après la marque)."""
    for segment in description.split(','):
        segment = segment.strip()
        if _is_upper_heavy(segment):
            return segment
    brand_words = []
    for w in description.split(' '):
        if _is_upper_heavy(w.strip()):
            brand_words.append(w.strip())
        else:
            break
    return ' '.join(brand_words) if brand_words else None


# Retour d'Alex (11/08/2026, 2e passe) : au lieu d'un "cheat meal" réduit au
# fast-food avec avertissement santé, TOUS les produits de marque déjà
# validés par les laboratoires USDA (Foundation/SR Legacy — jamais la base
# "Branded Foods" séparée, elle auto-déclarée par les fabricants, donc hors
# de la barre "tout doit être calculé en laboratoire" posée par Alex) sont
# réintégrés, classés en 2 familles filtrables : "restaurant" (chaînes où
# l'on mange sur place/à emporter) et "marque" (épicerie de marque). Le
# score NOVA reste calculé normalement (voir build_usda_taxonomy.py) — plus
# de discours santé en dur, juste une classification honnête.
RESTAURANT_CATEGORIES = {'Fast Foods', 'Restaurant Foods'}


def source_type_for(category: str) -> str:
    return 'restaurant' if category in RESTAURANT_CATEGORIES else 'marque'


def load_foods():
    """Retourne la liste des aliments canoniques (Foundation + SR Legacy),
    en excluant les enregistrements techniques (échantillons de labo,
    acquisitions de marché...) et 'Quality Control Materials' (matériel de
    référence de laboratoire, pas un aliment). Aucun produit de marque n'est
    retiré : chacun est classé 'generic'/'marque'/'restaurant'."""
    categories = load_categories()
    items = []
    for d, dt, src in ((FOUNDATION_DIR, 'foundation_food', 'foundation'),
                        (SR_DIR, 'sr_legacy_food', 'sr_legacy')):
        with open(f'{d}/food.csv', encoding='utf-8-sig') as f:
            for row in csv.DictReader(f):
                if row['data_type'] != dt or row['food_category_id'] == '27':
                    continue
                category = categories.get(row['food_category_id'], '')
                brand = extract_brand(row['description'])
                source_type = source_type_for(category) if brand else 'generic'
                items.append({
                    'fdc_id': row['fdc_id'],
                    'description': row['description'],
                    'category_id': row['food_category_id'],
                    'source': src,
                    'source_type': source_type,
                    'brand': brand or '',
                })
    return items


def load_nutrients(fdc_ids):
    """fdc_id -> {nutrient_id: amount}. Filtré aux fdc_id retenus pour
    limiter la mémoire (SR Legacy seul fait 644k lignes)."""
    result = defaultdict(dict)
    for d in (FOUNDATION_DIR, SR_DIR):
        with open(f'{d}/food_nutrient.csv', encoding='utf-8-sig') as f:
            for row in csv.DictReader(f):
                fid = row['fdc_id']
                if fid not in fdc_ids:
                    continue
                amt = row['amount']
                if not amt:
                    continue
                result[fid][row['nutrient_id']] = float(amt)
    return result


# ───────────────────────── 2. Mapping nutriment USDA -> colonne CIQUAL ─────────────────────────
# id nutriment USDA (nutrient.csv) -> nom de colonne, IDENTIQUE à assets/foods.csv
# pour que le code Dart lise les deux bases sans distinction.
NUTRIENT_COLUMN_MAP = [
    ('1008', 'Énergie_kcal_100g'),
    ('1004', 'Lipides_g_100g'),
    ('1258', 'AG_saturés_g_100g'),
    ('1268', 'Acide_oléique_W9_g_100g'),       # MUFA 18:1
    ('1316', 'Acide_linoléique_W6_LA_g_100g'), # PUFA 18:2 n-6 c,c
    ('1404', 'Acide_alpha-linolénique_W3_ALA_g_100g'),  # PUFA 18:3 n-3 (ALA)
    ('1278', 'EPA_g_100g'),   # PUFA 20:5 n-3
    ('1272', 'DHA_g_100g'),   # PUFA 22:6 n-3
    ('1253', 'Cholestérol_mg_100g'),
    ('1005', 'Glucides_g_100g'),   # Carbohydrate, by difference
    ('1063', 'Sucres_g_100g'),
    ('1079', 'Fibres_g_100g'),
    ('1003', 'Protéines_g_100g'),
    ('1087', 'Calcium_mg_100g'),
    ('1098', 'Cuivre_mg_100g'),
    ('1089', 'Fer_mg_100g'),
    ('1100', 'Iode_µg_100g'),
    ('1090', 'Magnésium_mg_100g'),
    ('1101', 'Manganèse_mg_100g'),
    ('1091', 'Phosphore_mg_100g'),
    ('1092', 'Potassium_mg_100g'),
    ('1103', 'Sélénium_µg_100g'),
    ('1093', 'Sodium_mg_100g'),
    ('1095', 'Zinc_mg_100g'),
    ('1105', 'Rétinol_µg_100g'),
    ('1107', 'Beta-Carotène_µg_100g'),
    ('1114', 'Vitamine_D_µg_100g'),   # Vitamin D (D2+D3)
    ('1109', 'Vitamine_E_mg_100g'),   # alpha-tocopherol
    ('1185', 'Vitamine_K1_µg_100g'),  # phylloquinone
    ('1183', 'Vitamine_K2_µg_100g'),  # Menaquinone-4
    ('1162', 'Vitamine_C_mg_100g'),
    ('1165', 'Vitamine_B1_mg_100g'),  # Thiamin
    ('1166', 'Vitamine_B2_mg_100g'),  # Riboflavin
    ('1167', 'Vitamine_B3_mg_100g'),  # Niacin
    ('1170', 'Vitamine_B5_mg_100g'),  # Pantothenic acid
    ('1175', 'Vitamine_B6_mg_100g'),
    ('1177', 'Vitamine_B9_µg_100g'),  # Folate, total (même choix que CIQUAL : "Folates totaux", pas DFE)
    ('1178', 'Vitamine_B12_µg_100g'),
    ('1051', 'Eau_g_100g'),
    ('1012', 'Fructose_g_100g'),
    ('1075', 'Galactose_g_100g'),
    ('1011', 'Glucose_g_100g'),
    ('1013', 'Lactose_g_100g'),
    ('1014', 'Maltose_g_100g'),
    ('1010', 'Saccharose_g_100g'),
    ('1009', 'Amidon_g_100g'),
    ('1018', 'Alcool_g_100g'),
]
# Polyols_g_100g : pas d'entrée USDA unique "polyols" — approximé par la
# somme sorbitol + xylitol (seuls polyols individuellement mesurés dispo).
POLYOL_IDS = ['1056', '1078']

ALL_MACRO_COLUMNS = [c for _, c in NUTRIENT_COLUMN_MAP] + ['Sel_g_100g', 'Polyols_g_100g']

CIQUAL_COLUMN_ORDER = [
    'Énergie_kcal_100g', 'Lipides_g_100g', 'AG_saturés_g_100g', 'Acide_oléique_W9_g_100g',
    'Acide_linoléique_W6_LA_g_100g', "Acide_alpha-linolénique_W3_ALA_g_100g", 'EPA_g_100g',
    'DHA_g_100g', 'Cholestérol_mg_100g', 'Glucides_g_100g', 'Sucres_g_100g', 'Fibres_g_100g',
    'Protéines_g_100g', 'Sel_g_100g', 'Calcium_mg_100g', 'Cuivre_mg_100g', 'Fer_mg_100g',
    'Iode_µg_100g', 'Magnésium_mg_100g', 'Manganèse_mg_100g', 'Phosphore_mg_100g',
    'Potassium_mg_100g', 'Sélénium_µg_100g', 'Sodium_mg_100g', 'Zinc_mg_100g',
    'Rétinol_µg_100g', 'Beta-Carotène_µg_100g', 'Vitamine_D_µg_100g', 'Vitamine_E_mg_100g',
    'Vitamine_K1_µg_100g', 'Vitamine_K2_µg_100g', 'Vitamine_C_mg_100g', 'Vitamine_B1_mg_100g',
    'Vitamine_B2_mg_100g', 'Vitamine_B3_mg_100g', 'Vitamine_B5_mg_100g', 'Vitamine_B6_mg_100g',
    'Vitamine_B9_µg_100g', 'Vitamine_B12_µg_100g', 'Eau_g_100g', 'Fructose_g_100g',
    'Galactose_g_100g', 'Glucose_g_100g', 'Lactose_g_100g', 'Maltose_g_100g',
    'Saccharose_g_100g', 'Amidon_g_100g', 'Polyols_g_100g', 'Alcool_g_100g',
]


def norm(s):
    s = s.lower()
    nfkd = unicodedata.normalize('NFKD', s)
    return ''.join(c for c in nfkd if not unicodedata.combining(c))


def build_row(food, nutrients_by_id, categories):
    n = nutrients_by_id.get(food['fdc_id'], {})
    row = {}
    for nid, col in NUTRIENT_COLUMN_MAP:
        v = n.get(nid)
        row[col] = '' if v is None else str(v)
    sodium = n.get('1093')
    row['Sel_g_100g'] = f'{sodium * 2.5 / 1000:.4f}' if sodium is not None else ''
    polyol_sum = sum(n[pid] for pid in POLYOL_IDS if pid in n)
    row['Polyols_g_100g'] = f'{polyol_sum:.3f}' if any(pid in n for pid in POLYOL_IDS) else ''
    return row


def main():
    print('Chargement des catégories...')
    categories = load_categories()
    print('Chargement des aliments canoniques...')
    foods = load_foods()
    print(f'{len(foods)} aliments (Foundation + SR Legacy).')
    fdc_ids = {f['fdc_id'] for f in foods}
    print('Chargement des nutriments (peut prendre quelques secondes)...')
    nutrients_by_id = load_nutrients(fdc_ids)

    all_rows = []
    for food in foods:
        macros = build_row(food, nutrients_by_id, categories)
        row = {
            'fdc_id': food['fdc_id'],
            'nom': food['description'],
            **macros,
            'usda_category': categories.get(food['category_id'], ''),
            'source': food['source'],
            'source_type': food['source_type'],
            'brand': food['brand'],
        }
        all_rows.append(row)

    # Sans kcal renseigné = aliment inexploitable pour le journal (le kcal
    # pilote tout l'affichage) — quelques dizaines de fiches labo très
    # pointues (ex. "Beans, Dry, ... (0% moisture)") sans donnée d'énergie.
    before = len(all_rows)
    all_rows = [r for r in all_rows if r['Énergie_kcal_100g']]
    print(f'Retirés (sans kcal) : {before - len(all_rows)}')

    # Dédoublonnage par nom EXACT (Foundation Foods réanalyse parfois un
    # aliment déjà présent dans SR Legacy, ex. "Broccoli, raw" x3) — Foundation
    # préféré (le plus récent, analyses de laboratoire), sinon 1er rencontré.
    by_name = {}
    for row in all_rows:
        key = row['nom']
        if key not in by_name:
            by_name[key] = row
        elif row['source'] == 'foundation' and by_name[key]['source'] != 'foundation':
            by_name[key] = row
    out_rows = list(by_name.values())
    print(f'Retirés (doublon de nom) : {len(all_rows) - len(out_rows)}')

    fieldnames = ['fdc_id', 'nom'] + CIQUAL_COLUMN_ORDER + ['usda_category', 'source', 'source_type', 'brand']
    with open(OUT, 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for row in out_rows:
            w.writerow(row)

    print(f'OK -> {OUT} : {len(out_rows)} lignes écrites.')


if __name__ == '__main__':
    main()
