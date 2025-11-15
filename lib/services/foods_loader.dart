import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modèle d’un aliment (issu d’une ligne du CSV).
class FoodItem {
  final String id;   // identifiant stable (nom normalisé)
  final String name; // libellé d’affichage

  // Macros / énergie (pour 100 g)
  final double? kcal100;
  final double? prot100;
  final double? carb100;
  final double? fat100;
  final double? fiber100;

  /// Tous les autres nutriments (pour 100 g), clé = nom de colonne tel que dans le CSV.
  final Map<String, double> micros100;

  FoodItem({
    required this.id,
    required this.name,
    this.kcal100,
    this.prot100,
    this.carb100,
    this.fat100,
    this.fiber100,
    required this.micros100,
  });

  /// Renvoie les valeurs **pour une quantité (g)**.
  Map<String, double> macrosFor(double grams) {
    final f = (double? v) => (v ?? 0) * grams / 100.0;
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

/// Charge et interroge la base CSV.
class FoodsRepository {
  static final FoodsRepository instance = FoodsRepository();

  final List<FoodItem> _items = [];

  // Liste privée des personnalisés
  final List<FoodItem> _customs = [];
  String? lastLoadError;

  // Getter en lecture seule
  List<FoodItem> get customs => List.unmodifiable(_customs);

  // Ajouter un aliment personnalisé
  void addCustomFood(FoodItem it) {
    // si un id identique existe déjà, on remplace le plus ancien
    _customs.removeWhere((e) => e.id == it.id);
    _customs.insert(0, it);
  }  
  
  // Trouver un aliment par nom (insensible aux accents / casse)
  FoodItem? findByName(String name) {
  String _norm(String s) => s.toLowerCase();
  final q = _norm(name);
  for (final it in [...customs, ..._items]) {
    final nn = _norm(it.name);
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
        ));
      }
    } catch (_) {
      // on ignore une corruption éventuelle
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
  Future<void> loadFromAsset(String assetPath) async {
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
        final carb = _readNum(row, ['Glucides_g_100g','Glucides (g/100g)','Carbs_g_100g','Sucres_g_100g']); // on affichera Glucides_g_100g si dispo
        final fat  = _readNum(row, ['Lipides_g_100g','Lipides (g/100g)','Fat_g_100g']);
        final fib  = _readNum(row, ['Fibres_g_100g','Fibres (g/100g)','Fiber_g_100g']);

        // Micros = toutes les colonnes numériques, hors nom & macros détectées
        final macroKeys = <String>{
          ...nameAliases,
          'Énergie_kcal_100g','Énergie (kcal/100g)','Calories_kcal_100g','kcal_100g','Energy_kcal_100g',
          'Protéines_g_100g','Proteines_g_100g','Protéines (g/100g)','Protein_g_100g',
          'Glucides_g_100g','Glucides (g/100g)','Carbs_g_100g','Sucres_g_100g',
          'Lipides_g_100g','Lipides (g/100g)','Fat_g_100g',
          'Fibres_g_100g','Fibres (g/100g)','Fiber_g_100g'
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

        _items.add(FoodItem(
          id: _norm(name),
          name: name,
          kcal100: kcal,
          prot100: prot,
          carb100: carb,
          fat100:  fat,
          fiber100: fib,
          micros100: micros,
        ));
      }
    } catch (e) {
      lastLoadError = 'Erreur de chargement CSV: $e';
    }
  }

  List<FoodItem> get items => List.unmodifiable(_items);

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
      final nn = _norm(it.name);
      if (nn.startsWith(q)) {
        starts.add(it);
      } else if (nn.contains(q)) {
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
