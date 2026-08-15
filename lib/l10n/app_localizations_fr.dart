// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Totum';

  @override
  String get weightScreenTitle => 'Poids';

  @override
  String get weightTrendEmptyState =>
      'Sauvegarde ton profil à quelques jours d\'écart pour voir ta courbe apparaître ici.';

  @override
  String get weightTrendRangeYear => '1A';

  @override
  String get weightTrendRangeAll => 'Tout';

  @override
  String get weightTrendRawLegend => 'Poids brut';

  @override
  String get weightTrendSmoothedLegend => 'Poids tendance';

  @override
  String get weightTrendAdviceText =>
      'Pèse-toi si possible tous les jours, dans les mêmes conditions à chaque fois — idéalement le matin à jeun, au lever. La fiabilité de la tendance — et de tes objectifs recalculés — dépend directement de cette régularité.';

  @override
  String get weightTrendRecentEvolution => 'Évolution récente (poids tendance)';

  @override
  String lastNDays(int days) {
    return '$days derniers jours';
  }

  @override
  String get expenditureScreenTitle => 'Dépense énergétique';

  @override
  String get expenditureNotEnoughWeighIns =>
      'Pas encore assez de pesées pour démarrer le calcul';

  @override
  String get expenditureComingSoon =>
      'Ta dépense énergétique estimée arrive bientôt';

  @override
  String expenditureAddSecondWeighIn(int count) {
    return 'Ajoute au moins une 2e pesée (tu en as $count/2) pour que le calcul puisse démarrer.';
  }

  @override
  String get expenditureSpanBetweenWeighIns => 'Écart entre 2 pesées';

  @override
  String get expenditureSpanBetweenWeighInsCompact => 'Écart pesées';

  @override
  String get expenditureMealsLogged => 'Repas renseignés (20 derniers jours)';

  @override
  String get expenditureMealsLoggedCompact => 'Repas renseignés';

  @override
  String get expenditureContinueHint =>
      'Continue à te peser et à noter tes repas régulièrement — ta dépense apparaîtra automatiquement dès ces deux seuils atteints.';

  @override
  String get expenditureEstimatedLegend => 'Dépense estimée';

  @override
  String get expenditureUncertaintyLegend => 'Marge d\'incertitude';

  @override
  String get expenditureDisclaimer =>
      'Cette estimation est calculée à partir de ton poids et de ton journal alimentaire (même principe que la calibration adaptative de TOTUM) — ce n\'est pas une mesure directe, ni une reproduction de l\'algorithme propriétaire d\'une autre application. Plus tu renseignes ton poids et tes repas régulièrement, plus la marge d\'incertitude se resserre.';

  @override
  String get expenditureRecentEvolution => 'Évolution récente';

  @override
  String get kcalPerDay => 'kcal/j';

  @override
  String get dayAbbrev => 'j';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonConfirm => 'Valider';

  @override
  String get barcodeEnterTitle => 'Saisir le code-barres';

  @override
  String get barcodeDigitsLabel => 'Chiffres du code-barres';

  @override
  String get barcodeScanScreenTitle => 'Scanner un produit';

  @override
  String get barcodeEnableFlash => 'Activer le flash';

  @override
  String barcodeCameraError(String error) {
    return 'Erreur caméra : $error';
  }

  @override
  String get barcodeAimInstruction => 'Visez le code-barre';

  @override
  String get barcodeAutoDetect => 'Détection automatique';

  @override
  String get barcodeManualEntry => 'Saisir le code manuellement';
}
