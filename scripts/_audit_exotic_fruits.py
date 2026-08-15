#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit script (temporary, session-only) : liste tous les aliments CIQUAL des
sous-groupes fruits/légumes qui retombent sur le défaut brut du sous-groupe
(icône == défaut du sous-groupe ET aucun mot-clé trouvé), pour cibler les 15
fruits exotiques + rhubarbe mentionnés par Alex."""
import csv
import sys
sys.path.insert(0, 'scripts')
import build_food_taxonomy as t

official = t.load_official_groups()

with open('assets/foods.csv', encoding='utf-8-sig', newline='') as f:
    r = csv.DictReader(f)
    rows = list(r)

out = []
target_subgroups = {
    ('fruits, légumes, légumineuses et oléagineux', 'fruits'),
    ('fruits, légumes, légumineuses et oléagineux', 'légumes'),
}

for row in rows:
    code = row['ciqual_code'].strip()
    nom = row['nom'].strip()
    if code in t.MANUAL_GROUPS:
        groupe, sous_groupe = t.MANUAL_GROUPS[code]
    elif code in official:
        groupe, sous_groupe = official[code]
    else:
        continue
    if (groupe, sous_groupe) not in target_subgroups:
        continue
    icon, nova = t.pick_icon_nova(nom, groupe, sous_groupe)
    default_icon = t.SUBGROUP_ICON_NOVA.get((groupe, sous_groupe), (t.DEFAULT_ICON, t.DEFAULT_NOVA))[0]
    if icon == default_icon:
        out.append((code, nom, groupe, sous_groupe, icon))

with open('scripts/_audit_exotic_fruits_out.txt', 'w', encoding='utf-8') as f:
    f.write(f'Total foods falling to bare subgroup default: {len(out)}\n\n')
    for code, nom, groupe, sous_groupe, icon in out:
        f.write(f'{code}\t{nom}\t[{sous_groupe}]\t{icon}\n')

print('done', len(out))
