import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings.dart';

/// Modèle d'un aliment (issu d'une ligne du CSV).
class FoodItem {
  final String id;         // identifiant stable : "ciqual:CODE" pour la base
  final String name;       // libellé d'affichage (nom CIQUAL complet, jamais perdu)
  final int? ciqualCode;   // code CIQUAL officiel (null pour perso/recette/scan)

  // Macros / énergie (pour 100 g)
  final double? kcal100;
  final double? prot100;
  final double? carb100;
  final double? fat100;
  final double? fiber100;

  /// Tous les autres nutriments (pour 100 g), clé = nom de colonne tel que dans le CSV.
  final Map<String, double> micros100;

  // ── Recherche/affichage façon MacroFactor (Priorité 25) ──────────────────
  final String? groupe;         // groupe alimentaire officiel ANSES (ex. "produits laitiers")
  final String? sousGroupe;     // sous-groupe officiel ANSES (ex. "fromages et alternatives végétales")
  final String? pictogramme;    // emoji représentatif
  final String? nomGenerique;   // libellé court dérivé du nom CIQUAL, pour la recherche/l'affichage
  final int? novaScore;         // 1-4 ; estimé pour la base CIQUAL, officiel pour un scan Open Food Facts
  final bool novaEstime;        // true = estimation TOTUM (pas une donnée officielle), false = NOVA officiel (scan OFF)
  final String? imageUrl;       // photo produit (scan Open Food Facts uniquement)

  // ── Base USDA uniquement (Priorité 39) ────────────────────────────────
  final String? nameFr;         // traduction française du nom (aliments USDA), repli sur `name` si absente
  final String? sourceType;     // 'marque' / 'restaurant' pour un aliment de marque USDA, null sinon
  final String? brand;          // nom de marque/enseigne extrait (ex. "MCDONALD'S", "KRAFT")

  // ── Base CIQUAL uniquement (Priorité 48) ──────────────────────────────
  final String? nameEn;         // traduction anglaise du nom (aliments CIQUAL), repli sur `name` si absente

  FoodItem({
    required this.id,
    required this.name,
    this.ciqualCode,
    this.kcal100,
    this.prot100,
    this.carb100,
    this.fat100,
    this.fiber100,
    required this.micros100,
    this.groupe,
    this.sousGroupe,
    this.pictogramme,
    this.nomGenerique,
    this.novaScore,
    this.novaEstime = false,
    this.imageUrl,
    this.nameFr,
    this.sourceType,
    this.brand,
    this.nameEn,
  });

  /// Renvoie les valeurs **pour une quantité (g)**.
  Map<String, double> macrosFor(double grams) {
    double f(double? v) => (v ?? 0) * grams / 100.0;
    return {
      'kcal': f(kcal100),
      'prot': f(prot100),
      'carb': f(carb100),
      'fat' : f(fat100),
      'fiber': f(fiber100),
    };
  }

  Map<String, double> microsFor(double grams) {
    final m = <String, double>{};
    for (final e in micros100.entries) {
      m[e.key] = (e.value) * grams / 100.0;
    }
    return m;
  }
}

/// Nom d'affichage le plus pertinent (Priorité 39, langue Priorité 48) :
/// selon la langue choisie dans Réglages → Langue des aliments, préfère la
/// traduction française (`nameFr`, aliments USDA) ou anglaise (`nameEn`,
/// aliments CIQUAL) quand elle existe, sinon le nom générique CIQUAL déjà en
/// place, sinon le nom brut fourni en repli — jamais de traduction inventée.
/// Un seul point d'entrée partagé (Priorité 63) pour ne pas dupliquer cette
/// logique à chaque écran de recherche/affichage (journal, recettes...).
String displayNameOf(dynamic it, String fallback) {
  if (it is FoodItem) {
    if (AppSettings.language.value == 'en') {
      final en = it.nameEn;
      if (en != null && en.trim().isNotEmpty) return en;
      return fallback;
    }
    final fr = it.nameFr;
    if (fr != null && fr.trim().isNotEmpty) return fr;
    final generic = it.nomGenerique;
    if (generic != null && generic.trim().isNotEmpty) return generic;
  }
  return fallback;
}

/// Portion courante d'un aliment USDA (ex. "1 cup" -> 227.0 g), issue de
/// mesures labo/enquête USDA (jamais estimée) — voir FoodsRepository.portionsFor.
class FoodPortion {
  final String label;
  final double grams;
  const FoodPortion({required this.label, required this.grams});
}

/// Charge et interroge la base CSV.
class FoodsRepository {
  static final FoodsRepository instance = FoodsRepository();

  final List<FoodItem> _items = [];

  // Liste privée des personnalisés
  final List<FoodItem> _customs = [];
  String? lastLoadError;

  // Index id -> FoodItem, construit paresseusement et invalidé à chaque
  // mutation de _items/_customs (Priorité 31, retour d'Alex sur la latence
  // Bilan/Conseils) : findById() était un scan linéaire sur une liste
  // ré-allouée à chaque appel ([..._customs, ..._items]), et ce même motif
  // était recopié dans bilan_screen.dart/conseils_screen.dart, appelé une
  // fois par aliment loggé x jusqu'à 90 jours pour un bilan — coût qui
  // explosait alors que la recherche par id est en réalité un simple lookup.
  Map<String, FoodItem>? _idIndex;

  Map<String, FoodItem> get _index {
    final idx = _idIndex;
    if (idx != null) return idx;
    final built = <String, FoodItem>{};
    for (final it in _items) {
      built[it.id] = it;
    }
    for (final it in _usdaItems) {
      built[it.id] = it;
    }
    for (final it in _brandItems) {
      built[it.id] = it;
    }
    for (final it in _customs) {
      built[it.id] = it; // les personnalisés priment en cas d'id partagé
    }
    _idIndex = built;
    return built;
  }

  // Getter en lecture seule
  List<FoodItem> get customs => List.unmodifiable(_customs);

  // Ajouter un aliment personnalisé
  void addCustomFood(FoodItem it) {
    // si un id identique existe déjà, on remplace le plus ancien
    _customs.removeWhere((e) => e.id == it.id);
    _customs.insert(0, it);
    _idIndex = null;
  }

  /// Trouve un aliment par son id de journal, avec compatibilité ascendante.
  /// Gère : "ciqual:CODE" (nouveau), et l'ancien id = nom normalisé (repli).
  FoodItem? findById(String foodId) {
    // 1. Recherche directe (cas normal : "ciqual:CODE" ou custom/recipe)
    final direct = _index[foodId];
    if (direct != null) return direct;
    // 2. Repli : ancienne entrée stockée par nom normalisé
    final n = _norm(foodId);
    for (final it in _items) {
      if (_norm(it.name) == n) return it;
    }
    return null;
  }

  // Trouver un aliment par nom (insensible aux accents / casse)
  FoodItem? findByName(String name) {
  String norm(String s) => s.toLowerCase();
  final q = norm(name);
  for (final it in [...customs, ..._items]) {
    final nn = norm(it.name);
    if (nn == q) return it;
  }
  return null;
}

    // ────────────────────────── PERSISTENCE CUSTOMS ──────────────────────────
  static const _spKeyCustoms = 'custom_foods_v1';

  Future<void> saveCustomFoods() async {
    final sp = await SharedPreferences.getInstance();
    final list = _customs.map((f) => {
      'id': f.id,
      'name': f.name,
      'kcal100': f.kcal100,
      'prot100': f.prot100,
      'carb100': f.carb100,
      'fat100' : f.fat100,
      'fiber100': f.fiber100,
      'micros100': f.micros100, // map<String,double>
      // Bug trouvé (11/08/2026, retour d'Alex — "la photo a disparu après
      // avoir rouvert l'app") : `_CustomFoodsStore` (journal_screen.dart) ET
      // `FoodsRepository` écrivent sur LA MÊME clé SharedPreferences
      // ('custom_foods_v1') mais avec des sérialisations différentes — cette
      // méthode ignorait imageUrl/novaScore, donc le moindre appel après un
      // scan écrasait silencieusement la photo déjà enregistrée par l'autre
      // store. Les deux sérialisations doivent maintenant rester en phase.
      'imageUrl': f.imageUrl,
      'novaScore': f.novaScore,
      'novaEstime': f.novaEstime,
    }).toList();
    await sp.setString(_spKeyCustoms, jsonEncode(list));
  }

  Future<void> loadCustomFoods() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_spKeyCustoms);
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw);
      if (data is! List) return;

      _customs.clear();
      for (final row in data) {
        if (row is! Map) continue;
        final micros = <String, double>{};
        final m = row['micros100'];
        if (m is Map) {
          for (final e in m.entries) {
            final k = e.key.toString();
            final v = (e.value is num) ? (e.value as num).toDouble() : double.tryParse(e.value.toString());
            if (v != null) micros[k] = v;
          }
        }
        _customs.add(FoodItem(
          id: row['id']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
          kcal100: (row['kcal100'] is num) ? (row['kcal100'] as num).toDouble() : double.tryParse('${row['kcal100']}'),
          prot100: (row['prot100'] is num) ? (row['prot100'] as num).toDouble() : double.tryParse('${row['prot100']}'),
          carb100: (row['carb100'] is num) ? (row['carb100'] as num).toDouble() : double.tryParse('${row['carb100']}'),
          fat100 : (row['fat100']  is num) ? (row['fat100']  as num).toDouble() : double.tryParse('${row['fat100']}'),
          fiber100: (row['fiber100'] is num) ? (row['fiber100'] as num).toDouble() : double.tryParse('${row['fiber100']}'),
          micros100: micros,
          imageUrl: row['imageUrl']?.toString(),
          novaScore: (row['novaScore'] is num) ? (row['novaScore'] as num).toInt() : int.tryParse('${row['novaScore']}'),
          novaEstime: row['novaEstime'] == true,
        ));
      }
    } catch (_) {
      // on ignore une corruption éventuelle
    } finally {
      _idIndex = null;
    }
  }


  /// Normalise (minuscules + sans accents) pour des recherches robustes.
  static String _norm(String s) {
  const repl = {
    'à':'a','â':'a','ä':'a','á':'a','ã':'a','å':'a',
    'ç':'c',
    'é':'e','è':'e','ê':'e','ë':'e',
    'î':'i','ï':'i','ì':'i','í':'i',
    'ô':'o','ö':'o','ò':'o','ó':'o','õ':'o',
    'ù':'u','û':'u','ü':'u','ú':'u',
    'ÿ':'y','ñ':'n',
    'œ':'oe','æ':'ae',
    'À':'a','Â':'a','Ä':'a','Á':'a','Ã':'a','Å':'a',
    'Ç':'c',
    'É':'e','È':'e','Ê':'e','Ë':'e',
    'Î':'i','Ï':'i','Ì':'i','Í':'i',
    'Ô':'o','Ö':'o','Ò':'o','Ó':'o','Õ':'o',
    'Ù':'u','Û':'u','Ü':'u','Ú':'u',
    'Ÿ':'y','Ñ':'n',
    'Œ':'oe','Æ':'ae',
  };
  final buf = StringBuffer();
  for (final ch in s.trim().runes) {
    final c = String.fromCharCode(ch);
    buf.write(repl[c] ?? c);
  }
  return buf.toString().toLowerCase();
}

  /// Tente plusieurs alias pour retrouver une valeur numérique dans une map de colonnes.
  double? _readNum(Map<String, String> row, List<String> aliases) {
    for (final a in aliases) {
      final k = row.keys.firstWhere(
        (c) => c.toLowerCase() == a.toLowerCase(),
        orElse: () => '',
      );
      if (k.isNotEmpty) {
        final raw = row[k]!.replaceAll(',', '.');
        final v = double.tryParse(raw);
        if (v != null) return v;
      }
    }
    return null;
  }

  /// Charge le CSV d’assets (UTF-8, séparateur `,`).
  // Garde-fous contre les chargements concurrents/redondants (plusieurs écrans
  // peuvent appeler loadFromAsset quasi simultanément, ce qui duplique sinon).
  Future<void>? _loadingFuture;
  bool _loadedOnce = false;

  Future<void> loadFromAsset(String assetPath) async {
    if (_loadedOnce && _items.isNotEmpty) {
      // Base CIQUAL déjà prête : on s'assure quand même que la base USDA
      // native l'est aussi (chargement indépendant, voir loadUsdaFromAsset).
      await loadUsdaFromAsset('assets/usda_foods.csv');
      return;
    }
    if (_loadingFuture != null) return _loadingFuture;
    // Les deux bases chargent en parallèle : aucun écran n'a besoin de les
    // distinguer pour être "prêt" — CIQUAL reste la base par défaut de la
    // recherche (Priorité 37), USDA est chargée en renfort dès le départ
    // pour que findById() résolve correctement un aliment déjà loggé/
    // favori venant de l'une ou l'autre, sans dépendance réseau.
    _loadingFuture = Future.wait([
      _doLoadFromAsset(assetPath),
      loadUsdaFromAsset('assets/usda_foods.csv'),
    ]);
    try {
      await _loadingFuture;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _doLoadFromAsset(String assetPath) async {
    try {
      lastLoadError = null;
      _items.clear();

      final raw = await rootBundle.loadString(assetPath);
      final lines = const LineSplitter().convert(raw);

      if (lines.isEmpty) {
        lastLoadError = 'CSV vide';
        return;
      }

      // Parse en CSV naïf (séparateur ,). Si ton fichier contient des valeurs
      // avec virgules protégées par guillemets, on peut basculer sur un vrai parser plus tard.
      final headers = _splitCsvLine(lines.first);
      for (int i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.isEmpty || cols.length != headers.length) continue;

        final row = <String, String>{};
        for (int c = 0; c < headers.length; c++) {
          row[headers[c]] = cols[c];
        }

        // Nom (alias robustes)
        final nameAliases = [
          'nom', 'name', 'libellé', 'libelle', 'désignation', 'designation', 'produit', 'aliment'
        ];
        String? name;
        for (final a in nameAliases) {
          name ??= row.entries.firstWhere(
            (e) => e.key.toLowerCase() == a,
            orElse: () => const MapEntry('', ''),
          ).value;
        }
        name = (name ?? '').trim();
        if (name.isEmpty) continue;

        // Macros (alias fréquents dans ton CSV)
        final kcal = _readNum(row, ['Énergie_kcal_100g','Énergie (kcal/100g)','Calories_kcal_100g','kcal_100g','Energy_kcal_100g']);
        final prot = _readNum(row, ['Protéines_g_100g','Proteines_g_100g','Protéines (g/100g)','Protein_g_100g']);
        final carb = _readNum(row, ['Glucides_g_100g','Glucides (g/100g)','Carbs_g_100g']); // on affichera Glucides_g_100g si dispo
        final fat  = _readNum(row, ['Lipides_g_100g','Lipides (g/100g)','Fat_g_100g']);
        final fib  = _readNum(row, ['Fibres_g_100g','Fibres (g/100g)','Fiber_g_100g']);

        // Micros = toutes les colonnes numériques, hors nom & macros détectées
        final macroKeys = <String>{
          ...nameAliases,
          'ciqual_code',
          'Énergie_kcal_100g','Énergie (kcal/100g)','Calories_kcal_100g','kcal_100g','Energy_kcal_100g',
          'Protéines_g_100g','Proteines_g_100g','Protéines (g/100g)','Protein_g_100g',
          'Glucides_g_100g','Glucides (g/100g)','Carbs_g_100g',
          'Lipides_g_100g','Lipides (g/100g)','Fat_g_100g',
          'Fibres_g_100g','Fibres (g/100g)','Fiber_g_100g',
          // Colonnes de taxonomie/recherche (Priorité 25) : texte, jamais des micronutriments.
          'groupe', 'sous_groupe', 'pictogramme', 'score_nova_estime', 'nom_generique', 'nom_en',
        }.map((e) => e.toLowerCase()).toSet();

        final micros = <String, double>{};
        for (final e in row.entries) {
          final key = e.key.trim();
          if (key.isEmpty) continue;
          if (macroKeys.contains(key.toLowerCase())) continue;

          final rawVal = e.value.replaceAll(',', '.');
          final v = double.tryParse(rawVal);
          if (v != null) micros[key] = v;
        }

        // Code CIQUAL officiel (colonne 'ciqual_code' de la base 2025)
        int? ciqualCode;
        for (final e in row.entries) {
          if (e.key.trim().toLowerCase() == 'ciqual_code') {
            ciqualCode = int.tryParse(e.value.trim());
            break;
          }
        }
        // id stable : "ciqual:CODE" si dispo, sinon repli sur le nom normalisé
        final foodId =
            ciqualCode != null ? 'ciqual:$ciqualCode' : _norm(name);

        String? colStr(String key) {
          final k = row.keys.firstWhere(
            (c) => c.toLowerCase() == key,
            orElse: () => '',
          );
          if (k.isEmpty) return null;
          final v = row[k]!.trim();
          return v.isEmpty ? null : v;
        }

        _items.add(FoodItem(
          id: foodId,
          name: name,
          ciqualCode: ciqualCode,
          kcal100: kcal,
          prot100: prot,
          carb100: carb,
          fat100:  fat,
          fiber100: fib,
          micros100: micros,
          groupe: colStr('groupe'),
          sousGroupe: colStr('sous_groupe'),
          pictogramme: colStr('pictogramme'),
          nomGenerique: colStr('nom_generique'),
          novaScore: int.tryParse(colStr('score_nova_estime') ?? ''),
          novaEstime: true,
          nameEn: colStr('nom_en'),
        ));
      }
      _loadedOnce = _items.isNotEmpty;
    } catch (e) {
      lastLoadError = 'Erreur de chargement CSV: $e';
    } finally {
      _idIndex = null;
    }
  }

  List<FoodItem> get items => List.unmodifiable(_items);

  // ────────────────────────── BASE USDA NATIVE (Priorité 37) ──────────────────────────
  // Extraction Foundation Foods + SR Legacy (scripts/build_usda_foods.py +
  // build_usda_taxonomy.py) — mêmes colonnes que la base CIQUAL, id
  // "usda:<fdc_id>" (même format que l'ancien flux réseau UsdaService, donc
  // aucun code de badge/favori/journal à changer : un aliment déjà loggé
  // depuis l'ancien flux réseau reste résolu à l'identique). Chargée en
  // renfort de CIQUAL, jamais à sa place par défaut.
  final List<FoodItem> _usdaItems = [];
  List<FoodItem> get usdaItems => List.unmodifiable(_usdaItems);
  Future<void>? _usdaLoadingFuture;
  bool _usdaLoadedOnce = false;

  // Marque/restaurant (Priorité 39) : aliments de marque USDA (chaînes de
  // fast-food/restauration comme épicerie de marque), TOUJOURS validés en
  // laboratoire (Foundation Foods/SR Legacy, jamais la base "Branded Foods"
  // séparée, auto-déclarée par les fabricants) — dissociés de la recherche
  // USDA générale par défaut, accessibles via leur propre écran filtrable
  // par enseigne (voir brandNames/restaurantNames/foodsForBrand).
  final List<FoodItem> _brandItems = [];
  List<FoodItem> get brandItems => List.unmodifiable(_brandItems);

  /// Noms de marques (épicerie) distincts, triés — pour peupler le
  /// sélecteur de l'écran "Marques".
  List<String> get brandNames => _brandItems
      .where((it) => it.sourceType == 'marque')
      .map((it) => it.brand ?? '')
      .where((b) => b.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  /// Noms d'enseignes de restauration distincts, triés — pour peupler le
  /// sélecteur de l'écran "Restaurants".
  List<String> get restaurantNames => _brandItems
      .where((it) => it.sourceType == 'restaurant')
      .map((it) => it.brand ?? '')
      .where((b) => b.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  /// Aliments d'une marque/enseigne précise (correspondance exacte sur
  /// [FoodItem.brand]), optionnellement filtrés par un texte de recherche.
  List<FoodItem> foodsForBrand(String brand, {String query = ''}) {
    final q = _norm(query);
    return _brandItems.where((it) {
      if (it.brand != brand) return false;
      if (q.isEmpty) return true;
      // Recherche sur le nom anglais ET la traduction française (Priorité
      // 39) : une fois affiché en français, chercher doit marcher en
      // français aussi, pas seulement sur le texte anglais sous-jacent.
      if (_norm(it.name).contains(q)) return true;
      final fr = it.nameFr;
      return fr != null && _norm(fr).contains(q);
    }).toList();
  }

  Future<void> loadUsdaFromAsset(String assetPath) async {
    if (_usdaLoadedOnce && _usdaItems.isNotEmpty) return;
    if (_usdaLoadingFuture != null) return _usdaLoadingFuture;
    _usdaLoadingFuture = _doLoadUsdaFromAsset(assetPath);
    try {
      await _usdaLoadingFuture;
    } finally {
      _usdaLoadingFuture = null;
    }
  }

  Future<void> _doLoadUsdaFromAsset(String assetPath) async {
    try {
      _usdaItems.clear();
      _brandItems.clear();
      final raw = await rootBundle.loadString(assetPath);
      final lines = const LineSplitter().convert(raw);
      if (lines.isEmpty) return;

      final headers = _splitCsvLine(lines.first);
      for (int i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.isEmpty || cols.length != headers.length) continue;
        final row = <String, String>{};
        for (int c = 0; c < headers.length; c++) {
          row[headers[c]] = cols[c];
        }

        final name = (row['nom'] ?? '').trim();
        if (name.isEmpty) continue;
        final fdcId = (row['fdc_id'] ?? '').trim();
        if (fdcId.isEmpty) continue;

        final kcal = double.tryParse((row['Énergie_kcal_100g'] ?? '').replaceAll(',', '.'));
        final prot = double.tryParse((row['Protéines_g_100g'] ?? '').replaceAll(',', '.'));
        final carb = double.tryParse((row['Glucides_g_100g'] ?? '').replaceAll(',', '.'));
        final fat  = double.tryParse((row['Lipides_g_100g'] ?? '').replaceAll(',', '.'));
        final fib  = double.tryParse((row['Fibres_g_100g'] ?? '').replaceAll(',', '.'));

        final macroKeys = <String>{
          'fdc_id', 'nom', 'nom_fr', 'énergie_kcal_100g', 'protéines_g_100g', 'glucides_g_100g',
          'lipides_g_100g', 'fibres_g_100g',
          'groupe', 'sous_groupe', 'pictogramme', 'score_nova_estime', 'nom_generique',
          'source', 'source_type', 'brand',
        };
        final micros = <String, double>{};
        for (final e in row.entries) {
          final key = e.key.trim();
          if (key.isEmpty || macroKeys.contains(key.toLowerCase())) continue;
          final v = double.tryParse(e.value.replaceAll(',', '.'));
          if (v != null) micros[key] = v;
        }

        String? colStr(String key) {
          final v = row[key]?.trim();
          return (v == null || v.isEmpty) ? null : v;
        }

        final item = FoodItem(
          id: 'usda:$fdcId',
          name: name,
          kcal100: kcal,
          prot100: prot,
          carb100: carb,
          fat100: fat,
          fiber100: fib,
          micros100: micros,
          groupe: colStr('groupe'),
          sousGroupe: colStr('sous_groupe'),
          pictogramme: colStr('pictogramme'),
          nomGenerique: colStr('nom_generique'),
          novaScore: int.tryParse(colStr('score_nova_estime') ?? ''),
          novaEstime: true,
          nameFr: colStr('nom_fr'),
          sourceType: colStr('source_type'),
          brand: colStr('brand'),
        );
        // Marque/restaurant (Priorité 39) : dissocié de la recherche USDA
        // générale par défaut (on ne veut pas qu'un Big Mac remonte pour
        // "poulet") mais accessible via son propre point d'entrée filtrable
        // par enseigne — plus de notion "cheat meal"/avertissement, juste
        // une classification honnête (voir _brandItems / brandNames /
        // restaurantNames / foodsForBrand ci-dessous).
        if (item.sourceType == 'marque' || item.sourceType == 'restaurant') {
          _brandItems.add(item);
        } else {
          _usdaItems.add(item);
        }
      }
      _usdaLoadedOnce = _usdaItems.isNotEmpty;
      await _loadPortions();
    } catch (_) {
      // Repli silencieux : la base CIQUAL reste pleinement fonctionnelle
      // même si l'asset USDA est absent/corrompu.
    } finally {
      _idIndex = null;
    }
  }

  // ─────────────────────── Portions courantes (Priorité 40) ───────────────────────
  // Réponse au constat d'Alex (11/08/2026, 3e passe) : quelqu'un qui logue
  // "100 g" par défaut pour un burger sous-estime largement son apport
  // réel — poids de portions courantes ("1 serving", "item 4 oz"...) issus
  // de food_portion.csv (mesures labo/enquête USDA, jamais estimées), même
  // principe que Cronometer/MyFitnessPal. Réservé aux aliments USDA : aucune
  // donnée équivalente fiable côté CIQUAL, donc rien n'est inventé pour
  // cette base (voir scripts/build_usda_portions.py).
  final Map<String, List<FoodPortion>> _portions = {};
  bool _portionsLoadedOnce = false;

  /// Portions courantes connues pour un aliment (liste vide si aucune —
  /// ~96% des aliments USDA en ont au moins une, mais jamais pour CIQUAL).
  List<FoodPortion> portionsFor(String foodId) => _portions[foodId] ?? const [];

  Future<void> _loadPortions() async {
    if (_portionsLoadedOnce) return;
    try {
      final raw = await rootBundle.loadString('assets/usda_portions.csv');
      final lines = const LineSplitter().convert(raw);
      for (int i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.length != 3) continue;
        final fdcId = cols[0].trim();
        final label = cols[1].trim();
        final grams = double.tryParse(cols[2].trim());
        if (fdcId.isEmpty || label.isEmpty || grams == null || grams <= 0) continue;
        final foodId = 'usda:$fdcId';
        (_portions[foodId] ??= []).add(FoodPortion(label: label, grams: grams));
      }
      _portionsLoadedOnce = _portions.isNotEmpty;
    } catch (_) {
      // Repli silencieux : le champ grammes manuel reste toujours disponible.
    }
  }

  /// "Commence par"/"contient" sur le nom anglais OU la traduction
  /// française (Priorité 39) — une fois l'aliment affiché en français, la
  /// recherche doit fonctionner en français aussi, pas seulement sur le
  /// texte anglais sous-jacent (encore vide tant que nameFr n'est pas
  /// renseigné, le repli sur `name` seul reste alors transparent).
  List<FoodItem> _searchBilingual(List<FoodItem> items, String query, int limit) {
    final q = _norm(query);
    if (q.isEmpty) return items.take(limit).toList();
    final starts = <FoodItem>[];
    final contains = <FoodItem>[];
    for (final it in items) {
      final nn = _norm(it.name);
      final frn = it.nameFr != null ? _norm(it.nameFr!) : null;
      if (nn.startsWith(q) || (frn != null && frn.startsWith(q))) {
        starts.add(it);
      } else if (nn.contains(q) || (frn != null && frn.contains(q))) {
        contains.add(it);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  /// Recherche dans la base USDA native uniquement — utilisée par l'écran de
  /// recherche USDA, en remplacement de l'ancien appel réseau.
  List<FoodItem> searchUsda(String query, {int limit = 50}) =>
      _searchBilingual(_usdaItems, query, limit);

  /// Recherche libre dans TOUS les aliments de marque/restaurant (toutes
  /// enseignes confondues) — utilisée pour une recherche par mot plutôt que
  /// par sélection d'enseigne (voir aussi [foodsForBrand]).
  List<FoodItem> searchBrandItems(String query, {int limit = 50}) =>
      _searchBilingual(_brandItems, query, limit);

  /// Recherche **robuste** (sans accents, insensible à la casse),
  /// et **inclut** les personnalisés + la base.
  List<FoodItem> search(String query, {int limit = 50}) {
    final q = _norm(query);

    // source = personnalisés + base
    final source = [..._customs, ..._items];

    if (q.isEmpty) {
      return source.take(limit).toList();
    }

    // Priorité 1 : commence par q, 2 : contient q
    final starts = <FoodItem>[];
    final contains = <FoodItem>[];
    for (final it in source) {
      // Le nom générique (ex. "Faux-filet de boeuf") est recherché en plus du
      // nom CIQUAL complet (ex. "Boeuf, faux-filet cru") : sans ça, une
      // recherche "faux-filet" ne remontait qu'en "contient" (priorité basse)
      // au lieu de "commence par" — but manqué de la refonte recherche rapide.
      final nn = _norm(it.name);
      final ng = it.nomGenerique != null ? _norm(it.nomGenerique!) : null;
      if (nn.startsWith(q) || (ng != null && ng.startsWith(q))) {
        starts.add(it);
      } else if (nn.contains(q) || (ng != null && ng.contains(q))) {
        contains.add(it);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  // --- utilitaire CSV très simple (gère "val,eur" basique) ---
  List<String> _splitCsvLine(String line) {
    final res = <String>[];
    final buf = StringBuffer();
    bool inQ = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQ = !inQ;
      } else if (ch == ',' && !inQ) {
        res.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    res.add(buf.toString());
    return res.map((s) => s.trim()).toList();
  }
}
