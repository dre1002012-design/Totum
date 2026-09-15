# Audit — Scanner code-barres & base d'aliments (étude de faisabilité)

**Date : 15/09/2026 — commandé par Alex.** Objectif : que le scanner Totum couvre "un panel d'aliments ultra complet", avec macros ET micronutriments à chaque scan, aussi vite et fiable que Yuka/Yazio/MyFitnessPal — sur web aujourd'hui, Play Store et App Store demain. Ce document est une **étude de faisabilité** : aucun code n'a été modifié pour cette partie, les recommandations attendent la décision d'Alex avant implémentation. (Le bug favoris signalé dans le même message a, lui, été corrigé séparément — voir `git log`.)

---

## 1. État actuel de Totum (relu dans le code, pas supposé)

- **Scan** : `mobile_scanner` 7.4.0, formats EAN‑13/EAN‑8/UPC‑A/UPC‑E (couvre la quasi‑totalité des codes-barres alimentaires du commerce). Moteur de décodage **ML Kit en natif** (Android/iOS) mais **ZXing‑js sur web** — deux moteurs différents, déjà documenté dans le code (`barcode_scan_screen.dart`) suite à un audit précédent d'Alex ("ça fonctionne une fois sur deux" sur la web app). Repli déjà en place : saisie manuelle du code si la caméra échoue.
- **Résolution du produit scanné** : un seul appel réseau **live** vers `world.openfoodfacts.org/api/v0/product/<code>.json`, avec 3 tentatives et 6 s de timeout chacune (jusqu'à ~18 s dans le pire cas), voir `_fetchOFF()`/`_handleBarcode()` dans `journal_screen.dart`. **Aucune base locale n'est utilisée pour le scan** — contrairement à la base "Commun" (CIQUAL + USDA), qui elle est bundlée en local (`assets/foods.csv`, `assets/usda_foods.csv`) et donc instantanée et disponible hors-ligne.
- **Micronutriments au scan** : déjà très complet — plus de 30 champs mappés depuis Open Food Facts (AG saturés, oméga 3/6/9, EPA/DHA, 11 minéraux, 13 vitamines...), avec repli sur plusieurs noms de clé OFF alternatifs par champ. **C'est déjà un point fort réel, pas un trou** : Cronometer indique lui-même que son propre scan ne remonte souvent que les nutriments de l'étiquette (limités), et recommande à ses utilisateurs d'éviter le scan pour un profil micronutriments complet. Totum fait déjà mieux que ça quand OFF a la donnée.
- **Base USDA déjà bundlée** (`assets/usda_foods.csv`, ~3,5 Mo) : uniquement **Foundation Foods + SR Legacy** (aliments bruts/génériques, un tag `marque` texte existe mais n'est pas relié à un vrai code-barres). La base **USDA Branded Foods** (celle qui contient les vrais GTIN/UPC) n'est **pas du tout intégrée aujourd'hui** — voir §3.

## 2. Ce que font vraiment les concurrents (audité, sources en bas de page)

| App | Base produits | Stratégie réelle |
|---|---|---|
| **Yuka** (80M utilisateurs) | **Construite sur Open Food Facts**, complétée par de la saisie propre + capture via **Scandit** (SDK commercial de reconnaissance) | Sa force n'est **pas** une base plus grande que celle de Totum — c'est la même base OFF en soustrait. Sa vraie différenciation : un moteur de capture caméra commercial plus robuste, et un score simple/lisible (déjà l'esprit du Score Totum). |
| **MyFitnessPal** (~18-20M entrées) | Très majoritairement **crowdsourcé par les utilisateurs**, comme OFF mais moins modéré | Base énorme mais réputation de données incohérentes/dupliquées (article même titré *"Why did MyFitnessPal remove barcode scanning?"* — passé Premium sur une partie de la fonctionnalité). Taille ≠ qualité. |
| **Cronometer** | **NCCDB + USDA FoodData Central + sa propre base vérifiée (CRDB)**, données de laboratoire (analyse chimique réelle, pas déclaratif) ; scan alimenté par **l'API commerciale Nutritionix** (~1,9M aliments, ~600k UPC, ~92% de taux de reconnaissance) | Exactement la philosophie déjà actée pour Totum dans la mémoire du projet ("niveau MacroFactor/Cronometer, rigueur scientifique avant tout") : petite base **mais fiable**, complétée par une source de scan tierce dédiée plutôt que de tout miser sur le crowdsourcing. |
| **Yazio** | ~4M produits, **sources sous licence** (pas seulement communautaire) | Bonne couverture européenne, cohérent avec son origine allemande. |

**Conclusion clé, qui recadre la demande d'Alex** : aucun concurrent sérieux n'a réinventé une base de zéro. Yuka réutilise la même base ouverte que Totum. Cronometer, le concurrent le plus proche de l'ADN Totum (rigueur > volume), **achète une API tierce en complément** plutôt que de tout construire. La bonne question n'est donc pas "remplacer Open Food Facts" mais **"que rajouter en complément, et où le vrai goulot d'étranglement se situe-t-il aujourd'hui"**.

## 3. Options concrètes, évaluées avec faisabilité réelle

### Option A — Bundler un instantané d'Open Food Facts en local (recommandé en premier, effort faible, gain immédiat sur la vitesse)
OFF publie un export officiel complet (JSONL/Parquet/CSV, ~1,7 à 3M produits selon la source, 150+ pays), mis à jour régulièrement, dans le même esprit que ce que Totum fait déjà pour CIQUAL/USDA (`scripts/build_usda_foods.py`). **C'est l'architecture qui a déjà fait ses preuves dans ce projet** : au lieu d'un appel réseau de plusieurs secondes à chaque scan, un sous-ensemble (produits les plus scannés/marchés visés) serait précalculé et embarqué dans l'app — résolution **instantanée et hors-ligne** pour la majorité des scans, avec l'appel réseau OFF gardé uniquement en repli pour les produits absents du bundle (nouveautés, produits rares). C'est le vrai levier "ultra rapide" demandé — le goulot actuel n'est pas la taille de la base OFF (1,7-3M produits, déjà large), c'est le fait de tout interroger en direct à chaque scan.
- **Coût** : 0 € (données ouvertes, licence ODbL — attribution requise, déjà a priori le cas si OFF est déjà cité quelque part dans l'app/les mentions légales, à vérifier).
- **Effort** : moyen — script de conversion (même famille que les scripts USDA existants) + gestion de la taille de l'asset embarqué (arbitrage à faire : bundle complet impossible en l'état — 7 Go compressé — donc un sous-ensemble filtré, ex. par marché/popularité, comme déjà fait pour USDA qui n'embarque pas la totalité de FoodData Central).

### Option B — Ajouter USDA Branded Foods (GTIN/UPC) comme 2ᵉ source locale (recommandé en second, effort faible, gratuit, cohérent avec l'existant)
Le dataset USDA "Global Branded Food Products Database" contient un champ `gtin_upc` explicite, ~400k+ produits de marque (États-Unis surtout, mais couverture internationale croissante via GS1/1WorldSync), mis à jour 2×/an en téléchargement gratuit. Le pipeline d'ingestion USDA existe déjà dans ce repo (`scripts/build_usda_foods.py`) — l'étendre pour absorber aussi ce dataset et l'indexer par code-barres serait la façon la plus rapide d'ajouter une **vraie 2ᵉ source de scan**, gratuite, offline, sans nouvelle dépendance réseau.
- **Coût** : 0 €.
- **Effort** : moyen (nouveau script d'extraction + filtre par GTIN valide + dédoublonnage avec OFF).
- **Complémentarité avec OFF** : USDA Branded est fort sur le marché américain (pertinent pour l'App Store/Play Store US à venir), OFF reste plus fort en couverture française/européenne (marché principal actuel de Totum) — les deux sources se complètent plus qu'elles ne se recoupent.

### Option C — API tierce commerciale (Nutritionix) en dernier repli, uniquement si les options A/B ne suffisent pas
Nutritionix (utilisé par Cronometer) : ~1,9M aliments, ~600k UPC, ~92% de reconnaissance, palier gratuit 200 appels/jour (utile pour valider l'intérêt réel sans engager de budget), palier payant ~50 $/mois pour ~10k appels/jour puis 500-2000+ $/mois à plus grande échelle.
- **Recommandation : ne pas partir directement sur cette option.** Tant qu'on n'a pas mesuré le vrai taux d'échec de scan des utilisateurs Totum (voir §4), engager un budget mensuel récurrent serait une décision à l'aveugle — exactement le genre de raccourci que la rigueur déjà actée sur ce projet (mesurer avant de construire) déconseille.

### Option D — Remplacer le moteur de capture caméra web (Scandit ou équivalent commercial)
Le vrai écart avec Yuka sur le *scan lui-même* (pas la base) est le moteur de capture web (ZXing‑js, déjà identifié comme le maillon faible documenté dans le code). Scandit (utilisé par Yuka) est un SDK commercial payant, généralement facturé par volume d'utilisateurs actifs scannant — à chiffrer séparément si, après l'option A (bundle local + repli manuel déjà en place), la fiabilité web reste un point de friction remonté par les utilisateurs. **Non prioritaire tant que le futur build natif iOS n'est pas en jeu** : côté natif (Android déjà, iOS demain), c'est déjà ML Kit, pas ZXing — ce problème est spécifiquement limité à la web app.

## 4. Recommandation d'ordre (challenge de la demande initiale)

Alex a demandé d'auditer et viser "le scanner le plus complet qui existe" — au vu de l'audit, **la vraie priorité n'est pas d'ajouter une 3ᵉ ou 4ᵉ base de données tout de suite**, mais dans cet ordre :

1. **Mesurer d'abord** : ajouter un log (Supabase, anonymisé — code-barres + pays si connu) à chaque "produit non trouvé" (`jrnlProductNotFoundTitle`, déjà affiché aujourd'hui) pour connaître le vrai taux d'échec réel des utilisateurs Totum, avant d'investir. Coût quasi nul, données déjà disponibles dans le flux existant.
2. **Option A (bundle OFF local)** : le gain de vitesse/fiabilité le plus large pour le moins d'effort, sur l'intégralité des scans (pas seulement ceux qui échouent aujourd'hui).
3. **Option B (USDA Branded)** : 2ᵉ source gratuite, complémentaire géographiquement, réutilise un pipeline déjà maîtrisé dans ce repo.
4. **Option C (Nutritionix)** seulement si la mesure de l'étape 1, après A+B, montre un taux d'échec encore significatif sur les marchés visés.
5. **Option D (Scandit)** seulement si des retours utilisateurs web confirment que la fiabilité caméra reste un problème après l'option A.

Ce séquencement évite d'engager un budget récurrent (Option C/D) avant d'avoir la preuve, par la mesure, qu'il est nécessaire — cohérent avec l'exigence de rigueur déjà actée sur ce projet pour tout ce qui touche au moteur de calcul.

## 5. Ce qui n'a PAS été touché

Aucun fichier de code n'a été modifié pour cette partie scanner — uniquement ce document d'audit. Le bug favoris signalé dans le même message a été traité séparément (voir le commit correspondant) et n'a aucun lien avec le scanner.

---

### Sources consultées (15/09/2026)
- [Yuka: AI-Powered Data Capture Enables Healthier Living (Scandit)](https://www.scandit.com/resources/case-studies/yuka/)
- [Yuka vs Open Food Facts: Which Is Better for US Shoppers? (Osana)](https://osana.co/blog/yuka-vs-open-food-facts)
- [How MyFitnessPal's Food Database Works](https://blog.myfitnesspal.com/how-food-database-works/)
- [Why Did MyFitnessPal Remove Barcode Scanning? (Nutrola)](https://nutrola.app/en/blog/why-did-myfitnesspal-remove-barcode-scanning)
- [Cronometer — Data Sources (support.cronometer.com)](https://support.cronometer.com/hc/en-us/articles/360018239472-Data-Sources)
- [How Accurate Is Cronometer? (Nutrola)](https://nutrola.app/en/blog/how-accurate-is-cronometer)
- [YAZIO — Google Play listing](https://play.google.com/store/apps/details?id=com.yazio.android&hl=en)
- [USDA FoodData Central — Download Datasets](https://fdc.nal.usda.gov/download-datasets)
- [USDA Global Branded Food Products Database (GBFPD) Documentation](https://fdc.nal.usda.gov/GBFPD_Documentation)
- [Open Food Facts — Data, API and SDKs](https://world.openfoodfacts.org/data)
- [DuckDB & Open Food Facts (Medium, taille/format du dump)](https://medium.com/@jeremyarancio/duckdb-open-food-facts-the-largest-open-food-database-in-the-palm-of-your-hand-0d4ab30d0701)
- [Nutritionix API pricing (calorieapi.com)](https://calorieapi.com/blog/nutritionix-api-pricing)
- [Nutritionix API overview (publicapis.io)](https://publicapis.io/nutritionix-api)
