# -*- coding: utf-8 -*-
"""
Fusionne une nouvelle version de foods.csv (issue d'une future mise à jour de la
base CIQUAL) avec les corrections USDA tracées dans Corrections_Proposees.csv,
sans refaire tout le travail d'audit manuel.

Contexte
--------
foods.csv est dérivé de la base CIQUAL, qui reste LE socle de référence de
l'application. L'audit scientifique mené en 2026 (voir Audit_Global.md) a comblé
~2900 cellules vides ou incohérentes sur les micronutriments, avec des données
USDA FoodData Central sourcées et vérifiées une par une (voir
Corrections_Proposees.csv). Le jour où l'ANSES publie une nouvelle édition de
CIQUAL, il ne faut PAS repartir de zéro : ce script réapplique automatiquement
les corrections encore utiles à la nouvelle table.

Règle de fusion (le principe const à respecter à chaque mise à jour) :
    - Le nouveau CIQUAL est toujours prioritaire. Si la nouvelle table a
      elle-même comblé une cellule que nous avions corrigée (ANSES a mis à jour
      sa donnée), on garde la valeur CIQUAL et on n'écrase jamais une valeur
      officielle par notre correction USDA.
    - Si la cellule est encore vide dans la nouvelle table, on réapplique notre
      correction USDA (elle reste la meilleure donnée disponible).
    - Si l'aliment (ciqual_code) a disparu de la nouvelle table, la correction
      est ignorée et listée comme obsolète.
    - Si une colonne référencée par une correction n'existe plus dans la
      nouvelle table (renommage/refonte de schéma côté CIQUAL), le script
      s'arrête avec une erreur claire plutôt que d'appliquer une correction au
      mauvais endroit — il faudra alors adapter Corrections_Proposees.csv à la
      main pour cette colonne avant de relancer.

Usage
-----
    python scripts/merge_ciqual_update.py \
        --new-ciqual chemin/vers/nouveau_foods.csv \
        --out assets/foods.csv \
        [--corrections Corrections_Proposees.csv] \
        [--report rapport_fusion.md]

Par défaut, --corrections pointe vers Corrections_Proposees.csv à la racine du
dépôt, et --report écrit un résumé Markdown à côté du fichier de sortie.

Le script ne modifie jamais le fichier d'entrée --new-ciqual ; il écrit un
nouveau fichier vers --out (peut être le même chemin que assets/foods.csv une
fois le résultat vérifié).
"""

import argparse
import csv
import sys
from pathlib import Path


def detect_newline(path: Path) -> str:
    raw = path.read_bytes()
    if b"\r\n" in raw:
        return "\r\n"
    if b"\n" in raw:
        return "\n"
    return "\r\n"


def load_csv_rows(path: Path):
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)
    return header, rows


def load_corrections(path: Path):
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return list(reader)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--new-ciqual", required=True, help="Chemin vers le nouveau foods.csv basé sur la future table CIQUAL")
    parser.add_argument("--out", required=True, help="Chemin de sortie pour le foods.csv fusionné")
    parser.add_argument("--corrections", default="Corrections_Proposees.csv", help="Chemin vers Corrections_Proposees.csv (défaut : à la racine du dépôt)")
    parser.add_argument("--report", default=None, help="Chemin du rapport de fusion Markdown (défaut : <out>.fusion_report.md)")
    args = parser.parse_args()

    new_path = Path(args.new_ciqual)
    out_path = Path(args.out)
    corrections_path = Path(args.corrections)
    report_path = Path(args.report) if args.report else out_path.with_suffix(out_path.suffix + ".fusion_report.md")

    if not new_path.exists():
        sys.exit(f"Erreur : fichier introuvable : {new_path}")
    if not corrections_path.exists():
        sys.exit(f"Erreur : fichier introuvable : {corrections_path}")

    newline = detect_newline(new_path)
    header, rows = load_csv_rows(new_path)

    if "ciqual_code" not in header:
        sys.exit("Erreur : le nouveau fichier CIQUAL n'a pas de colonne 'ciqual_code'. "
                  "Vérifie que le schéma de colonnes n'a pas changé avant de continuer.")
    id_idx = header.index("ciqual_code")
    col_idx = {name: i for i, name in enumerate(header)}

    corrections = load_corrections(corrections_path)

    # Vérifie que toutes les colonnes référencées existent dans le nouveau schéma
    # AVANT de commencer à modifier quoi que ce soit.
    unknown_cols = sorted({c["colonne"] for c in corrections if c["colonne"] not in col_idx})
    if unknown_cols:
        sys.exit(
            "Erreur : les colonnes suivantes, référencées dans Corrections_Proposees.csv, "
            "n'existent plus dans le nouveau foods.csv :\n  - " + "\n  - ".join(unknown_cols) +
            "\nLe schéma CIQUAL a probablement changé (renommage de colonne). "
            "Mets à jour Corrections_Proposees.csv en conséquence avant de relancer la fusion."
        )

    by_id = {row[id_idx]: row for row in rows}

    reapplied = []
    superseded = []
    obsolete_food = []
    already_reapplied_dupe = set()

    for c in corrections:
        cid, col, new_val = c["id"], c["colonne"], c["nouvelle_valeur"]
        row = by_id.get(cid)
        if row is None:
            obsolete_food.append(c)
            continue
        idx = col_idx[col]
        current = row[idx].strip()
        key = (cid, col)
        if current == "":
            if key in already_reapplied_dupe:
                continue  # Corrections_Proposees.csv peut contenir plusieurs lots historiques pour la même cellule
            row[idx] = new_val
            already_reapplied_dupe.add(key)
            reapplied.append(c)
        else:
            superseded.append(c)

    with out_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator=newline)
        writer.writerow(header)
        writer.writerows(rows)

    report_lines = [
        "# Rapport de fusion CIQUAL",
        "",
        f"- Nouvelle table CIQUAL : `{new_path}`",
        f"- Corrections appliquées depuis : `{corrections_path}`",
        f"- Fichier fusionné écrit vers : `{out_path}`",
        "",
        f"- **{len(reapplied)}** corrections réappliquées (cellule encore vide dans la nouvelle table).",
        f"- **{len(superseded)}** corrections désormais superflues (la nouvelle table CIQUAL a comblé la cellule elle-même — valeur CIQUAL conservée, notre correction n'a pas été appliquée).",
        f"- **{len(obsolete_food)}** corrections obsolètes (l'aliment `ciqual_code` n'existe plus dans la nouvelle table).",
        "",
    ]
    if obsolete_food:
        report_lines.append("## Aliments disparus de la nouvelle table CIQUAL")
        report_lines.append("")
        for c in obsolete_food[:200]:
            report_lines.append(f"- `{c['id']}` — {c['nom_aliment']} ({c['colonne']})")
        if len(obsolete_food) > 200:
            report_lines.append(f"- … et {len(obsolete_food) - 200} de plus.")
        report_lines.append("")

    report_path.write_text("\n".join(report_lines), encoding="utf-8")

    print(f"Réappliquées : {len(reapplied)}")
    print(f"Superflues (CIQUAL a maintenant sa propre valeur) : {len(superseded)}")
    print(f"Obsolètes (aliment disparu) : {len(obsolete_food)}")
    print(f"Fichier fusionné : {out_path}")
    print(f"Rapport détaillé : {report_path}")


if __name__ == "__main__":
    main()
