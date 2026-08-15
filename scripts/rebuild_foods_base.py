#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RECONSTRUCTION D'URGENCE (10/08/2026) — voir docs/TODO.md, incident du 10/08/2026.

`assets/foods.csv` (version aboutie : 3490 lignes, 51 colonnes, ciqual_code,
~3026 corrections nutritionnelles tracées) n'avait jamais été committée dans
git et a été écrasée par erreur (voir incident documenté). Ce script reconstruit
une base 51 colonnes propre, alignée sur le même schéma de colonnes, à partir
de la table officielle ANSES `assets/Table Ciqual 2025.csv` (intacte).

Les ~3021 corrections de `Corrections_Proposees.csv` sont ensuite réappliquées
par `scripts/merge_ciqual_update.py` (déjà existant, prévu pour ce cas d'usage).

Choix explicite et documenté : les valeurs CIQUAL au format "< X" (résultat
sous le seuil de quantification, ex. "< 0,041") sont traitées comme une cellule
vide — pas comme X ni X/2 — pour rester cohérent avec le principe déjà établi
de tout l'audit ("jamais inventer, en cas de doute la cellule reste vide").
C'est un choix de reconstruction assumé, pas une garantie d'identité parfaite
avec le fichier perdu.
"""
import csv

SRC = 'assets/Table Ciqual 2025.csv'
OUT = 'scripts/_rebuilt_base.csv'

# (index dans Table Ciqual 2025.csv, nom de colonne cible dans foods.csv)
COLUMN_MAP = [
    (10, 'Énergie_kcal_100g'),
    (17, 'Lipides_g_100g'),
    (31, 'AG_saturés_g_100g'),
    (42, 'Acide_oléique_W9_g_100g'),
    (43, 'Acide_linoléique_W6_LA_g_100g'),
    (44, 'Acide_alpha-linolénique_W3_ALA_g_100g'),
    (46, 'EPA_g_100g'),
    (47, 'DHA_g_100g'),
    (48, 'Cholestérol_mg_100g'),
    (16, 'Glucides_g_100g'),
    (18, 'Sucres_g_100g'),
    (26, 'Fibres_g_100g'),
    (14, 'Protéines_g_100g'),
    (49, 'Sel_g_100g'),
    (50, 'Calcium_mg_100g'),
    (52, 'Cuivre_mg_100g'),
    (53, 'Fer_mg_100g'),
    (54, 'Iode_µg_100g'),
    (55, 'Magnésium_mg_100g'),
    (56, 'Manganèse_mg_100g'),
    (57, 'Phosphore_mg_100g'),
    (58, 'Potassium_mg_100g'),
    (59, 'Sélénium_µg_100g'),
    (60, 'Sodium_mg_100g'),
    (61, 'Zinc_mg_100g'),
    (63, 'Rétinol_µg_100g'),
    (64, 'Beta-Carotène_µg_100g'),
    (65, 'Vitamine_D_µg_100g'),
    (69, 'Vitamine_E_mg_100g'),
    (70, 'Vitamine_K1_µg_100g'),
    (71, 'Vitamine_K2_µg_100g'),
    (72, 'Vitamine_C_mg_100g'),
    (73, 'Vitamine_B1_mg_100g'),
    (74, 'Vitamine_B2_mg_100g'),
    (75, 'Vitamine_B3_mg_100g'),
    (76, 'Vitamine_B5_mg_100g'),
    (77, 'Vitamine_B6_mg_100g'),
    # idx79 (pas 78, "...DFE") : vérifié empiriquement — c'est la colonne 79
    # ("Vitamine B9 ou Folates totaux", sans ajustement DFE) qui était vide
    # pour les aliments ciblés par l'audit Vitamine B9 (ex. 20299 Asperge :
    # col78=69,9 déjà rempli par l'ANSES, col79='-' vide, exactement le trou
    # que Lot 3 de l'audit comblait à 149,0) — idx78 aurait rendu ~289
    # corrections tracées "superflues" à tort.
    (79, 'Vitamine_B9_µg_100g'),
    (82, 'Vitamine_B12_µg_100g'),
    (13, 'Eau_g_100g'),
    (19, 'Fructose_g_100g'),
    (20, 'Galactose_g_100g'),
    (21, 'Glucose_g_100g'),
    (22, 'Lactose_g_100g'),
    (23, 'Maltose_g_100g'),
    (24, 'Saccharose_g_100g'),
    (25, 'Amidon_g_100g'),
    (27, 'Polyols_g_100g'),
    (29, 'Alcool_g_100g'),
]

TARGET_HEADER = ['ciqual_code', 'nom'] + [name for _, name in COLUMN_MAP]


def clean_value(raw: str) -> str:
    v = raw.strip()
    if v in ('', '-', 'traces', 'Traces'):
        return ''
    if v.startswith('<'):
        # Résultat sous le seuil de quantification : traité comme une cellule
        # vide (cf. docstring), jamais comme la borne indiquée.
        return ''
    return v.replace(',', '.').strip()


def main():
    with open(SRC, encoding='utf-8-sig', newline='') as f:
        r = csv.reader(f)
        header = next(r)
        rows = list(r)

    assert header[6] == 'alim_code', f'colonne 6 inattendue : {header[6]!r}'
    assert header[7] == 'alim_nom_fr', f'colonne 7 inattendue : {header[7]!r}'

    out_rows = []
    for row in rows:
        code = row[6].strip()
        nom = row[7].strip()
        if not code:
            continue
        new_row = [code, nom]
        for idx, _name in COLUMN_MAP:
            new_row.append(clean_value(row[idx]))
        out_rows.append(new_row)

    with open(OUT, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(TARGET_HEADER)
        w.writerows(out_rows)

    print(f'{len(out_rows)} lignes écrites vers {OUT}')
    print(f'{len(TARGET_HEADER)} colonnes')


if __name__ == '__main__':
    main()
