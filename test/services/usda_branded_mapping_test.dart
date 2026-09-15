// Audit scanner (15/09/2026, voir docs/AUDIT_SCANNER_BASE_ALIMENTS.md) —
// UsdaService.findByBarcode() ajoute USDA Branded Foods comme repli quand
// Open Food Facts ne connaît pas le produit scanné. Ce test verrouille la
// partie la plus sensible : la conversion des IDs nutriments USDA (bruts,
// par nutrientId) en valeurs affichées à l'utilisateur — sur un vrai jeu de
// données (réponse réelle de l'API FoodData Central pour Coca-Cola, capturée
// et vérifiée à la main le 15/09/2026 contre l'étiquette nutritionnelle
// réelle du produit), pas une réponse inventée.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/usda_service.dart';

/// Construit un hit `/foods/search` (dataType=Branded) minimal, avec les
/// nutriments donnés sous forme {nutrientId: (value, unitName)}.
Map<String, dynamic> _hit({
  required int fdcId,
  required String description,
  String? brandName,
  required Map<int, num> nutrients,
}) {
  return {
    'fdcId': fdcId,
    'description': description,
    'gtinUpc': '00000000',
    if (brandName != null) 'brandName': brandName,
    'foodNutrients': [
      for (final e in nutrients.entries)
        {'nutrientId': e.key, 'value': e.value, 'unitName': 'G'},
    ],
  };
}

void main() {
  test('cas réel capturé (Coca-Cola, 15/09/2026) : macros + sucres (id '
      '2000, spécifique Branded) correctement extraits, pour 100 mL', () {
    final item = UsdaService.foodItemFromBrandedSearchHit(_hit(
      fdcId: 2678649,
      description: 'COCA-COLA, COLA',
      brandName: 'COCA-COLA',
      nutrients: {
        1003: 0.0,  // Protein
        1004: 0.0,  // Total lipid (fat)
        1005: 11.0, // Carbohydrate, by difference
        1008: 39.0, // Energy (kcal)
        2000: 11.0, // Total Sugars (id Branded, différent de 1063)
        1093: 13.0, // Sodium
      },
    ));

    expect(item.id, 'usda:2678649');
    expect(item.kcal100, 39.0);
    expect(item.prot100, 0.0);
    expect(item.carb100, 11.0);
    expect(item.fat100, 0.0);
    expect(item.micros100['Sucres_g_100g'], 11.0,
        reason: 'doit lire id 2000 ("Total Sugars"), pas seulement 1063 '
            '(Foundation/SR Legacy) — sinon 0 sur presque tous les produits '
            'de marque');
    expect(item.micros100['Sodium_mg_100g'], 13.0);
    expect(item.micros100['Sel_g_100g'], closeTo(13.0 * 2.5 / 1000, 1e-9),
        reason: 'sel dérivé du sodium (aucune étiquette US ne donne le sel '
            'directement) — même formule que scripts/build_usda_foods.py');
    expect(item.brand, 'COCA-COLA');
  });

  test('vitamine D : conversion UI -> µg (id 1110) appliquée uniquement en '
      "l'absence de la forme directe en µg (id 1114)", () {
    final withIuOnly = UsdaService.foodItemFromBrandedSearchHit(_hit(
      fdcId: 1,
      description: 'Test céréales',
      nutrients: {1008: 300, 1110: 200}, // 200 UI de vitamine D
    ));
    expect(item(withIuOnly, 'Vitamine_D_µg_100g'), closeTo(200 * 0.025, 1e-9),
        reason: 'facteur officiel NIH/FDA 1 UI = 0.025 µg cholécalciférol');

    final withUgDirect = UsdaService.foodItemFromBrandedSearchHit(_hit(
      fdcId: 2,
      description: 'Test céréales 2',
      nutrients: {1008: 300, 1114: 12.0, 1110: 999}, // µg direct présent
    ));
    expect(item(withUgDirect, 'Vitamine_D_µg_100g'), 12.0,
        reason: 'la valeur directe en µg (1114) prime sur la conversion '
            "depuis l'UI (1110) quand les deux sont présentes");
  });

  test('vitamine A (id 1104, "Vitamin A, IU") volontairement PAS convertie — '
      'conversion UI -> µg RAE dépendante de la source (rétinol vs '
      'caroténoïdes), pas un facteur fixe fiable', () {
    final result = UsdaService.foodItemFromBrandedSearchHit(_hit(
      fdcId: 3,
      description: 'Test avec vitamine A en UI seulement',
      nutrients: {1008: 300, 1104: 5000}, // 5000 UI de vitamine A
    ));
    expect(item(result, 'Rétinol_µg_100g'), 0.0,
        reason: 'mieux vaut 0 (comportement déjà standard ailleurs dans '
            "l'app) qu'une valeur potentiellement fausse sur un champ "
            'nutritionnel de santé');
  });

  test('nutriment absent de la liste -> 0, jamais une exception', () {
    final result = UsdaService.foodItemFromBrandedSearchHit(_hit(
      fdcId: 4,
      description: 'Produit avec très peu de nutriments déclarés',
      nutrients: {1008: 100},
    ));
    expect(result.kcal100, 100.0);
    expect(result.prot100, isNull,
        reason: 'macro absente -> null (comme le reste de FoodItem), '
            'jamais 0 fabriqué qui laisserait croire à une vraie mesure');
    expect(item(result, 'Calcium_mg_100g'), 0.0);
  });
}

double item(dynamic foodItem, String key) =>
    (foodItem.micros100 as Map<String, double>)[key] ?? -1;
