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

  /// No description provided for @authWrongCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect. Vérifie et réessaie.'**
  String get authWrongCredentials;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'📧 Ton email n\'est pas encore confirmé. Ouvre le lien reçu par mail, puis reconnecte-toi.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authUserAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet email. Essaie de te connecter.'**
  String get authUserAlreadyRegistered;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères.'**
  String get authPasswordTooShort;

  /// No description provided for @authInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse email ne semble pas valide.'**
  String get authInvalidEmail;

  /// No description provided for @authNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion internet indisponible. Vérifie ta connexion et réessaie.'**
  String get authNetworkError;

  /// No description provided for @authRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patiente une minute avant de réessayer.'**
  String get authRateLimit;

  /// No description provided for @authGenericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie dans un instant.'**
  String get authGenericError;

  /// No description provided for @authSignUpWelcome.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Bienvenue ! Ton compte est créé.\n📧 Ouvre ta boîte mail et clique sur le lien de confirmation, puis reviens te connecter ici.'**
  String get authSignUpWelcome;

  /// No description provided for @authSignInSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie ✅ Bon retour parmi nous !'**
  String get authSignInSuccess;

  /// No description provided for @authEnterEmailFirst.
  ///
  /// In fr, this message translates to:
  /// **'Entre d\'abord ton email ci-dessus, puis appuie sur « Mot de passe oublié ».'**
  String get authEnterEmailFirst;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In fr, this message translates to:
  /// **'📧 Si un compte existe pour cet email, tu vas recevoir un lien pour réinitialiser ton mot de passe. Pense à vérifier tes spams.'**
  String get authResetPasswordSent;

  /// No description provided for @authGoogleSignInFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion avec Google n\'a pas abouti. Réessaie ou utilise ton email.'**
  String get authGoogleSignInFailed;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur TOTUM'**
  String get authWelcomeTitle;

  /// No description provided for @authTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ton compagnon de suivi complet, pour une vitalité totale.'**
  String get authTagline;

  /// No description provided for @authPricingText.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit 7 jours, puis abonnement 14,99 €/an renouvelé automatiquement. Annulable à tout moment.'**
  String get authPricingText;

  /// No description provided for @authEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entre un email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entre un mot de passe'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères'**
  String get authPasswordMinLength;

  /// No description provided for @authForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPassword;

  /// No description provided for @authSignInButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignInButton;

  /// No description provided for @authSignUpButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authSignUpButton;

  /// No description provided for @authOr.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get authOr;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authTermsNotice.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, tu acceptes les conditions d\'utilisation et la politique de confidentialité de TOTUM.'**
  String get authTermsNotice;

  /// No description provided for @sunScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Soleil & vitamine D'**
  String get sunScreenTitle;

  /// No description provided for @sunSkinType1Label.
  ///
  /// In fr, this message translates to:
  /// **'Type I — Très claire'**
  String get sunSkinType1Label;

  /// No description provided for @sunSkinType1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Peau très pâle, brûle toujours, ne bronze jamais. Souvent cheveux roux, taches de rousseur.'**
  String get sunSkinType1Desc;

  /// No description provided for @sunSkinType2Label.
  ///
  /// In fr, this message translates to:
  /// **'Type II — Claire'**
  String get sunSkinType2Label;

  /// No description provided for @sunSkinType2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Peau claire, brûle facilement, bronze peu et difficilement.'**
  String get sunSkinType2Desc;

  /// No description provided for @sunSkinType3Label.
  ///
  /// In fr, this message translates to:
  /// **'Type III — Intermédiaire'**
  String get sunSkinType3Label;

  /// No description provided for @sunSkinType3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Peau moyenne, brûle modérément, bronze progressivement.'**
  String get sunSkinType3Desc;

  /// No description provided for @sunSkinType4Label.
  ///
  /// In fr, this message translates to:
  /// **'Type IV — Mate'**
  String get sunSkinType4Label;

  /// No description provided for @sunSkinType4Desc.
  ///
  /// In fr, this message translates to:
  /// **'Peau mate/olivâtre, brûle peu, bronze bien et facilement.'**
  String get sunSkinType4Desc;

  /// No description provided for @sunSkinType5Label.
  ///
  /// In fr, this message translates to:
  /// **'Type V — Foncée'**
  String get sunSkinType5Label;

  /// No description provided for @sunSkinType5Desc.
  ///
  /// In fr, this message translates to:
  /// **'Peau brun foncé, brûle rarement, bronze intensément.'**
  String get sunSkinType5Desc;

  /// No description provided for @sunSkinType6Label.
  ///
  /// In fr, this message translates to:
  /// **'Type VI — Très foncée'**
  String get sunSkinType6Label;

  /// No description provided for @sunSkinType6Desc.
  ///
  /// In fr, this message translates to:
  /// **'Peau noire, ne brûle quasiment jamais.'**
  String get sunSkinType6Desc;

  /// No description provided for @sunExposureFaceHands.
  ///
  /// In fr, this message translates to:
  /// **'Visage & mains'**
  String get sunExposureFaceHands;

  /// No description provided for @sunExposureArmsFace.
  ///
  /// In fr, this message translates to:
  /// **'Bras & visage'**
  String get sunExposureArmsFace;

  /// No description provided for @sunExposureArmsLegs.
  ///
  /// In fr, this message translates to:
  /// **'Bras & jambes'**
  String get sunExposureArmsLegs;

  /// No description provided for @sunExposureSwimwear.
  ///
  /// In fr, this message translates to:
  /// **'Maillot de bain'**
  String get sunExposureSwimwear;

  /// No description provided for @sunSkinPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel est ton type de peau ?'**
  String get sunSkinPickerTitle;

  /// No description provided for @sunSkinPickerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ta peau détermine la vitesse à laquelle tu synthétises la vitamine D au soleil. On te le demande une seule fois.'**
  String get sunSkinPickerSubtitle;

  /// No description provided for @sunLocationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Localisation désactivée sur l\'appareil. Active-la, ou saisis l\'UV index à la main.'**
  String get sunLocationDisabled;

  /// No description provided for @sunLocationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée. Tu peux saisir l\'UV index à la main.'**
  String get sunLocationDenied;

  /// No description provided for @sunUvFetchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer l\'UV index pour l\'instant.'**
  String get sunUvFetchFailed;

  /// No description provided for @sunLocationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Localisation indisponible. Saisis l\'UV index à la main.'**
  String get sunLocationUnavailable;

  /// No description provided for @sunValidateSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'☀️ +{amount} µg de vitamine D ajoutés à ta journée !'**
  String sunValidateSnackbar(String amount);

  /// No description provided for @sunTodayEstimateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine D solaire estimée aujourd\'hui'**
  String get sunTodayEstimateLabel;

  /// No description provided for @sunResetTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get sunResetTooltip;

  /// No description provided for @sunUvCurrentTitle.
  ///
  /// In fr, this message translates to:
  /// **'UV index actuel'**
  String get sunUvCurrentTitle;

  /// No description provided for @sunRefreshLocationTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser ma position'**
  String get sunRefreshLocationTooltip;

  /// No description provided for @sunBelowUv3Info.
  ///
  /// In fr, this message translates to:
  /// **'En dessous de UV 3, la synthèse de vitamine D est négligeable. Ce n\'est pas le bon moment — mais profite quand même du grand air.'**
  String get sunBelowUv3Info;

  /// No description provided for @sunUvUnknown.
  ///
  /// In fr, this message translates to:
  /// **'UV index inconnu.'**
  String get sunUvUnknown;

  /// No description provided for @sunManualUvLabel.
  ///
  /// In fr, this message translates to:
  /// **'Saisir manuellement : '**
  String get sunManualUvLabel;

  /// No description provided for @sunYourSkinTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ton type de peau : '**
  String get sunYourSkinTypeLabel;

  /// No description provided for @sunModifyButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get sunModifyButton;

  /// No description provided for @sunExposedSkinSurface.
  ///
  /// In fr, this message translates to:
  /// **'Surface de peau exposée'**
  String get sunExposedSkinSurface;

  /// No description provided for @sunSunDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée au soleil'**
  String get sunSunDuration;

  /// No description provided for @sunMinutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String sunMinutesShort(int minutes);

  /// No description provided for @sunSunscreenSwitchTitle.
  ///
  /// In fr, this message translates to:
  /// **'J\'avais de la crème solaire'**
  String get sunSunscreenSwitchTitle;

  /// No description provided for @sunSunscreenSwitchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'La crème bloque 95 à 98 % de la synthèse de vitamine D.'**
  String get sunSunscreenSwitchSubtitle;

  /// No description provided for @sunEstimatedAmount.
  ///
  /// In fr, this message translates to:
  /// **'≈ {amount} µg estimés'**
  String sunEstimatedAmount(String amount);

  /// No description provided for @sunEstimateDetail.
  ///
  /// In fr, this message translates to:
  /// **'pour {minutes} min, peau {skinType}, {exposure}'**
  String sunEstimateDetail(int minutes, String skinType, String exposure);

  /// No description provided for @sunValidateButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider mon exposition'**
  String get sunValidateButton;

  /// No description provided for @sunGoodConditionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les bonnes conditions'**
  String get sunGoodConditionsTitle;

  /// No description provided for @sunCondition1.
  ///
  /// In fr, this message translates to:
  /// **'Les UVB nécessaires à la vitamine D ne sont présents qu\'au milieu de journée. Vise plutôt les bords de ce créneau (fin de matinée, milieu d\'après-midi) : quelques minutes suffisent. Entre 12h et 16h, le rayonnement est à son pic — bref et prudent, jamais une exposition prolongée.'**
  String get sunCondition1;

  /// No description provided for @sunCondition2.
  ///
  /// In fr, this message translates to:
  /// **'Derrière une vitre (fenêtre, voiture), le verre bloque 100 % des UVB : aucune vitamine D produite.'**
  String get sunCondition2;

  /// No description provided for @sunCondition3.
  ///
  /// In fr, this message translates to:
  /// **'Les lunettes de soleil ne gênent PAS la synthèse : elle se fait par la peau, garde-les pour protéger tes yeux.'**
  String get sunCondition3;

  /// No description provided for @sunCondition4.
  ///
  /// In fr, this message translates to:
  /// **'Sous nos latitudes, la synthèse n\'est possible qu\'environ de mars à octobre. L\'hiver, mise sur l\'alimentation et éventuellement un complément.'**
  String get sunCondition4;

  /// No description provided for @sunCondition5.
  ///
  /// In fr, this message translates to:
  /// **'Ton corps ne produit qu\'une dose limitée de vitamine D, puis s\'arrête : rester plus longtemps n\'apporte rien de plus, mais accélère le vieillissement de la peau et augmente le risque de cancer cutané. L\'objectif est le strict nécessaire, pas le bronzage.'**
  String get sunCondition5;

  /// No description provided for @sunDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Estimation pédagogique fondée sur des modèles scientifiques. Ce n\'est pas une mesure médicale : seule une prise de sang évalue précisément ton taux de vitamine D.'**
  String get sunDisclaimer;

  /// No description provided for @sunUvLow.
  ///
  /// In fr, this message translates to:
  /// **'Faible — synthèse négligeable'**
  String get sunUvLow;

  /// No description provided for @sunUvModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré — synthèse possible'**
  String get sunUvModerate;

  /// No description provided for @sunUvHigh.
  ///
  /// In fr, this message translates to:
  /// **'Élevé — synthèse efficace, protège-toi'**
  String get sunUvHigh;

  /// No description provided for @sunUvVeryHigh.
  ///
  /// In fr, this message translates to:
  /// **'Très élevé — quelques minutes suffisent'**
  String get sunUvVeryHigh;

  /// No description provided for @sunUvExtreme.
  ///
  /// In fr, this message translates to:
  /// **'Extrême — grande prudence'**
  String get sunUvExtreme;
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
