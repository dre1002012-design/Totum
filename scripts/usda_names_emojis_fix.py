# -*- coding: utf-8 -*-
"""
Passe qualité sur assets/usda_foods.csv (31/10/2026) :
1. Traductions françaises littérales des intitulés USDA corrigées
   (« poulets de chair ou friteuses » = broilers or fryers, « maigre
   séparable », grades de bœuf « au choix »/« sélectionné » = Choice/Select,
   « paré à 0" de gras »…).
2. Pictogrammes des légumes et fruits USDA restés sur le défaut de leur
   catégorie (🥦 pour 354 légumes dont 14 brocolis, 🍎 pour des agrumes,
   prunes, olives…), alignés sur les choix de la base CIQUAL.
Ne réécrit QUE les colonnes nom_fr et pictogramme (reste du fichier à
l'octet près). Idempotent. Usage : python scripts/usda_names_emojis_fix.py .
"""
import csv
import io
import re
import sys
from collections import Counter

NAME_FIXES = [
    (r',\s*poulets de chair ou friteuses', ''),
    (r',\s*poulets à griller ou à frire', ''),
    (r'maigre et gras séparables?', 'maigre et gras'),
    (r'maigre séparables? (?:seulement|uniquement)', 'maigre seul'),
    (r'gras séparables? (?:seulement|uniquement)', 'gras seul'),
    (r'paré à 0" de gras', 'sans gras'),
    (r'paré à 1/8" de gras', 'gras paré à 3 mm'),
    (r'paré à 1/4" de gras', 'gras paré à 6 mm'),
    (r'paré à 1/2" de gras', 'gras paré à 12 mm'),
    (r',\s*au choix\b', ', qualité Choice'),
    (r',\s*sélectionnée?s?\b', ', qualité Select'),
    (r',\s*toutes catégories\b', ', toutes qualités'),
]

VEG_EMOJI = [
    (r'broccoli', '🥦'),
    (r'hot chili|jalape|chili pepper|peppers, hot|serrano|hungarian', '🌶️'),
    (r'pepper', '🫑'),
    (r'beans, snap|green bean|snap bean|yardlong|drumstick pods|okra|hyacinth|winged bean|edamame|'
     r'soybeans, green|peas, green|edible-podded|snow pea|peas and carrots', '🫛'),
    # Feuilles AVANT racines : « turnip greens », « beet greens », « sweet potato leaves ».
    (r'cauliflower|brussels|cabbage|kale|collard|greens|spinach|chard|lettuce|cress|purslane|lambsquarters|'
     r'dandelion|borage|chrysanthemum|leaves|jute|amaranth|convolvulus|butterbur|sesbania|arugula|endive|'
     r'escarole|pak-choi|bok choy|mustard|watercress|sorrel|fiddlehead|nopales|cactus', '🥬'),
    (r'beans|cowpea|mung|soybean|broadbean|lentil|chickpea|pigeon pea', '🫘'),
    (r'tomato', '🍅'), (r'carrot', '🥕'),
    (r'sweet potato|taro|yam|arrowhead|lotus root|burdock|cassava|jicama|yambean|tannier', '🍠'),
    (r'potato', '🥔'),
    (r'cucumber|zucchini', '🥒'), (r'gourd|squash|pumpkin|chayote|calabash', '🎃'),
    (r'mushroom|shiitake|enoki|chanterelle|morel|portabella|maitake', '🍄'),
    (r'onion|leek|shallot|scallion|chive', '🧅'), (r'garlic', '🧄'), (r'corn', '🌽'), (r'eggplant', '🍆'),
    (r'radish', '🔴'), (r'beet', '🟣'),
    (r'turnip|rutabaga|kohlrabi|celeriac|parsnip|salsify', '⚪'),
    (r'asparagus|celery|fennel|cardoon|artichoke|bamboo', '🍃'),
    (r'seaweed|kelp|spirulina|laver|wakame|agar|irishmoss', '🌊'),
    (r'mixed vegetables|vegetables, mixed|succotash|stew', '🥗'),
]
FRUIT_EMOJI = [
    (r'lemon|lime', '🍋'), (r'pummelo|pomelo|grapefruit|orange|tangerine|mandarin|kumquat|clementine', '🍊'),
    (r'rhubarb|pomegranate|rambutan|lychee|litchi|jujube|acerola|cherr', '🔴'),
    (r'prune|plum|tamarind|sapodilla|baobab|date', '🟤'), (r'olive', '🫒'), (r'quince|pear', '🍐'),
    (r'guava|soursop|feijoa|cherimoya', '🟢'), (r'peach|nectarine|apricot', '🍑'),
    (r'banana|plantain', '🍌'), (r'pineapple', '🍍'), (r'mango', '🥭'), (r'kiwi', '🥝'),
    (r'strawberr', '🍓'), (r'blueberr|blackberr|raspberr|cranberr|currant|elderberr|gooseberr|boysenberr', '🫐'),
    (r'grape|raisin', '🍇'), (r'watermelon', '🍉'), (r'melon|cantaloupe|honeydew', '🍈'), (r'coconut', '🥥'),
    (r'avocado', '🥑'), (r'candied', '🍬'), (r'sapote|naranjilla|papaya|persimmon|passion', '🟠'),
]


def fix_name(n):
    for pat, rep in NAME_FIXES:
        n = re.sub(pat, rep, n, flags=re.I)
    return re.sub(r'\s{2,}', ' ', n).replace(' ,', ',')


def pick(rules, name, current, default):
    if current != default:
        return current
    low = name.lower()
    for pat, emo in rules:
        if re.search(pat, low):
            return emo
    return current


def main(root):
    path = f'{root}/assets/usda_foods.csv'
    raw = open(path, 'rb').read().decode('utf-8')
    nl = '\r\n' if '\r\n' in raw else '\n'
    lines = raw.split(nl)
    header = next(csv.reader([lines[0]]))
    i_fr, i_en, i_pic, i_sg = (header.index(c) for c in ('nom_fr', 'nom', 'pictogramme', 'sous_groupe'))
    out, stats = [lines[0]], Counter()
    for line in lines[1:]:
        if not line:
            out.append(line)
            continue
        cells = next(csv.reader([line]))
        before = list(cells)
        cells[i_fr] = fix_name(cells[i_fr])
        sg = cells[i_sg]
        if sg == 'Vegetables and Vegetable Products':
            cells[i_pic] = pick(VEG_EMOJI, cells[i_en], cells[i_pic], '🥦')
        elif sg == 'Fruits and Fruit Juices' and not cells[i_en].lower().startswith('apple'):
            cells[i_pic] = pick(FRUIT_EMOJI, cells[i_en], cells[i_pic], '🍎')
        if cells != before:
            stats['name' if cells[i_fr] != before[i_fr] else 'emoji'] += 1
            if cells[i_pic] != before[i_pic]:
                stats['emoji_changed'] += 1
            buf = io.StringIO()
            csv.writer(buf, lineterminator='').writerow(cells)
            line = buf.getvalue()
        out.append(line)
    open(path, 'wb').write(nl.join(out).encode('utf-8'))
    print(dict(stats))


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
