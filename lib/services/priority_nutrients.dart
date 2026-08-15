// lib/services/priority_nutrients.dart
//
// Les 10 micronutriments jugés prioritaires pour la plupart des gens (liste
// validée avec Alex — source canonique : `_kPriorityRatioKeys` dans
// conseils_screen.dart, où ils dominent le calcul de "Priorité du jour").
// Réexposés ici en public pour être utilisables depuis le Tableau de bord
// (carte "Micronutriments en vedette") sans dépendre des constantes privées
// de conseils_screen.dart — recopie volontaire et restreinte à ces 10 clés
// (pas un import), à garder synchronisée si la liste canonique évolue.
import '../services/profile.dart' as nutri;

// Ordre d'affichage demandé par Alex (carte "Micronutriments en vedette",
// Tableau de bord) : ligne du haut = minéraux (+ oméga-3 marins), ligne du
// bas = vitamines — répartition logique plus lisible que l'ordre précédent.
const List<String> kPriorityNutrientKeys = [
  'omega3_marins', 'magnesium', 'iron', 'iodine', 'zinc',
  'vitC', 'vitD', 'vitK', 'B9', 'B12',
];

const Map<String, String> kPriorityNutrientLabel = {
  'vitD': 'Vitamine D',
  'magnesium': 'Magnésium',
  'iron': 'Fer',
  'B12': 'Vitamine B12',
  'zinc': 'Zinc',
  'omega3_marins': 'Oméga 3 marins',
  'vitC': 'Vitamine C',
  'vitK': 'Vitamine K',
  'iodine': 'Iode',
  'B9': 'Vitamine B9',
};

/// Nom de colonne CSV correspondant (clé de `DayTotals.micros`).
const Map<String, String> kPriorityNutrientColumn = {
  'vitD': 'Vitamine_D_µg_100g',
  'magnesium': 'Magnésium_mg_100g',
  'iron': 'Fer_mg_100g',
  'B12': 'Vitamine_B12_µg_100g',
  'zinc': 'Zinc_mg_100g',
  'vitC': 'Vitamine_C_mg_100g',
  'vitK': 'Vitamine_K1_µg_100g',
  'iodine': 'Iode_µg_100g',
  'B9': 'Vitamine_B9_µg_100g',
};

/// Cible du jour pour un nutriment prioritaire, à partir des objectifs
/// nutritionnels calculés (`NutritionTargets`). 'omega3_marins' = EPA + DHA
/// combinés (pas de colonne CSV unique — additionné à part dans le
/// consommé, voir [priorityNutrientConsumed]).
double? priorityNutrientTarget(String key, nutri.NutritionTargets t) {
  switch (key) {
    case 'vitD': return t.vitDUg;
    case 'magnesium': return t.mgMg;
    case 'iron': return t.feMg;
    case 'B12': return t.b12Ug;
    case 'zinc': return t.znMg;
    case 'omega3_marins': return t.epa + t.dha;
    case 'vitC': return t.vitCMg;
    case 'vitK': return t.vitKUg;
    case 'iodine': return t.iUg;
    case 'B9': return t.b9Ug;
    default: return null;
  }
}

/// Valeur consommée aujourd'hui pour un nutriment prioritaire, à partir des
/// micros bruts du journal (`DayTotals.micros`, clés = colonnes CSV).
double priorityNutrientConsumed(String key, Map<String, double> micros) {
  if (key == 'omega3_marins') {
    return (micros['EPA_g_100g'] ?? 0) + (micros['DHA_g_100g'] ?? 0);
  }
  final col = kPriorityNutrientColumn[key];
  if (col == null) return 0;
  return micros[col] ?? 0;
}
