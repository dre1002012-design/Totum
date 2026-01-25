// lib/services/usda_service.dart
//
// Service pour interroger USDA FoodData Central et convertir
// les aliments dans le format FoodItem de ton application,
// avec un mapping le plus complet possible de macro + micro nutriments.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/foods_loader.dart' as foods_loader;
import '../secrets/usda_keys.dart';

/// Résultat simplifié pour la liste de recherche USDA
class UsdaFoodResult {
  final int fdcId;
  final String description;

  UsdaFoodResult({
    required this.fdcId,
    required this.description,
  });
}

class UsdaService {
  static const _host = 'api.nal.usda.gov';

  /// Recherche d’aliments USDA par texte
  static Future<List<UsdaFoodResult>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(_host, '/fdc/v1/foods/search', {
      'api_key': usdaApiKey,
      'query': query,
      'pageSize': '25',
      // Survey + SR Legacy + Branded donne une bonne couverture
      'dataType': 'Survey (FNDDS),SR Legacy,Branded',
    });

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List foods = data['foods'] as List? ?? const [];

    return foods.map((f) {
      final m = f as Map<String, dynamic>;
      return UsdaFoodResult(
        fdcId: (m['fdcId'] as num).toInt(),
        description: (m['description'] ?? 'Aliment USDA') as String,
      );
    }).toList();
  }

  /// Détail d’un aliment USDA -> conversion dans ton FoodItem
  static Future<foods_loader.FoodItem?> getFoodItem(int fdcId) async {
    final uri = Uri.https(_host, '/fdc/v1/food/$fdcId', {
      'api_key': usdaApiKey,
    });

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final String name = (data['description'] ?? 'Aliment USDA') as String;
    final List nutrients = data['foodNutrients'] as List? ?? const [];

    // ───── MACROS ─────
    double? kcal;
    double? prot;
    double? carb;
    double? fat;
    double? fiber;

    // ───── MICROS (toutes tes colonnes connues) ─────
    final Map<String, double> micros = {
      // Lipides / sucres / sel
      'AG_saturés_g_100g': 0,
      'Acide_oléique_W9_g_100g': 0,
      'Acide_linoléique_W6_LA_g_100g': 0,
      'Acide_alpha-linolénique_W3_ALA_g_100g': 0,
      'EPA_g_100g': 0,
      'DHA_g_100g': 0,
      'Sucres_g_100g': 0,
      'Sel_g_100g': 0,

      // Minéraux
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

      // Vitamines liposolubles
      'Rétinol_µg_100g': 0,
      'Vitamine_D_µg_100g': 0,
      'Vitamine_E_mg_100g': 0,
      'Vitamine_K1_µg_100g': 0,
      'Vitamine_K2_µg_100g': 0,

      // Vitamines hydrosolubles
      'Vitamine_C_mg_100g': 0,
      'Vitamine_B1_mg_100g': 0,
      'Vitamine_B2_mg_100g': 0,
      'Vitamine_B3_mg_100g': 0,
      'Vitamine_B5_mg_100g': 0,
      'Vitamine_B6_mg_100g': 0,
      'Vitamine_B9_µg_100g': 0,
      'Vitamine_B12_µg_100g': 0,
    };

    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) {
        return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      }
      return 0;
    }

    bool _isZero(String key) => (micros[key] ?? 0) == 0;

    for (final n in nutrients) {
      final m = n as Map<String, dynamic>;

      // Format USDA: nutrient: { name, number, unitName }, amount
      final nutrient = m['nutrient'] as Map<String, dynamic>?;

      final String nName =
          (nutrient?['name'] ?? m['nutrientName'] ?? '') as String;
      final String nNumber =
          (nutrient?['number'] ?? m['nutrientNumber'] ?? '') as String;

      final String lowerName = nName.toLowerCase();
      final double amount = _toDouble(m['amount'] ?? m['value']);

      // ───────────────────── MACROS ─────────────────────

      // ÉNERGIE — attraper tous les formats (kcal, kJ) et convertir si nécessaire
        if (kcal == null &&
            (nNumber == '1008' ||        // USDA Energy (kcal)
            nNumber == '208'  ||        // Legacy code
            lowerName.contains('energy') ||
            lowerName.contains('kcal') ||
            lowerName.contains('calories'))) {

          final unit = (nutrient?['unitName'] ?? '')
              .toString()
              .toLowerCase()
              .trim();

          if (unit == 'kj' || unit == 'kilojoules') {
            kcal = amount / 4.184;    // kJ -> kcal
          } else {
            kcal = amount;            // kcal direct
          }

          // Sécurisation : arrondi propre (sans warning)
          kcal = double.parse(kcal.toStringAsFixed(1));
        }


      // Protéines : 1003 / 203
      else if ((nNumber == '1003' || nNumber == '203' || nName.contains('Protein')) &&
          prot == null) {
        prot = amount;
      }

      // Glucides disponibles : 1005 / 205
      else if ((nNumber == '1005' || nNumber == '205' || nName.contains('Carbohydrate')) &&
          carb == null) {
        carb = amount;
      }

      // Lipides totaux : 1004 / 204
      else if ((nNumber == '1004' || nNumber == '204' || nName.contains('Total lipid')) &&
          fat == null) {
        fat = amount;
      }

      // Fibres : 1079 / 291
      else if ((nNumber == '1079' || nNumber == '291' || nName.contains('Fiber')) &&
          fiber == null) {
        fiber = amount;
      }

      // Sucres totaux (on match large : “sugars, total” etc.)
      if (lowerName.contains('sugars, total') ||
          lowerName.contains('sugars, total including nlea') ||
          lowerName == 'sugars') {
        micros['Sucres_g_100g'] = amount;
      }

      // ───────────────────── ACIDES GRAS ─────────────────────
      // Objectif : ne pas rater oméga 3 / 6 / 9 quand ils existent.

      // Saturés totaux : 1258 ou nom "fatty acids, total saturated"
      if (nNumber == '1258' ||
          lowerName.contains('fatty acids, total saturated')) {
        micros['AG_saturés_g_100g'] = amount;
      }

      // Oméga-9 (acide oléique, 18:1 n-9)
      // 1) cas spécifique 18:1
      if (lowerName.contains('18:1') &&
          (lowerName.contains('oleic') || lowerName.contains('n-9'))) {
        micros['Acide_oléique_W9_g_100g'] = amount;
      }
      // 2) fallback “monoinsaturés totaux” si oléique encore à 0
      else if ((lowerName.contains('fatty acids, total monounsaturated') ||
                lowerName.contains('fatty acids, total monoenoic')) &&
               _isZero('Acide_oléique_W9_g_100g')) {
        micros['Acide_oléique_W9_g_100g'] = amount;
      }

      // Oméga-6 (acide linoléique, 18:2 n-6)
      // spécifique 18:2
      if (lowerName.contains('18:2') &&
          (lowerName.contains('linoleic') || lowerName.contains('n-6'))) {
        micros['Acide_linoléique_W6_LA_g_100g'] = amount;
      }
      // total n-6 : on l’utilise comme fallback si LA = 0
      else if ((lowerName.contains('fatty acids, total n-6') ||
                lowerName.contains('omega-6')) &&
               _isZero('Acide_linoléique_W6_LA_g_100g')) {
        micros['Acide_linoléique_W6_LA_g_100g'] = amount;
      }

      // Oméga-3 (ALA, EPA, DHA)
      // 18:3 (alpha-linolénique)
      if (lowerName.contains('18:3') &&
          (lowerName.contains('linolenic') || lowerName.contains('n-3'))) {
        micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = amount;
      }

      // EPA 20:5 n-3 / Eicosapentaenoic acid
      if (lowerName.contains('20:5') ||
          lowerName.contains('eicosapentaenoic') ||
          lowerName.contains('epa')) {
        micros['EPA_g_100g'] = amount;
      }

      // DHA 22:6 n-3 / Docosahexaenoic acid
      if (lowerName.contains('22:6') ||
          lowerName.contains('docosahexaenoic') ||
          lowerName.contains('dha')) {
        micros['DHA_g_100g'] = amount;
      }

      // total n-3 : si aucun détail ALA/EPA/DHA mais total dispo, on met tout sur ALA
      if ((lowerName.contains('fatty acids, total n-3') ||
           lowerName.contains('omega-3')) &&
          _isZero('Acide_alpha-linolénique_W3_ALA_g_100g') &&
          _isZero('EPA_g_100g') &&
          _isZero('DHA_g_100g')) {
        micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = amount;
      }

      // ───────────────────── MINÉRAUX ─────────────────────

      // Calcium : 1087 / 301
      if (nNumber == '1087' || nNumber == '301' || nName.contains('Calcium')) {
        micros['Calcium_mg_100g'] = amount;
      }

      // Fer : 1089 / 303
      if (nNumber == '1089' || nNumber == '303' || nName.contains('Iron')) {
        micros['Fer_mg_100g'] = amount;
      }

      // Magnésium : 1090 / 304
      if (nNumber == '1090' || nNumber == '304' || nName.contains('Magnesium')) {
        micros['Magnésium_mg_100g'] = amount;
      }

      // Phosphore : 1091 / 305
      if (nNumber == '1091' || nNumber == '305' || nName.contains('Phosphorus')) {
        micros['Phosphore_mg_100g'] = amount;
      }

      // Potassium : 1092 / 306
      if (nNumber == '1092' || nNumber == '306' || nName.contains('Potassium')) {
        micros['Potassium_mg_100g'] = amount;
      }

      // Sodium : 1093 / 307
      if (nNumber == '1093' || nNumber == '307' || nName.contains('Sodium')) {
        micros['Sodium_mg_100g'] = amount;
        // Conversion Na -> sel (NaCl) ≈ Na * 2.5, mg -> g
        micros['Sel_g_100g'] = (amount * 2.5) / 1000.0;
      }

      // Zinc : 1095 / 309
      if (nNumber == '1095' || nNumber == '309' || nName.contains('Zinc')) {
        micros['Zinc_mg_100g'] = amount;
      }

      // Cuivre : 1102 / 312
      if (nNumber == '1102' || nNumber == '312' || nName.contains('Copper')) {
        micros['Cuivre_mg_100g'] = amount;
      }

      // Manganèse : 1103 / 315
      if (nNumber == '1103' || nNumber == '315' || nName.contains('Manganese')) {
        micros['Manganèse_mg_100g'] = amount;
      }

      // Sélénium : 1180 / 317
      if (nNumber == '1180' || nNumber == '317' || nName.contains('Selenium')) {
        micros['Sélénium_µg_100g'] = amount;
      }

      // Iode : attrape tout ce qui ressemble à iodine
      if (lowerName.contains('iodine') ||
          lowerName.contains('iodide') ||
          lowerName.endsWith(' iodine') ||
          lowerName == 'i') {
        micros['Iode_µg_100g'] = amount;
      }

      // ───────────────────── VITAMINES ─────────────────────

      // Vitamine A (Rétinol) : 1104 / 318
      if (nNumber == '1104' || nNumber == '318' || nName.contains('Retinol')) {
        micros['Rétinol_µg_100g'] = amount;
      }

      // Vitamine D : 1114 / 324
      if (nNumber == '1114' || nNumber == '324' || nName.contains('Vitamin D')) {
        micros['Vitamine_D_µg_100g'] = amount;
      }

      // Vitamine E (alpha-tocopherol) : 1109 / 323
      if (nNumber == '1109' ||
          nNumber == '323' ||
          nName.contains('Vitamin E')) {
        micros['Vitamine_E_mg_100g'] = amount;
      }

      // Vitamine K1 (phylloquinone) : 1185 / 430
      if (nNumber == '1185' ||
          nNumber == '430' ||
          lowerName.contains('phylloquinone')) {
        micros['Vitamine_K1_µg_100g'] = amount;
      }

      // Vitamine K2 : ménakinones (très rares dans USDA, mais on tente)
      if (lowerName.contains('menaquinone') || lowerName.contains('vitamin k-2')) {
        micros['Vitamine_K2_µg_100g'] = amount;
      }

      // Vitamine C : 1162 / 401
      if (nNumber == '1162' || nNumber == '401' || nName.contains('Vitamin C')) {
        micros['Vitamine_C_mg_100g'] = amount;
      }

      // Vitamine B1 (Thiamine) : 1165 / 404
      if (nNumber == '1165' ||
          nNumber == '404' ||
          nName.contains('Thiamin')) {
        micros['Vitamine_B1_mg_100g'] = amount;
      }

      // Vitamine B2 (Riboflavine) : 1166 / 405
      if (nNumber == '1166' ||
          nNumber == '405' ||
          nName.contains('Riboflavin')) {
        micros['Vitamine_B2_mg_100g'] = amount;
      }

      // Vitamine B3 (Niacine) : 1167 / 406
      if (nNumber == '1167' ||
          nNumber == '406' ||
          nName.contains('Niacin')) {
        micros['Vitamine_B3_mg_100g'] = amount;
      }

      // Vitamine B5 (Acide pantothénique) : 1170 / 410
      if (nNumber == '1170' ||
          nNumber == '410' ||
          lowerName.contains('pantothenic')) {
        micros['Vitamine_B5_mg_100g'] = amount;
      }

      // Vitamine B6 : 1175 / 415
      if (nNumber == '1175' ||
          nNumber == '415' ||
          nName.contains('Vitamin B-6') ||
          nName.contains('Vitamin B6')) {
        micros['Vitamine_B6_mg_100g'] = amount;
      }

      // Vitamine B9 (Folate) : 1190 / 417
      if (nNumber == '1190' ||
          nNumber == '417' ||
          nName.contains('Folate')) {
        micros['Vitamine_B9_µg_100g'] = amount;
      }

      // Vitamine B12 : 1178 / 418, on gère plusieurs variantes
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
