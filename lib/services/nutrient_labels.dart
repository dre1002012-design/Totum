// lib/services/nutrient_labels.dart
//
// Les libellés courts de nutriments ('Fer', 'Vit D', 'Oméga 9 (Oléique)'...)
// servent d'IDENTIFIANT INTERNE STABLE dans tout le code existant (clés de
// Map comme `vitTargets`/`minTargets`/`_kMicroKeyByLabel`, comparaisons
// directes comme `m.label == 'Vit D'`, listes d'avertissements de score) —
// jamais renommés ni traduits à la source (Priorité 62, 15/08/2026), pour
// ne casser aucun calcul ni lookup existant. Cette fonction ne fait QUE
// traduire le libellé pour l'AFFICHAGE — à appeler uniquement au moment de
// construire un Text(), jamais pour re-comparer ou re-indexer une Map.
import '../l10n/app_localizations.dart';

String nutrientDisplayLabel(String label, AppLocalizations l10n) => switch (label) {
      'Énergie' => l10n.nutrientEnergy,
      'Protéines' => l10n.nutrientProtein,
      'Glucides' => l10n.nutrientCarbs,
      'Lipides' => l10n.nutrientFat,
      'Fibres' => l10n.nutrientFiber,
      'Oméga 9 (Oléique)' => l10n.nutrientOmega9,
      'Oméga 6 (LA)' => l10n.nutrientOmega6,
      'Oméga 3 (ALA)' => l10n.nutrientOmega3,
      'AG saturés' => l10n.nutrientSatFat,
      'Sucres' => l10n.nutrientSugars,
      'Sel' => l10n.nutrientSalt,
      'Alcool' => l10n.nutrientAlcohol,
      'Rétinol' => l10n.nutrientRetinol,
      'Bêta-car.' => l10n.nutrientBetaCarotene,
      'Cuivre' => l10n.nutrientCopper,
      'Fer' => l10n.nutrientIron,
      'Iode' => l10n.nutrientIodine,
      'Magnésium' => l10n.nutrientMagnesium,
      'Manganèse' => l10n.nutrientManganese,
      'Phosphore' => l10n.nutrientPhosphorus,
      'Sélénium' => l10n.nutrientSelenium,
      'Cholestérol' => l10n.nutrientCholesterol,
      'Vitamine D' => l10n.nutrientVitaminDFull,
      'Vitamine C' => l10n.nutrientVitaminCFull,
      'Vitamine K' => l10n.nutrientVitaminKFull,
      'Vitamine B9' => l10n.nutrientVitaminB9Full,
      'Vitamine B12' => l10n.nutrientVitaminB12Full,
      'Oméga 3 marins' => l10n.nutrientOmega3Marine,
      // Déjà identiques en anglais (abréviations internationales ou noms
      // propres) : Vit D/E/K/C, B1-B12, EPA, DHA, Calcium, Potassium,
      // Sodium, Zinc, Polyols — passent tels quels.
      _ => label,
    };
