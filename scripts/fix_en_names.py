# -*- coding: utf-8 -*-
"""Corrige les traductions anglaises (colonne nom_en de assets/foods.csv) les
plus fautives repérées le 01/11/2026 — noms propres de fromages traduits mot
à mot (« Crottin de chèvre » -> « Goat manure », « Comté » -> « County »…).
Ne réécrit que la colonne nom_en des codes listés. Idempotent."""
import csv
import io
import sys

FIX = {
    12112: 'Abondance cheese',
    12064: "Boulette d'Avesnes cheese",
    12722: 'Cantal cheese, medium-aged (entre-deux)',
    12109: 'Young Cantal cheese',
    12025: "Carré de l'Est cheese",
    12110: 'Comté cheese',
    12832: 'Crottin goat cheese, raw milk',
    12833: 'Crottin goat cheese, unspecified milk (pasteurised or raw)',
    12764: 'Tête de Moine cheese',
    12758: "Tomme cheese, cow's milk",
    12771: 'Tomme de Savoie cheese',
    12773: 'Tomme des Pyrénées cheese',
    12760: 'Tomme cheese, reduced fat',
    20099: "Lamb's lettuce, raw",
    26018: 'Monkfish (anglerfish), raw',
    26081: 'Monkfish (anglerfish), grilled/pan-fried',
    17270: 'Extra virgin olive oil',
    20586: 'Blond lentils, dry',
}


def main(root):
    path = f'{root}/assets/foods.csv'
    raw = open(path, 'rb').read().decode('utf-8')
    nl = '\r\n' if '\r\n' in raw else '\n'
    lines = raw.split(nl)
    header = next(csv.reader([lines[0]]))
    ie = header.index('nom_en')
    n = 0
    out = [lines[0]]
    for line in lines[1:]:
        if line:
            cells = next(csv.reader([line]))
            code = int(cells[0]) if cells[0].isdigit() else None
            if code in FIX and cells[ie] != FIX[code]:
                cells[ie] = FIX[code]
                buf = io.StringIO()
                csv.writer(buf, lineterminator='').writerow(cells)
                line = buf.getvalue()
                n += 1
        out.append(line)
    open(path, 'wb').write(nl.join(out).encode('utf-8'))
    print(n, 'noms anglais corrigés')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
