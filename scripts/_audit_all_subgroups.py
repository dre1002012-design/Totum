#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit script (temporaire) : pour CHAQUE (groupe, sous_groupe), calcule la
fraction d'aliments qui retombent sur le défaut BRUT du sous-groupe (icône ==
défaut, aucun mot-clé gagnant), et donne un échantillon des noms concernés —
pour repérer les sous-groupes où le défaut est un aliment précis plutôt qu'un
repère neutre (même bug que condiments/tartinables/huiles déjà corrigés)."""
import csv, sys
sys.path.insert(0, 'scripts')
import build_food_taxonomy as t

official = t.load_official_groups()
with open('assets/foods.csv', encoding='utf-8-sig', newline='') as f:
    rows = list(csv.DictReader(f))

by_subgroup = {}
for row in rows:
    code = row['ciqual_code'].strip()
    nom = row['nom'].strip()
    if code in t.MANUAL_GROUPS:
        groupe, sous_groupe = t.MANUAL_GROUPS[code]
    elif code in official:
        groupe, sous_groupe = official[code]
    else:
        continue
    key = (groupe, sous_groupe)
    if key not in t.SUBGROUP_ICON_NOVA:
        continue
    default_icon = t.SUBGROUP_ICON_NOVA[key][0]
    icon, nova = t.pick_icon_nova(nom, groupe, sous_groupe)
    by_subgroup.setdefault(key, {'total': 0, 'default_hits': [], 'default_icon': default_icon})
    by_subgroup[key]['total'] += 1
    if icon == default_icon:
        by_subgroup[key]['default_hits'].append(nom)

out = []
for key in sorted(by_subgroup, key=lambda k: -by_subgroup[k]['default_hits'].__len__() / by_subgroup[k]['total']):
    d = by_subgroup[key]
    frac = len(d['default_hits']) / d['total']
    out.append(f"\n=== {key[0]} > {key[1]}  (défaut {d['default_icon']}) : {len(d['default_hits'])}/{d['total']} = {frac:.0%} ===")
    for nom in d['default_hits'][:15]:
        out.append(f"   - {nom}")
    if len(d['default_hits']) > 15:
        out.append(f"   ... (+{len(d['default_hits'])-15} autres)")

with open('scripts/_audit_all_subgroups_out.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('done')
