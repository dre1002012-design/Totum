#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Traduction en masse des noms d'aliments (USDA -> français, CIQUAL ->
anglais), en tâche de fond, résumable (checkpoint JSON sauvegardé au fur et
à mesure) — un aller-retour de traduction gratuite prend ~1,3 s/aliment, donc
plusieurs heures pour ~11 260 aliments au total. Ce script peut être arrêté
et relancé sans perdre la progression déjà faite.

Usage :
  python3 scripts/translate_names.py usda    # ~7770 aliments, en -> fr
  python3 scripts/translate_names.py ciqual  # ~3490 aliments, fr -> en
"""
import csv
import json
import sys
import time
from pathlib import Path

from deep_translator import GoogleTranslator

CHECKPOINT_DIR = Path('scripts/translation_cache')
CHECKPOINT_DIR.mkdir(exist_ok=True)

CONFIGS = {
    'usda': {
        'csv': 'assets/usda_foods.csv',
        'id_col': 'fdc_id',
        'name_col': 'nom',
        'source_lang': 'en',
        'target_lang': 'fr',
        'checkpoint': CHECKPOINT_DIR / 'usda_fr.json',
    },
    'ciqual': {
        'csv': 'assets/foods.csv',
        'id_col': 'ciqual_code',
        'name_col': 'nom',
        'source_lang': 'fr',
        'target_lang': 'en',
        'checkpoint': CHECKPOINT_DIR / 'ciqual_en.json',
    },
}


def load_checkpoint(path: Path) -> dict:
    if path.exists():
        try:
            return json.loads(path.read_text(encoding='utf-8'))
        except Exception:
            return {}
    return {}


def save_checkpoint(path: Path, data: dict):
    tmp = path.with_suffix('.tmp')
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=0), encoding='utf-8')
    tmp.replace(path)


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in CONFIGS:
        print('Usage: python3 scripts/translate_names.py usda|ciqual')
        sys.exit(1)
    cfg = CONFIGS[sys.argv[1]]

    with open(cfg['csv'], encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    done = load_checkpoint(cfg['checkpoint'])
    print(f'{len(done)} déjà traduits (reprise depuis le checkpoint).')

    todo = [r for r in rows if r[cfg['id_col']] not in done]
    print(f'{len(todo)} restants sur {len(rows)}.')

    translator = GoogleTranslator(source=cfg['source_lang'], target=cfg['target_lang'])
    save_every = 20
    since_save = 0
    t0 = time.time()

    for i, row in enumerate(todo):
        rid = row[cfg['id_col']]
        name = row[cfg['name_col']]
        translated = None
        for attempt in range(3):
            try:
                translated = translator.translate(name)
                break
            except Exception as e:
                print(f'  retry ({attempt}) sur "{name}": {e}')
                time.sleep(3 * (attempt + 1))
        done[rid] = translated if translated else name  # repli : garder l'original plutôt qu'un vide
        since_save += 1
        if since_save >= save_every:
            save_checkpoint(cfg['checkpoint'], done)
            since_save = 0
            elapsed = time.time() - t0
            rate = (i + 1) / elapsed if elapsed > 0 else 0
            remaining = (len(todo) - i - 1) / rate if rate > 0 else 0
            print(f'{len(done)}/{len(rows)} — {elapsed:.0f}s écoulées, '
                  f'~{remaining/60:.0f} min restantes')

    save_checkpoint(cfg['checkpoint'], done)
    print(f'Terminé : {len(done)}/{len(rows)} traduits -> {cfg["checkpoint"]}')


if __name__ == '__main__':
    main()
