# Rapport de fusion CIQUAL

- Nouvelle table CIQUAL : `scripts\_rebuilt_base.csv`
- Corrections appliquées depuis : `scripts\_corrections_filtered.csv`
- Fichier fusionné écrit vers : `scripts\_merged_base.csv`

- **3020** corrections réappliquées (cellule encore vide dans la nouvelle table).
- **0** corrections désormais superflues (la nouvelle table CIQUAL a comblé la cellule elle-même — valeur CIQUAL conservée, notre correction n'a pas été appliquée).
- **0** corrections obsolètes (l'aliment `ciqual_code` n'existe plus dans la nouvelle table).
