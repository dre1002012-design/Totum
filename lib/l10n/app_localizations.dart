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

  /// No description provided for @accountScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte & Paramètres'**
  String get accountScreenTitle;

  /// No description provided for @accountSettingsSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get accountSettingsSectionLabel;

  /// No description provided for @accountMenuAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountMenuAccount;

  /// No description provided for @accountMenuAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get accountMenuAppearance;

  /// No description provided for @accountMenuLanguageUnits.
  ///
  /// In fr, this message translates to:
  /// **'Langue & unités'**
  String get accountMenuLanguageUnits;

  /// No description provided for @accountMenuMyData.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get accountMenuMyData;

  /// No description provided for @accountMenuAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get accountMenuAbout;

  /// No description provided for @accountDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Compte TOTUM'**
  String get accountDefaultName;

  /// No description provided for @accountStatusLifetimePremium.
  ///
  /// In fr, this message translates to:
  /// **'Premium à vie'**
  String get accountStatusLifetimePremium;

  /// No description provided for @accountStatusAnnualSubscriber.
  ///
  /// In fr, this message translates to:
  /// **'Abonné·e annuel'**
  String get accountStatusAnnualSubscriber;

  /// No description provided for @accountStatusTrialRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Essai — {days} j restants'**
  String accountStatusTrialRemaining(int days);

  /// No description provided for @accountStatusTrialEnded.
  ///
  /// In fr, this message translates to:
  /// **'Essai terminé'**
  String get accountStatusTrialEnded;

  /// No description provided for @accountSubLifetimeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès complet, sans publicité — merci pour ta confiance.'**
  String get accountSubLifetimeSubtitle;

  /// No description provided for @accountSubActiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement annuel actif'**
  String get accountSubActiveTitle;

  /// No description provided for @accountSubActiveSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'au {date} · 14,99 €/an'**
  String accountSubActiveSubtitle(String date);

  /// No description provided for @accountManageSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon abonnement'**
  String get accountManageSubscription;

  /// No description provided for @accountManageViaStripeReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Pour gérer ou annuler ton abonnement, utilise le lien « Gérer votre abonnement » présent dans tes reçus Stripe.'**
  String get accountManageViaStripeReceipt;

  /// No description provided for @accountTrialUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Nous n\'avons pas encore pu déterminer ton essai. Si besoin, déconnecte-toi puis reconnecte-toi.'**
  String get accountTrialUnknown;

  /// No description provided for @accountTrialRemainingDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Il te reste 1 jour d\'accès complet à TOTUM.} other{Il te reste {count} jours d\'accès complet à TOTUM.}}'**
  String accountTrialRemainingDays(int count);

  /// No description provided for @accountTrialEndedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai gratuit est terminé — abonne-toi pour retrouver un accès complet.'**
  String get accountTrialEndedSubtitle;

  /// No description provided for @accountTrialInProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit en cours'**
  String get accountTrialInProgressTitle;

  /// No description provided for @accountTrialEndedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit terminé'**
  String get accountTrialEndedTitle;

  /// No description provided for @accountProcessing.
  ///
  /// In fr, this message translates to:
  /// **'Traitement en cours…'**
  String get accountProcessing;

  /// No description provided for @accountSubscribeWithPrice.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner ({price})'**
  String accountSubscribeWithPrice(String price);

  /// No description provided for @accountSubscribeAnnualWeb.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner — 14,99 €/an'**
  String get accountSubscribeAnnualWeb;

  /// No description provided for @accountInAppUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement in-app n\'est pas disponible sur cet appareil.'**
  String get accountInAppUnavailable;

  /// No description provided for @accountStripeSecurePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement 100 % sécurisé via Stripe · renouvelé automatiquement chaque année, annulable à tout moment.'**
  String get accountStripeSecurePayment;

  /// No description provided for @accountProductNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Produit Premium introuvable sur le Store.'**
  String get accountProductNotFound;

  /// No description provided for @accountSubscriptionUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement non disponible pour le moment. Réessaie dans quelques instants.'**
  String get accountSubscriptionUnavailable;

  /// No description provided for @accountAlreadyOwnedRestored.
  ///
  /// In fr, this message translates to:
  /// **'Tu possédais déjà TOTUM Premium sur ce compte Google, ton accès a été restauré.'**
  String get accountAlreadyOwnedRestored;

  /// No description provided for @accountUnknownError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue.'**
  String get accountUnknownError;

  /// No description provided for @accountPremiumActivated.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! TOTUM Premium est activé !'**
  String get accountPremiumActivated;

  /// No description provided for @accountActivationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'activation : {error}'**
  String accountActivationError(String error);

  /// No description provided for @accountSubscriptionActivated.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Ton abonnement TOTUM Premium est actif !'**
  String get accountSubscriptionActivated;

  /// No description provided for @accountDeleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get accountDeleteDialogTitle;

  /// No description provided for @accountDeleteDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible : ta demande de suppression sera enregistrée, ton compte et toutes tes données (journal, objectifs, historique de poids) seront supprimés définitivement. Tu seras déconnecté immédiatement.'**
  String get accountDeleteDialogContent;

  /// No description provided for @accountDeletePermanently.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get accountDeletePermanently;

  /// No description provided for @accountDeletingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Suppression…'**
  String get accountDeletingInProgress;

  /// No description provided for @accountDetailsScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountDetailsScreenTitle;

  /// No description provided for @accountEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse courriel'**
  String get accountEmailLabel;

  /// No description provided for @accountSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get accountSignOut;

  /// No description provided for @appearanceScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearanceScreenTitle;

  /// No description provided for @appearanceThemeSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get appearanceThemeSectionTitle;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceTextSizeSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get appearanceTextSizeSectionTitle;

  /// No description provided for @languageUnitsScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue & unités'**
  String get languageUnitsScreenTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languageSectionTitle;

  /// No description provided for @languageSubLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'interface'**
  String get languageSubLabel;

  /// No description provided for @languageSubLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'S\'applique à toute l\'application, y compris les noms d\'aliments dans la recherche et le journal.'**
  String get languageSubLabelHint;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get languageEnglish;

  /// No description provided for @unitsSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Unités de mesure'**
  String get unitsSectionTitle;

  /// No description provided for @unitsSubLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids et taille'**
  String get unitsSubLabel;

  /// No description provided for @unitsSubLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Les calculs internes restent toujours en métrique.'**
  String get unitsSubLabelHint;

  /// No description provided for @dataExportScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get dataExportScreenTitle;

  /// No description provided for @dataExportSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mon journal'**
  String get dataExportSectionTitle;

  /// No description provided for @dataExportDescription.
  ///
  /// In fr, this message translates to:
  /// **'Exporte ton journal alimentaire, tes objectifs et tes micronutriments sur une période, au format HTML (convertible en PDF, ex. pour un professionnel de santé).'**
  String get dataExportDescription;

  /// No description provided for @dataExportPeriodHelpText.
  ///
  /// In fr, this message translates to:
  /// **'Période à exporter'**
  String get dataExportPeriodHelpText;

  /// No description provided for @dataExportSaveText.
  ///
  /// In fr, this message translates to:
  /// **'EXPORTER'**
  String get dataExportSaveText;

  /// No description provided for @dataExportSuccessSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Rapport exporté'**
  String get dataExportSuccessSnackbar;

  /// No description provided for @dataExportErrorSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Erreur export : {error}'**
  String dataExportErrorSnackbar(String error);

  /// No description provided for @dataExportGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération…'**
  String get dataExportGenerating;

  /// No description provided for @dataExportButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get dataExportButton;

  /// No description provided for @aboutScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutScreenTitle;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @activityLevelSedentaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sédentaire'**
  String get activityLevelSedentaryTitle;

  /// No description provided for @activityLevelLightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Légèrement actif'**
  String get activityLevelLightTitle;

  /// No description provided for @activityLevelModerateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modérément actif'**
  String get activityLevelModerateTitle;

  /// No description provided for @activityLevelActiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get activityLevelActiveTitle;

  /// No description provided for @activityLevelVeryActiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Très actif'**
  String get activityLevelVeryActiveTitle;

  /// No description provided for @activityLevelExtremeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Extrêmement actif'**
  String get activityLevelExtremeTitle;

  /// No description provided for @activityLevelSedentaryDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vie plutôt sédentaire (bureau, peu de marche), pas ou très peu de sport.'**
  String get activityLevelSedentaryDesc;

  /// No description provided for @activityLevelLightDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un peu de marche au quotidien, et/ou 1 à 3 séances de sport par semaine.'**
  String get activityLevelLightDesc;

  /// No description provided for @activityLevelModerateDesc.
  ///
  /// In fr, this message translates to:
  /// **'Bonne marche au quotidien (~8 000-10 000 pas), et/ou 3 à 5 séances de sport par semaine.'**
  String get activityLevelModerateDesc;

  /// No description provided for @activityLevelActiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Beaucoup de mouvement au quotidien (métier debout), et/ou sport quasi quotidien (5-6 séances/semaine).'**
  String get activityLevelActiveDesc;

  /// No description provided for @activityLevelVeryActiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Métier physique, et/ou plusieurs séances intenses certains jours (ex. course + muscu le même jour).'**
  String get activityLevelVeryActiveDesc;

  /// No description provided for @activityLevelExtremeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Métier physique intense ET entraînement quasi quotidien à haute intensité (ex. sportif semi-pro).'**
  String get activityLevelExtremeDesc;

  /// No description provided for @bodyFatTierEssential.
  ///
  /// In fr, this message translates to:
  /// **'Essentiel'**
  String get bodyFatTierEssential;

  /// No description provided for @bodyFatTierAthlete.
  ///
  /// In fr, this message translates to:
  /// **'Athlète'**
  String get bodyFatTierAthlete;

  /// No description provided for @bodyFatTierFitness.
  ///
  /// In fr, this message translates to:
  /// **'Fitness'**
  String get bodyFatTierFitness;

  /// No description provided for @bodyFatTierAverage.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get bodyFatTierAverage;

  /// No description provided for @bodyFatTierHigh.
  ///
  /// In fr, this message translates to:
  /// **'Élevé'**
  String get bodyFatTierHigh;

  /// No description provided for @dietStyleBalancedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get dietStyleBalancedTitle;

  /// No description provided for @dietStyleHighCarbTitle.
  ///
  /// In fr, this message translates to:
  /// **'Riche en glucides'**
  String get dietStyleHighCarbTitle;

  /// No description provided for @dietStyleHighFatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Riche en lipides'**
  String get dietStyleHighFatTitle;

  /// No description provided for @dietStyleKetoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cétogène (Keto)'**
  String get dietStyleKetoTitle;

  /// No description provided for @dietStyleBalancedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Répartition de référence (~30 % lipides / ~45 % glucides des calories totales) : la zone associée à la mortalité totale la plus basse dans les grandes études de cohorte, dans les bornes officielles (AMDR).'**
  String get dietStyleBalancedDesc;

  /// No description provided for @dietStyleHighCarbDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lipides ramenés vers le bas de la fourchette recommandée, glucides plus généreux — utile pour les sports d\'endurance à fort volume, sans jamais sortir des bornes officielles.'**
  String get dietStyleHighCarbDesc;

  /// No description provided for @dietStyleHighFatDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lipides plus présents pour qui les préfère (satiété, appétence) — plafonnés à la limite haute recommandée (35 % des calories), jamais au-delà.'**
  String get dietStyleHighFatDesc;

  /// No description provided for @dietStyleKetoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Glucides maintenus très bas, lipides très élevés — approche validée pour certains usages thérapeutiques encadrés (ex. épilepsie), mais dont les effets cardiovasculaires à long terme en population générale restent peu documentés (études majoritairement sur quelques semaines). À utiliser ponctuellement et avec discernement, pas comme réglage par défaut.'**
  String get dietStyleKetoDesc;

  /// No description provided for @profileDietOmnivore.
  ///
  /// In fr, this message translates to:
  /// **'Omnivore'**
  String get profileDietOmnivore;

  /// No description provided for @profileDietVegetarian.
  ///
  /// In fr, this message translates to:
  /// **'Végétarien'**
  String get profileDietVegetarian;

  /// No description provided for @profileDietVegan.
  ///
  /// In fr, this message translates to:
  /// **'Végétalien'**
  String get profileDietVegan;

  /// No description provided for @goalLoseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Perte de gras'**
  String get goalLoseTitle;

  /// No description provided for @goalLoseDesc.
  ///
  /// In fr, this message translates to:
  /// **'Perdre de la masse grasse à un bon rythme, tout en préservant tes muscles et ton énergie.'**
  String get goalLoseDesc;

  /// No description provided for @goalLoseTip1.
  ///
  /// In fr, this message translates to:
  /// **'Garde un bon apport en protéines pour protéger tes muscles'**
  String get goalLoseTip1;

  /// No description provided for @goalLoseTip2.
  ///
  /// In fr, this message translates to:
  /// **'Bouge régulièrement — même une marche quotidienne compte'**
  String get goalLoseTip2;

  /// No description provided for @goalLoseTip3.
  ///
  /// In fr, this message translates to:
  /// **'Dors suffisamment : la récupération fait partie du résultat'**
  String get goalLoseTip3;

  /// No description provided for @goalLoseTip4.
  ///
  /// In fr, this message translates to:
  /// **'Après 8 à 10 semaines, prévois une pause en Maintien'**
  String get goalLoseTip4;

  /// No description provided for @goalLoseCoach.
  ///
  /// In fr, this message translates to:
  /// **'La priorité est de préserver ta masse musculaire pendant que tu perds du gras. TOTUM relève automatiquement ta cible en protéines. Un rythme modéré est plus efficace et bien plus durable qu\'un régime extrême.'**
  String get goalLoseCoach;

  /// No description provided for @goalLoseMildTitle.
  ///
  /// In fr, this message translates to:
  /// **'Perte en douceur'**
  String get goalLoseMildTitle;

  /// No description provided for @goalLoseMildDesc.
  ///
  /// In fr, this message translates to:
  /// **'Perdre du poids progressivement, sans frustration ni coup de fatigue. Idéal pour tenir dans le temps.'**
  String get goalLoseMildDesc;

  /// No description provided for @goalLoseMildTip1.
  ///
  /// In fr, this message translates to:
  /// **'Un déficit léger, plus facile à tenir au quotidien'**
  String get goalLoseMildTip1;

  /// No description provided for @goalLoseMildTip2.
  ///
  /// In fr, this message translates to:
  /// **'Prends soin de ta récupération et de ton sommeil'**
  String get goalLoseMildTip2;

  /// No description provided for @goalLoseMildTip3.
  ///
  /// In fr, this message translates to:
  /// **'Garde de l\'énergie pour tes activités et ta forme'**
  String get goalLoseMildTip3;

  /// No description provided for @goalLoseMildTip4.
  ///
  /// In fr, this message translates to:
  /// **'La régularité compte plus que la vitesse'**
  String get goalLoseMildTip4;

  /// No description provided for @goalLoseMildCoach.
  ///
  /// In fr, this message translates to:
  /// **'Cette approche tout en douceur est parfaite pour perdre du poids sans y penser en permanence. La progression est plus lente, mais c\'est justement ce qui la rend durable : patience et constance sont tes meilleures alliées.'**
  String get goalLoseMildCoach;

  /// No description provided for @goalMaintainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maintien'**
  String get goalMaintainTitle;

  /// No description provided for @goalMaintainDesc.
  ///
  /// In fr, this message translates to:
  /// **'Stabiliser ton poids et te sentir bien, sur la durée.'**
  String get goalMaintainDesc;

  /// No description provided for @goalMaintainTip1.
  ///
  /// In fr, this message translates to:
  /// **'Mange à hauteur de tes besoins, ni plus ni moins'**
  String get goalMaintainTip1;

  /// No description provided for @goalMaintainTip2.
  ///
  /// In fr, this message translates to:
  /// **'Garde une activité physique régulière'**
  String get goalMaintainTip2;

  /// No description provided for @goalMaintainTip3.
  ///
  /// In fr, this message translates to:
  /// **'Conserve un bon apport en protéines'**
  String get goalMaintainTip3;

  /// No description provided for @goalMaintainTip4.
  ///
  /// In fr, this message translates to:
  /// **'Observe ton poids moyen sur la semaine, pas au jour le jour'**
  String get goalMaintainTip4;

  /// No description provided for @goalMaintainCoach.
  ///
  /// In fr, this message translates to:
  /// **'Ton objectif n\'est plus de perdre ou de prendre, mais de conserver tes résultats et de te sentir bien. C\'est la régularité qui ancre les bonnes habitudes sur le long terme — tu es dans la zone de la sérénité.'**
  String get goalMaintainCoach;

  /// No description provided for @goalGainMildTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prise de muscle'**
  String get goalGainMildTitle;

  /// No description provided for @goalGainMildDesc.
  ///
  /// In fr, this message translates to:
  /// **'Développer tes muscles progressivement, avec une prise de gras maîtrisée.'**
  String get goalGainMildDesc;

  /// No description provided for @goalGainMildTip1.
  ///
  /// In fr, this message translates to:
  /// **'Un léger surplus, juste ce qu\'il faut pour construire'**
  String get goalGainMildTip1;

  /// No description provided for @goalGainMildTip2.
  ///
  /// In fr, this message translates to:
  /// **'Associe à une activité de renforcement si tu le peux'**
  String get goalGainMildTip2;

  /// No description provided for @goalGainMildTip3.
  ///
  /// In fr, this message translates to:
  /// **'Un bon apport en protéines soutient tes muscles'**
  String get goalGainMildTip3;

  /// No description provided for @goalGainMildTip4.
  ///
  /// In fr, this message translates to:
  /// **'Un sommeil de qualité accélère les progrès'**
  String get goalGainMildTip4;

  /// No description provided for @goalGainMildCoach.
  ///
  /// In fr, this message translates to:
  /// **'Une progression lente et maîtrisée donne un bien meilleur ratio muscle/graisse qu\'une prise rapide. Inutile de forcer : la qualité prime sur la quantité, et ton corps te remerciera.'**
  String get goalGainMildCoach;

  /// No description provided for @goalGainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prise de masse'**
  String get goalGainTitle;

  /// No description provided for @goalGainDesc.
  ///
  /// In fr, this message translates to:
  /// **'Maximiser ta prise de muscle et de force, pour les objectifs les plus ambitieux.'**
  String get goalGainDesc;

  /// No description provided for @goalGainTip1.
  ///
  /// In fr, this message translates to:
  /// **'Un surplus plus marqué pour soutenir la construction'**
  String get goalGainTip1;

  /// No description provided for @goalGainTip2.
  ///
  /// In fr, this message translates to:
  /// **'Idéal si tu t\'entraînes intensément et régulièrement'**
  String get goalGainTip2;

  /// No description provided for @goalGainTip3.
  ///
  /// In fr, this message translates to:
  /// **'Une bonne récupération est essentielle'**
  String get goalGainTip3;

  /// No description provided for @goalGainTip4.
  ///
  /// In fr, this message translates to:
  /// **'Surveille ton évolution pour rester sur la bonne voie'**
  String get goalGainTip4;

  /// No description provided for @goalGainCoach.
  ///
  /// In fr, this message translates to:
  /// **'Ce mode est fait pour les objectifs ambitieux. Contrôle régulièrement ton évolution pour éviter une prise de graisse superflue : un surplus maîtrisé donne toujours de meilleurs résultats qu\'un excès non suivi.'**
  String get goalGainCoach;

  /// No description provided for @profileMaintainDynamic.
  ///
  /// In fr, this message translates to:
  /// **'Maintien dynamique'**
  String get profileMaintainDynamic;

  /// No description provided for @profileEquilibrium.
  ///
  /// In fr, this message translates to:
  /// **'Équilibre'**
  String get profileEquilibrium;

  /// No description provided for @profileTargetedRateNeg.
  ///
  /// In fr, this message translates to:
  /// **'Rythme visé : −{pct} %/sem'**
  String profileTargetedRateNeg(String pct);

  /// No description provided for @profileTargetedRatePos.
  ///
  /// In fr, this message translates to:
  /// **'Rythme visé : +{pct} %/sem'**
  String profileTargetedRatePos(String pct);

  /// No description provided for @profileMacroCoherenceOver.
  ///
  /// In fr, this message translates to:
  /// **'Tes macros représentent {computed} kcal — {diff} kcal ({pct} %) DE PLUS que les {kcal} kcal indiquées.'**
  String profileMacroCoherenceOver(
      String computed, String diff, String pct, String kcal);

  /// No description provided for @profileMacroCoherenceUnder.
  ///
  /// In fr, this message translates to:
  /// **'Tes macros représentent {computed} kcal — {diff} kcal ({pct} %) DE MOINS que les {kcal} kcal indiquées.'**
  String profileMacroCoherenceUnder(
      String computed, String diff, String pct, String kcal);

  /// No description provided for @profileGoalsUpdatedSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs mis à jour · {kcal} kcal par jour'**
  String profileGoalsUpdatedSnackbar(int kcal);

  /// No description provided for @profileConfirmGoals.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer mes objectifs'**
  String get profileConfirmGoals;

  /// No description provided for @profileGoalsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs enregistrés'**
  String get profileGoalsSaved;

  /// No description provided for @profileBackToAuto.
  ///
  /// In fr, this message translates to:
  /// **'Revenir au calcul automatique'**
  String get profileBackToAuto;

  /// No description provided for @profileCustomizeGoals.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser mes objectifs'**
  String get profileCustomizeGoals;

  /// No description provided for @profileFullDetailFooter.
  ///
  /// In fr, this message translates to:
  /// **'Le détail complet (vitamines, minéraux, acides gras) se calcule automatiquement dans l\'onglet Bilan.'**
  String get profileFullDetailFooter;

  /// No description provided for @profileTodayEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'AUJOURD\'HUI'**
  String get profileTodayEyebrow;

  /// No description provided for @profileKcalOver.
  ///
  /// In fr, this message translates to:
  /// **'kcal dépassé'**
  String get profileKcalOver;

  /// No description provided for @profileKcalRemaining.
  ///
  /// In fr, this message translates to:
  /// **'kcal restant'**
  String get profileKcalRemaining;

  /// No description provided for @profileBaseGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif de base'**
  String get profileBaseGoal;

  /// No description provided for @profileFoodsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aliments'**
  String get profileFoodsLabel;

  /// No description provided for @profileRefinedByResults.
  ///
  /// In fr, this message translates to:
  /// **'Affiné selon tes résultats réels'**
  String get profileRefinedByResults;

  /// No description provided for @profileMacroGramsOver.
  ///
  /// In fr, this message translates to:
  /// **'+{amount} g dépassé'**
  String profileMacroGramsOver(int amount);

  /// No description provided for @profileMacroGramsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{amount} g restants'**
  String profileMacroGramsRemaining(int amount);

  /// No description provided for @profileMacronutrients.
  ///
  /// In fr, this message translates to:
  /// **'Macronutriments'**
  String get profileMacronutrients;

  /// No description provided for @profileCarbs.
  ///
  /// In fr, this message translates to:
  /// **'Glucides'**
  String get profileCarbs;

  /// No description provided for @profileFats.
  ///
  /// In fr, this message translates to:
  /// **'Lipides'**
  String get profileFats;

  /// No description provided for @profileProteins.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get profileProteins;

  /// No description provided for @profilePlateToday.
  ///
  /// In fr, this message translates to:
  /// **'Ton assiette aujourd\'hui'**
  String get profilePlateToday;

  /// No description provided for @profilePlateGoal.
  ///
  /// In fr, this message translates to:
  /// **'Ton assiette (objectif)'**
  String get profilePlateGoal;

  /// No description provided for @profileMicronutrientsFeatured.
  ///
  /// In fr, this message translates to:
  /// **'Micronutriments en vedette'**
  String get profileMicronutrientsFeatured;

  /// No description provided for @profileGoalTileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get profileGoalTileLabel;

  /// No description provided for @profileMeasuresTileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mesures'**
  String get profileMeasuresTileLabel;

  /// No description provided for @profileActivityLevelTileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'activité'**
  String get profileActivityLevelTileLabel;

  /// No description provided for @profileDietTileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Régime alimentaire'**
  String get profileDietTileLabel;

  /// No description provided for @profileMacroSplitTileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des macros'**
  String get profileMacroSplitTileLabel;

  /// No description provided for @profileDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get profileDone;

  /// No description provided for @profileImpactChanged.
  ///
  /// In fr, this message translates to:
  /// **'Impact sur ton objectif : {before} → {after} kcal ({diff})'**
  String profileImpactChanged(int before, int after, String diff);

  /// No description provided for @profileImpactUnchanged.
  ///
  /// In fr, this message translates to:
  /// **'Objectif actuel : {after} kcal'**
  String profileImpactUnchanged(int after);

  /// No description provided for @profileYourGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton objectif'**
  String get profileYourGoalTitle;

  /// No description provided for @profileToRemember.
  ///
  /// In fr, this message translates to:
  /// **'À retenir'**
  String get profileToRemember;

  /// No description provided for @profileCoachAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Conseil du coach'**
  String get profileCoachAdvice;

  /// No description provided for @profileMeasuresSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes mesures'**
  String get profileMeasuresSheetTitle;

  /// No description provided for @profileMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get profileMale;

  /// No description provided for @profileFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get profileFemale;

  /// No description provided for @profileAgeYears.
  ///
  /// In fr, this message translates to:
  /// **'Âge (ans)'**
  String get profileAgeYears;

  /// No description provided for @profileHeightCm.
  ///
  /// In fr, this message translates to:
  /// **'Taille (cm)'**
  String get profileHeightCm;

  /// No description provided for @profileHeightIn.
  ///
  /// In fr, this message translates to:
  /// **'Taille (in)'**
  String get profileHeightIn;

  /// No description provided for @profileWeightKg.
  ///
  /// In fr, this message translates to:
  /// **'Poids (kg)'**
  String get profileWeightKg;

  /// No description provided for @profileWeightLb.
  ///
  /// In fr, this message translates to:
  /// **'Poids (lb)'**
  String get profileWeightLb;

  /// No description provided for @profileWeighInAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Pèse-toi si possible tous les jours, dans les mêmes conditions à chaque fois — idéalement le matin à jeun, au lever.'**
  String get profileWeighInAdvice;

  /// No description provided for @profileTargetWeightKg.
  ///
  /// In fr, this message translates to:
  /// **'Poids cible (kg) — optionnel'**
  String get profileTargetWeightKg;

  /// No description provided for @profileTargetWeightLb.
  ///
  /// In fr, this message translates to:
  /// **'Poids cible (lb) — optionnel'**
  String get profileTargetWeightLb;

  /// No description provided for @profileTargetWeightHint.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé uniquement pour l\'objectif Maintien : une fois proche de ta cible, tes calories suivent ta dépense réelle ; si tu t\'en éloignes, un léger ajustement automatique t\'y ramène doucement.'**
  String get profileTargetWeightHint;

  /// No description provided for @profileBodyFatOptional.
  ///
  /// In fr, this message translates to:
  /// **'Masse grasse — optionnel'**
  String get profileBodyFatOptional;

  /// No description provided for @profileBodyFatHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisis la plage la plus proche de ta silhouette actuelle.'**
  String get profileBodyFatHint;

  /// No description provided for @profileActivitySheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau d\'activité'**
  String get profileActivitySheetTitle;

  /// No description provided for @profileActivitySheetDesc.
  ///
  /// In fr, this message translates to:
  /// **'Choisis la description la plus proche de TA semaine type — quotidien ET sport confondus, l\'un ou l\'autre suffit à te situer dans un palier.'**
  String get profileActivitySheetDesc;

  /// No description provided for @profileMacroSplitSheetDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ne change ni tes calories ni tes protéines — seulement comment le reste se répartit entre lipides et glucides.'**
  String get profileMacroSplitSheetDesc;

  /// No description provided for @profileInvalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get profileInvalidNumber;

  /// No description provided for @profileYourEvolution.
  ///
  /// In fr, this message translates to:
  /// **'Ton évolution'**
  String get profileYourEvolution;

  /// No description provided for @profileLast60Days.
  ///
  /// In fr, this message translates to:
  /// **'60 derniers jours'**
  String get profileLast60Days;

  /// No description provided for @profileAdaptiveEstimate.
  ///
  /// In fr, this message translates to:
  /// **'estimation adaptative'**
  String get profileAdaptiveEstimate;

  /// No description provided for @profileCustomGoalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes objectifs personnalisés'**
  String get profileCustomGoalsTitle;

  /// No description provided for @profileCustomGoalsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ces valeurs remplacent le calcul automatique.'**
  String get profileCustomGoalsSubtitle;

  /// No description provided for @profileEnergyKcal.
  ///
  /// In fr, this message translates to:
  /// **'Énergie (kcal)'**
  String get profileEnergyKcal;

  /// No description provided for @profileProteinG.
  ///
  /// In fr, this message translates to:
  /// **'Protéines (g)'**
  String get profileProteinG;

  /// No description provided for @profileCarbG.
  ///
  /// In fr, this message translates to:
  /// **'Glucides (g)'**
  String get profileCarbG;

  /// No description provided for @profileFatG.
  ///
  /// In fr, this message translates to:
  /// **'Lipides (g)'**
  String get profileFatG;

  /// No description provided for @profileFiberG.
  ///
  /// In fr, this message translates to:
  /// **'Fibres (g)'**
  String get profileFiberG;

  /// No description provided for @profileApplyGoals.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer mes objectifs'**
  String get profileApplyGoals;

  /// No description provided for @nutrientEnergy.
  ///
  /// In fr, this message translates to:
  /// **'Énergie'**
  String get nutrientEnergy;

  /// No description provided for @nutrientProtein.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get nutrientProtein;

  /// No description provided for @nutrientCarbs.
  ///
  /// In fr, this message translates to:
  /// **'Glucides'**
  String get nutrientCarbs;

  /// No description provided for @nutrientFat.
  ///
  /// In fr, this message translates to:
  /// **'Lipides'**
  String get nutrientFat;

  /// No description provided for @nutrientFiber.
  ///
  /// In fr, this message translates to:
  /// **'Fibres'**
  String get nutrientFiber;

  /// No description provided for @nutrientOmega9.
  ///
  /// In fr, this message translates to:
  /// **'Oméga 9 (Oléique)'**
  String get nutrientOmega9;

  /// No description provided for @nutrientOmega6.
  ///
  /// In fr, this message translates to:
  /// **'Oméga 6 (LA)'**
  String get nutrientOmega6;

  /// No description provided for @nutrientOmega3.
  ///
  /// In fr, this message translates to:
  /// **'Oméga 3 (ALA)'**
  String get nutrientOmega3;

  /// No description provided for @nutrientSatFat.
  ///
  /// In fr, this message translates to:
  /// **'AG saturés'**
  String get nutrientSatFat;

  /// No description provided for @nutrientSugars.
  ///
  /// In fr, this message translates to:
  /// **'Sucres'**
  String get nutrientSugars;

  /// No description provided for @nutrientSalt.
  ///
  /// In fr, this message translates to:
  /// **'Sel'**
  String get nutrientSalt;

  /// No description provided for @nutrientAlcohol.
  ///
  /// In fr, this message translates to:
  /// **'Alcool'**
  String get nutrientAlcohol;

  /// No description provided for @nutrientRetinol.
  ///
  /// In fr, this message translates to:
  /// **'Rétinol'**
  String get nutrientRetinol;

  /// No description provided for @nutrientBetaCarotene.
  ///
  /// In fr, this message translates to:
  /// **'Bêta-car.'**
  String get nutrientBetaCarotene;

  /// No description provided for @nutrientCopper.
  ///
  /// In fr, this message translates to:
  /// **'Cuivre'**
  String get nutrientCopper;

  /// No description provided for @nutrientIron.
  ///
  /// In fr, this message translates to:
  /// **'Fer'**
  String get nutrientIron;

  /// No description provided for @nutrientIodine.
  ///
  /// In fr, this message translates to:
  /// **'Iode'**
  String get nutrientIodine;

  /// No description provided for @nutrientMagnesium.
  ///
  /// In fr, this message translates to:
  /// **'Magnésium'**
  String get nutrientMagnesium;

  /// No description provided for @nutrientManganese.
  ///
  /// In fr, this message translates to:
  /// **'Manganèse'**
  String get nutrientManganese;

  /// No description provided for @nutrientPhosphorus.
  ///
  /// In fr, this message translates to:
  /// **'Phosphore'**
  String get nutrientPhosphorus;

  /// No description provided for @nutrientSelenium.
  ///
  /// In fr, this message translates to:
  /// **'Sélénium'**
  String get nutrientSelenium;

  /// No description provided for @nutrientCholesterol.
  ///
  /// In fr, this message translates to:
  /// **'Cholestérol'**
  String get nutrientCholesterol;

  /// No description provided for @nutrientVitaminDFull.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine D'**
  String get nutrientVitaminDFull;

  /// No description provided for @nutrientVitaminCFull.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine C'**
  String get nutrientVitaminCFull;

  /// No description provided for @nutrientVitaminKFull.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine K'**
  String get nutrientVitaminKFull;

  /// No description provided for @nutrientVitaminB9Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B9'**
  String get nutrientVitaminB9Full;

  /// No description provided for @nutrientVitaminB12Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B12'**
  String get nutrientVitaminB12Full;

  /// No description provided for @nutrientOmega3Marine.
  ///
  /// In fr, this message translates to:
  /// **'Oméga 3 marins'**
  String get nutrientOmega3Marine;

  /// No description provided for @moodExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellent équilibre !'**
  String get moodExcellent;

  /// No description provided for @moodGood.
  ///
  /// In fr, this message translates to:
  /// **'Bon équilibre'**
  String get moodGood;

  /// No description provided for @moodCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Correct, peut mieux faire'**
  String get moodCorrect;

  /// No description provided for @moodToImprove.
  ///
  /// In fr, this message translates to:
  /// **'À améliorer'**
  String get moodToImprove;

  /// No description provided for @moodRebalance.
  ///
  /// In fr, this message translates to:
  /// **'Journée à rééquilibrer'**
  String get moodRebalance;

  /// No description provided for @scorePillarVitamins.
  ///
  /// In fr, this message translates to:
  /// **'Vitamines'**
  String get scorePillarVitamins;

  /// No description provided for @scorePillarMinerals.
  ///
  /// In fr, this message translates to:
  /// **'Minéraux'**
  String get scorePillarMinerals;

  /// No description provided for @scorePillarFattyAcids.
  ///
  /// In fr, this message translates to:
  /// **'Acides gras'**
  String get scorePillarFattyAcids;

  /// No description provided for @scorePillarHydration.
  ///
  /// In fr, this message translates to:
  /// **'Hydratation'**
  String get scorePillarHydration;

  /// No description provided for @scorePillarWatch.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get scorePillarWatch;

  /// No description provided for @scoreCapReason.
  ///
  /// In fr, this message translates to:
  /// **'{label} à {pct} % de ta cible du jour — la note est plafonnée tant que ça dure.'**
  String scoreCapReason(String label, int pct);

  /// No description provided for @bilanScoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Score TOTUM'**
  String get bilanScoreTitle;

  /// No description provided for @bilanScoreUpdatesLive.
  ///
  /// In fr, this message translates to:
  /// **'Se met à jour à chaque repas ajouté'**
  String get bilanScoreUpdatesLive;

  /// No description provided for @bilanScoreHowCalculated.
  ///
  /// In fr, this message translates to:
  /// **'Comment est calculée cette note ?'**
  String get bilanScoreHowCalculated;

  /// No description provided for @bilanSafetyLimitExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Limite de sécurité dépassée : {list}'**
  String bilanSafetyLimitExceeded(String list);

  /// No description provided for @bilanUnderstandLabel.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre : {label}'**
  String bilanUnderstandLabel(String label);

  /// No description provided for @bilanWhyLimitExists.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi cette limite existe'**
  String get bilanWhyLimitExists;

  /// No description provided for @bilanExcessConsequences.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'un excès prolongé peut provoquer'**
  String get bilanExcessConsequences;

  /// No description provided for @bilanExcessSource.
  ///
  /// In fr, this message translates to:
  /// **'D\'où vient le dépassement'**
  String get bilanExcessSource;

  /// No description provided for @bilanWhatToDo.
  ///
  /// In fr, this message translates to:
  /// **'Que faire concrètement'**
  String get bilanWhatToDo;

  /// No description provided for @bilanSafetyLimitDetail.
  ///
  /// In fr, this message translates to:
  /// **'Limite de sécurité : {limite}  ·  {reference}'**
  String bilanSafetyLimitDetail(String limite, String reference);

  /// No description provided for @bilanConcernedFoods.
  ///
  /// In fr, this message translates to:
  /// **'Les aliments concernés {periode}'**
  String bilanConcernedFoods(String periode);

  /// No description provided for @bilanNoFoodIdentifiedPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucun aliment identifié sur cette période.'**
  String get bilanNoFoodIdentifiedPeriod;

  /// No description provided for @bilanPeriodToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get bilanPeriodToday;

  /// No description provided for @bilanPeriodThatDay.
  ///
  /// In fr, this message translates to:
  /// **'ce jour-là'**
  String get bilanPeriodThatDay;

  /// No description provided for @bilanPeriodLastNDays.
  ///
  /// In fr, this message translates to:
  /// **'sur les {days} derniers jours'**
  String bilanPeriodLastNDays(int days);

  /// No description provided for @bilanPeriodOnDate.
  ///
  /// In fr, this message translates to:
  /// **'le {date}'**
  String bilanPeriodOnDate(String date);

  /// No description provided for @bilanCarbBreakdownTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des glucides'**
  String get bilanCarbBreakdownTitle;

  /// No description provided for @bilanCarbBreakdownIntro.
  ///
  /// In fr, this message translates to:
  /// **'Tous les glucides ne se valent pas. L\'amidon libère son énergie lentement ; les sucres simples, rapidement.'**
  String get bilanCarbBreakdownIntro;

  /// No description provided for @bilanNoCarbDataPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de glucides détaillée pour cette période.'**
  String get bilanNoCarbDataPeriod;

  /// No description provided for @bilanStarchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Amidon (glucides complexes)'**
  String get bilanStarchLabel;

  /// No description provided for @bilanStarchHint.
  ///
  /// In fr, this message translates to:
  /// **'Céréales, légumineuses, tubercules — énergie durable.'**
  String get bilanStarchHint;

  /// No description provided for @bilanSimpleSugarsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sucres simples (total)'**
  String get bilanSimpleSugarsLabel;

  /// No description provided for @bilanSimpleSugarsHint.
  ///
  /// In fr, this message translates to:
  /// **'Assimilation rapide — à privilégier via les fruits entiers.'**
  String get bilanSimpleSugarsHint;

  /// No description provided for @bilanPolyolsHint.
  ///
  /// In fr, this message translates to:
  /// **'Édulcorants de masse — souvent signe d\'un produit transformé.'**
  String get bilanPolyolsHint;

  /// No description provided for @bilanSimpleSugarsDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail des sucres simples'**
  String get bilanSimpleSugarsDetailTitle;

  /// No description provided for @bilanFructoseHint.
  ///
  /// In fr, this message translates to:
  /// **'Sucre des fruits et du miel.'**
  String get bilanFructoseHint;

  /// No description provided for @bilanSaccharoseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Saccharose'**
  String get bilanSaccharoseLabel;

  /// No description provided for @bilanSaccharoseHint.
  ///
  /// In fr, this message translates to:
  /// **'Le sucre de table (fructose + glucose).'**
  String get bilanSaccharoseHint;

  /// No description provided for @bilanLactoseHint.
  ///
  /// In fr, this message translates to:
  /// **'Sucre du lait et des produits laitiers.'**
  String get bilanLactoseHint;

  /// No description provided for @bilanFruitVsSodaNote.
  ///
  /// In fr, this message translates to:
  /// **'Un fruit entier et un soda peuvent contenir le même fructose, mais le fruit l\'accompagne de fibres, d\'eau et de vitamines qui en ralentissent l\'absorption. La matrice compte autant que le sucre.'**
  String get bilanFruitVsSodaNote;

  /// No description provided for @dietNoteOmega3NoFish.
  ///
  /// In fr, this message translates to:
  /// **'Sans poisson, ta meilleure source directe d\'EPA/DHA est un complément d\'oméga 3 issu de micro-algues — c\'est justement là que les poissons puisent les leurs. Les oméga 3 végétaux (ALA du lin, chanvre, noix) restent utiles mais se convertissent mal en EPA/DHA.'**
  String get dietNoteOmega3NoFish;

  /// No description provided for @dietNoteB12Vegan.
  ///
  /// In fr, this message translates to:
  /// **'La vitamine B12 n\'existe pas dans le végétal : en régime végétalien, une supplémentation est indispensable, pas optionnelle. C\'est le seul nutriment qui fait consensus absolu sur ce point. Vise une prise régulière et surveille ton statut par une prise de sang.'**
  String get dietNoteB12Vegan;

  /// No description provided for @dietNoteB12Vegetarian.
  ///
  /// In fr, this message translates to:
  /// **'En régime végétarien, les œufs et les produits laitiers couvrent une partie de tes besoins en B12, mais surveille ton statut : selon ta consommation, une supplémentation légère peut être utile.'**
  String get dietNoteB12Vegetarian;

  /// No description provided for @dietNoteIronVegetal.
  ///
  /// In fr, this message translates to:
  /// **'Le fer végétal (non héminique) s\'absorbe moins bien que le fer animal : associe systématiquement une source de vitamine C (citron, poivron, persil) à tes légumineuses et céréales complètes pour en multiplier l\'absorption. Évite thé et café pendant le repas.'**
  String get dietNoteIronVegetal;

  /// No description provided for @dietNoteZincVegetal.
  ///
  /// In fr, this message translates to:
  /// **'Les phytates des céréales et légumineuses freinent l\'absorption du zinc végétal. Le trempage, la germination et la fermentation (pain au levain) les neutralisent en grande partie — un réflexe précieux en régime végétal.'**
  String get dietNoteZincVegetal;

  /// No description provided for @dietNoteCalciumVegan.
  ///
  /// In fr, this message translates to:
  /// **'Sans produits laitiers, mise sur les végétaux riches en calcium bien absorbé (chou kale, brocoli, tofu au sulfate de calcium, amandes) et les eaux minérales calciques. La vitamine D et la K2 restent essentielles pour bien le fixer sur l\'os.'**
  String get dietNoteCalciumVegan;

  /// No description provided for @dietNoteIodineVegan.
  ///
  /// In fr, this message translates to:
  /// **'Sans produits de la mer ni laitages, l\'iode peut manquer en régime végétalien : les algues (avec modération, car très concentrées) et le sel iodé sont tes principales sources. Surveille cet apport souvent négligé.'**
  String get dietNoteIodineVegan;

  /// No description provided for @dietNoteVitDVegan.
  ///
  /// In fr, this message translates to:
  /// **'Sans poisson gras ni œufs, l\'alimentation couvre difficilement la vitamine D en régime végétalien : le soleil (voir la page dédiée) et une supplémentation, idéalement d\'origine végétale (lichen), sont à privilégier, surtout d\'octobre à avril.'**
  String get dietNoteVitDVegan;

  /// No description provided for @dietNoteProteinVegan.
  ///
  /// In fr, this message translates to:
  /// **'En régime végétalien, varie tes sources de protéines dans la journée (légumineuses + céréales complètes, tofu, tempeh, oléagineux) pour obtenir tous les acides aminés essentiels. La complémentarité sur la journée suffit, pas besoin de tout combiner à chaque repas.'**
  String get dietNoteProteinVegan;

  /// No description provided for @bilanFicheUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Fiche non disponible pour le moment.'**
  String get bilanFicheUnavailable;

  /// No description provided for @bilanFicheBenefits.
  ///
  /// In fr, this message translates to:
  /// **'Bénéfices santé'**
  String get bilanFicheBenefits;

  /// No description provided for @bilanFicheIntakes.
  ///
  /// In fr, this message translates to:
  /// **'Apports conseillés'**
  String get bilanFicheIntakes;

  /// No description provided for @bilanFicheSafetyLimit.
  ///
  /// In fr, this message translates to:
  /// **'Limite de sécurité'**
  String get bilanFicheSafetyLimit;

  /// No description provided for @bilanFicheWhereToFind.
  ///
  /// In fr, this message translates to:
  /// **'Où en trouver'**
  String get bilanFicheWhereToFind;

  /// No description provided for @bilanDietAdaptedVegan.
  ///
  /// In fr, this message translates to:
  /// **'Adapté à ton régime végétalien'**
  String get bilanDietAdaptedVegan;

  /// No description provided for @bilanDietAdaptedVegetarian.
  ///
  /// In fr, this message translates to:
  /// **'Adapté à ton régime végétarien'**
  String get bilanDietAdaptedVegetarian;

  /// No description provided for @bilanDidYouKnow.
  ///
  /// In fr, this message translates to:
  /// **'Le savais-tu ?'**
  String get bilanDidYouKnow;

  /// No description provided for @bilanEducationalDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Informations éducatives basées sur les références ANSES et EFSA. Elles ne remplacent pas un avis médical personnalisé.'**
  String get bilanEducationalDisclaimer;

  /// No description provided for @bilanScoreExplainerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment est calculée ta note ?'**
  String get bilanScoreExplainerTitle;

  /// No description provided for @bilanScoreExplainerIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le Score TOTUM combine 5 piliers de ta journée, pondérés selon leur importance pour ta santé, ta longévité et ta performance :'**
  String get bilanScoreExplainerIntro;

  /// No description provided for @bilanPillarFattyAcidsFull.
  ///
  /// In fr, this message translates to:
  /// **'Acides gras essentiels'**
  String get bilanPillarFattyAcidsFull;

  /// No description provided for @bilanPillarVitaminsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Couverture de tes besoins en vitamines par rapport à tes objectifs du jour.'**
  String get bilanPillarVitaminsDetail;

  /// No description provided for @bilanPillarMineralsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Couverture de tes besoins en minéraux (fer, magnésium, zinc...).'**
  String get bilanPillarMineralsDetail;

  /// No description provided for @bilanPillarFattyAcidsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-3/6/9 — indispensables, non fabriqués par le corps.'**
  String get bilanPillarFattyAcidsDetail;

  /// No description provided for @bilanPillarHydrationDetail.
  ///
  /// In fr, this message translates to:
  /// **'Eau bue + eau apportée par les aliments, vs ton objectif.'**
  String get bilanPillarHydrationDetail;

  /// No description provided for @bilanPillarWatchDetail.
  ///
  /// In fr, this message translates to:
  /// **'Sucres, sel, graisses saturées — rester sous la limite du jour est le bon signal.'**
  String get bilanPillarWatchDetail;

  /// No description provided for @bilanSafetyCapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le plafond de sécurité'**
  String get bilanSafetyCapTitle;

  /// No description provided for @bilanSafetyCapExplainer.
  ///
  /// In fr, this message translates to:
  /// **'Si un seul élément \"à surveiller\" dépasse fortement ta limite du jour (par exemple bien au-delà du double), ta note est automatiquement plafonnée — même si tout le reste de ta journée est parfait. Un excès important d\'un coup a un vrai impact sur ta santé (cœur, tension), la note doit le montrer clairement, pas le diluer dans une moyenne.'**
  String get bilanSafetyCapExplainer;

  /// No description provided for @bilanScoreLiveNote.
  ///
  /// In fr, this message translates to:
  /// **'Ta note évolue au fil de la journée, à mesure que tu ajoutes tes repas — c\'est normal, elle reflète ce que tu as réellement mangé jusqu\'ici.'**
  String get bilanScoreLiveNote;

  /// No description provided for @bilanScoreSourcesNote.
  ///
  /// In fr, this message translates to:
  /// **'Fondé sur les recommandations officielles (OMS, EFSA, ANSES) et les index de référence internationaux (Healthy Eating Index, Alternate Healthy Eating Index).'**
  String get bilanScoreSourcesNote;

  /// No description provided for @bilanSunVitDTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine D solaire'**
  String get bilanSunVitDTitle;

  /// No description provided for @bilanSunVitDAverageDesc.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne estimée {periode}, synthétisée par ta peau au soleil'**
  String bilanSunVitDAverageDesc(String periode);

  /// No description provided for @bilanSunVitDSingleDesc.
  ///
  /// In fr, this message translates to:
  /// **'Estimée {periode}, synthétisée par ta peau au soleil'**
  String bilanSunVitDSingleDesc(String periode);

  /// No description provided for @bilanSunVitDAlreadyCounted.
  ///
  /// In fr, this message translates to:
  /// **'déjà comptés dans ta ligne \"Vit D\" ci-dessus, en plus de ce que t\'apporte l\'alimentation.'**
  String get bilanSunVitDAlreadyCounted;

  /// No description provided for @bilanSunVitDNoSession.
  ///
  /// In fr, this message translates to:
  /// **'Aucune session au soleil enregistrée sur cette période — seule la part alimentaire est comptée pour l\'instant.'**
  String get bilanSunVitDNoSession;

  /// No description provided for @bilanLogSunExposure.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une exposition au soleil'**
  String get bilanLogSunExposure;

  /// No description provided for @bilanConsumedPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as consommé {periode}'**
  String bilanConsumedPeriod(String periode);

  /// No description provided for @bilanNoFoodContainedNutrient.
  ///
  /// In fr, this message translates to:
  /// **'Aucun aliment consommé ne contenait ce nutriment sur cette période. C\'est peut-être là qu\'il faut agir : consulte la fiche pour savoir où le trouver.'**
  String get bilanNoFoodContainedNutrient;

  /// No description provided for @bilanUnnamedFood.
  ///
  /// In fr, this message translates to:
  /// **'Aliment'**
  String get bilanUnnamedFood;

  /// No description provided for @bilanIntakeMainFoods.
  ///
  /// In fr, this message translates to:
  /// **'Apport en {label} : aliments principaux'**
  String bilanIntakeMainFoods(String label);

  /// No description provided for @bilanTopContributorsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Voici les aliments qui ont le plus contribué à ton apport en {label} ce jour-là, du plus grand au plus petit.'**
  String bilanTopContributorsIntro(String label);

  /// No description provided for @bilanNoFoodIdentifiedNutrient.
  ///
  /// In fr, this message translates to:
  /// **'Aucun aliment identifié pour ce nutriment.'**
  String get bilanNoFoodIdentifiedNutrient;

  /// No description provided for @bilanOccasionalExcessNote.
  ///
  /// In fr, this message translates to:
  /// **'Un dépassement ponctuel n\'est généralement pas préoccupant. Si cela se répète souvent, tu peux espacer les aliments les plus concentrés ou en réduire la portion.'**
  String get bilanOccasionalExcessNote;

  /// No description provided for @bilanDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bilan du {date}'**
  String bilanDayTitle(String date);

  /// No description provided for @bilanNoDataForDay.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour ce jour.'**
  String get bilanNoDataForDay;

  /// No description provided for @bilanMacrosCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Macros'**
  String get bilanMacrosCardTitle;

  /// No description provided for @bilanGroupMacroTargets.
  ///
  /// In fr, this message translates to:
  /// **'Macro-cibles'**
  String get bilanGroupMacroTargets;

  /// No description provided for @bilanGroupIndicative.
  ///
  /// In fr, this message translates to:
  /// **'Apports indicatifs'**
  String get bilanGroupIndicative;

  /// No description provided for @bilanTargetKcal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif = {target} kcal'**
  String bilanTargetKcal(String target);

  /// No description provided for @bilanConsumedKcal.
  ///
  /// In fr, this message translates to:
  /// **'Consommé = {value} kcal'**
  String bilanConsumedKcal(String value);

  /// No description provided for @bilanRemainingKcal.
  ///
  /// In fr, this message translates to:
  /// **'Restant = {value} kcal'**
  String bilanRemainingKcal(String value);

  /// No description provided for @bilanExceededByKcal.
  ///
  /// In fr, this message translates to:
  /// **'Dépassé de {value} kcal'**
  String bilanExceededByKcal(String value);

  /// No description provided for @bilanMacroProgressOvershot.
  ///
  /// In fr, this message translates to:
  /// **'{value} / {target} {unit} • dépassé de {excess} {unit}'**
  String bilanMacroProgressOvershot(
      String value, String target, String unit, String excess);

  /// No description provided for @bilanMacroProgressRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{value} / {target} {unit} • reste {remaining} {unit}'**
  String bilanMacroProgressRemaining(
      String value, String target, String unit, String remaining);

  /// No description provided for @bilanExceedsSafetyLimit.
  ///
  /// In fr, this message translates to:
  /// **'Dépasse la limite de sécurité ({ul} {unit}/jour)'**
  String bilanExceedsSafetyLimit(String ul, String unit);

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get navDashboard;

  /// No description provided for @navJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navBilan.
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get navBilan;

  /// No description provided for @navConseils.
  ///
  /// In fr, this message translates to:
  /// **'Conseils'**
  String get navConseils;

  /// No description provided for @bilanGeneratingReport.
  ///
  /// In fr, this message translates to:
  /// **'Génération du rapport…'**
  String get bilanGeneratingReport;

  /// No description provided for @bilanNoDataToDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée à afficher.'**
  String get bilanNoDataToDisplay;

  /// No description provided for @bilanSpanDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get bilanSpanDay;

  /// No description provided for @bilanSpan7d.
  ///
  /// In fr, this message translates to:
  /// **'7 j'**
  String get bilanSpan7d;

  /// No description provided for @bilanSpan30d.
  ///
  /// In fr, this message translates to:
  /// **'30 j'**
  String get bilanSpan30d;

  /// No description provided for @bilanSpan90d.
  ///
  /// In fr, this message translates to:
  /// **'90 j'**
  String get bilanSpan90d;

  /// No description provided for @bilanEnergyBalance7d.
  ///
  /// In fr, this message translates to:
  /// **'Ton équilibre énergétique (7 jours)'**
  String get bilanEnergyBalance7d;

  /// No description provided for @bilanEnergyBalance30d.
  ///
  /// In fr, this message translates to:
  /// **'Ton équilibre énergétique (30 jours)'**
  String get bilanEnergyBalance30d;

  /// No description provided for @bilanEnergyBalance90d.
  ///
  /// In fr, this message translates to:
  /// **'Ton équilibre énergétique (90 jours)'**
  String get bilanEnergyBalance90d;

  /// No description provided for @bilanEnergyBalance1d.
  ///
  /// In fr, this message translates to:
  /// **'Ton équilibre énergétique (1 jour)'**
  String get bilanEnergyBalance1d;

  /// No description provided for @bilanVeryConsistent.
  ///
  /// In fr, this message translates to:
  /// **'Très régulier : ton apport moyen colle à {label} sur cette période (écart de {delta} kcal/j).'**
  String bilanVeryConsistent(String label, String delta);

  /// No description provided for @bilanAverageDeltaSummary.
  ///
  /// In fr, this message translates to:
  /// **'En moyenne, tu es à {delta} kcal/j {dir} de {label}.'**
  String bilanAverageDeltaSummary(String delta, String dir, String label);

  /// No description provided for @bilanAboveDir.
  ///
  /// In fr, this message translates to:
  /// **'au-dessus'**
  String get bilanAboveDir;

  /// No description provided for @bilanBelowDir.
  ///
  /// In fr, this message translates to:
  /// **'en dessous'**
  String get bilanBelowDir;

  /// No description provided for @bilanYourEstimatedExpenditure.
  ///
  /// In fr, this message translates to:
  /// **'ta dépense estimée'**
  String get bilanYourEstimatedExpenditure;

  /// No description provided for @bilanYourGoal.
  ///
  /// In fr, this message translates to:
  /// **'ton objectif'**
  String get bilanYourGoal;

  /// No description provided for @bilanMonthJan.
  ///
  /// In fr, this message translates to:
  /// **'Jan'**
  String get bilanMonthJan;

  /// No description provided for @bilanMonthFeb.
  ///
  /// In fr, this message translates to:
  /// **'Fév'**
  String get bilanMonthFeb;

  /// No description provided for @bilanMonthMar.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get bilanMonthMar;

  /// No description provided for @bilanMonthApr.
  ///
  /// In fr, this message translates to:
  /// **'Avr'**
  String get bilanMonthApr;

  /// No description provided for @bilanMonthMay.
  ///
  /// In fr, this message translates to:
  /// **'Mai'**
  String get bilanMonthMay;

  /// No description provided for @bilanMonthJun.
  ///
  /// In fr, this message translates to:
  /// **'Juin'**
  String get bilanMonthJun;

  /// No description provided for @bilanMonthJul.
  ///
  /// In fr, this message translates to:
  /// **'Juil'**
  String get bilanMonthJul;

  /// No description provided for @bilanMonthAug.
  ///
  /// In fr, this message translates to:
  /// **'Août'**
  String get bilanMonthAug;

  /// No description provided for @bilanMonthSep.
  ///
  /// In fr, this message translates to:
  /// **'Sep'**
  String get bilanMonthSep;

  /// No description provided for @bilanMonthOct.
  ///
  /// In fr, this message translates to:
  /// **'Oct'**
  String get bilanMonthOct;

  /// No description provided for @bilanMonthNov.
  ///
  /// In fr, this message translates to:
  /// **'Nov'**
  String get bilanMonthNov;

  /// No description provided for @bilanMonthDec.
  ///
  /// In fr, this message translates to:
  /// **'Déc'**
  String get bilanMonthDec;

  /// No description provided for @bilanVsGoal.
  ///
  /// In fr, this message translates to:
  /// **'Vs. Objectif'**
  String get bilanVsGoal;

  /// No description provided for @bilanVsExpenditure.
  ///
  /// In fr, this message translates to:
  /// **'Vs. Dépense estimée'**
  String get bilanVsExpenditure;

  /// No description provided for @bilanExpenditureThatDay.
  ///
  /// In fr, this message translates to:
  /// **'Dépense estimée ce jour-là'**
  String get bilanExpenditureThatDay;

  /// No description provided for @bilanGoalThatDay.
  ///
  /// In fr, this message translates to:
  /// **'Objectif ce jour-là'**
  String get bilanGoalThatDay;

  /// No description provided for @bilanAverageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get bilanAverageLabel;

  /// No description provided for @bilanAverageDeltaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Écart moyen'**
  String get bilanAverageDeltaLabel;

  /// No description provided for @bilanInTargetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dans la cible'**
  String get bilanInTargetLabel;

  /// No description provided for @bilanInTargetLegend.
  ///
  /// In fr, this message translates to:
  /// **'Dans la cible (±10 %)'**
  String get bilanInTargetLegend;

  /// No description provided for @bilanModerateDeltaLegend.
  ///
  /// In fr, this message translates to:
  /// **'Écart modéré (±10-25 %)'**
  String get bilanModerateDeltaLegend;

  /// No description provided for @bilanLargeDeltaLegend.
  ///
  /// In fr, this message translates to:
  /// **'Écart important (>25 %)'**
  String get bilanLargeDeltaLegend;

  /// No description provided for @bilanGoalChangedHint.
  ///
  /// In fr, this message translates to:
  /// **'Ton objectif a changé pendant cette période : chaque barre est comparée à l\'objectif qui était le tien ce jour-là (touche une barre pour le détail).'**
  String get bilanGoalChangedHint;

  /// No description provided for @bilanTapBarHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche une barre pour voir le détail du jour.'**
  String get bilanTapBarHint;

  /// No description provided for @bilanHydrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hydratation'**
  String get bilanHydrationTitle;

  /// No description provided for @bilanDrinksLabel.
  ///
  /// In fr, this message translates to:
  /// **'Boissons'**
  String get bilanDrinksLabel;

  /// No description provided for @bilanFoodsWaterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aliments'**
  String get bilanFoodsWaterLabel;

  /// No description provided for @bilanHydrationGoalReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif d\'hydratation atteint, bravo !'**
  String get bilanHydrationGoalReached;

  /// No description provided for @bilanHydrationReminder.
  ///
  /// In fr, this message translates to:
  /// **'Pense à boire : vise environ 1,5 L de boissons sur la journée'**
  String get bilanHydrationReminder;

  /// No description provided for @bilanHydrationAddGlasses.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux ajouter des verres depuis l\'onglet Journal'**
  String get bilanHydrationAddGlasses;

  /// No description provided for @bilanTopHydratingFoods.
  ///
  /// In fr, this message translates to:
  /// **'Principaux aliments hydratants :'**
  String get bilanTopHydratingFoods;

  /// No description provided for @bilanAverageSuffix.
  ///
  /// In fr, this message translates to:
  /// **' (moyenne)'**
  String get bilanAverageSuffix;

  /// No description provided for @bilanPeriodOver7d.
  ///
  /// In fr, this message translates to:
  /// **'sur 7 jours'**
  String get bilanPeriodOver7d;

  /// No description provided for @bilanPeriodOver30d.
  ///
  /// In fr, this message translates to:
  /// **'sur 30 jours'**
  String get bilanPeriodOver30d;

  /// No description provided for @bilanPeriodOver90d.
  ///
  /// In fr, this message translates to:
  /// **'sur 90 jours'**
  String get bilanPeriodOver90d;

  /// No description provided for @bilanRefLabelLine.
  ///
  /// In fr, this message translates to:
  /// **'\n{label} : {value} kcal'**
  String bilanRefLabelLine(String label, String value);

  /// No description provided for @bilanAboveKcal.
  ///
  /// In fr, this message translates to:
  /// **'\n+{value} kcal au-dessus'**
  String bilanAboveKcal(String value);

  /// No description provided for @bilanBelowKcal.
  ///
  /// In fr, this message translates to:
  /// **'\n{value} kcal en dessous'**
  String bilanBelowKcal(String value);

  /// No description provided for @bilanRightOnTarget.
  ///
  /// In fr, this message translates to:
  /// **'\nPile dans la cible'**
  String get bilanRightOnTarget;

  /// No description provided for @bilanHydrationOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'{total} ml sur un objectif de {target} ml d\'eau totale'**
  String bilanHydrationOfTotal(String total, String target);

  /// No description provided for @nutrientVitaminEFull.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine E'**
  String get nutrientVitaminEFull;

  /// No description provided for @nutrientVitaminB1Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B1'**
  String get nutrientVitaminB1Full;

  /// No description provided for @nutrientVitaminB2Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B2'**
  String get nutrientVitaminB2Full;

  /// No description provided for @nutrientVitaminB3Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B3'**
  String get nutrientVitaminB3Full;

  /// No description provided for @nutrientVitaminB5Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B5'**
  String get nutrientVitaminB5Full;

  /// No description provided for @nutrientVitaminB6Full.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B6'**
  String get nutrientVitaminB6Full;

  /// No description provided for @nutrientVitaminAFull.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine A'**
  String get nutrientVitaminAFull;

  /// No description provided for @nutrientOmega3MarineFull.
  ///
  /// In fr, this message translates to:
  /// **'Oméga 3 marins (EPA/DHA)'**
  String get nutrientOmega3MarineFull;

  /// No description provided for @consPriorityNutritionalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Priorités nutritionnelles'**
  String get consPriorityNutritionalTitle;

  /// No description provided for @consNoDeficitToday.
  ///
  /// In fr, this message translates to:
  /// **'Bel équilibre aujourd\'hui !\nAucune carence marquée détectée.'**
  String get consNoDeficitToday;

  /// No description provided for @consPriorityIntro.
  ///
  /// In fr, this message translates to:
  /// **'Classées par priorité, en tenant compte de l\'importance de chaque nutriment. Touche une carence pour voir les aliments qui la comblent.'**
  String get consPriorityIntro;

  /// No description provided for @consCoveredToday.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % de ta cible couverte aujourd\'hui'**
  String consCoveredToday(int percent);

  /// No description provided for @consWhatYouAteToday.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as consommé aujourd\'hui'**
  String get consWhatYouAteToday;

  /// No description provided for @consNoFoodContainedTodayAction.
  ///
  /// In fr, this message translates to:
  /// **'Aucun aliment consommé aujourd\'hui n\'en contenait. C\'est là qu\'il faut agir : consulte la fiche ci-dessous pour savoir où le trouver.'**
  String get consNoFoodContainedTodayAction;

  /// No description provided for @consWhereToFindReadFiche.
  ///
  /// In fr, this message translates to:
  /// **'Où en trouver ? Lire la fiche {label}'**
  String consWhereToFindReadFiche(String label);

  /// No description provided for @consRecipeAddedSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Recette ajoutée à tes recettes !'**
  String get consRecipeAddedSnackbar;

  /// No description provided for @consAddRecipeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout.'**
  String get consAddRecipeError;

  /// No description provided for @consHealthyScoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Healthy Score'**
  String get consHealthyScoreTitle;

  /// No description provided for @consHealthyScoreIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une note sur 100 qui évalue la qualité nutritionnelle globale du plat, calculée sur ses vraies valeurs CIQUAL (macros + micronutriments) :'**
  String get consHealthyScoreIntro;

  /// No description provided for @consCriteriaMicronutrients.
  ///
  /// In fr, this message translates to:
  /// **'Micronutriments'**
  String get consCriteriaMicronutrients;

  /// No description provided for @consCriteriaMicronutrientsDetail.
  ///
  /// In fr, this message translates to:
  /// **'20 pts — diversité vitamines/minéraux'**
  String get consCriteriaMicronutrientsDetail;

  /// No description provided for @consCriteriaProteinDetail.
  ///
  /// In fr, this message translates to:
  /// **'20 pts — densité protéique du plat'**
  String get consCriteriaProteinDetail;

  /// No description provided for @consCriteriaFiberDetail.
  ///
  /// In fr, this message translates to:
  /// **'15 pts — apport en fibres'**
  String get consCriteriaFiberDetail;

  /// No description provided for @consCriteriaFatQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité des lipides'**
  String get consCriteriaFatQuality;

  /// No description provided for @consCriteriaFatQualityDetail.
  ///
  /// In fr, this message translates to:
  /// **'15 pts — part d\'acides gras insaturés'**
  String get consCriteriaFatQualityDetail;

  /// No description provided for @consCriteriaCalorieDensity.
  ///
  /// In fr, this message translates to:
  /// **'Densité calorique'**
  String get consCriteriaCalorieDensity;

  /// No description provided for @consCriteriaCalorieDensityDetail.
  ///
  /// In fr, this message translates to:
  /// **'15 pts — pénalise les plats très caloriques au poids'**
  String get consCriteriaCalorieDensityDetail;

  /// No description provided for @consCriteriaSugarsDetail.
  ///
  /// In fr, this message translates to:
  /// **'7,5 pts — maîtrise des sucres'**
  String get consCriteriaSugarsDetail;

  /// No description provided for @consCriteriaSodiumDetail.
  ///
  /// In fr, this message translates to:
  /// **'7,5 pts — maîtrise du sel'**
  String get consCriteriaSodiumDetail;

  /// No description provided for @consHealthyScoreLegend.
  ///
  /// In fr, this message translates to:
  /// **'70-100 : excellent  •  45-69 : correct  •  <45 : à limiter'**
  String get consHealthyScoreLegend;

  /// No description provided for @consHealthyScorePreworkoutNote.
  ///
  /// In fr, this message translates to:
  /// **'Les collations Pré-workout sont volontairement pauvres en fibres/protéines (digestion rapide avant l\'effort) : un score plus bas y est normal, pas un signal à éviter juste avant une séance.'**
  String get consHealthyScorePreworkoutNote;

  /// No description provided for @consFitScoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fit avec ta journée'**
  String get consFitScoreTitle;

  /// No description provided for @consFitScoreIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un pourcentage qui indique à quel point la taille et l\'équilibre de cette recette sont cohérents pour ce type de repas, compte tenu de ce qu\'il te reste à manger aujourd\'hui et de tes objectifs personnels (calories, protéines, glucides, lipides).'**
  String get consFitScoreIntro;

  /// No description provided for @consCriteriaCalories.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get consCriteriaCalories;

  /// No description provided for @consFitCriteriaCaloriesDetail.
  ///
  /// In fr, this message translates to:
  /// **'40 % — cohérence avec une portion type de ce repas'**
  String get consFitCriteriaCaloriesDetail;

  /// No description provided for @consFitCriteriaProteinDetail.
  ///
  /// In fr, this message translates to:
  /// **'30 % — cohérence avec tes protéines restantes'**
  String get consFitCriteriaProteinDetail;

  /// No description provided for @consFitCriteriaCarbsDetail.
  ///
  /// In fr, this message translates to:
  /// **'15 % — cohérence avec tes glucides restants'**
  String get consFitCriteriaCarbsDetail;

  /// No description provided for @consFitCriteriaFatDetail.
  ///
  /// In fr, this message translates to:
  /// **'15 % — cohérence avec tes lipides restants'**
  String get consFitCriteriaFatDetail;

  /// No description provided for @consFitScoreLegend.
  ///
  /// In fr, this message translates to:
  /// **'Proche de 100 % : une taille de portion cohérente pour ce repas, compte tenu de ce qu\'il te reste aujourd\'hui  •  Score plus bas : le plat est nettement trop copieux ou trop léger pour ce moment de la journée.'**
  String get consFitScoreLegend;

  /// No description provided for @consFitScoreDetail.
  ///
  /// In fr, this message translates to:
  /// **'Le calcul tient compte du type de repas (un petit-déjeuner ou une collation ne doivent pas peser aussi lourd qu\'un déjeuner) et évolue au fil de la journée selon ce que tu as déjà mangé. C\'est un indicateur de timing/portion, pas de qualité nutritionnelle : regarde-le en complément du Healthy Score, pas à sa place.'**
  String get consFitScoreDetail;

  /// No description provided for @consRecipeScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recette TOTUM'**
  String get consRecipeScreenTitle;

  /// No description provided for @consHealthyScoreBadge.
  ///
  /// In fr, this message translates to:
  /// **'Healthy Score {score}/100'**
  String consHealthyScoreBadge(int score);

  /// No description provided for @consFitBadge.
  ///
  /// In fr, this message translates to:
  /// **'Fit {score}% avec ta journée'**
  String consFitBadge(int score);

  /// No description provided for @consPreparationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get consPreparationTitle;

  /// No description provided for @consRecipeValuesFor.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs pour la recette ({grams} g)'**
  String consRecipeValuesFor(String grams);

  /// No description provided for @consAfterThisMeal.
  ///
  /// In fr, this message translates to:
  /// **'Après ce repas, il te restera'**
  String get consAfterThisMeal;

  /// No description provided for @consIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get consIngredientsTitle;

  /// No description provided for @consStatProt.
  ///
  /// In fr, this message translates to:
  /// **'Prot'**
  String get consStatProt;

  /// No description provided for @consStatCarb.
  ///
  /// In fr, this message translates to:
  /// **'Gluc'**
  String get consStatCarb;

  /// No description provided for @consStatFat.
  ///
  /// In fr, this message translates to:
  /// **'Lip'**
  String get consStatFat;
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
