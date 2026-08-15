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
}
