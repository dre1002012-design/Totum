// lib/services/usda_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/foods_loader.dart' as foods_loader;
import '../secrets/usda_keys.dart';

/// Résultat simplifié pour la liste de recherche USDA
class UsdaFoodResult {
  final int fdcId;
  final String description;
  // Foundation / SR Legacy / Survey (FNDDS) / Branded — pilote uniquement le
  // tri de fiabilité (voir _tierForDataType), jamais affiché tel quel à
  // l'utilisateur (même principe d'affichage que la base CIQUAL : kcal/100g).
  final String dataType;
  // Calories/100g extraites directement de la réponse de recherche (déjà
  // présentes dans `foodNutrients` sur ce endpoint) — évite un appel réseau
  // par résultat juste pour afficher un aperçu.
  final double? kcal100;

  UsdaFoodResult({
    required this.fdcId,
    required this.description,
    required this.dataType,
    this.kcal100,
  });
}

/// Normalisation légère (descriptions USDA en anglais, pas d'accents à
/// gérer comme pour CIQUAL) — juste casse/espaces.
String _normUsda(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

/// Pertinence texte — même principe que `_scoreForQuery` déjà utilisé côté
/// recherche CIQUAL (`journal_screen.dart`) : plus négatif = meilleur match,
/// pour homogénéiser le comportement de recherche dans toute l'app.
int _scoreForQueryUsda(String name, String q) {
  final n = _normUsda(name), query = _normUsda(q);
  if (query.isEmpty) return 0;
  if (n.startsWith(query)) return -100;
  if (n.contains(', $query') || n.contains(' $query')) return -60;
  if (n.contains(query)) return -30;
  return n.length;
}

/// Clé de dédoublonnage : libellé normalisé, ponctuation retirée — l'API
/// USDA renvoie régulièrement le même aliment sous des libellés quasi
/// identiques (casse différente, virgule en plus...), d'où les "dix fois
/// beef" constatés par Alex.
String _dedupKeyUsda(String description) {
  var s = _normUsda(description);
  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}

/// Fiabilité/pertinence nutritionnelle de la source — Foundation et SR
/// Legacy sont des aliments génériques analysés en laboratoire (même
/// niveau de rigueur que CIQUAL), Survey (FNDDS) des aliments composites
/// représentatifs, Branded des produits de marque spécifiques (souvent
/// des dizaines de quasi-doublons par marque/formats, moins homogènes) —
/// classés en dernier plutôt qu'exclus (utiles pour un supplément/produit
/// précis absent de CIQUAL, mais pas prioritaires sur une recherche générique).
int _tierForDataType(String dataType) {
  switch (dataType) {
    case 'Foundation':
      return 0;
    case 'SR Legacy':
      return 1;
    case 'Survey (FNDDS)':
      return 2;
    case 'Branded':
      return 3;
    default:
      return 4;
  }
}

/// Extrait les kcal/100g depuis les nutriments abrégés déjà présents dans
/// une réponse de RECHERCHE (`foods/search`) — forme légèrement différente
/// de l'endpoint détail (`food/{fdcId}`, voir `getFoodItem`) : pas de champ
/// `nutrient` imbriqué, juste `nutrientName`/`nutrientNumber`/`value` à plat.
/// Permet d'afficher un aperçu "kcal/100g" dans la liste, comme pour CIQUAL,
/// sans appel réseau supplémentaire par résultat.
double? _extractKcal100FromSearchHit(Map<String, dynamic> foodMap) {
  final List nutrients = foodMap['foodNutrients'] as List? ?? const [];
  for (final n in nutrients) {
    final m = n as Map<String, dynamic>;
    final nutrient = m['nutrient'] as Map<String, dynamic>?;
    final String nName = (nutrient?['name'] ?? m['nutrientName'] ?? '') as String;
    final String nNumber = (nutrient?['number'] ?? m['nutrientNumber'] ?? '') as String;
    final lowerName = nName.toLowerCase();
    final isEnergy = nNumber == '1008' ||
        nNumber == '208' ||
        lowerName.contains('energy') ||
        lowerName.contains('kcal') ||
        lowerName.contains('calories');
    if (!isEnergy) continue;
    final amount = ((m['amount'] ?? m['value']) as num?)?.toDouble();
    if (amount == null) continue;
    final unit = ((nutrient?['unitName'] ?? m['unitName']) ?? '').toString().toLowerCase().trim();
    return (unit == 'kj' || unit == 'kilojoules') ? amount / 4.184 : amount;
  }
  return null;
}

class UsdaService {
  static const _host = 'api.nal.usda.gov';

  /// Cache mémoire (durée de vie de l'app) — une même recherche tapée deux
  /// fois (correction de frappe, retour en arrière) ne retape pas le réseau.
  /// Volontairement non persisté : les données USDA peuvent évoluer, et le
  /// volume de requêtes par session reste faible.
  static final Map<String, List<UsdaFoodResult>> _cache = {};

  /// Recherche d'aliments USDA par texte — dédoublonnée et triée par
  /// pertinence texte puis fiabilité de la source (voir _scoreForQueryUsda/
  /// _tierForDataType), pas l'ordre brut renvoyé par l'API USDA.
  static Future<List<UsdaFoodResult>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final cacheKey = q.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.https(_host, '/fdc/v1/foods/search', {
      'api_key': usdaApiKey,
      'query': q,
      // 50 candidats bruts avant filtrage/tri côté client — sur une requête
      // générique, l'API renvoie souvent une majorité de Branded quasi
      // identiques ; il faut regarder plus large pour ne pas manquer les
      // quelques entrées génériques (Foundation/SR Legacy) pertinentes.
      'pageSize': '50',
      // Foundation ajouté (absent avant) : dataset USDA le plus rigoureux,
      // même niveau d'exigence que les entrées CIQUAL "brutes".
      'dataType': 'Foundation,SR Legacy,Survey (FNDDS),Branded',
    });

    // Bug trouvé (11/08/2026, retour d'Alex — "un coup sur deux rien
    // n'apparaît, je reviens dessus, ça marche") : un hoquet réseau/API
    // transitoire (statut non-200) renvoyait silencieusement une liste
    // vide, indiscernable d'un "aucun résultat" légitime — l'utilisateur
    // devait retaper pour retenter sans le savoir. 2 tentatives avant
    // d'abandonner, comme déjà fait ailleurs dans l'app pour Open Food Facts.
    final List<UsdaFoodResult> raw;
    Object? lastError;
    List<UsdaFoodResult>? parsed;
    for (var attempt = 0; attempt < 2 && parsed == null; attempt++) {
      try {
        final resp = await http.get(uri).timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) {
          lastError = Exception('USDA HTTP ${resp.statusCode}');
          if (attempt == 0) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          continue;
        }
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final List foods = data['foods'] as List? ?? const [];
        parsed = foods.map((f) {
          final m = f as Map<String, dynamic>;
          return UsdaFoodResult(
            fdcId: (m['fdcId'] as num).toInt(),
            description: (m['description'] ?? 'Aliment USDA') as String,
            dataType: (m['dataType'] ?? '') as String,
            kcal100: _extractKcal100FromSearchHit(m),
          );
        }).toList();
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt == 0) await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (parsed == null) {
      // Distingué d'un "aucun résultat" côté écran de recherche (message +
      // bouton "réessayer" plutôt qu'un silence trompeur).
      throw lastError ?? Exception('USDA search failed');
    }
    raw = parsed;

    // Dédoublonnage (garde la 1ère occurrence par libellé normalisé — l'ordre
    // d'arrivée de l'API n'a pas d'importance, le tri ci-dessous refait tout).
    final seen = <String>{};
    final deduped = <UsdaFoodResult>[
      for (final r in raw)
        if (seen.add(_dedupKeyUsda(r.description))) r,
    ];

    deduped.sort((a, b) {
      final sa = _scoreForQueryUsda(a.description, q);
      final sb = _scoreForQueryUsda(b.description, q);
      if (sa != sb) return sa.compareTo(sb);
      final ta = _tierForDataType(a.dataType);
      final tb = _tierForDataType(b.dataType);
      if (ta != tb) return ta.compareTo(tb);
      return a.description.length.compareTo(b.description.length);
    });

    final result = deduped.take(30).toList();
    _cache[cacheKey] = result;
    return result;
  }

  /// Détail d'un aliment USDA -> conversion dans ton FoodItem
  static Future<foods_loader.FoodItem?> getFoodItem(int fdcId) async {
    final uri = Uri.https(_host, '/fdc/v1/food/$fdcId', {
      'api_key': usdaApiKey,
    });

    // Même résilience que searchFoods : un hoquet réseau ne doit pas se
    // traduire par un tap sans effet ("je sélectionne un résultat, rien ne
    // se passe") — 2 tentatives avant d'abandonner.
    http.Response? resp;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        resp = await http.get(uri).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) break;
      } catch (_) {
        // on retente une fois, sinon on abandonne silencieusement plus bas
      }
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 500));
    }
    if (resp == null || resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final String name = (data['description'] ?? 'Aliment USDA') as String;
    final List nutrients = data['foodNutrients'] as List? ?? const [];

    double? kcal;
    double? prot;
    double? carb;
    double? fat;
    double? fiber;

    final Map<String, double> micros = {
      'AG_saturés_g_100g': 0,
      'Acide_oléique_W9_g_100g': 0,
      'Acide_linoléique_W6_LA_g_100g': 0,
      'Acide_alpha-linolénique_W3_ALA_g_100g': 0,
      'EPA_g_100g': 0,
      'DHA_g_100g': 0,
      'Sucres_g_100g': 0,
      'Sel_g_100g': 0,
      'Calcium_mg_100g': 0,
      'Cuivre_mg_100g': 0,
      'Fer_mg_100g': 0,
      'Iode_µg_100g': 0,
      'Magnésium_mg_100g': 0,
      'Manganèse_mg_100g': 0,
      'Phosphore_mg_100g': 0,
      'Potassium_mg_100g': 0,
      'Sélénium_µg_100g': 0,
      'Sodium_mg_100g': 0,
      'Zinc_mg_100g': 0,
      'Rétinol_µg_100g': 0,
      'Vitamine_D_µg_100g': 0,
      'Vitamine_E_mg_100g': 0,
      'Vitamine_K1_µg_100g': 0,
      'Vitamine_K2_µg_100g': 0,
      'Vitamine_C_mg_100g': 0,
      'Vitamine_B1_mg_100g': 0,
      'Vitamine_B2_mg_100g': 0,
      'Vitamine_B3_mg_100g': 0,
      'Vitamine_B5_mg_100g': 0,
      'Vitamine_B6_mg_100g': 0,
      'Vitamine_B9_µg_100g': 0,
      'Vitamine_B12_µg_100g': 0,
    };

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    bool isZero(String key) => (micros[key] ?? 0) == 0;

    for (final n in nutrients) {
      final m = n as Map<String, dynamic>;
      final nutrient = m['nutrient'] as Map<String, dynamic>?;
      final String nName =
          (nutrient?['name'] ?? m['nutrientName'] ?? '') as String;
      final String nNumber =
          (nutrient?['number'] ?? m['nutrientNumber'] ?? '') as String;
      final String lowerName = nName.toLowerCase();
      final double amount = toDouble(m['amount'] ?? m['value']);

      // ÉNERGIE
      if (kcal == null &&
          (nNumber == '1008' || nNumber == '208' ||
              lowerName.contains('energy') ||
              lowerName.contains('kcal') ||
              lowerName.contains('calories'))) {
        final unit =
            (nutrient?['unitName'] ?? '').toString().toLowerCase().trim();
        if (unit == 'kj' || unit == 'kilojoules') {
          kcal = amount / 4.184;
        } else {
          kcal = amount;
        }
        kcal = double.parse(kcal.toStringAsFixed(1));
      }
      // PROTÉINES
      else if ((nNumber == '1003' || nNumber == '203' ||
              nName.contains('Protein')) &&
          prot == null) {
        prot = amount;
      }
      // GLUCIDES
      else if ((nNumber == '1005' || nNumber == '205' ||
              nName.contains('Carbohydrate')) &&
          carb == null) {
        carb = amount;
      }
      // LIPIDES
      else if ((nNumber == '1004' || nNumber == '204' ||
              nName.contains('Total lipid')) &&
          fat == null) {
        fat = amount;
      }
      // FIBRES
      else if ((nNumber == '1079' || nNumber == '291' ||
              nName.contains('Fiber')) &&
          fiber == null) {
        fiber = amount;
      }

      // SUCRES
      if (lowerName.contains('sugars, total') ||
          lowerName.contains('sugars, total including nlea') ||
          lowerName == 'sugars') {
        micros['Sucres_g_100g'] = amount;
      }

      // ACIDES GRAS SATURÉS
      if (nNumber == '1258' ||
          lowerName.contains('fatty acids, total saturated')) {
        micros['AG_saturés_g_100g'] = amount;
      }

      // OMÉGA 9
      if (lowerName.contains('18:1') &&
          (lowerName.contains('oleic') || lowerName.contains('n-9'))) {
        micros['Acide_oléique_W9_g_100g'] = amount;
      } else if ((lowerName.contains('fatty acids, total monounsaturated') ||
              lowerName.contains('fatty acids, total monoenoic')) &&
          isZero('Acide_oléique_W9_g_100g')) {
        micros['Acide_oléique_W9_g_100g'] = amount;
      }

      // OMÉGA 6
      if (lowerName.contains('18:2') &&
          (lowerName.contains('linoleic') || lowerName.contains('n-6'))) {
        micros['Acide_linoléique_W6_LA_g_100g'] = amount;
      } else if ((lowerName.contains('fatty acids, total n-6') ||
              lowerName.contains('omega-6')) &&
          isZero('Acide_linoléique_W6_LA_g_100g')) {
        micros['Acide_linoléique_W6_LA_g_100g'] = amount;
      }

      // OMÉGA 3
      if (lowerName.contains('18:3') &&
          (lowerName.contains('linolenic') || lowerName.contains('n-3'))) {
        micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = amount;
      }
      if (lowerName.contains('20:5') ||
          lowerName.contains('eicosapentaenoic') ||
          lowerName.contains('epa')) {
        micros['EPA_g_100g'] = amount;
      }
      if (lowerName.contains('22:6') ||
          lowerName.contains('docosahexaenoic') ||
          lowerName.contains('dha')) {
        micros['DHA_g_100g'] = amount;
      }
      if ((lowerName.contains('fatty acids, total n-3') ||
              lowerName.contains('omega-3')) &&
          isZero('Acide_alpha-linolénique_W3_ALA_g_100g') &&
          isZero('EPA_g_100g') &&
          isZero('DHA_g_100g')) {
        micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = amount;
      }

      // MINÉRAUX
      if (nNumber == '1087' || nNumber == '301' || nName.contains('Calcium')) {
        micros['Calcium_mg_100g'] = amount;
      }
      if (nNumber == '1089' || nNumber == '303' || nName.contains('Iron')) {
        micros['Fer_mg_100g'] = amount;
      }
      if (nNumber == '1090' || nNumber == '304' || nName.contains('Magnesium')) {
        micros['Magnésium_mg_100g'] = amount;
      }
      if (nNumber == '1091' || nNumber == '305' || nName.contains('Phosphorus')) {
        micros['Phosphore_mg_100g'] = amount;
      }
      if (nNumber == '1092' || nNumber == '306' || nName.contains('Potassium')) {
        micros['Potassium_mg_100g'] = amount;
      }
      if (nNumber == '1093' || nNumber == '307' || nName.contains('Sodium')) {
        micros['Sodium_mg_100g'] = amount;
        micros['Sel_g_100g'] = (amount * 2.5) / 1000.0;
      }
      if (nNumber == '1095' || nNumber == '309' || nName.contains('Zinc')) {
        micros['Zinc_mg_100g'] = amount;
      }
      if (nNumber == '1102' || nNumber == '312' || nName.contains('Copper')) {
        micros['Cuivre_mg_100g'] = amount;
      }
      if (nNumber == '1103' || nNumber == '315' || nName.contains('Manganese')) {
        micros['Manganèse_mg_100g'] = amount;
      }
      if (nNumber == '1180' || nNumber == '317' || nName.contains('Selenium')) {
        micros['Sélénium_µg_100g'] = amount;
      }
      if (lowerName.contains('iodine') ||
          lowerName.contains('iodide') ||
          lowerName.endsWith(' iodine') ||
          lowerName == 'i') {
        micros['Iode_µg_100g'] = amount;
      }

      // VITAMINES
      if (nNumber == '1104' || nNumber == '318' || nName.contains('Retinol')) {
        micros['Rétinol_µg_100g'] = amount;
      }
      if (nNumber == '1114' || nNumber == '324' || nName.contains('Vitamin D')) {
        micros['Vitamine_D_µg_100g'] = amount;
      }
      if (nNumber == '1109' || nNumber == '323' || nName.contains('Vitamin E')) {
        micros['Vitamine_E_mg_100g'] = amount;
      }
      if (nNumber == '1185' ||
          nNumber == '430' ||
          lowerName.contains('phylloquinone')) {
        micros['Vitamine_K1_µg_100g'] = amount;
      }
      if (lowerName.contains('menaquinone') ||
          lowerName.contains('vitamin k-2')) {
        micros['Vitamine_K2_µg_100g'] = amount;
      }
      if (nNumber == '1162' || nNumber == '401' || nName.contains('Vitamin C')) {
        micros['Vitamine_C_mg_100g'] = amount;
      }
      if (nNumber == '1165' || nNumber == '404' || nName.contains('Thiamin')) {
        micros['Vitamine_B1_mg_100g'] = amount;
      }
      if (nNumber == '1166' || nNumber == '405' || nName.contains('Riboflavin')) {
        micros['Vitamine_B2_mg_100g'] = amount;
      }
      if (nNumber == '1167' || nNumber == '406' || nName.contains('Niacin')) {
        micros['Vitamine_B3_mg_100g'] = amount;
      }
      if (nNumber == '1170' ||
          nNumber == '410' ||
          lowerName.contains('pantothenic')) {
        micros['Vitamine_B5_mg_100g'] = amount;
      }
      if (nNumber == '1175' ||
          nNumber == '415' ||
          nName.contains('Vitamin B-6') ||
          nName.contains('Vitamin B6')) {
        micros['Vitamine_B6_mg_100g'] = amount;
      }
      if (nNumber == '1190' || nNumber == '417' || nName.contains('Folate')) {
        micros['Vitamine_B9_µg_100g'] = amount;
      }
      if (nNumber == '1178' ||
          nNumber == '418' ||
          lowerName.contains('vitamin b-12') ||
          lowerName.contains('vitamin b12') ||
          lowerName.contains('cobalamin') ||
          lowerName.contains('cobalamine')) {
        micros['Vitamine_B12_µg_100g'] = amount;
      }
    }

    return foods_loader.FoodItem(
      id: 'usda:$fdcId',
      name: name,
      kcal100: kcal,
      prot100: prot,
      carb100: carb,
      fat100: fat,
      fiber100: fiber,
      micros100: micros,
    );
  }
}