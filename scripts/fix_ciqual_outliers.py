# -*- coding: utf-8 -*-
"""
Corrige les valeurs CIQUAL ABERRANTES repérées le 01/11/2026 (audit du
partage 3.0 : chaque aliment affiche désormais ses propres apports — « Café :
vitamine B6 107 % », « Pomme de terre : sélénium 50 % » étaient faux).

Méthode — deux contrôles, puis une décision au cas par cas :
1. cohérence INTERNE de la table : la valeur dépasse ≥ 4 fois toutes les
   autres préparations du même aliment (même espèce, même état), alors que
   la cuisson concentre (un aliment cru ne peut pas être 5 fois plus riche
   que le même aliment cuit) ;
2. cohérence EXTERNE : équivalent USDA FoodData Central choisi à la main.
Seules les erreurs flagrantes qui changent un visuel avec une portion
normale sont corrigées ; les écarts plausibles (sélénium des légumineuses
canadiennes, folates des fromages affinés, vitamine E des mayonnaises au
tournesol, iode des produits de la mer…) restent tels quels.

Contrairement aux compléments de cases vides, ces lignes REMPLACENT une
valeur ANSES : l'ancienne valeur est tracée dans Corrections_Proposees.csv
(colonne ancienne_valeur). Une cellule n'est modifiée que si elle contient
encore exactement l'ancienne valeur attendue. Idempotent.
Usage : python scripts/fix_ciqual_outliers.py .
"""
import csv
import io
import sys

U = 'USDA FoodData Central (SR Legacy) — '
_COFFEE = ("Valeur aberrante : un café infusé ne peut pas contenir des centaines de fois plus de vitamine B6 que "
           "le café moulu dont il est extrait (CIQUAL 18003 : 0,001) ; une tasse affichait plus de 100 % de l'apport conseillé.")
_RAW_GT_COOKED = ("Le produit cru ne peut pas être plusieurs fois plus riche que le même produit cuit "
                  "(la cuisson concentre en retirant de l'eau).")
_TOMATO = ("15 fois toutes les autres tomates ; valeur identique à une entrée USDA isolée (« packed in tomato juice », "
           "0,575) contredite par toutes les autres conserves (0,034 à 0,046) : la mise en conserve n'ajoute pas de vitamine B1.")

# (code, colonne, ancienne valeur, nouvelle valeur, source principale, source secondaire, justification, confiance)
FIX = [
    (18004, 'Vitamine_B6_mg_100g', 0.73, 0.001, U + 'Beverages, coffee, brewed, prepared with tap water',
     'CIQUAL 18003 Café, moulu : 0,001', _COFFEE, 'Élevé'),
    (18071, 'Vitamine_B6_mg_100g', 0.74, 0.002, U + 'Beverages, coffee, brewed, espresso, restaurant-prepared',
     'CIQUAL 18003 Café, moulu : 0,001', _COFFEE, 'Élevé'),
    (18162, 'Vitamine_B6_mg_100g', 0.86, 0.025, 'CIQUAL 18153 (même boisson, autre reconstitution)',
     'CIQUAL 18150 poudre soluble : 0,029',
     'Boisson prête à boire 30 fois plus riche que la poudre dont elle est faite : impossible.', 'Élevé'),
    (4008, 'Sélénium_µg_100g', 22.9, 0.4, U + 'Potatoes, flesh and skin, raw',
     'CIQUAL 4003, 4026, 4007 (pommes de terre cuites) : 0,3 à 1',
     "57 fois les autres pommes de terre ; la pomme de terre n'accumule pas le sélénium.", 'Élevé'),
    (4048, 'Sélénium_µg_100g', 8.0, 0.6,
     "Moyenne des pommes de terre cuites mesurées par l'ANSES (CIQUAL 4003 : 0,3 ; 4026 : 0,4 ; 4007 : 1)",
     'USDA Potatoes, boiled : 0,3', "Moyenne de l'« aliment moyen » tirée vers le haut par une valeur aberrante "
     '(pomme de terre crue, 22,9).', 'Élevé'),
    (26043, 'Sélénium_µg_100g', 136.0, 33.1, U + 'Fish, cod, Atlantic, raw',
     'CIQUAL 26125 Cabillaud du Pacifique, cru : 33,1 ; cabillaud cuit : 22,4 à 29,1', _RAW_GT_COOKED, 'Élevé'),
    (26134, 'Sélénium_µg_100g', 120.0, 19.8, 'CIQUAL 26047 Lieu noir, surgelé, cru',
     'CIQUAL 26015 Lieu noir, cuit : 23,8', _RAW_GT_COOKED, 'Élevé'),
    (28902, 'Zinc_mg_100g', 6.5, 2.1,
     'CIQUAL 28900 Jambon cuit, supérieur (2) et 28906 Jambon cuit, supérieur, découenné dégraissé (2,2)',
     'USDA Ham, sliced, regular : 1,35', 'Le même jambon, avec ou sans couenne, ne peut pas tripler en zinc.', 'Élevé'),
    (27006, 'Fer_mg_100g', 1.92, 0.35, 'CIQUAL 27014 Truite arc-en-ciel, élevage, rôtie/cuite au four',
     'USDA Fish, trout, rainbow, farmed, cooked, dry heat : 0,36', '5 fois toutes les autres truites (0,35 à 0,5).',
     'Élevé'),
    (20116, 'Sélénium_µg_100g', 20.0, 1.86, 'CIQUAL 20069 Chou vert, cru',
     'Autres choux CIQUAL : 0,3 à 2,1 ; USDA Cabbage, raw : 0,3', '10 fois tous les autres choux.', 'Élevé'),
    (36016, 'Fer_mg_100g', 3.41, 0.9, U + 'Chicken, broilers or fryers, meat and skin, raw',
     'CIQUAL 36005 Poulet, viande et peau rôties : 0,68', _RAW_GT_COOKED, 'Élevé'),
    (36016, 'Vitamine_B2_mg_100g', 0.82, 0.12, U + 'Chicken, broilers or fryers, meat and skin, raw',
     'CIQUAL 36005 Poulet, viande et peau rôties : 0,16', _RAW_GT_COOKED, 'Élevé'),
    (36016, 'Vitamine_B12_µg_100g', 2.21, 0.31, U + 'Chicken, broilers or fryers, meat and skin, raw',
     'CIQUAL 36005 Poulet, viande et peau rôties : 0,52', _RAW_GT_COOKED, 'Élevé'),
    (20137, 'Vitamine_B1_mg_100g', 0.58, 0.046, U + 'Tomatoes, red, ripe, canned, stewed',
     'CIQUAL purée de tomates 0,1 ; concentré 0,08', _TOMATO, 'Moyen'),
    (20048, 'Vitamine_B1_mg_100g', 0.58, 0.046, U + 'Tomatoes, red, ripe, canned, stewed',
     'CIQUAL purée de tomates 0,1 ; concentré 0,08', _TOMATO, 'Moyen'),
    (20255, 'Vitamine_B1_mg_100g', 0.53, 0.032, 'CIQUAL 20335 Échalote, sautée/poêlée sans matière grasse',
     'CIQUAL 20097 Échalote, crue : 0,036 ; USDA Shallots, raw : 0,06', "15 fois l'échalote crue et poêlée.", 'Élevé'),
    (6591, 'Vitamine_B1_mg_100g', 0.7, 0.06,
     U + 'Veal, shoulder, whole (arm and blade), separable lean and fat, cooked, braised',
     'CIQUAL 6551 Veau, rôti cuit : 0,06', "12 fois le veau rôti ; le veau n'est pas une viande riche en B1 (contrairement au porc).",
     'Moyen'),
    (19037, 'Vitamine_B2_mg_100g', 1.16, 0.16, 'CIQUAL 19041 Lait demi-écrémé, UHT',
     'Autres laits CIQUAL : 0,16 à 0,23 ; USDA lait 2 % : 0,137',
     'Lait enrichi en vitamine D seulement : 7 fois la vitamine B2 de tous les autres laits.', 'Élevé'),
    (26080, 'Fer_mg_100g', 1.6, 0.39, 'CIQUAL 26088 Dorade royale, élevage, crue',
     'CIQUAL 27031 Dorade royale, rôtie : 0,2', '4 fois la même espèce d\'élevage, 8 fois la dorade rôtie.', 'Moyen'),
    (26109, 'Fer_mg_100g', 4.3, 0.39, 'CIQUAL 26099 Dorade grise, crue',
     'CIQUAL 26088 Dorade royale, élevage, crue : 0,39', '11 fois les autres dorades.', 'Moyen'),
    (10037, 'Fer_mg_100g', 5.77, 0.68, U + 'Mollusks, squid, mixed species, raw',
     'CIQUAL 10001 Calmar, cru : 0,2 ; 10084 Calmar, frit : 1,01',
     '29 fois le calmar cru (valeurs proches de celles du poulpe : confusion probable).', 'Moyen'),
    (10037, 'Rétinol_µg_100g', 203.0, 10.0, U + 'Mollusks, squid, mixed species, raw',
     'CIQUAL 10001 Calmar, cru : 2 ; 10084 Calmar, frit : 11', '100 fois le calmar cru.', 'Moyen'),
    (4004, 'Vitamine_B3_mg_100g', 19.4, 4.76, U + 'Snacks, potato chips, plain, salted',
     'CIQUAL 4037 chips à l\'ancienne : 4,74 ; 4038 chips allégées : 2,56', '4 fois toutes les autres chips.', 'Moyen'),
    (4038, 'Vitamine_B9_µg_100g', 254.0, 29.0, U + 'Snacks, potato chips, plain, salted',
     'CIQUAL 4004 : 31,6 ; 4037 : 27,3', '8 fois les autres chips.', 'Moyen'),
]
UNIT = {'g': 'g/100g', 'mg': 'mg/100g', 'µg': 'µg/100g'}


def main(root):
    path = f'{root}/assets/foods.csv'
    raw = open(path, 'rb').read().decode('utf-8')
    nl = '\r\n' if '\r\n' in raw else '\n'
    lines = raw.split(nl)
    header = next(csv.reader([lines[0]]))
    idx = {c: i for i, c in enumerate(header)}
    by_code = {}
    for fx in FIX:
        by_code.setdefault(fx[0], []).append(fx)
    log, out = [], [lines[0]]
    for line in lines[1:]:
        if not line:
            out.append(line)
            continue
        cells = next(csv.reader([line]))
        code = int(cells[0]) if cells[0].isdigit() else None
        changed = False
        for (_, col, old, new, src, src2, why, conf) in by_code.get(code, []):
            cur = cells[idx[col]].strip()
            try:
                cv = float(cur.replace(',', '.'))
            except ValueError:
                cv = None
            if cv is not None and abs(cv - new) < 1e-9:
                continue  # déjà corrigé
            if cv is None or abs(cv - old) > 1e-9:
                print(f'!! {code} {col} : valeur actuelle {cur!r}, attendue {old:g} — ignorée')
                continue
            cells[idx[col]] = f'{new:g}'
            changed = True
            log.append([code, cells[idx['nom']], col, cur, f'{new:g}', UNIT.get(col.split('_')[-2], ''),
                        src, src2, 'Valeur CIQUAL aberrante remplacée. ' + why, conf, '2026-11-01'])
        if changed:
            buf = io.StringIO()
            csv.writer(buf, lineterminator='').writerow(cells)
            line = buf.getvalue()
        out.append(line)
    open(path, 'wb').write(nl.join(out).encode('utf-8'))
    if log:
        corr = f'{root}/Corrections_Proposees.csv'
        crlf = open(corr, 'rb').read().count(b'\r\n') > 0
        with open(corr, 'a', encoding='utf-8', newline='') as f:
            w = csv.writer(f, lineterminator='\r\n' if crlf else '\n')
            for row in log:
                w.writerow(row)
    print(f'{len(log)} valeurs aberrantes corrigées')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
