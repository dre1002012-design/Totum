import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en')
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Totum'**
  String get appTitle;

  /// No description provided for @weightScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get weightScreenTitle;

  /// No description provided for @weightTrendEmptyState.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde ton profil à quelques jours d\'écart pour voir ta courbe apparaître ici.'**
  String get weightTrendEmptyState;

  /// No description provided for @weightTrendRangeYear.
  ///
  /// In fr, this message translates to:
  /// **'1A'**
  String get weightTrendRangeYear;

  /// No description provided for @weightTrendRangeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get weightTrendRangeAll;

  /// No description provided for @weightTrendRawLegend.
  ///
  /// In fr, this message translates to:
  /// **'Poids brut'**
  String get weightTrendRawLegend;

  /// No description provided for @weightTrendSmoothedLegend.
  ///
  /// In fr, this message translates to:
  /// **'Poids tendance'**
  String get weightTrendSmoothedLegend;

  /// No description provided for @weightTrendAdviceText.
  ///
  /// In fr, this message translates to:
  /// **'Pèse-toi si possible tous les jours, dans les mêmes conditions à chaque fois — idéalement le matin à jeun, au lever. La fiabilité de la tendance — et de tes objectifs recalculés — dépend directement de cette régularité.'**
  String get weightTrendAdviceText;

  /// No description provided for @weightTrendRecentEvolution.
  ///
  /// In fr, this message translates to:
  /// **'Évolution récente (poids tendance)'**
  String get weightTrendRecentEvolution;

  /// No description provided for @lastNDays.
  ///
  /// In fr, this message translates to:
  /// **'{days} derniers jours'**
  String lastNDays(int days);

  /// No description provided for @expenditureScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépense énergétique'**
  String get expenditureScreenTitle;

  /// No description provided for @expenditureNotEnoughWeighIns.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez de pesées pour démarrer le calcul'**
  String get expenditureNotEnoughWeighIns;

  /// No description provided for @expenditureComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Ta dépense énergétique estimée arrive bientôt'**
  String get expenditureComingSoon;

  /// No description provided for @expenditureAddSecondWeighIn.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins une 2e pesée (tu en as {count}/2) pour que le calcul puisse démarrer.'**
  String expenditureAddSecondWeighIn(int count);

  /// No description provided for @expenditureSpanBetweenWeighIns.
  ///
  /// In fr, this message translates to:
  /// **'Écart entre 2 pesées'**
  String get expenditureSpanBetweenWeighIns;

  /// No description provided for @expenditureSpanBetweenWeighInsCompact.
  ///
  /// In fr, this message translates to:
  /// **'Écart pesées'**
  String get expenditureSpanBetweenWeighInsCompact;

  /// No description provided for @expenditureMealsLogged.
  ///
  /// In fr, this message translates to:
  /// **'Repas renseignés (20 derniers jours)'**
  String get expenditureMealsLogged;

  /// No description provided for @expenditureMealsLoggedCompact.
  ///
  /// In fr, this message translates to:
  /// **'Repas renseignés'**
  String get expenditureMealsLoggedCompact;

  /// No description provided for @expenditureContinueHint.
  ///
  /// In fr, this message translates to:
  /// **'Continue à te peser et à noter tes repas régulièrement — ta dépense apparaîtra automatiquement dès ces deux seuils atteints.'**
  String get expenditureContinueHint;

  /// No description provided for @expenditureEstimatedLegend.
  ///
  /// In fr, this message translates to:
  /// **'Dépense estimée'**
  String get expenditureEstimatedLegend;

  /// No description provided for @expenditureUncertaintyLegend.
  ///
  /// In fr, this message translates to:
  /// **'Marge d\'incertitude'**
  String get expenditureUncertaintyLegend;

  /// No description provided for @expenditureDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Cette estimation est calculée à partir de ton poids et de ton journal alimentaire (même principe que la calibration adaptative de TOTUM) — ce n\'est pas une mesure directe, ni une reproduction de l\'algorithme propriétaire d\'une autre application. Plus tu renseignes ton poids et tes repas régulièrement, plus la marge d\'incertitude se resserre.'**
  String get expenditureDisclaimer;

  /// No description provided for @expenditureRecentEvolution.
  ///
  /// In fr, this message translates to:
  /// **'Évolution récente'**
  String get expenditureRecentEvolution;

  /// No description provided for @kcalPerDay.
  ///
  /// In fr, this message translates to:
  /// **'kcal/j'**
  String get kcalPerDay;

  /// No description provided for @dayAbbrev.
  ///
  /// In fr, this message translates to:
  /// **'j'**
  String get dayAbbrev;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get commonConfirm;

  /// No description provided for @barcodeEnterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code-barres'**
  String get barcodeEnterTitle;

  /// No description provided for @barcodeDigitsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres du code-barres'**
  String get barcodeDigitsLabel;

  /// No description provided for @barcodeScanScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un produit'**
  String get barcodeScanScreenTitle;

  /// No description provided for @barcodeEnableFlash.
  ///
  /// In fr, this message translates to:
  /// **'Activer le flash'**
  String get barcodeEnableFlash;

  /// No description provided for @barcodeCameraError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur caméra : {error}'**
  String barcodeCameraError(String error);

  /// No description provided for @barcodeAimInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Visez le code-barre'**
  String get barcodeAimInstruction;

  /// No description provided for @barcodeAutoDetect.
  ///
  /// In fr, this message translates to:
  /// **'Détection automatique'**
  String get barcodeAutoDetect;

  /// No description provided for @barcodeManualEntry.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code manuellement'**
  String get barcodeManualEntry;

  /// No description provided for @paywallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai TOTUM est terminé'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitleWeb.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai gratuit de 7 jours est arrivé à son terme. 🎯\n\nTu as pu découvrir TOTUM dans son intégralité : suivi nutritionnel complet, conseils bien-être personnalisés et analyse de tes micronutriments.\n\nPour continuer à prendre soin de toi sans interruption, passe à TOTUM Premium : abonnement de 14,99 € par an — soit 1,25 € par mois — renouvelé automatiquement chaque année.'**
  String get paywallSubtitleWeb;

  /// No description provided for @paywallSubtitleLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du prix en cours…'**
  String get paywallSubtitleLoading;

  /// No description provided for @paywallSubtitleNative.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai gratuit de 7 jours est arrivé à son terme. 🎯\n\nPour continuer à profiter de TOTUM sans aucune publicité, passe à TOTUM Premium : abonnement de {price}, renouvelé automatiquement chaque année et annulable à tout moment.'**
  String paywallSubtitleNative(String price);

  /// No description provided for @paywallButtonSubscribe.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner'**
  String get paywallButtonSubscribe;

  /// No description provided for @paywallButtonSubscribeWithPrice.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner — {price}'**
  String paywallButtonSubscribeWithPrice(String price);

  /// No description provided for @paywallBenefitsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avec TOTUM Premium, tu gardes :'**
  String get paywallBenefitsTitle;

  /// No description provided for @paywallBenefit1.
  ///
  /// In fr, this message translates to:
  /// **'Accès illimité à toutes les fonctions'**
  String get paywallBenefit1;

  /// No description provided for @paywallBenefit2.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publicité ni distraction'**
  String get paywallBenefit2;

  /// No description provided for @paywallBenefit3.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement annuel — annulable à tout moment'**
  String get paywallBenefit3;

  /// No description provided for @paywallStoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le Store n\'est pas disponible pour le moment.\nVérifie ta connexion internet ou essaie de relancer l\'application.'**
  String get paywallStoreUnavailable;

  /// No description provided for @paywallSubscriptionNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement introuvable sur le Store.'**
  String get paywallSubscriptionNotFound;

  /// No description provided for @paywallFooterWeb.
  ///
  /// In fr, this message translates to:
  /// **'🔒 Paiement 100 % sécurisé via Stripe\nAbonnement annuel de 14,99 €, renouvelé automatiquement chaque année. Annulable à tout moment : l\'accès reste actif jusqu\'à la fin de la période déjà payée.'**
  String get paywallFooterWeb;

  /// No description provided for @paywallFooterNative.
  ///
  /// In fr, this message translates to:
  /// **'🔒 Paiement géré de manière sécurisée par Google Play.\nAbonnement annuel renouvelé automatiquement. Annulable à tout moment depuis le Play Store.'**
  String get paywallFooterNative;

  /// No description provided for @paywallChangeAccount.
  ///
  /// In fr, this message translates to:
  /// **'Changer de compte'**
  String get paywallChangeAccount;

  /// No description provided for @paywallChangeAccountError.
  ///
  /// In fr, this message translates to:
  /// **'Problème lors du changement de compte : {error}'**
  String paywallChangeAccountError(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
