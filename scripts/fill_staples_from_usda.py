# -*- coding: utf-8 -*-
"""
Complète les cases VIDES (non mesurées par l'ANSES) des « essentiels du
quotidien » (lib/services/staple_foods.dart) avec la valeur d'un équivalent
USDA FoodData Central (SR Legacy/Foundation, déjà embarqué dans
assets/usda_foods.csv) — même méthode que Corrections_Proposees.csv (audit
du 04/08/2026) : JAMAIS d'écrasement d'une valeur CIQUAL, une ligne de
traçabilité par cellule complétée (source, justification, confiance, date).

Garde-fous :
- correspondance choisie À LA MAIN (intitulé exact, état cru/cuit) ;
- produits céréaliers américains ENRICHIS : B1, B2, B3, B9 et fer exclus
  (enrichissement obligatoire aux États-Unis, absent en France) ;
- laits/boissons végétales américains ENRICHIS : vitamines A, D, B2, B12,
  calcium exclus ;
- seules les valeurs > 0 sont reportées (une case vide reste « inconnue »).
Idempotent. Usage : python scripts/fill_staples_from_usda.py .
"""
import csv
import io
import sys

# code CIQUAL -> (début exact de l'intitulé USDA, confiance, colonnes exclues)
ENRICHED_GRAIN = ('Vitamine_B1_mg_100g', 'Vitamine_B2_mg_100g', 'Vitamine_B3_mg_100g', 'Vitamine_B9_µg_100g', 'Fer_mg_100g')
FORTIFIED_MILK = ('Vitamine_D_µg_100g', 'Rétinol_µg_100g', 'Vitamine_B2_mg_100g', 'Vitamine_B12_µg_100g', 'Calcium_mg_100g',
                  'Vitamine_E_mg_100g')
MAP = {
    22000: ('Egg, whole, raw, fresh', 'Élevé', ()),
    22010: ('Egg, whole, cooked, hard-boiled', 'Élevé', ()),
    22001: ('Egg, white, raw, fresh', 'Élevé', ()),
    36017: ('Chicken, broiler or fryers, breast, skinless, boneless, meat only, raw', 'Élevé', ()),
    36018: ('Chicken, broiler or fryers, breast, skinless, boneless, meat only, cooked, grilled', 'Élevé', ()),
    36304: ('Turkey, whole, breast, meat only, raw', 'Élevé', ()),
    36306: ('Turkey, whole, breast, meat only, cooked, roasted', 'Élevé', ()),
    6250: ('Beef, ground, 95% lean meat / 5% fat, raw', 'Élevé', ()),
    6251: ('Beef, ground, 95% lean meat / 5% fat, patty, cooked, broiled', 'Élevé', ()),
    6255: ('Beef, ground, 85% lean meat / 15% fat, patty, cooked, broiled', 'Élevé', ()),
    6201: ('Beef, top sirloin, steak, separable lean and fat, trimmed to 1/8" fat, choice, raw', 'Moyen', ()),
    28203: ('Pork, fresh, loin, tenderloin, separable lean only, cooked, roasted', 'Élevé', ()),
    28902: ('Ham, sliced, regular (approximately 11% fat)', 'Moyen', ()),
    26036: ('Fish, salmon, Atlantic, farmed, raw', 'Élevé', ()),
    26229: ('Fish, salmon, Atlantic, farmed, cooked, dry heat', 'Élevé', ()),
    26037: ('Fish, salmon, chinook, smoked', 'Moyen', ()),
    26039: ('Fish, tuna, light, canned in water, drained solids', 'Élevé', ()),
    26043: ('Fish, cod, Atlantic, raw', 'Élevé', ()),
    26023: ('Fish, cod, Atlantic, cooked, dry heat', 'Élevé', ()),
    26129: ('Fish, pollock, Atlantic, raw', 'Élevé', ()),
    26051: ('Fish, mackerel, Atlantic, raw', 'Élevé', ()),
    26040: ('Fish, sardine, Atlantic, canned in oil, drained solids with bone', 'Élevé', ()),
    10007: ('Crustaceans, shrimp, cooked', 'Élevé', ()),
    19033: ('Milk, reduced fat, fluid, 2% milkfat, without added vitamin A', 'Élevé', FORTIFIED_MILK),
    19050: ('Milk, nonfat, fluid, without added vitamin A', 'Élevé', FORTIFIED_MILK),
    19023: ('Milk, whole, 3.25% milkfat, without added vitamin A', 'Élevé', FORTIFIED_MILK),
    19593: ('Yogurt, plain, whole milk', 'Élevé', ()),
    19594: ('Yogurt, plain, skim milk', 'Élevé', ()),
    19860: ('Yogurt, Greek, plain, whole milk', 'Élevé', ()),
    19724: ('Yogurt, Greek, plain, nonfat', 'Moyen', ()),
    19644: ('Yogurt, Greek, plain, nonfat', 'Moyen', ()),
    19646: ('Yogurt, Greek, plain, lowfat', 'Moyen', ()),
    12115: ('Cheese, swiss', 'Élevé', ()),
    12110: ('Cheese, gruyere', 'Élevé', ()),
    19590: ('Cheese, mozzarella, whole milk', 'Élevé', ()),
    12120: ('Cheese, parmesan, hard', 'Élevé', ()),
    12066: ('Cheese, feta', 'Élevé', ()),
    12812: ('Cheese, goat, soft type', 'Élevé', ()),
    90002: ('Beverages, Protein powder whey based', 'Moyen', ()),
    20904: ('Tofu, raw, regular, prepared with calcium sulfate', 'Moyen', ('Calcium_mg_100g',)),
    20917: ('Tempeh', 'Élevé', ()),
    20360: ('Lentils, mature seeds, cooked, boiled, without salt', 'Élevé', ()),
    20507: ('Chickpeas (garbanzo beans, bengal gram), mature seeds, cooked, boiled, without salt', 'Élevé', ()),
    20532: ('Chickpeas (garbanzo beans, bengal gram), mature seeds, canned, drained', 'Élevé', ()),
    20503: ('Beans, kidney, red, mature seeds, cooked, boiled, without salt', 'Élevé', ()),
    25621: ('Hummus, commercial', 'Élevé', ()),
    9104: ('Rice, white, long-grain, regular, unenriched, cooked without salt', 'Élevé', ()),
    9100: ('Rice, white, long-grain, regular, raw, unenriched', 'Élevé', ()),
    9103: ('Rice, brown, long-grain, cooked', 'Élevé', ()),
    9125: ('Rice, white, long-grain, regular, unenriched, cooked without salt', 'Moyen', ()),
    9811: ('Pasta, cooked, unenriched, without added salt', 'Élevé', ()),
    9810: ('Pasta, dry, unenriched', 'Élevé', ()),
    9871: ('Pasta, whole-wheat, cooked', 'Élevé', ()),
    9341: ('Quinoa, cooked', 'Élevé', ()),
    9340: ('Quinoa, uncooked', 'Élevé', ()),
    32140: ('Cereals, oats, regular and quick, not fortified, dry', 'Élevé', ()),
    4003: ('Potatoes, boiled, cooked without skin, flesh, without salt', 'Élevé', ()),
    4026: ('Potatoes, baked, flesh and skin, without salt', 'Élevé', ()),
    4102: ('Sweet potato, cooked, baked in skin, flesh, without salt', 'Élevé', ()),
    9683: ('Couscous, cooked', 'Élevé', ()),
    9691: ('Bulgur, cooked', 'Élevé', ()),
    7001: ('Bread, french or vienna (includes sourdough)', 'Moyen', ENRICHED_GRAIN),
    7110: ('Bread, whole-wheat, commercially prepared', 'Élevé', ()),
    7200: ('Bread, white, commercially prepared (includes soft bread crumbs)', 'Moyen', ENRICHED_GRAIN),
    7352: ('Snacks, rice cakes, brown rice, plain, unsalted', 'Élevé', ()),
    20057: ('Broccoli, raw', 'Élevé', ()),
    20304: ('Broccoli, cooked, boiled, drained, without salt', 'Élevé', ()),
    20020: ('Squash, summer, zucchini, includes skin, raw', 'Élevé', ()),
    20021: ('Squash, summer, zucchini, includes skin, cooked, boiled, drained, without salt', 'Élevé', ()),
    20009: ('Carrots, raw', 'Élevé', ()),
    20353: ('Carrots, cooked, boiled, drained, without salt', 'Élevé', ()),
    20385: ('Tomatoes, red, ripe, raw, year round average', 'Élevé', ()),
    20172: ('Tomatoes, red, ripe, raw, year round average', 'Moyen', ()),
    20019: ('Cucumber, with peel, raw', 'Élevé', ()),
    20031: ('Lettuce, butterhead (includes boston and bibb types), raw', 'Élevé', ()),
    20099: ('Cornsalad, raw', 'Élevé', ()),
    20217: ('Arugula, raw', 'Élevé', ()),
    20059: ('Spinach, raw', 'Élevé', ()),
    20027: ('Spinach, cooked, boiled, drained, without salt', 'Élevé', ()),
    20030: ('Beans, snap, green, cooked, boiled, drained, without salt', 'Élevé', ()),
    20087: ('Peppers, sweet, red, raw', 'Élevé', ()),
    20056: ('Mushrooms, white, raw', 'Élevé', ()),
    20034: ('Onions, raw', 'Élevé', ()),
    11000: ('Garlic, raw', 'Élevé', ()),
    13004: ('Avocados, raw, all commercial varieties', 'Élevé', ()),
    20016: ('Cauliflower, raw', 'Élevé', ()),
    20037: ('Peas, green, cooked, boiled, drained, without salt', 'Élevé', ()),
    20053: ('Eggplant, raw', 'Élevé', ()),
    20003: ('Beets, cooked, boiled, drained', 'Élevé', ()),
    20346: ('Kale, raw', 'Élevé', ()),
    20327: ('Leeks, (bulb and lower leaf-portion), cooked, boiled, drained, without salt', 'Élevé', ()),
    13005: ('Bananas, raw', 'Élevé', ()),
    13039: ('Apples, raw, with skin (Includes', 'Élevé', ()),
    13034: ('Oranges, raw, all commercial varieties', 'Élevé', ()),
    13021: ('Kiwifruit, green, raw', 'Élevé', ()),
    13024: ('Tangerines, (mandarin oranges), raw', 'Élevé', ()),
    13014: ('Strawberries, raw', 'Élevé', ()),
    13028: ('Blueberries, raw', 'Élevé', ()),
    13015: ('Raspberries, raw', 'Élevé', ()),
    13037: ('Pears, raw', 'Élevé', ()),
    13395: ('Grapes, red or green (European type, such as Thompson seedless), raw', 'Élevé', ()),
    13025: ('Mangos, raw', 'Élevé', ()),
    13002: ('Pineapple, raw, all varieties', 'Élevé', ()),
    13043: ('Peaches, yellow, raw', 'Élevé', ()),
    13000: ('Apricots, raw', 'Élevé', ()),
    13008: ('Cherries, sweet, raw', 'Élevé', ()),
    13026: ('Melons, cantaloupe, raw', 'Élevé', ()),
    13036: ('Watermelon, raw', 'Élevé', ()),
    13011: ('Dates, deglet noor', 'Élevé', ()),
    13046: ('Raisins, dark, seedless', 'Élevé', ()),
    13187: ('Applesauce, canned, unsweetened, without added ascorbic acid', 'Élevé', ()),
    15000: ('Nuts, almonds', 'Élevé', ()),
    15005: ('Nuts, walnuts, english', 'Élevé', ()),
    15004: ('Nuts, hazelnuts or filberts', 'Élevé', ()),
    15054: ('Nuts, cashew nuts, dry roasted, without salt added', 'Élevé', ()),
    15001: ('Peanuts, all types, raw', 'Élevé', ()),
    15202: ('Peanut butter, smooth style, without salt', 'Élevé', ()),
    15047: ('Seeds, chia seeds, dried', 'Élevé', ()),
    15034: ('Seeds, flaxseed', 'Élevé', ()),
    15064: ('Seeds, pumpkin and squash seed kernels, dried', 'Élevé', ()),
    17270: ('Oil, olive, salad or cooking', 'Élevé', ()),
    17130: ('Oil, canola', 'Élevé', ()),
    16400: ('Butter, without salt', 'Élevé', ()),
    19410: ('Cream, fluid, heavy whipping', 'Moyen', ()),
    18004: ('Beverages, coffee, brewed, prepared with tap water', 'Élevé', ()),
    18071: ('Beverages, coffee, brewed, espresso, restaurant-prepared', 'Élevé', ()),
    18020: ('Beverages, tea, black, brewed, prepared with tap water', 'Élevé', ()),
    18155: ('Beverages, tea, green, brewed, regular', 'Élevé', ()),
    2070: ('Orange juice, raw', 'Élevé', ()),
    31008: ('Honey', 'Élevé', ()),
    31074: ('Chocolate, dark, 70-85% cacao solids', 'Élevé', ()),
    11013: ('Mustard, prepared, yellow', 'Élevé', ()),
    11104: ('Soy sauce made from soy and wheat (shoyu)', 'Élevé', ()),
    11054: ('Salad dressing, mayonnaise, regular', 'Élevé', ()),
    11008: ('Catsup', 'Élevé', ()),
    # Ajouts du 01/11/2026
    15008: ('Nuts, brazilnuts, dried, unblanched', 'Élevé', ()),
    15011: ('Seeds, sunflower seed kernels, dried', 'Élevé', ()),
    15009: ('Nuts, pistachio nuts, dry roasted, with salt added', 'Élevé', ()),
    20502: ('Beans, white, mature seeds, cooked, boiled, without salt', 'Élevé', ()),
    20589: ('Lentils, mature seeds, cooked, boiled, without salt', 'Moyen', ()),
    20014: ('Cabbage, red, raw', 'Élevé', ()),
    20292: ('Squash, winter, butternut, frozen, cooked, boiled, without salt', 'Moyen', ()),
    13001: ('Apricots, dried, sulfured, uncooked', 'Élevé', ()),
    13013: ('Figs, dried, uncooked', 'Élevé', ()),
    19865: ('Kefir, lowfat, plain, LIFEWAY', 'Moyen', FORTIFIED_MILK),
    2028: ('Lemon juice, raw', 'Élevé', ()),
    17220: ('Oil, walnut', 'Élevé', ()),
    36004: ('Chicken, broilers or fryers, leg, meat and skin, cooked, roasted', 'Élevé', ()),
    26019: ('Fish, mackerel, Atlantic, cooked, dry heat', 'Élevé', ()),
    27006: ('Fish, trout, rainbow, farmed, cooked, dry heat', 'Moyen', ()),
}
NUTRIENTS = [
    'EPA_g_100g', 'DHA_g_100g', 'Acide_alpha-linolénique_W3_ALA_g_100g', 'Acide_linoléique_W6_LA_g_100g',
    'Vitamine_D_µg_100g', 'Magnésium_mg_100g', 'Vitamine_B9_µg_100g', 'Fer_mg_100g', 'Calcium_mg_100g',
    'Potassium_mg_100g', 'Zinc_mg_100g', 'Sélénium_µg_100g', 'Vitamine_C_mg_100g', 'Vitamine_K1_µg_100g',
    'Vitamine_E_mg_100g', 'Rétinol_µg_100g', 'Beta-Carotène_µg_100g', 'Vitamine_B6_mg_100g', 'Vitamine_B2_mg_100g',
    'Vitamine_B1_mg_100g', 'Vitamine_B3_mg_100g', 'Vitamine_B5_mg_100g', 'Vitamine_B12_µg_100g', 'Fibres_g_100g',
    'Cuivre_mg_100g', 'Manganèse_mg_100g', 'Phosphore_mg_100g',
]
UNIT = {'g': 'g/100g', 'mg': 'mg/100g', 'µg': 'µg/100g'}


def main(root, dry=False):
    usda = list(csv.DictReader(open(f'{root}/assets/usda_foods.csv', encoding='utf-8')))
    path = f'{root}/assets/foods.csv'
    raw = open(path, 'rb').read().decode('utf-8')
    nl = '\r\n' if '\r\n' in raw else '\n'
    lines = raw.split(nl)
    header = next(csv.reader([lines[0]]))
    idx = {c: i for i, c in enumerate(header)}
    matched = {}
    for code, (prefix, conf, excl) in MAP.items():
        cands = [u for u in usda if u['nom'].startswith(prefix)]
        if not cands:
            print(f'!! aucune correspondance pour {code} : {prefix}')
            continue
        # L'intitulé EXACT d'abord (« Cheese, swiss » et non « …, low fat »).
        cands.sort(key=lambda u: (u['nom'].split(' (Includes')[0] != prefix, u['source'] != 'sr_legacy', len(u['nom'])))
        matched[code] = (cands[0], conf, excl)
    log = []
    out = [lines[0]]
    for line in lines[1:]:
        if not line:
            out.append(line)
            continue
        cells = next(csv.reader([line]))
        code = int(cells[0]) if cells[0].isdigit() else None
        if code in matched:
            u, conf, excl = matched[code]
            changed = False
            for col in NUTRIENTS:
                if col in excl or cells[idx[col]].strip() != '':
                    continue
                v = (u.get(col) or '').strip()
                try:
                    fv = float(v)
                except ValueError:
                    continue
                if fv <= 0:
                    continue
                cells[idx[col]] = f'{fv:g}'
                changed = True
                unit = UNIT.get(col.split('_')[-2], col.split('_')[-2] + '/100g')
                log.append([code, cells[idx['nom']], col, '', f'{fv:g}', unit,
                            f"USDA FoodData Central ({'Foundation' if u['source'] == 'foundation' else 'SR Legacy'}) — {u['nom']}",
                            '', 'Case non mesurée par l\'ANSES ; équivalent choisi à la main (même aliment, même état).'
                            + (' Valeurs d\'enrichissement américain exclues.' if excl else ''), conf, '2026-11-01'])
            if changed:
                buf = io.StringIO()
                csv.writer(buf, lineterminator='').writerow(cells)
                line = buf.getvalue()
        out.append(line)
    print(f'{len(matched)} correspondances, {len(log)} cellules complétées')
    if dry:
        for code, (u, conf, _) in sorted(matched.items()):
            print(f'  {code} -> {u["nom"][:80]}')
        return
    open(path, 'wb').write(nl.join(out).encode('utf-8'))
    with open(f'{root}/Corrections_Proposees.csv', 'a', encoding='utf-8', newline='') as f:
        w = csv.writer(f, lineterminator='\r\n' if open(f'{root}/Corrections_Proposees.csv', 'rb').read().count(b'\r\n') else '\n')
        for row in log:
            w.writerow(row)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.', dry='--dry' in sys.argv)
