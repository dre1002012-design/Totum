#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Construit assets/usda_portions.csv : portions courantes ("1 serving", "1 cup",
"item 4 oz"...) avec leur poids réel en grammes, à partir de food_portion.csv
(Foundation Foods + SR Legacy) — poids mesurés en laboratoire/enquête USDA,
jamais estimés. Répond au besoin d'Alex (11/08/2026, 3e passe) : éviter la
sous-estimation calorique quand quelqu'un entre "100 g" par défaut pour un
aliment dont la vraie portion pèse nettement plus (ex. un burger de
fast-food) — mêmes portions que Cronometer/MyFitnessPal, mais réservées aux
aliments USDA (aucune donnée équivalente disponible côté CIQUAL, donc rien
n'est inventé pour cette base).

Filtré aux fdc_id déjà retenus dans assets/usda_foods.csv (build_usda_foods.py
doit avoir tourné avant). Aucun plafond ici — le nombre de portions par
aliment est déjà naturellement bas (94% en ont 1 à 3) ; le plafond d'affichage
(4 choix max) est appliqué côté app pour ne pas alourdir la fiche.

Usage : python3 scripts/build_usda_portions.py
"""
import csv

RAW = 'scripts/usda_raw'
FOUNDATION_DIR = f'{RAW}/foundation/FoodData_Central_foundation_food_csv_2026-04-30'
SR_DIR = f'{RAW}/sr_legacy/FoodData_Central_sr_legacy_food_csv_2018-04'
FOODS_CSV = 'assets/usda_foods.csv'
OUT = 'assets/usda_portions.csv'


def load_kept_fdc_ids():
    with open(FOODS_CSV, encoding='utf-8') as f:
        return {row['fdc_id'] for row in csv.DictReader(f)}


def load_units(d):
    units = {}
    with open(f'{d}/measure_unit.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            units[row['id']] = row['name']
    return units


def fmt_amount(amount: str) -> str:
    try:
        v = float(amount)
    except ValueError:
        return amount
    return str(int(v)) if v == int(v) else f'{v:g}'


def build_label(row, units):
    modifier = row['modifier'].strip()
    desc = row['portion_description'].strip()
    if modifier:
        return modifier
    if desc:
        return desc
    unit_name = units.get(row['measure_unit_id'], '')
    if not unit_name or unit_name == 'undetermined':
        return None
    amount = fmt_amount(row['amount']) if row['amount'] else '1'
    return f'{amount} {unit_name}'


def main():
    kept = load_kept_fdc_ids()
    print(f'{len(kept)} aliments USDA retenus (assets/usda_foods.csv).')

    out_rows = []
    for d in (FOUNDATION_DIR, SR_DIR):
        units = load_units(d)
        with open(f'{d}/food_portion.csv', encoding='utf-8-sig') as f:
            for row in csv.DictReader(f):
                fid = row['fdc_id']
                if fid not in kept:
                    continue
                gw = row['gram_weight']
                if not gw:
                    continue
                try:
                    grams = float(gw)
                except ValueError:
                    continue
                if grams <= 0:
                    continue
                label = build_label(row, units)
                if not label:
                    continue
                out_rows.append({
                    'fdc_id': fid,
                    'label': label,
                    'grams': f'{grams:.1f}',
                })

    # Dédoublonnage (même libellé + même poids pour un même aliment, ça
    # arrive côté Foundation quand plusieurs échantillons partagent la même
    # portion de référence).
    seen = set()
    deduped = []
    for r in out_rows:
        key = (r['fdc_id'], r['label'], r['grams'])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(r)

    with open(OUT, 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['fdc_id', 'label', 'grams'])
        w.writeheader()
        for r in deduped:
            w.writerow(r)

    foods_with_portions = len({r['fdc_id'] for r in deduped})
    print(f'OK -> {OUT} : {len(deduped)} portions pour {foods_with_portions}/{len(kept)} aliments '
          f'({foods_with_portions / len(kept) * 100:.1f}%).')


if __name__ == '__main__':
    main()
