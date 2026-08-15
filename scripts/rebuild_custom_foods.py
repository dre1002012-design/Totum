#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reconstruit les 6 aliments hors-CIQUAL (90001-90006 : compléments protéinés +
natto, cf. Audit_Global.md Lots 10 et 12) à partir de leurs fiches USDA
FoodData Central exactes (fdcId documenté dans Corrections_Proposees.csv),
suite à l'incident de perte de données du 10/08/2026.

Même règle que l'audit d'origine : seuls les nutriments réellement rapportés
par la fiche USDA sont renseignés ; tout le reste reste vide (jamais estimé).
"""
import csv
import json

FDC_DIR = 'scripts/_fdc'
OUT = 'scripts/_custom_rows.csv'

# USDA nutrient number -> nom de colonne foods.csv
NUTRIENT_MAP = {
    '208': 'Énergie_kcal_100g',
    '204': 'Lipides_g_100g',
    '606': 'AG_saturés_g_100g',
    '617': 'Acide_oléique_W9_g_100g',
    '618': 'Acide_linoléique_W6_LA_g_100g',
    '619': 'Acide_alpha-linolénique_W3_ALA_g_100g',
    '629': 'EPA_g_100g',
    '621': 'DHA_g_100g',
    '601': 'Cholestérol_mg_100g',
    '205': 'Glucides_g_100g',
    '269': 'Sucres_g_100g',
    '291': 'Fibres_g_100g',
    '203': 'Protéines_g_100g',
    '301': 'Calcium_mg_100g',
    '312': 'Cuivre_mg_100g',
    '303': 'Fer_mg_100g',
    '314': 'Iode_µg_100g',
    '304': 'Magnésium_mg_100g',
    '315': 'Manganèse_mg_100g',
    '305': 'Phosphore_mg_100g',
    '306': 'Potassium_mg_100g',
    '317': 'Sélénium_µg_100g',
    '307': 'Sodium_mg_100g',
    '309': 'Zinc_mg_100g',
    '319': 'Rétinol_µg_100g',
    '321': 'Beta-Carotène_µg_100g',
    '328': 'Vitamine_D_µg_100g',
    '323': 'Vitamine_E_mg_100g',
    '430': 'Vitamine_K1_µg_100g',
    '401': 'Vitamine_C_mg_100g',
    '404': 'Vitamine_B1_mg_100g',
    '405': 'Vitamine_B2_mg_100g',
    '406': 'Vitamine_B3_mg_100g',
    '410': 'Vitamine_B5_mg_100g',
    '415': 'Vitamine_B6_mg_100g',
    '417': 'Vitamine_B9_µg_100g',
    '418': 'Vitamine_B12_µg_100g',
    '255': 'Eau_g_100g',
    '221': 'Alcool_g_100g',
}

# (ciqual_code, nom CIQUAL exact tel que dans Corrections_Proposees.csv, fdcId)
ITEMS = [
    ('90001', "Whey (protéine de lactosérum), isolat, poudre, enrichie en vitamines et minéraux", '173177'),
    ('90002', "Whey (protéine de lactosérum), poudre, boisson protéinée", '173180'),
    ('90003', "Protéine de soja, isolat, poudre, nature", '174276'),
    ('90004', "Protéine de soja, poudre, boisson protéinée aromatisée", '173181'),
    ('90005', "Blanc d'oeuf, déshydraté, poudre", '323793'),
    ('90006', 'Natto (soja fermenté)', '172443'),
]

TARGET_HEADER = None  # rempli depuis _rebuilt_with_corrections.csv pour garantir le même ordre exact


def load_target_header():
    with open('scripts/_rebuilt_with_corrections.csv', encoding='utf-8-sig', newline='') as f:
        return next(csv.reader(f))


def main():
    global TARGET_HEADER
    TARGET_HEADER = load_target_header()
    nutrient_cols = TARGET_HEADER[2:]  # tout sauf ciqual_code, nom

    out_rows = []
    for code, nom, fdc_id in ITEMS:
        with open(f'{FDC_DIR}/fdc_{fdc_id}.json', encoding='utf-8') as f:
            d = json.load(f)

        values = {}
        for fn in d['foodNutrients']:
            nut = fn.get('nutrient', {})
            num = nut.get('number')
            amount = fn.get('amount')
            if num in NUTRIENT_MAP and amount is not None:
                values[NUTRIENT_MAP[num]] = amount

        # Sel = sodium × 2,5 / 1000 (conversion réglementaire ANSES/CIQUAL standard,
        # pas une valeur USDA brute — même méthode que le Lot 10 d'origine).
        if 'Sodium_mg_100g' in values:
            values['Sel_g_100g'] = round(values['Sodium_mg_100g'] * 2.5 / 1000, 4)

        row = [code, nom]
        for col in nutrient_cols:
            v = values.get(col, '')
            row.append(str(v) if v != '' else '')
        out_rows.append(row)
        print(f'{code} {nom[:40]!r} (fdcId {fdc_id}) — {len([v for v in row[2:] if v])}/{len(nutrient_cols)} nutriments renseignés')

    with open(OUT, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(TARGET_HEADER)
        w.writerows(out_rows)
    print('Écrit vers', OUT)


if __name__ == '__main__':
    main()
