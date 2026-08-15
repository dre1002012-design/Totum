#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit (temporaire) : pour chaque catégorie USDA, fraction d'aliments qui
retombent sur le défaut brut (icône == défaut catégorie), avec échantillon."""
import csv, sys
sys.path.insert(0, 'scripts')
import build_usda_taxonomy as u

with open('assets/usda_foods.csv', encoding='utf-8') as f:
    rows = list(csv.DictReader(f))

by_cat = {}
for row in rows:
    cat = row['sous_groupe']
    nom = row['nom']
    if not cat:
        continue
    groupe, icon, nova = u.pick_icon_nova(nom, cat)
    default_icon = u.CATEGORY_INFO.get(cat, ('autres', u.DEFAULT_ICON, u.DEFAULT_NOVA))[1]
    d = by_cat.setdefault(cat, {'total': 0, 'hits': [], 'default_icon': default_icon})
    d['total'] += 1
    if icon == default_icon:
        d['hits'].append(nom)

out = []
for cat in sorted(by_cat, key=lambda k: -len(by_cat[k]['hits']) / by_cat[k]['total']):
    d = by_cat[cat]
    frac = len(d['hits']) / d['total']
    out.append(f"\n=== {cat}  (défaut {d['default_icon']}) : {len(d['hits'])}/{d['total']} = {frac:.0%} ===")
    for nom in d['hits'][:20]:
        out.append(f"   - {nom}")
    if len(d['hits']) > 20:
        out.append(f"   ... (+{len(d['hits'])-20} autres)")

with open('scripts/_audit_usda_out.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('done')
