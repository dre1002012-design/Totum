#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fusionne les traductions déjà produites (scripts/translation_cache/*.json,
alimenté par translate_names.py, potentiellement partiel/en cours) dans les
CSV finaux : colonne 'nom_fr' sur assets/usda_foods.csv, colonne 'nom_en'
sur assets/foods.csv. Ré-exécutable à tout moment (même avec une traduction
encore en cours en tâche de fond) sans rien casser — les entrées pas encore
traduites gardent juste une colonne vide (repli automatique côté app sur le
nom natif tant que ce n'est pas rempli).

Usage :
  python3 scripts/merge_translations.py usda
  python3 scripts/merge_translations.py ciqual
"""
import csv
import json
import sys
from pathlib import Path

CONFIGS = {
    'usda': {
        'csv': 'assets/usda_foods.csv',
        'id_col': 'fdc_id',
        'out_col': 'nom_fr',
        'checkpoint': Path('scripts/translation_cache/usda_fr.json'),
    },
    'ciqual': {
        'csv': 'assets/foods.csv',
        'id_col': 'ciqual_code',
        'out_col': 'nom_en',
        'checkpoint': Path('scripts/translation_cache/ciqual_en.json'),
    },
}


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in CONFIGS:
        print('Usage: python3 scripts/merge_translations.py usda|ciqual')
        sys.exit(1)
    cfg = CONFIGS[sys.argv[1]]

    if not cfg['checkpoint'].exists():
        print(f'Pas de checkpoint à {cfg["checkpoint"]} — rien à fusionner.')
        sys.exit(0)
    translations = json.loads(cfg['checkpoint'].read_text(encoding='utf-8'))

    with open(cfg['csv'], encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames)
        rows = list(reader)

    filled = 0
    for row in rows:
        t = translations.get(row[cfg['id_col']], '')
        row[cfg['out_col']] = t
        if t:
            filled += 1

    if cfg['out_col'] not in fieldnames:
        fieldnames.append(cfg['out_col'])

    with open(cfg['csv'], 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for row in rows:
            w.writerow({k: row.get(k, '') for k in fieldnames})

    print(f'{filled}/{len(rows)} lignes avec "{cfg["out_col"]}" rempli -> {cfg["csv"]}')


if __name__ == '__main__':
    main()
