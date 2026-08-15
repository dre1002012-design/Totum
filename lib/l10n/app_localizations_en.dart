// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Totum';

  @override
  String get weightScreenTitle => 'Weight';

  @override
  String get weightTrendEmptyState =>
      'Save your profile a few days apart to see your curve appear here.';

  @override
  String get weightTrendRangeYear => '1Y';

  @override
  String get weightTrendRangeAll => 'All';

  @override
  String get weightTrendRawLegend => 'Raw weight';

  @override
  String get weightTrendSmoothedLegend => 'Weight trend';

  @override
  String get weightTrendAdviceText =>
      'Weigh yourself every day if possible, under the same conditions each time — ideally in the morning, fasted, right after waking up. The reliability of the trend — and your recalculated targets — depends directly on this consistency.';

  @override
  String get weightTrendRecentEvolution => 'Recent evolution (weight trend)';

  @override
  String lastNDays(int days) {
    return 'Last $days days';
  }

  @override
  String get expenditureScreenTitle => 'Energy expenditure';

  @override
  String get expenditureNotEnoughWeighIns =>
      'Not enough weigh-ins yet to start the calculation';

  @override
  String get expenditureComingSoon =>
      'Your estimated energy expenditure is coming soon';

  @override
  String expenditureAddSecondWeighIn(int count) {
    return 'Add at least a 2nd weigh-in (you have $count/2) for the calculation to start.';
  }

  @override
  String get expenditureSpanBetweenWeighIns => 'Span between 2 weigh-ins';

  @override
  String get expenditureSpanBetweenWeighInsCompact => 'Weigh-in span';

  @override
  String get expenditureMealsLogged => 'Meals logged (last 20 days)';

  @override
  String get expenditureMealsLoggedCompact => 'Meals logged';

  @override
  String get expenditureContinueHint =>
      'Keep weighing yourself and logging your meals regularly — your expenditure will appear automatically once both thresholds are reached.';

  @override
  String get expenditureEstimatedLegend => 'Estimated expenditure';

  @override
  String get expenditureUncertaintyLegend => 'Uncertainty margin';

  @override
  String get expenditureDisclaimer =>
      'This estimate is calculated from your weight and food journal (same principle as TOTUM\'s adaptive calibration) — it is not a direct measurement, nor a reproduction of another app\'s proprietary algorithm. The more regularly you log your weight and meals, the tighter the uncertainty margin becomes.';

  @override
  String get expenditureRecentEvolution => 'Recent evolution';

  @override
  String get kcalPerDay => 'kcal/day';

  @override
  String get dayAbbrev => 'd';
}
