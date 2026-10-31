"""Recalcule les valeurs nutritionnelles des recettes de la bibliothèque
(assets/totum_recipes.json et _en.json) depuis assets/foods.csv — à relancer
après TOUTE mise à jour de foods.csv (sinon test/services/
library_recipes_integrity_test.dart échoue). Usage :
    python scripts/regen_recipes_nutrition.py .

Regenerate nutrition of the library recipes from current assets/foods.csv,
mirroring the app's own logic (foods_loader + _recomputeRecipeFromIngredients):
  per-100g = sum(grams * value/100) / total_weight * 100
  energy: Énergie column, else EU 1169/2011 factors from macros (energyFromMacros)
  micros: every numeric column except macros/text (FoodItem.micros100)
Only nutrition fields + ingredient foodName are rewritten; text untouched."""
import csv, json, sys, collections

ROOT = sys.argv[1]
foods = {r['ciqual_code']: r for r in csv.DictReader(open(ROOT + '/assets/foods.csv', encoding='utf-8'))}
MACRO = [('Énergie_kcal_100g', 'kcal100'), ('Protéines_g_100g', 'prot100'), ('Glucides_g_100g', 'carb100'),
         ('Lipides_g_100g', 'fat100'), ('Fibres_g_100g', 'fiber100')]
TEXT = {'ciqual_code', 'nom', 'groupe', 'sous_groupe', 'pictogramme', 'score_nova_estime', 'nom_generique', 'nom_en'}
MICRO_COLS = [c for c in next(iter(foods.values())).keys() if c not in TEXT and c not in dict(MACRO)]
# Ingrédient sans énergie ni macros dans la table ANSES -> équivalent complet.
REPLACE = {'20040': '20327'}  # Poireau, cuit -> Poireau, bouilli/cuit à l'eau


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def energy(r):
    e = num(r['Énergie_kcal_100g'])
    if e is not None:
        return e
    p, c, f = num(r['Protéines_g_100g']), num(r['Glucides_g_100g']), num(r['Lipides_g_100g'])
    if None in (p, c, f):
        return None
    return (4 * p + 4 * c + 9 * f + 2 * (num(r['Fibres_g_100g']) or 0)
            + 7 * (num(r['Alcool_g_100g']) or 0) + 2.4 * (num(r['Polyols_g_100g']) or 0))

for lang in ('', '_en'):
    path = f'{ROOT}/assets/totum_recipes{lang}.json'
    raw = open(path, 'rb').read().decode('utf-8')
    d = json.loads(raw)
    for rc in d['recipes']:
        sums = collections.defaultdict(float)
        has = set()
        for i in rc['ingredients']:
            code = REPLACE.get(str(i['foodId']), str(i['foodId']))
            f = foods[code]
            i['foodId'] = code
            i['foodName'] = f['nom'].strip()
            g = i['grams'] / 100
            e = energy(f)
            assert e is not None, (rc['id'], f['nom'])
            sums['Énergie_kcal_100g'] += e * g
            for c in [m for m, _ in MACRO[1:]] + MICRO_COLS:
                v = num(f[c])
                if v is not None:
                    sums[c] += v * g
                    has.add(c)
        tot = sum(i['grams'] for i in rc['ingredients'])
        rc['total_weight_g'] = round(tot, 1)
        k = 100 / tot
        for c, key in MACRO:
            rc[key] = round(sums[c] * k, 2)
        rc['micros100'] = {c: round(sums[c] * k, 4) for c in MICRO_COLS if c in has}
    indent = 1 if '\n "' in raw[:200] else (2 if '\n  "' in raw[:200] else None)
    out = json.dumps(d, ensure_ascii=False, indent=indent)
    nl = '\r\n' if '\r\n' in raw else '\n'
    if nl != '\n':
        out = out.replace('\n', nl)
    if raw.endswith(nl):
        out += nl
    open(path, 'wb').write(out.encode('utf-8'))
    print(path, 'indent', indent, 'recipes', len(d['recipes']))
