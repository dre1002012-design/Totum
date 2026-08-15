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

  /// No description provided for @consAddedToRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutée à tes recettes'**
  String get consAddedToRecipes;

  /// No description provided for @consAddToMyRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à mes recettes'**
  String get consAddToMyRecipes;

  /// No description provided for @consFindInJournalNote.
  ///
  /// In fr, this message translates to:
  /// **'Une fois ajoutée, retrouve cette recette dans ton onglet Journal pour l\'intégrer à tes repas.'**
  String get consFindInJournalNote;

  /// No description provided for @consCatAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get consCatAll;

  /// No description provided for @consCatBreakfast.
  ///
  /// In fr, this message translates to:
  /// **'Petit-déjeuner'**
  String get consCatBreakfast;

  /// No description provided for @consCatLunch.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get consCatLunch;

  /// No description provided for @consCatDinner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get consCatDinner;

  /// No description provided for @consCatSnack.
  ///
  /// In fr, this message translates to:
  /// **'Collation'**
  String get consCatSnack;

  /// No description provided for @consCatPreworkout.
  ///
  /// In fr, this message translates to:
  /// **'Pré-workout'**
  String get consCatPreworkout;

  /// No description provided for @consTagLight.
  ///
  /// In fr, this message translates to:
  /// **'Léger'**
  String get consTagLight;

  /// No description provided for @consTagHighProtein.
  ///
  /// In fr, this message translates to:
  /// **'Hyperprotéiné'**
  String get consTagHighProtein;

  /// No description provided for @consTagQuick.
  ///
  /// In fr, this message translates to:
  /// **'Rapide'**
  String get consTagQuick;

  /// No description provided for @consTagGlutenFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans gluten'**
  String get consTagGlutenFree;

  /// No description provided for @consTagLactoseFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans lactose'**
  String get consTagLactoseFree;

  /// No description provided for @consTagPostWorkout.
  ///
  /// In fr, this message translates to:
  /// **'Post-training'**
  String get consTagPostWorkout;

  /// No description provided for @consRecipesTotumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recettes TOTUM'**
  String get consRecipesTotumTitle;

  /// No description provided for @consRecipesCountSorted.
  ///
  /// In fr, this message translates to:
  /// **'{count} recettes triées par objectif'**
  String consRecipesCountSorted(int count);

  /// No description provided for @consForYouChip.
  ///
  /// In fr, this message translates to:
  /// **'Pour toi'**
  String get consForYouChip;

  /// No description provided for @consListView.
  ///
  /// In fr, this message translates to:
  /// **'Affichage liste'**
  String get consListView;

  /// No description provided for @consGridView.
  ///
  /// In fr, this message translates to:
  /// **'Affichage grille'**
  String get consGridView;

  /// No description provided for @consResetFilters.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les filtres'**
  String get consResetFilters;

  /// No description provided for @consSearchByIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Chercher par ingrédient (ex. poulet, riz...)'**
  String get consSearchByIngredient;

  /// No description provided for @consForYouToday.
  ///
  /// In fr, this message translates to:
  /// **'Pour toi aujourd\'hui'**
  String get consForYouToday;

  /// No description provided for @consNoRecipe.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette'**
  String get consNoRecipe;

  /// No description provided for @consRecipesSelectedForYou.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 recette sélectionnée pour toi} other{{count} recettes sélectionnées pour toi}}'**
  String consRecipesSelectedForYou(int count);

  /// No description provided for @consRecipesCountPlural.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 recette} other{{count} recettes}}'**
  String consRecipesCountPlural(int count);

  /// No description provided for @consNoAdviceAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun conseil disponible.'**
  String get consNoAdviceAvailable;

  /// No description provided for @consTabCoaching.
  ///
  /// In fr, this message translates to:
  /// **'Coaching'**
  String get consTabCoaching;

  /// No description provided for @consTabVitality.
  ///
  /// In fr, this message translates to:
  /// **'Vitalité'**
  String get consTabVitality;

  /// No description provided for @consTabRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get consTabRecipes;

  /// No description provided for @consMedicalDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Ces conseils ne remplacent pas un avis médical. En cas de pathologie ou de doute, rapprochez-vous de votre professionnel de santé.'**
  String get consMedicalDisclaimer;

  /// No description provided for @consGreetingNight.
  ///
  /// In fr, this message translates to:
  /// **'Belle nuit'**
  String get consGreetingNight;

  /// No description provided for @consGreetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get consGreetingMorning;

  /// No description provided for @consGreetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bel après-midi'**
  String get consGreetingAfternoon;

  /// No description provided for @consGreetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonne soirée'**
  String get consGreetingEvening;

  /// No description provided for @consGreetingLateNight.
  ///
  /// In fr, this message translates to:
  /// **'Bonne nuit'**
  String get consGreetingLateNight;

  /// No description provided for @consCoachTodayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ton coach TOTUM du jour'**
  String get consCoachTodayLabel;

  /// No description provided for @consDefaultCoachQuote.
  ///
  /// In fr, this message translates to:
  /// **'Chaque choix aligné aujourd\'hui construit ta vitalité de demain.'**
  String get consDefaultCoachQuote;

  /// No description provided for @consScoreProvisional.
  ///
  /// In fr, this message translates to:
  /// **'Provisoire · {pct} % de ta journée'**
  String consScoreProvisional(int pct);

  /// No description provided for @consSeeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get consSeeDetail;

  /// No description provided for @consPriorityOfTheDay.
  ///
  /// In fr, this message translates to:
  /// **'Priorité du jour'**
  String get consPriorityOfTheDay;

  /// No description provided for @consNoDeficitTodayShort.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carence marquée aujourd\'hui. Beau travail !'**
  String get consNoDeficitTodayShort;

  /// No description provided for @consTapToSeeWhereToFind.
  ///
  /// In fr, this message translates to:
  /// **'Appuie pour voir où en trouver'**
  String get consTapToSeeWhereToFind;

  /// No description provided for @consDailyAdviceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils du jour'**
  String get consDailyAdviceTitle;

  /// No description provided for @consPersonalizedAdviceCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} conseils personnalisés pour aujourd\'hui'**
  String consPersonalizedAdviceCount(int count);

  /// No description provided for @consAdviceCategories.
  ///
  /// In fr, this message translates to:
  /// **'Nutrition, mouvement, sommeil, stress, mindset'**
  String get consAdviceCategories;

  /// No description provided for @consWellbeingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bien-être holistique'**
  String get consWellbeingTitle;

  /// No description provided for @consWellbeingIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les trois piliers de ta vitalité au quotidien : sommeil, stress et exposition au soleil.'**
  String get consWellbeingIntro;

  /// No description provided for @consSleepVeryShort.
  ///
  /// In fr, this message translates to:
  /// **'Très court'**
  String get consSleepVeryShort;

  /// No description provided for @consSleepInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Insuffisant'**
  String get consSleepInsufficient;

  /// No description provided for @consSleepCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get consSleepCorrect;

  /// No description provided for @consSleepIdeal.
  ///
  /// In fr, this message translates to:
  /// **'Idéal'**
  String get consSleepIdeal;

  /// No description provided for @consSleepLong.
  ///
  /// In fr, this message translates to:
  /// **'Long'**
  String get consSleepLong;

  /// No description provided for @consStressSerene.
  ///
  /// In fr, this message translates to:
  /// **'Serein'**
  String get consStressSerene;

  /// No description provided for @consStressCalm.
  ///
  /// In fr, this message translates to:
  /// **'Calme'**
  String get consStressCalm;

  /// No description provided for @consStressModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get consStressModerate;

  /// No description provided for @consStressHigh.
  ///
  /// In fr, this message translates to:
  /// **'Élevé'**
  String get consStressHigh;

  /// No description provided for @consStressVeryHigh.
  ///
  /// In fr, this message translates to:
  /// **'Très élevé'**
  String get consStressVeryHigh;

  /// No description provided for @consSleepTipVeryShort.
  ///
  /// In fr, this message translates to:
  /// **'Une nuit aussi courte pèse sur ta récupération et tes fringales dès demain — priorise le coucher ce soir.'**
  String get consSleepTipVeryShort;

  /// No description provided for @consSleepTipUnder6.
  ///
  /// In fr, this message translates to:
  /// **'Sous 6h de façon répétée, le risque de fatigue et de fringales augmente nettement — regagne du terrain progressivement.'**
  String get consSleepTipUnder6;

  /// No description provided for @consSleepTipBorderline.
  ///
  /// In fr, this message translates to:
  /// **'Zone \"limite acceptable\" pour les experts du sommeil : quelques minutes de plus suffiraient à basculer dans la zone recommandée.'**
  String get consSleepTipBorderline;

  /// No description provided for @consSleepTipRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Tu es dans la fourchette recommandée pour un adulte — la zone la plus favorable à ta récupération.'**
  String get consSleepTipRecommended;

  /// No description provided for @consSleepTipAcceptableLong.
  ///
  /// In fr, this message translates to:
  /// **'Toujours une zone jugée acceptable — un besoin naturel de dormir un peu plus n\'est pas un problème en soi.'**
  String get consSleepTipAcceptableLong;

  /// No description provided for @consSleepTipTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Au-delà de 10h de façon récurrente, ça vaut la peine de vérifier la qualité de ton sommeil si la fatigue persiste.'**
  String get consSleepTipTooLong;

  /// No description provided for @consStressTipVeryLow.
  ///
  /// In fr, this message translates to:
  /// **'Un très bon terrain pour ta récupération globale — profites-en pour ancrer ce qui fonctionne bien pour toi.'**
  String get consStressTipVeryLow;

  /// No description provided for @consStressTipHealthy.
  ///
  /// In fr, this message translates to:
  /// **'Un niveau sain. Garde les leviers qui t\'aident à rester dans cette zone.'**
  String get consStressTipHealthy;

  /// No description provided for @consStressTipModerate.
  ///
  /// In fr, this message translates to:
  /// **'Rien d\'alarmant, mais quelques minutes de respiration lente peuvent t\'aider à redescendre encore.'**
  String get consStressTipModerate;

  /// No description provided for @consStressTipHigh.
  ///
  /// In fr, this message translates to:
  /// **'À ce niveau, le corps carbure aux hormones du stress — une pause respiration ou une marche peuvent vraiment faire la différence aujourd\'hui.'**
  String get consStressTipHigh;

  /// No description provided for @consStressTipVeryHigh.
  ///
  /// In fr, this message translates to:
  /// **'Un niveau qui mérite ton attention en priorité aujourd\'hui — commence par une pause calme avant toute autre chose.'**
  String get consStressTipVeryHigh;

  /// No description provided for @consSleepPillarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get consSleepPillarTitle;

  /// No description provided for @consEveningRitualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rituel du soir'**
  String get consEveningRitualTitle;

  /// No description provided for @consSleepBetterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mieux dormir'**
  String get consSleepBetterSubtitle;

  /// No description provided for @consStressPillarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stress'**
  String get consStressPillarTitle;

  /// No description provided for @consBreathingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Respiration'**
  String get consBreathingTitle;

  /// No description provided for @consAntiStressSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Anti-stress'**
  String get consAntiStressSubtitle;

  /// No description provided for @consTodayAnalysisTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton analyse du jour'**
  String get consTodayAnalysisTitle;

  /// No description provided for @consUpdateMyAdviceButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour mes conseils'**
  String get consUpdateMyAdviceButton;

  /// No description provided for @consSunVitDCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Soleil & vitamine D'**
  String get consSunVitDCardTitle;

  /// No description provided for @consSunVitDCardIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une bonne partie de ta vitamine D vient de l\'exposition au soleil, pas seulement de l\'alimentation. Estime ta synthèse du jour pour savoir où tu en es.'**
  String get consSunVitDCardIntro;

  /// No description provided for @consEstimateMySynthesis.
  ///
  /// In fr, this message translates to:
  /// **'Estimer ma synthèse'**
  String get consEstimateMySynthesis;

  /// No description provided for @breathPhaseInhale.
  ///
  /// In fr, this message translates to:
  /// **'Inspire'**
  String get breathPhaseInhale;

  /// No description provided for @breathPhaseHold.
  ///
  /// In fr, this message translates to:
  /// **'Retiens'**
  String get breathPhaseHold;

  /// No description provided for @breathPhaseExhale.
  ///
  /// In fr, this message translates to:
  /// **'Expire'**
  String get breathPhaseExhale;

  /// No description provided for @breathPhaseInhaleBelly.
  ///
  /// In fr, this message translates to:
  /// **'Inspire (ventre)'**
  String get breathPhaseInhaleBelly;

  /// No description provided for @breathPhaseInhaleTopUp.
  ///
  /// In fr, this message translates to:
  /// **'Inspire (complément)'**
  String get breathPhaseInhaleTopUp;

  /// No description provided for @breathCoherenceName.
  ///
  /// In fr, this message translates to:
  /// **'Cohérence cardiaque'**
  String get breathCoherenceName;

  /// No description provided for @breathCoherenceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un rythme régulier où l\'inspiration et l\'expiration durent le même temps. Le classique « 365 » : 3 fois par jour, 6 respirations par minute, pendant 5 minutes.'**
  String get breathCoherenceDesc;

  /// No description provided for @breathCoherenceBenefit.
  ///
  /// In fr, this message translates to:
  /// **'La technique anti-stress la plus étudiée. Elle synchronise le cœur et la respiration, équilibre le système nerveux autonome, fait baisser le cortisol et améliore la variabilité cardiaque — un marqueur clé de santé et de longévité.'**
  String get breathCoherenceBenefit;

  /// No description provided for @breathSquareName.
  ///
  /// In fr, this message translates to:
  /// **'Respiration carrée'**
  String get breathSquareName;

  /// No description provided for @breathSquareDesc.
  ///
  /// In fr, this message translates to:
  /// **'Quatre temps égaux : inspire, retiens poumons pleins, expire, retiens poumons vides. On dessine mentalement un carré. Utilisée par les forces spéciales pour rester calme sous pression.'**
  String get breathSquareDesc;

  /// No description provided for @breathSquareBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Les deux rétentions renforcent le contrôle du souffle et la concentration. Idéale pour retrouver son sang-froid avant un événement stressant, calmer le mental et ancrer l\'attention dans l\'instant.'**
  String get breathSquareBenefit;

  /// No description provided for @breathWeil478Name.
  ///
  /// In fr, this message translates to:
  /// **'4-7-8'**
  String get breathWeil478Name;

  /// No description provided for @breathWeil478Desc.
  ///
  /// In fr, this message translates to:
  /// **'Inspire 4 secondes, retiens 7 secondes, expire lentement sur 8 secondes. Popularisée par le Dr Andrew Weil, parfois surnommée \"calmant naturel\".'**
  String get breathWeil478Desc;

  /// No description provided for @breathWeil478Benefit.
  ///
  /// In fr, this message translates to:
  /// **'L\'expiration longue associée à la rétention active fortement le système nerveux parasympathique — celui du repos et de la récupération. Particulièrement efficace pour redescendre avant le sommeil ou calmer une montée d\'anxiété.'**
  String get breathWeil478Benefit;

  /// No description provided for @breathDiaphragmaticName.
  ///
  /// In fr, this message translates to:
  /// **'Respiration ventrale'**
  String get breathDiaphragmaticName;

  /// No description provided for @breathDiaphragmaticDesc.
  ///
  /// In fr, this message translates to:
  /// **'La base de toute pratique respiratoire : on gonfle le ventre à l\'inspire (pas la poitrine), on le relâche à l\'expire. Aucune rétention, aucun rythme complexe à retenir.'**
  String get breathDiaphragmaticDesc;

  /// No description provided for @breathDiaphragmaticBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Réapprend à utiliser pleinement le diaphragme plutôt qu\'une respiration thoracique courte et superficielle — la base sur laquelle s\'appuient toutes les autres techniques. Le point de départ le plus accessible pour découvrir la respiration guidée.'**
  String get breathDiaphragmaticBenefit;

  /// No description provided for @breathPhysiologicalSighName.
  ///
  /// In fr, this message translates to:
  /// **'Soupir physiologique'**
  String get breathPhysiologicalSighName;

  /// No description provided for @breathPhysiologicalSighDesc.
  ///
  /// In fr, this message translates to:
  /// **'Deux inspirations courtes par le nez, l\'une après l\'autre sans expirer entre les deux, puis une longue expiration par la bouche. Le geste que le corps fait déjà naturellement pour \"souffler\".'**
  String get breathPhysiologicalSighDesc;

  /// No description provided for @breathPhysiologicalSighBenefit.
  ///
  /// In fr, this message translates to:
  /// **'La double inspiration rouvre les petits sacs pulmonaires (alvéoles) affaissés, l\'expiration longue qui suit déclenche un apaisement quasi immédiat. Dans une étude comparative, cette technique a fait mieux que la respiration carrée, l\'hyperventilation cyclique ET la méditation de pleine conscience pour améliorer l\'humeur.'**
  String get breathPhysiologicalSighBenefit;

  /// No description provided for @consPhaseDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée de chaque phase'**
  String get consPhaseDuration;

  /// No description provided for @breathCyclicHyperventilationName.
  ///
  /// In fr, this message translates to:
  /// **'Hyperventilation cyclique'**
  String get breathCyclicHyperventilationName;

  /// No description provided for @breathCyclicHyperventilationDesc.
  ///
  /// In fr, this message translates to:
  /// **'Une série de 30 respirations amples et rapides, suivie d\'une rétention poumons vides, puis d\'une courte récupération. On répète l\'ensemble sur plusieurs \"rounds\", les yeux fermés du début à la fin — aucune action requise pendant la séance.'**
  String get breathCyclicHyperventilationDesc;

  /// No description provided for @breathCyclicHyperventilationBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Un vrai coup de fouet : la phase rapide augmente temporairement l\'alcalinité du sang, la rétention qui suit entraîne la tolérance au CO2 et le contrôle du souffle. Une pratique intense, à réserver aux moments où vous cherchez de l\'énergie ou à repousser vos limites de contrôle respiratoire — pas une technique de détente.'**
  String get breathCyclicHyperventilationBenefit;

  /// No description provided for @breathCyclicHyperventilationSafetyWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette technique fait momentanément baisser le taux de CO2 dans le sang et peut provoquer des étourdissements, des picotements ou, rarement, un évanouissement.\n\nÀ ne jamais pratiquer :\n• en étant debout, en conduisant, en nageant ou dans/près de l\'eau (risque de noyade documenté en cas de perte de connaissance)\n• en cas de grossesse\n• en cas d\'épilepsie ou d\'antécédents de convulsions\n• en cas de troubles cardiovasculaires\n• en cas de malaises ou évanouissements déjà connus\n\nPratiquez toujours assis ou allongé, dans un endroit sûr. En cas de doute médical, demandez l\'avis d\'un professionnel de santé avant de commencer.'**
  String get breathCyclicHyperventilationSafetyWarning;

  /// No description provided for @consNumberOfRounds.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de rounds'**
  String get consNumberOfRounds;

  /// No description provided for @consHoldDurationPerRound.
  ///
  /// In fr, this message translates to:
  /// **'Durée de rétention par round'**
  String get consHoldDurationPerRound;

  /// No description provided for @consNoActionDuringSession.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action à faire pendant la séance — réglez chaque round à l\'avance selon votre expérience.'**
  String get consNoActionDuringSession;

  /// No description provided for @consRoundLabel.
  ///
  /// In fr, this message translates to:
  /// **'Round {n}'**
  String consRoundLabel(int n);

  /// No description provided for @consSessionDurationEstimate.
  ///
  /// In fr, this message translates to:
  /// **'≈ {min} min de séance'**
  String consSessionDurationEstimate(String min);

  /// No description provided for @consStartButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get consStartButton;

  /// No description provided for @consRoundOf.
  ///
  /// In fr, this message translates to:
  /// **'Round {round} / {total}'**
  String consRoundOf(int round, int total);

  /// No description provided for @consAmpleRapidBreaths.
  ///
  /// In fr, this message translates to:
  /// **'Respirations amples et rapides'**
  String get consAmpleRapidBreaths;

  /// No description provided for @consHoldEmptyLungs.
  ///
  /// In fr, this message translates to:
  /// **'Retenez, poumons vides'**
  String get consHoldEmptyLungs;

  /// No description provided for @consCloseEyesFollowSound.
  ///
  /// In fr, this message translates to:
  /// **'Fermez les yeux, laissez-vous guider par le son'**
  String get consCloseEyesFollowSound;

  /// No description provided for @consInhaleAndHoldRecovery.
  ///
  /// In fr, this message translates to:
  /// **'Inspirez et retenez — récupération'**
  String get consInhaleAndHoldRecovery;

  /// No description provided for @consSessionComplete.
  ///
  /// In fr, this message translates to:
  /// **'Séance terminée'**
  String get consSessionComplete;

  /// No description provided for @consRoundsCompletedNote.
  ///
  /// In fr, this message translates to:
  /// **'{rounds, plural, =1{1 round complété. Prends un instant pour ressentir.} other{{rounds} rounds complétés. Prends un instant pour ressentir.}}'**
  String consRoundsCompletedNote(int rounds);

  /// No description provided for @consFinishButton.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get consFinishButton;

  /// No description provided for @consBeforeYouStart.
  ///
  /// In fr, this message translates to:
  /// **'Avant de commencer'**
  String get consBeforeYouStart;

  /// No description provided for @consReadAndUnderstand.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu et je comprends ces précautions'**
  String get consReadAndUnderstand;

  /// No description provided for @consContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get consContinueButton;

  /// No description provided for @consAdvancedProtocol.
  ///
  /// In fr, this message translates to:
  /// **'Protocole avancé'**
  String get consAdvancedProtocol;

  /// No description provided for @consStopButton.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get consStopButton;

  /// No description provided for @consCycleOf.
  ///
  /// In fr, this message translates to:
  /// **'Cycle {cycle} / {total}'**
  String consCycleOf(int cycle, int total);

  /// No description provided for @consNumberOfCycles.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de cycles'**
  String get consNumberOfCycles;

  /// No description provided for @consGuidanceSounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons de guidage'**
  String get consGuidanceSounds;

  /// No description provided for @consStartSessionButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la séance'**
  String get consStartSessionButton;

  /// No description provided for @consSessionCompleteSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Séance terminée. Prends un instant pour ressentir.'**
  String get consSessionCompleteSnackbar;

  /// No description provided for @advFirstLeverTitle.
  ///
  /// In fr, this message translates to:
  /// **'🎯 Premier levier : nourrir ton TOTUM'**
  String get advFirstLeverTitle;

  /// No description provided for @advFirstLeverTheme.
  ///
  /// In fr, this message translates to:
  /// **'Construire ta base de données personnelle'**
  String get advFirstLeverTheme;

  /// No description provided for @advFirstLeverInsight.
  ///
  /// In fr, this message translates to:
  /// **'Plus tu enregistres tes repas, plus les conseils deviennent précis, utiles et motivants.'**
  String get advFirstLeverInsight;

  /// No description provided for @advNoJournalCritique.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de détecter des déficits sans journal.'**
  String get advNoJournalCritique;

  /// No description provided for @advNoJournalBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Tu construis ton Totem alimentaire : vision claire de ce que tu offres à ton corps.'**
  String get advNoJournalBenefit;

  /// No description provided for @advNoJournalSource.
  ///
  /// In fr, this message translates to:
  /// **'Enregistre petit-déj + repas principal, avec quantités & aliments détaillés.'**
  String get advNoJournalSource;

  /// No description provided for @advNoJournalTip.
  ///
  /// In fr, this message translates to:
  /// **'Commence par tes repas « typiques », on raffinera ensuite sur les micronutriments.'**
  String get advNoJournalTip;

  /// No description provided for @advNoJournalChrono.
  ///
  /// In fr, this message translates to:
  /// **'Sans sommeil/eau/stress renseignés, le lien sensations ↔ hygiène de vie reste flou.'**
  String get advNoJournalChrono;

  /// No description provided for @advNoJournalAction.
  ///
  /// In fr, this message translates to:
  /// **'Ce soir, note heure de coucher, durée, stress (1–10). Demain matin : humeur/énergie.'**
  String get advNoJournalAction;

  /// No description provided for @advNoJournalLogTitle.
  ///
  /// In fr, this message translates to:
  /// **'📝 Active ton suivi holistique'**
  String get advNoJournalLogTitle;

  /// No description provided for @advNoJournalDefi24h.
  ///
  /// In fr, this message translates to:
  /// **'Défi 24h : renseigne 2 repas complets + sommeil, eau, stress.'**
  String get advNoJournalDefi24h;

  /// No description provided for @advNoJournalQuote.
  ///
  /// In fr, this message translates to:
  /// **'« Ce qui se mesure se transforme. »'**
  String get advNoJournalQuote;

  /// No description provided for @advNoJournalMacroTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚙️ Macros en attente'**
  String get advNoJournalMacroTitle;

  /// No description provided for @advNoJournalMacroBody.
  ///
  /// In fr, this message translates to:
  /// **'Dès qu\'un repas est saisi, je peux vérifier énergie & protéines vs ton objectif.'**
  String get advNoJournalMacroBody;

  /// No description provided for @advActivityCoachTitle.
  ///
  /// In fr, this message translates to:
  /// **'🏃‍♂️ Coach activité & récupération'**
  String get advActivityCoachTitle;

  /// No description provided for @advActivityCoachSportif.
  ///
  /// In fr, this message translates to:
  /// **'Note tes entraînements + repas pré/post pour affiner énergie & timing.'**
  String get advActivityCoachSportif;

  /// No description provided for @advActivityCoachSedentary.
  ///
  /// In fr, this message translates to:
  /// **'2–3 créneaux de 20–30 min/semaine (marche rapide, vélo doux, renfo).'**
  String get advActivityCoachSedentary;

  /// No description provided for @advDefaultMindsetTitle.
  ///
  /// In fr, this message translates to:
  /// **'🧠 Progression > perfection'**
  String get advDefaultMindsetTitle;

  /// No description provided for @advDefaultMindsetBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque repas aligné est un vote pour ton identité.'**
  String get advDefaultMindsetBody;

  /// No description provided for @advLogFieldSleep.
  ///
  /// In fr, this message translates to:
  /// **'Durée de sommeil (heures)'**
  String get advLogFieldSleep;

  /// No description provided for @advLogFieldWater.
  ///
  /// In fr, this message translates to:
  /// **'Litres d\'eau (hors café/alcool)'**
  String get advLogFieldWater;

  /// No description provided for @advLogFieldStress.
  ///
  /// In fr, this message translates to:
  /// **'Stress ressenti (1–10)'**
  String get advLogFieldStress;

  /// No description provided for @advDashboardLogTitle.
  ///
  /// In fr, this message translates to:
  /// **'🧭 Ajuste ton tableau de bord holistique'**
  String get advDashboardLogTitle;

  /// No description provided for @advOmega9Critique.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-9 en dessous de la zone optimale.'**
  String get advOmega9Critique;

  /// No description provided for @advOmega9Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Soutien cardio-métabolique & souplesse membranaire.'**
  String get advOmega9Benefit;

  /// No description provided for @advOmega9Source.
  ///
  /// In fr, this message translates to:
  /// **'Huile d\'olive, avocat, amandes/noisettes au quotidien.'**
  String get advOmega9Source;

  /// No description provided for @advOmega9Tip.
  ///
  /// In fr, this message translates to:
  /// **'Utilise l\'huile d\'olive à cru/fin de cuisson douce.'**
  String get advOmega9Tip;

  /// No description provided for @advOmega6Critique.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-6 (LA) un peu bas.'**
  String get advOmega6Critique;

  /// No description provided for @advOmega6Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Structure membranaire, peau & voies hormonales.'**
  String get advOmega6Benefit;

  /// No description provided for @advOmega6Source.
  ///
  /// In fr, this message translates to:
  /// **'Huiles vierges (tournesol bio), noix/graines variées.'**
  String get advOmega6Source;

  /// No description provided for @advOmega6Tip.
  ///
  /// In fr, this message translates to:
  /// **'Évite les huiles raffinées surchauffées.'**
  String get advOmega6Tip;

  /// No description provided for @advOmega3AlaCritique.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-3 ALA insuffisants.'**
  String get advOmega3AlaCritique;

  /// No description provided for @advOmega3AlaBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Précurseur végétal des oméga-3 marins EPA/DHA.'**
  String get advOmega3AlaBenefit;

  /// No description provided for @advOmega3AlaSource.
  ///
  /// In fr, this message translates to:
  /// **'1 c.s lin/chia moulus/jour ou quelques noix.'**
  String get advOmega3AlaSource;

  /// No description provided for @advOmega3AlaTip.
  ///
  /// In fr, this message translates to:
  /// **'Mouds le lin/chia juste avant de consommer.'**
  String get advOmega3AlaTip;

  /// No description provided for @advOmega3Critique.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-3 ALA (végétaux) sous la cible.'**
  String get advOmega3Critique;

  /// No description provided for @advOmega3Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Précurseur végétal des oméga-3, anti-inflammatoire.'**
  String get advOmega3Benefit;

  /// No description provided for @advOmega3Source.
  ///
  /// In fr, this message translates to:
  /// **'Graines de chanvre/lin moulues, noix, huile de colza.'**
  String get advOmega3Source;

  /// No description provided for @advOmega3Tip.
  ///
  /// In fr, this message translates to:
  /// **'Mouds les graines juste avant de consommer.'**
  String get advOmega3Tip;

  /// No description provided for @advOmega3MarineCritique.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-3 marins sous la cible.'**
  String get advOmega3MarineCritique;

  /// No description provided for @advOmega3MarineBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Clarté mentale, récupération, anti-inflammation.'**
  String get advOmega3MarineBenefit;

  /// No description provided for @advOmega3MarineSource.
  ///
  /// In fr, this message translates to:
  /// **'2×/sem poisson gras (sardines/maquereau/hareng).'**
  String get advOmega3MarineSource;

  /// No description provided for @advOmega3MarineTip.
  ///
  /// In fr, this message translates to:
  /// **'Cuisson douce + bons lipides.'**
  String get advOmega3MarineTip;

  /// No description provided for @advVitACritique.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine A en dessous de l\'optimum.'**
  String get advVitACritique;

  /// No description provided for @advVitABenefit.
  ///
  /// In fr, this message translates to:
  /// **'Vision nocturne, peau/muqueuses, immunité.'**
  String get advVitABenefit;

  /// No description provided for @advVitASource.
  ///
  /// In fr, this message translates to:
  /// **'Carotte/patate douce + abats/œufs (selon choix).'**
  String get advVitASource;

  /// No description provided for @advVitATip.
  ///
  /// In fr, this message translates to:
  /// **'Associe à un peu de gras pour conversion.'**
  String get advVitATip;

  /// No description provided for @advVitDCritique.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine D probablement insuffisante.'**
  String get advVitDCritique;

  /// No description provided for @advVitDBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Immunité, force, humeur, santé osseuse.'**
  String get advVitDBenefit;

  /// No description provided for @advVitDSource.
  ///
  /// In fr, this message translates to:
  /// **'Sardines/maquereau/œufs entiers, lumière matin.'**
  String get advVitDSource;

  /// No description provided for @advVitDTip.
  ///
  /// In fr, this message translates to:
  /// **'Lipides de qualité au repas contenant vit D.'**
  String get advVitDTip;

  /// No description provided for @advVitECritique.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine E insuffisante.'**
  String get advVitECritique;

  /// No description provided for @advVitEBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Antioxydant des membranes cellulaires.'**
  String get advVitEBenefit;

  /// No description provided for @advVitESource.
  ///
  /// In fr, this message translates to:
  /// **'Huiles vierges, amandes, noisettes, graines.'**
  String get advVitESource;

  /// No description provided for @advVitETip.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation à froid/cuisson douce.'**
  String get advVitETip;

  /// No description provided for @advVitKCritique.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine K un peu juste.'**
  String get advVitKCritique;

  /// No description provided for @advVitKBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Coagulation équilibrée & santé osseuse.'**
  String get advVitKBenefit;

  /// No description provided for @advVitKSource.
  ///
  /// In fr, this message translates to:
  /// **'Légumes verts + un filet d\'huile.'**
  String get advVitKSource;

  /// No description provided for @advVitKTip.
  ///
  /// In fr, this message translates to:
  /// **'Associe verts feuillus à un peu de lipides.'**
  String get advVitKTip;

  /// No description provided for @advVitCCritique.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine C sous optimal.'**
  String get advVitCCritique;

  /// No description provided for @advVitCBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Antioxydant, immunité, absorption du fer.'**
  String get advVitCBenefit;

  /// No description provided for @advVitCSource.
  ///
  /// In fr, this message translates to:
  /// **'Kiwi, agrumes, poivron cru, persil.'**
  String get advVitCSource;

  /// No description provided for @advVitCTip.
  ///
  /// In fr, this message translates to:
  /// **'Consomme plutôt cru/peu cuit.'**
  String get advVitCTip;

  /// No description provided for @advB123Critique.
  ///
  /// In fr, this message translates to:
  /// **'B1/B2/B3 un peu en deçà.'**
  String get advB123Critique;

  /// No description provided for @advB123Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Métabolisme énergétique & système nerveux.'**
  String get advB123Benefit;

  /// No description provided for @advB123Source.
  ///
  /// In fr, this message translates to:
  /// **'Céréales complètes, légumineuses, poissons/œufs.'**
  String get advB123Source;

  /// No description provided for @advB123Tip.
  ///
  /// In fr, this message translates to:
  /// **'Réduis l\'ultra-transformé pauvre en B.'**
  String get advB123Tip;

  /// No description provided for @advB56Critique.
  ///
  /// In fr, this message translates to:
  /// **'B5/B6 sous la cible.'**
  String get advB56Critique;

  /// No description provided for @advB56Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Stress, neurotransmetteurs, AA.'**
  String get advB56Benefit;

  /// No description provided for @advB56Source.
  ///
  /// In fr, this message translates to:
  /// **'Volailles, banane, pois chiches, œufs, avocat.'**
  String get advB56Source;

  /// No description provided for @advB56Tip.
  ///
  /// In fr, this message translates to:
  /// **'Répartis sur la journée.'**
  String get advB56Tip;

  /// No description provided for @advB9Critique.
  ///
  /// In fr, this message translates to:
  /// **'Folates (B9) insuffisants.'**
  String get advB9Critique;

  /// No description provided for @advB9Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement cellulaire & qualité du sang.'**
  String get advB9Benefit;

  /// No description provided for @advB9Source.
  ///
  /// In fr, this message translates to:
  /// **'Verts feuillus, légumineuses, herbes fraîches.'**
  String get advB9Source;

  /// No description provided for @advB9Tip.
  ///
  /// In fr, this message translates to:
  /// **'Part crue ou vapeur douce.'**
  String get advB9Tip;

  /// No description provided for @advB12Critique.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine B12 basse.'**
  String get advB12Critique;

  /// No description provided for @advB12Benefit.
  ///
  /// In fr, this message translates to:
  /// **'Système nerveux & globules rouges.'**
  String get advB12Benefit;

  /// No description provided for @advB12Source.
  ///
  /// In fr, this message translates to:
  /// **'Produits animaux ou aliments enrichis.'**
  String get advB12Source;

  /// No description provided for @advB12Tip.
  ///
  /// In fr, this message translates to:
  /// **'Vegan strict : discuter supplémentation pro.'**
  String get advB12Tip;

  /// No description provided for @advCalciumCritique.
  ///
  /// In fr, this message translates to:
  /// **'Calcium sous la cible.'**
  String get advCalciumCritique;

  /// No description provided for @advCalciumBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Solidité osseuse & signalisation cellulaire.'**
  String get advCalciumBenefit;

  /// No description provided for @advCalciumSource.
  ///
  /// In fr, this message translates to:
  /// **'Laitiers/alternatives, eaux calciques, tahini.'**
  String get advCalciumSource;

  /// No description provided for @advCalciumTip.
  ///
  /// In fr, this message translates to:
  /// **'Répartis + statut vit D correct.'**
  String get advCalciumTip;

  /// No description provided for @advCopperCritique.
  ///
  /// In fr, this message translates to:
  /// **'Cuivre un peu faible.'**
  String get advCopperCritique;

  /// No description provided for @advCopperBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Collagène, vaisseaux, métabolisme du fer.'**
  String get advCopperBenefit;

  /// No description provided for @advCopperSource.
  ///
  /// In fr, this message translates to:
  /// **'Fruits de mer, cacao, noix/graines.'**
  String get advCopperSource;

  /// No description provided for @advCopperTip.
  ///
  /// In fr, this message translates to:
  /// **'Associe à alimentation variée.'**
  String get advCopperTip;

  /// No description provided for @advIronCritique.
  ///
  /// In fr, this message translates to:
  /// **'Fer sous-optimal.'**
  String get advIronCritique;

  /// No description provided for @advIronBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Oxygénation musculaire & énergie.'**
  String get advIronBenefit;

  /// No description provided for @advIronSource.
  ///
  /// In fr, this message translates to:
  /// **'Légumineuses/abats/viandes + vit C.'**
  String get advIronSource;

  /// No description provided for @advIronTip.
  ///
  /// In fr, this message translates to:
  /// **'Évite thé/café juste après repas riches en fer.'**
  String get advIronTip;

  /// No description provided for @advIodineCritique.
  ///
  /// In fr, this message translates to:
  /// **'Iode plutôt bas.'**
  String get advIodineCritique;

  /// No description provided for @advIodineBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Thyroïde → métabolisme & température.'**
  String get advIodineBenefit;

  /// No description provided for @advIodineSource.
  ///
  /// In fr, this message translates to:
  /// **'Sel iodé, poissons, fruits de mer, algues raisonnées.'**
  String get advIodineSource;

  /// No description provided for @advIodineTip.
  ///
  /// In fr, this message translates to:
  /// **'Évite excès d\'algues si pathologie thyroïde.'**
  String get advIodineTip;

  /// No description provided for @advMagnesiumCritique.
  ///
  /// In fr, this message translates to:
  /// **'Magnésium insuffisant.'**
  String get advMagnesiumCritique;

  /// No description provided for @advMagnesiumBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Relaxation nerveuse/musculaire, sommeil.'**
  String get advMagnesiumBenefit;

  /// No description provided for @advMagnesiumSource.
  ///
  /// In fr, this message translates to:
  /// **'Amandes, chocolat noir, verts feuillus, eaux magnésiennes.'**
  String get advMagnesiumSource;

  /// No description provided for @advMagnesiumTip.
  ///
  /// In fr, this message translates to:
  /// **'Limite café tardif ; associe B6.'**
  String get advMagnesiumTip;

  /// No description provided for @advManganeseCritique.
  ///
  /// In fr, this message translates to:
  /// **'Manganèse bas.'**
  String get advManganeseCritique;

  /// No description provided for @advManganeseBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Cofacteur antioxydant.'**
  String get advManganeseBenefit;

  /// No description provided for @advManganeseSource.
  ///
  /// In fr, this message translates to:
  /// **'Céréales complètes, noix, thé vert (modéré).'**
  String get advManganeseSource;

  /// No description provided for @advManganeseTip.
  ///
  /// In fr, this message translates to:
  /// **'Limite raffinés pauvres en oligo-éléments.'**
  String get advManganeseTip;

  /// No description provided for @advPhosphorusCritique.
  ///
  /// In fr, this message translates to:
  /// **'Phosphore légèrement bas.'**
  String get advPhosphorusCritique;

  /// No description provided for @advPhosphorusBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Structure os/dents & énergie.'**
  String get advPhosphorusBenefit;

  /// No description provided for @advPhosphorusSource.
  ///
  /// In fr, this message translates to:
  /// **'Poisson, œufs, oléagineux.'**
  String get advPhosphorusSource;

  /// No description provided for @advPhosphorusTip.
  ///
  /// In fr, this message translates to:
  /// **'Évite sodas aux phosphates ajoutés.'**
  String get advPhosphorusTip;

  /// No description provided for @advPotassiumCritique.
  ///
  /// In fr, this message translates to:
  /// **'Potassium insuffisant.'**
  String get advPotassiumCritique;

  /// No description provided for @advPotassiumBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Équilibre tensionnel, contraction musculaire.'**
  String get advPotassiumBenefit;

  /// No description provided for @advPotassiumSource.
  ///
  /// In fr, this message translates to:
  /// **'Banane, avocat, verts, patate douce, légumineuses.'**
  String get advPotassiumSource;

  /// No description provided for @advPotassiumTip.
  ///
  /// In fr, this message translates to:
  /// **'Une part crue/vapeur pour préserver minéraux.'**
  String get advPotassiumTip;

  /// No description provided for @advSeleniumCritique.
  ///
  /// In fr, this message translates to:
  /// **'Sélénium un peu juste.'**
  String get advSeleniumCritique;

  /// No description provided for @advSeleniumBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Antioxydant clé + thyroïde.'**
  String get advSeleniumBenefit;

  /// No description provided for @advSeleniumSource.
  ///
  /// In fr, this message translates to:
  /// **'Poisson, fruits de mer, œufs (mieux absorbés).'**
  String get advSeleniumSource;

  /// No description provided for @advSeleniumTip.
  ///
  /// In fr, this message translates to:
  /// **'Évite les excès prolongés.'**
  String get advSeleniumTip;

  /// No description provided for @advSodiumCritique.
  ///
  /// In fr, this message translates to:
  /// **'Sodium un peu bas vs besoins.'**
  String get advSodiumCritique;

  /// No description provided for @advSodiumBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Hydrique, conduction nerveuse.'**
  String get advSodiumBenefit;

  /// No description provided for @advSodiumSource.
  ///
  /// In fr, this message translates to:
  /// **'Sel de qualité sur aliments bruts si transpiration.'**
  String get advSodiumSource;

  /// No description provided for @advSodiumTip.
  ///
  /// In fr, this message translates to:
  /// **'Évite ultra-salés transformés.'**
  String get advSodiumTip;

  /// No description provided for @advZincCritique.
  ///
  /// In fr, this message translates to:
  /// **'Zinc possiblement insuffisant.'**
  String get advZincCritique;

  /// No description provided for @advZincBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Immunité, peau, hormones.'**
  String get advZincBenefit;

  /// No description provided for @advZincSource.
  ///
  /// In fr, this message translates to:
  /// **'Fruits de mer, bœuf, graines de courge.'**
  String get advZincSource;

  /// No description provided for @advZincTip.
  ///
  /// In fr, this message translates to:
  /// **'Limite excès de sucre.'**
  String get advZincTip;

  /// No description provided for @advFibersCritique.
  ///
  /// In fr, this message translates to:
  /// **'Fibres sous 30 g/j.'**
  String get advFibersCritique;

  /// No description provided for @advFibersBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Microbiote, satiété, glycémie.'**
  String get advFibersBenefit;

  /// No description provided for @advFibersSource.
  ///
  /// In fr, this message translates to:
  /// **'+Légumineuses, légumes à chaque repas, fruits entiers.'**
  String get advFibersSource;

  /// No description provided for @advFibersTip.
  ///
  /// In fr, this message translates to:
  /// **'Monte progressivement + eau suffisante.'**
  String get advFibersTip;

  /// No description provided for @advDefaultCritique.
  ///
  /// In fr, this message translates to:
  /// **'Un ou plusieurs micronutriments sous la cible.'**
  String get advDefaultCritique;

  /// No description provided for @advDefaultBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Plus de densité micro = énergie & sommeil meilleurs.'**
  String get advDefaultBenefit;

  /// No description provided for @advDefaultSource.
  ///
  /// In fr, this message translates to:
  /// **'Aliments bruts variés, poissons & œufs.'**
  String get advDefaultSource;

  /// No description provided for @advDefaultTip.
  ///
  /// In fr, this message translates to:
  /// **'Assiette colorée = spectre micro plus large.'**
  String get advDefaultTip;

  /// No description provided for @advMoveTodayDefault.
  ///
  /// In fr, this message translates to:
  /// **'Bouge un peu aujourd\'hui 😉'**
  String get advMoveTodayDefault;

  /// No description provided for @advPackLowSleepHighStress1.
  ///
  /// In fr, this message translates to:
  /// **'1️⃣ 20–30 min dehors (lumière naturelle) + 5 min de respiration nasale lente en fin de journée.'**
  String get advPackLowSleepHighStress1;

  /// No description provided for @advPackLowSleepHighStress2.
  ///
  /// In fr, this message translates to:
  /// **'2️⃣ Couvre-feu digital 45–60 min avant le coucher + lecture légère ou journal de gratitude (3 points).'**
  String get advPackLowSleepHighStress2;

  /// No description provided for @advPackLowSleepHighStress3.
  ///
  /// In fr, this message translates to:
  /// **'3️⃣ Dîner plus tôt, léger et peu sucré, puis douche tiède et respiration 4–6 pendant 3–5 min.'**
  String get advPackLowSleepHighStress3;

  /// No description provided for @advPackLowSleepHighStress4.
  ///
  /// In fr, this message translates to:
  /// **'4️⃣ Si ruminations : noter tout ce qui tourne en boucle sur papier avant d\'aller au lit.'**
  String get advPackLowSleepHighStress4;

  /// No description provided for @advPackLowSleep1.
  ///
  /// In fr, this message translates to:
  /// **'1️⃣ Fixer une heure de coucher cible réaliste (même le week-end) et s\'y tenir 3 soirs de suite.'**
  String get advPackLowSleep1;

  /// No description provided for @advPackLowSleep2.
  ///
  /// In fr, this message translates to:
  /// **'2️⃣ Avancer le dernier café/thé noir au plus tard 14–15 h.'**
  String get advPackLowSleep2;

  /// No description provided for @advPackLowSleep3.
  ///
  /// In fr, this message translates to:
  /// **'3️⃣ Créer un petit rituel de \"décompression\" de 10–15 min (étirements doux + lumière tamisée).'**
  String get advPackLowSleep3;

  /// No description provided for @advPackLowSleep4.
  ///
  /// In fr, this message translates to:
  /// **'4️⃣ Chambre : fraîche, très sombre, silencieuse ou bruit blanc léger.'**
  String get advPackLowSleep4;

  /// No description provided for @advPackHighStress1.
  ///
  /// In fr, this message translates to:
  /// **'1️⃣ Micro-pauses : 2–3 min toutes les 60–90 min (respiration calme + quelques pas).'**
  String get advPackHighStress1;

  /// No description provided for @advPackHighStress2.
  ///
  /// In fr, this message translates to:
  /// **'2️⃣ 5 respirations lentes avant chaque repas pour faire redescendre le système nerveux.'**
  String get advPackHighStress2;

  /// No description provided for @advPackHighStress3.
  ///
  /// In fr, this message translates to:
  /// **'3️⃣ Marche de 10–15 min en extérieur sans téléphone, en portant l\'attention sur la respiration.'**
  String get advPackHighStress3;

  /// No description provided for @advPackHighStress4.
  ///
  /// In fr, this message translates to:
  /// **'4️⃣ Le soir : écrire 3 choses qui se sont bien passées dans la journée, même si elles sont petites.'**
  String get advPackHighStress4;

  /// No description provided for @advPackHighStressHydration.
  ///
  /// In fr, this message translates to:
  /// **'Hydratation un peu basse : répartir l\'eau sur la journée aide aussi la clarté mentale.'**
  String get advPackHighStressHydration;

  /// No description provided for @advPackStable1.
  ///
  /// In fr, this message translates to:
  /// **'1️⃣ Maintiens ton rythme de coucher et de lever, même le week-end (±1 h max).'**
  String get advPackStable1;

  /// No description provided for @advPackStable2.
  ///
  /// In fr, this message translates to:
  /// **'2️⃣ Ajoute 8–12 min de marche lente après un repas pour digestion + glycémie.'**
  String get advPackStable2;

  /// No description provided for @advPackStable3.
  ///
  /// In fr, this message translates to:
  /// **'3️⃣ Prévois 1 moment \"off écran\" de 15–20 min dans la journée (lecture, musique, nature).'**
  String get advPackStable3;

  /// No description provided for @advPackStable4.
  ///
  /// In fr, this message translates to:
  /// **'4️⃣ Introduis 1 portion de légumes verts en plus pour soutenir micronutrition & récupération.'**
  String get advPackStable4;

  /// No description provided for @advChronoLowSleepHighStress.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil court (~{hours} h) + stress élevé ({stress}/10). Le système nerveux tire fort sur les réserves.'**
  String advChronoLowSleepHighStress(String hours, int stress);

  /// No description provided for @advChronoLowSleep.
  ///
  /// In fr, this message translates to:
  /// **'Temps de sommeil un peu court (~{hours} h). L\'empilement de nuits raccourcies finit par impacter énergie et humeur.'**
  String advChronoLowSleep(String hours);

  /// No description provided for @advChronoHighStress.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil convenable (~{hours} h) mais stress élevé ({stress}/10). Le mental tourne vite.'**
  String advChronoHighStress(String hours, int stress);

  /// No description provided for @advChronoStable.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil et niveau de stress plutôt stables (≈{hours} h, stress {stress}/10). On peut jouer le \"fine tuning\" vitalité.'**
  String advChronoStable(String hours, int stress);

  /// No description provided for @advChronoIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne ton sommeil et ton niveau de stress pour des conseils bien-être personnalisés, adaptés à ta forme du moment.'**
  String get advChronoIncomplete;

  /// No description provided for @advActionIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Pendant 3 jours, note chaque matin tes heures de sommeil, ton niveau de stress (1–10) et ton énergie au réveil. TOTUM affinera progressivement les leviers proposés pour toi.'**
  String get advActionIncomplete;

  /// No description provided for @advMacroLossTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚖️ Perte de poids intelligente'**
  String get advMacroLossTitle;

  /// No description provided for @advMacroLossHigh.
  ///
  /// In fr, this message translates to:
  /// **'Apport ~{pct} : vise un déficit léger (-10 à -20 %) durable.'**
  String advMacroLossHigh(String pct);

  /// No description provided for @advMacroLossLow.
  ///
  /// In fr, this message translates to:
  /// **'Apport ~{pct} : si fatigue/fringales, remonte avec aliments bruts.'**
  String advMacroLossLow(String pct);

  /// No description provided for @advMacroLossOk.
  ///
  /// In fr, this message translates to:
  /// **'Énergie ~{pct} : trajectoire cohérente. Qualité & fibres = priorité.'**
  String advMacroLossOk(String pct);

  /// No description provided for @advMacroProteinLow.
  ///
  /// In fr, this message translates to:
  /// **' • Protéines ~{pct} : une source à chaque repas.'**
  String advMacroProteinLow(String pct);

  /// No description provided for @advMacroProteinHighSportif.
  ///
  /// In fr, this message translates to:
  /// **' • Protéines généreuses ~{pct} : répartis sur 3–4 prises.'**
  String advMacroProteinHighSportif(String pct);

  /// No description provided for @advMacroGainTitle.
  ///
  /// In fr, this message translates to:
  /// **'🏗️ Construction musculaire'**
  String get advMacroGainTitle;

  /// No description provided for @advMacroGainLow.
  ///
  /// In fr, this message translates to:
  /// **'Calories ~{pct} : surplus +10–15 % conseillé.'**
  String advMacroGainLow(String pct);

  /// No description provided for @advMacroGainHigh.
  ///
  /// In fr, this message translates to:
  /// **'Surplus ~{pct} : ramène vers +10–15 % pour limiter la prise de gras.'**
  String advMacroGainHigh(String pct);

  /// No description provided for @advMacroGainOk.
  ///
  /// In fr, this message translates to:
  /// **'Niveau ~{pct} : OK. Timing glucides autour séances = clé.'**
  String advMacroGainOk(String pct);

  /// No description provided for @advMacroGainProteinLow.
  ///
  /// In fr, this message translates to:
  /// **' • Protéines ~{pct} : 1.6–2.2 g/kg/j sur 3–4 repas.'**
  String advMacroGainProteinLow(String pct);

  /// No description provided for @advMacroGainProteinOk.
  ///
  /// In fr, this message translates to:
  /// **' • Couverture protéique ~{pct}.'**
  String advMacroGainProteinOk(String pct);

  /// No description provided for @advMacroMaintainTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚙️ Maintien du poids de forme'**
  String get advMacroMaintainTitle;

  /// No description provided for @advMacroMaintainLow.
  ///
  /// In fr, this message translates to:
  /// **'Énergie ~{pct} : un peu basse. Remonte légèrement si fatigue.'**
  String advMacroMaintainLow(String pct);

  /// No description provided for @advMacroMaintainHigh.
  ///
  /// In fr, this message translates to:
  /// **'Énergie ~{pct} : un peu haute. Ajuste extras & boissons.'**
  String advMacroMaintainHigh(String pct);

  /// No description provided for @advMacroMaintainOk.
  ///
  /// In fr, this message translates to:
  /// **'Énergie ~{pct} : alignée. Joue la qualité pour digestion/sommeil.'**
  String advMacroMaintainOk(String pct);

  /// No description provided for @advMacroMaintainProteinLow.
  ///
  /// In fr, this message translates to:
  /// **' • Protéines ~{pct} : garde un socle suffisant.'**
  String advMacroMaintainProteinLow(String pct);

  /// No description provided for @advDefiHydration.
  ///
  /// In fr, this message translates to:
  /// **'Atteins {liters} L aujourd\'hui, répartis sur la journée.'**
  String advDefiHydration(String liters);

  /// No description provided for @advQuoteHydration.
  ///
  /// In fr, this message translates to:
  /// **'« Une cellule bien hydratée travaille en silence pour ta longévité. »'**
  String get advQuoteHydration;

  /// No description provided for @advDefiEfas.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une vraie source d\'EFAs (poisson gras ou lin/chia moulus + huile colza/olive).'**
  String get advDefiEfas;

  /// No description provided for @advQuoteEfas.
  ///
  /// In fr, this message translates to:
  /// **'« Les lipides de qualité sont la matière première de ton cerveau. »'**
  String get advQuoteEfas;

  /// No description provided for @advDefiLiposoluble.
  ///
  /// In fr, this message translates to:
  /// **'1 source liposoluble + lumière du matin 10–15 min.'**
  String get advDefiLiposoluble;

  /// No description provided for @advQuoteLiposoluble.
  ///
  /// In fr, this message translates to:
  /// **'« Lumière + liposolubles = orchestration métabolique. »'**
  String get advQuoteLiposoluble;

  /// No description provided for @advDefiBVitamins.
  ///
  /// In fr, this message translates to:
  /// **'Repas très coloré + une bonne source protéique.'**
  String get advDefiBVitamins;

  /// No description provided for @advQuoteBVitamins.
  ///
  /// In fr, this message translates to:
  /// **'« Ton énergie, c\'est du code info + du carburant. »'**
  String get advQuoteBVitamins;

  /// No description provided for @advDefiFibers.
  ///
  /// In fr, this message translates to:
  /// **'1 portion de légumes en plus + 1 portion de légumineuses.'**
  String get advDefiFibers;

  /// No description provided for @advQuoteFibers.
  ///
  /// In fr, this message translates to:
  /// **'« Ton microbiote se nourrit de tes habitudes. »'**
  String get advQuoteFibers;

  /// No description provided for @advDefiDefault.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une action du Labo et applique-la aujourd\'hui.'**
  String get advDefiDefault;

  /// No description provided for @advQuoteDefault.
  ///
  /// In fr, this message translates to:
  /// **'« Les micronutriments, code source de ta vitalité. »'**
  String get advQuoteDefault;

  /// No description provided for @coachNoData.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne tes repas et je te dis en un coup d\'œil où tu en es et quoi ajuster.'**
  String get coachNoData;

  /// No description provided for @coachEtatGoodStart.
  ///
  /// In fr, this message translates to:
  /// **'Bon début : {s}/100 sur ce que tu as déjà mangé.'**
  String coachEtatGoodStart(int s);

  /// No description provided for @coachEtatStarting.
  ///
  /// In fr, this message translates to:
  /// **'Journée qui démarre : {s}/100 pour l\'instant, tout reste à construire.'**
  String coachEtatStarting(int s);

  /// No description provided for @coachEtatExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellente journée : {s}/100. C\'est ce niveau-là qui construit ta santé sur le long terme.'**
  String coachEtatExcellent(int s);

  /// No description provided for @coachEtatGood.
  ///
  /// In fr, this message translates to:
  /// **'Bonne journée : {s}/100, avec encore un peu de marge.'**
  String coachEtatGood(int s);

  /// No description provided for @coachEtatOk.
  ///
  /// In fr, this message translates to:
  /// **'Journée correcte : {s}/100. Un geste ciblé et tu passes un cap.'**
  String coachEtatOk(int s);

  /// No description provided for @coachEtatToRebalance.
  ///
  /// In fr, this message translates to:
  /// **'Journée à rééquilibrer : {s}/100. Rien de grave, un bon repas inverse la tendance.'**
  String coachEtatToRebalance(int s);

  /// No description provided for @coachProgressUp.
  ///
  /// In fr, this message translates to:
  /// **' En hausse de {diff} points vs ta dernière journée 📈.'**
  String coachProgressUp(int diff);

  /// No description provided for @coachProgressDown.
  ///
  /// In fr, this message translates to:
  /// **' En baisse de {diff} points vs ta dernière journée.'**
  String coachProgressDown(int diff);

  /// No description provided for @coachActionSleepCritical.
  ///
  /// In fr, this message translates to:
  /// **' Ta priorité aujourd\'hui n\'est pas dans l\'assiette : tu n\'as dormi que {hours} h. Tes fringales seront plus fortes — mise sur du brut et du rassasiant, et vise une nuit plus longue ce soir.'**
  String coachActionSleepCritical(String hours);

  /// No description provided for @coachActionStressHigh.
  ///
  /// In fr, this message translates to:
  /// **' Ton stress est à {stress}/10 : c\'est le point à travailler en priorité. Prends 5 respirations lentes avant chaque repas — ça apaise le mental et améliore ta digestion.'**
  String coachActionStressHigh(int stress);

  /// No description provided for @coachActionDeficitMajorWithFix.
  ///
  /// In fr, this message translates to:
  /// **' Le point à corriger en priorité : {label} ({pct}% de ta cible). Le réflexe : {fix}.'**
  String coachActionDeficitMajorWithFix(String label, int pct, String fix);

  /// No description provided for @coachActionDeficitMajor.
  ///
  /// In fr, this message translates to:
  /// **' Le point à corriger en priorité : {label} ({pct}% de ta cible).'**
  String coachActionDeficitMajor(String label, int pct);

  /// No description provided for @coachActionSleepMedium.
  ///
  /// In fr, this message translates to:
  /// **' Ta nuit a été un peu courte ({hours} h) : privilégie du rassasiant aujourd\'hui et lève le pied sur les excitants.'**
  String coachActionSleepMedium(String hours);

  /// No description provided for @coachActionStressNotable.
  ///
  /// In fr, this message translates to:
  /// **' Ton stress ({stress}/10) mérite un peu d\'attention : quelques respirations lentes dans la journée te feront du bien.'**
  String coachActionStressNotable(int stress);

  /// No description provided for @coachActionDeficitMinorWithFix.
  ///
  /// In fr, this message translates to:
  /// **' Petit point d\'amélioration : {label} ({pct}% de ta cible). Pense à {fix}.'**
  String coachActionDeficitMinorWithFix(String label, int pct, String fix);

  /// No description provided for @coachActionDeficitMinor.
  ///
  /// In fr, this message translates to:
  /// **' Petit point d\'amélioration : {label} ({pct}% de ta cible).'**
  String coachActionDeficitMinor(String label, int pct);

  /// No description provided for @coachActionNoneEvening.
  ///
  /// In fr, this message translates to:
  /// **' Rien à corriger d\'urgence : laisse la nuit faire son travail de récupération.'**
  String get coachActionNoneEvening;

  /// No description provided for @coachActionNoneLoss.
  ///
  /// In fr, this message translates to:
  /// **' Rien à corriger : garde le cap avec le duo protéines + légumes à chaque repas, c\'est lui qui tient la satiété.'**
  String get coachActionNoneLoss;

  /// No description provided for @coachActionNoneGain.
  ///
  /// In fr, this message translates to:
  /// **' Rien à corriger : pense à répartir tes protéines sur la journée pour bien nourrir ton muscle.'**
  String get coachActionNoneGain;

  /// No description provided for @coachActionNoneMaintain.
  ///
  /// In fr, this message translates to:
  /// **' Rien à corriger : garde le cap avec du brut et de la variété, c\'est la régularité qui paie.'**
  String get coachActionNoneMaintain;

  /// No description provided for @quickFixIron.
  ///
  /// In fr, this message translates to:
  /// **'des lentilles ou un peu de boudin, avec un filet de citron pour l\'absorption'**
  String get quickFixIron;

  /// No description provided for @quickFixMagnesium.
  ///
  /// In fr, this message translates to:
  /// **'une poignée d\'amandes ou un carré de chocolat noir'**
  String get quickFixMagnesium;

  /// No description provided for @quickFixCalcium.
  ///
  /// In fr, this message translates to:
  /// **'des sardines, un yaourt ou une poignée d\'amandes'**
  String get quickFixCalcium;

  /// No description provided for @quickFixZinc.
  ///
  /// In fr, this message translates to:
  /// **'des graines de courge, du bœuf ou des huîtres'**
  String get quickFixZinc;

  /// No description provided for @quickFixIodine.
  ///
  /// In fr, this message translates to:
  /// **'du poisson, des fruits de mer ou un œuf'**
  String get quickFixIodine;

  /// No description provided for @quickFixSelenium.
  ///
  /// In fr, this message translates to:
  /// **'une sardine, un œuf ou des fruits de mer'**
  String get quickFixSelenium;

  /// No description provided for @quickFixPotassium.
  ///
  /// In fr, this message translates to:
  /// **'un avocat, une patate douce ou des légumineuses'**
  String get quickFixPotassium;

  /// No description provided for @quickFixVitC.
  ///
  /// In fr, this message translates to:
  /// **'un kiwi, un poivron rouge ou quelques fraises'**
  String get quickFixVitC;

  /// No description provided for @quickFixVitD.
  ///
  /// In fr, this message translates to:
  /// **'un poisson gras (sardine, maquereau) et un peu de soleil'**
  String get quickFixVitD;

  /// No description provided for @quickFixVitE.
  ///
  /// In fr, this message translates to:
  /// **'des amandes, des noisettes ou un filet d\'huile vierge'**
  String get quickFixVitE;

  /// No description provided for @quickFixVitA.
  ///
  /// In fr, this message translates to:
  /// **'une carotte, de la patate douce ou du jaune d\'œuf'**
  String get quickFixVitA;

  /// No description provided for @quickFixVitK.
  ///
  /// In fr, this message translates to:
  /// **'des légumes verts (épinard, chou) ou un peu de fromage affiné'**
  String get quickFixVitK;

  /// No description provided for @quickFixB9.
  ///
  /// In fr, this message translates to:
  /// **'des légumes verts à feuilles ou des légumineuses'**
  String get quickFixB9;

  /// No description provided for @quickFixB12.
  ///
  /// In fr, this message translates to:
  /// **'des œufs, du poisson ou de la viande'**
  String get quickFixB12;

  /// No description provided for @quickFixB6.
  ///
  /// In fr, this message translates to:
  /// **'de la volaille, une banane ou des pois chiches'**
  String get quickFixB6;

  /// No description provided for @quickFixOmega3.
  ///
  /// In fr, this message translates to:
  /// **'des graines de chanvre ou de lin moulues, ou des noix'**
  String get quickFixOmega3;

  /// No description provided for @quickFixOmega3Marine.
  ///
  /// In fr, this message translates to:
  /// **'des sardines, du maquereau ou du hareng'**
  String get quickFixOmega3Marine;

  /// No description provided for @quickFixCopper.
  ///
  /// In fr, this message translates to:
  /// **'des oléagineux, du chocolat noir ou des fruits de mer'**
  String get quickFixCopper;

  /// No description provided for @quickFixManganese.
  ///
  /// In fr, this message translates to:
  /// **'des céréales complètes, des oléagineux ou du thé'**
  String get quickFixManganese;

  /// No description provided for @quickFixPhosphorus.
  ///
  /// In fr, this message translates to:
  /// **'des œufs, du poisson ou des légumineuses'**
  String get quickFixPhosphorus;

  /// No description provided for @quickFixFibers.
  ///
  /// In fr, this message translates to:
  /// **'des légumineuses, un fruit entier ou des légumes'**
  String get quickFixFibers;

  /// No description provided for @dietFixMarineOmega3.
  ///
  /// In fr, this message translates to:
  /// **'un complément d\'oméga 3 issu de micro-algues (source végétale d\'EPA/DHA)'**
  String get dietFixMarineOmega3;

  /// No description provided for @dietFixB12Vegan.
  ///
  /// In fr, this message translates to:
  /// **'un complément de vitamine B12 (indispensable en régime végétalien)'**
  String get dietFixB12Vegan;

  /// No description provided for @sleepRitualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rituel du soir'**
  String get sleepRitualTitle;

  /// No description provided for @sleepRitualIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un sommeil de qualité n\'est pas une chance, c\'est le résultat de bonnes habitudes. Voici les leviers qui comptent vraiment — coche ceux que tu mets en place.'**
  String get sleepRitualIntro;

  /// No description provided for @sleepRitualLeversHeading.
  ///
  /// In fr, this message translates to:
  /// **'Les 6 leviers de ton sommeil'**
  String get sleepRitualLeversHeading;

  /// No description provided for @sleepRitualLeversSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur un levier pour voir les gestes et cocher ceux que tu mets en place.'**
  String get sleepRitualLeversSubtitle;

  /// No description provided for @sleepPillarLightTitle.
  ///
  /// In fr, this message translates to:
  /// **'La lumière'**
  String get sleepPillarLightTitle;

  /// No description provided for @sleepPillarLightIntro.
  ///
  /// In fr, this message translates to:
  /// **'La lumière est le principal régulateur de ton horloge biologique. Bien gérée, elle cale ton sommeil naturellement.'**
  String get sleepPillarLightIntro;

  /// No description provided for @sleepActionLightWakeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vois la lumière du jour dès le réveil'**
  String get sleepActionLightWakeTitle;

  /// No description provided for @sleepActionLightWakeWhy.
  ///
  /// In fr, this message translates to:
  /// **'10 à 30 minutes de lumière naturelle le matin calent ton horloge interne et déclenchent, 14 à 16 h plus tard, la sécrétion de mélatonine du soir. C\'est le geste le plus puissant pour bien dormir — et il se fait le matin.'**
  String get sleepActionLightWakeWhy;

  /// No description provided for @sleepActionLightDimTitle.
  ///
  /// In fr, this message translates to:
  /// **'Baisse les lumières 1 à 2 h avant le coucher'**
  String get sleepActionLightDimTitle;

  /// No description provided for @sleepActionLightDimWhy.
  ///
  /// In fr, this message translates to:
  /// **'Une lumière vive le soir fait croire à ton cerveau qu\'il fait encore jour et bloque la mélatonine. Passe en éclairage tamisé, chaud, indirect.'**
  String get sleepActionLightDimWhy;

  /// No description provided for @sleepActionLightScreensTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coupe les écrans ou filtre la lumière bleue'**
  String get sleepActionLightScreensTitle;

  /// No description provided for @sleepActionLightScreensWhy.
  ///
  /// In fr, this message translates to:
  /// **'La lumière bleue des écrans est celle qui supprime le plus la mélatonine. Mode nuit, lunettes anti-lumière bleue, ou mieux : pose l\'écran.'**
  String get sleepActionLightScreensWhy;

  /// No description provided for @sleepActionLightDarkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dors dans l\'obscurité totale'**
  String get sleepActionLightDarkTitle;

  /// No description provided for @sleepActionLightDarkWhy.
  ///
  /// In fr, this message translates to:
  /// **'La moindre source lumineuse, même une veilleuse ou une LED de chargeur, perçue à travers les paupières, réduit la qualité du sommeil profond. Rideaux occultants ou masque.'**
  String get sleepActionLightDarkWhy;

  /// No description provided for @sleepPillarTempTitle.
  ///
  /// In fr, this message translates to:
  /// **'La température'**
  String get sleepPillarTempTitle;

  /// No description provided for @sleepPillarTempIntro.
  ///
  /// In fr, this message translates to:
  /// **'S\'endormir exige que la température de ton corps baisse d\'environ 1 °C. Tout ce qui favorise ce refroidissement aide à dormir.'**
  String get sleepPillarTempIntro;

  /// No description provided for @sleepActionTempRoomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Garde ta chambre autour de 18 °C'**
  String get sleepActionTempRoomTitle;

  /// No description provided for @sleepActionTempRoomWhy.
  ///
  /// In fr, this message translates to:
  /// **'Une chambre fraîche facilite la baisse de température corporelle nécessaire à l\'endormissement. Trop chaude, elle est l\'une des causes les plus fréquentes de réveils nocturnes.'**
  String get sleepActionTempRoomWhy;

  /// No description provided for @sleepActionTempShowerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prends une douche tiède 1 à 2 h avant'**
  String get sleepActionTempShowerTitle;

  /// No description provided for @sleepActionTempShowerWhy.
  ///
  /// In fr, this message translates to:
  /// **'Paradoxalement, une douche tiède dilate les vaisseaux et aide le corps à évacuer sa chaleur ensuite : la température chute plus vite, et l\'endormissement suit.'**
  String get sleepActionTempShowerWhy;

  /// No description provided for @sleepActionTempExtremitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Garde les extrémités au chaud'**
  String get sleepActionTempExtremitiesTitle;

  /// No description provided for @sleepActionTempExtremitiesWhy.
  ///
  /// In fr, this message translates to:
  /// **'Des pieds froids resserrent les vaisseaux et empêchent le corps d\'évacuer sa chaleur centrale. Des chaussettes peuvent, contre l\'intuition, aider à s\'endormir plus vite.'**
  String get sleepActionTempExtremitiesWhy;

  /// No description provided for @sleepPillarFoodTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stimulants & alimentation'**
  String get sleepPillarFoodTitle;

  /// No description provided for @sleepPillarFoodIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu consommes dans la seconde partie de journée pèse lourd sur ta nuit.'**
  String get sleepPillarFoodIntro;

  /// No description provided for @sleepActionFoodCaffeineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernière caféine 6 à 8 h avant le coucher'**
  String get sleepActionFoodCaffeineTitle;

  /// No description provided for @sleepActionFoodCaffeineWhy.
  ///
  /// In fr, this message translates to:
  /// **'La caféine bloque l\'adénosine, la molécule qui te rend somnolent, pendant 6 h et plus. Un café de milieu d\'après-midi ampute le sommeil profond sans même t\'empêcher de t\'endormir. Pense aussi au thé, au maté, au chocolat noir.'**
  String get sleepActionFoodCaffeineWhy;

  /// No description provided for @sleepActionFoodDinnerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dîne léger et tôt, 3 h avant'**
  String get sleepActionFoodDinnerTitle;

  /// No description provided for @sleepActionFoodDinnerWhy.
  ///
  /// In fr, this message translates to:
  /// **'Une digestion en cours élève la température du corps et mobilise l\'organisme, à l\'opposé de ce que demande le sommeil. Un dîner léger et précoce améliore nettement la profondeur de la nuit.'**
  String get sleepActionFoodDinnerWhy;

  /// No description provided for @sleepActionFoodLiquidsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modère les liquides en soirée'**
  String get sleepActionFoodLiquidsTitle;

  /// No description provided for @sleepActionFoodLiquidsWhy.
  ///
  /// In fr, this message translates to:
  /// **'Trop boire juste avant de dormir multiplie les réveils nocturnes pour aller aux toilettes, qui fragmentent les cycles. Hydrate-toi surtout en journée.'**
  String get sleepActionFoodLiquidsWhy;

  /// No description provided for @sleepActionFoodChoicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise sur les aliments favorables au sommeil'**
  String get sleepActionFoodChoicesTitle;

  /// No description provided for @sleepActionFoodChoicesWhy.
  ///
  /// In fr, this message translates to:
  /// **'Certains aliments bruts apportent du tryptophane, du magnésium et de la glycine, précurseurs de la mélatonine et de la sérotonine : amandes, noix, banane, flocons d\'avoine, kiwi, poisson gras.'**
  String get sleepActionFoodChoicesWhy;

  /// No description provided for @sleepPillarMentalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mental & stress'**
  String get sleepPillarMentalTitle;

  /// No description provided for @sleepPillarMentalIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un mental agité est la cause n°1 des difficultés d\'endormissement. L\'apaiser est un entraînement.'**
  String get sleepPillarMentalIntro;

  /// No description provided for @sleepActionMentalDumpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fais une décharge mentale'**
  String get sleepActionMentalDumpTitle;

  /// No description provided for @sleepActionMentalDumpWhy.
  ///
  /// In fr, this message translates to:
  /// **'Note sur papier ce qui t\'préoccupe et tes tâches du lendemain. Sortir les pensées de ta tête pour les poser ailleurs réduit la rumination qui tourne en boucle au coucher.'**
  String get sleepActionMentalDumpWhy;

  /// No description provided for @sleepActionMentalCoherenceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pratique quelques minutes de cohérence cardiaque'**
  String get sleepActionMentalCoherenceTitle;

  /// No description provided for @sleepActionMentalCoherenceWhy.
  ///
  /// In fr, this message translates to:
  /// **'Ralentir le souffle active le système parasympathique, celui du repos. Quelques cycles de respiration lente préparent physiologiquement le corps au sommeil.'**
  String get sleepActionMentalCoherenceWhy;

  /// No description provided for @sleepActionMentalGratitudeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Termine sur trois gratitudes'**
  String get sleepActionMentalGratitudeTitle;

  /// No description provided for @sleepActionMentalGratitudeWhy.
  ///
  /// In fr, this message translates to:
  /// **'Repenser à trois moments positifs de la journée oriente le mental vers le calme plutôt que vers l\'anxiété, et facilite un endormissement serein.'**
  String get sleepActionMentalGratitudeWhy;

  /// No description provided for @sleepActionMentalAvoidTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évite les contenus anxiogènes le soir'**
  String get sleepActionMentalAvoidTitle;

  /// No description provided for @sleepActionMentalAvoidWhy.
  ///
  /// In fr, this message translates to:
  /// **'Actualités, mails de travail, débats en ligne activent le système de vigilance juste avant de dormir. Réserve la soirée à ce qui apaise.'**
  String get sleepActionMentalAvoidWhy;

  /// No description provided for @sleepPillarRhythmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rythme & régularité'**
  String get sleepPillarRhythmTitle;

  /// No description provided for @sleepPillarRhythmIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le sommeil aime la régularité plus que tout. Un rythme stable vaut mieux qu\'une longue grasse matinée de rattrapage.'**
  String get sleepPillarRhythmIntro;

  /// No description provided for @sleepActionRhythmScheduleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couche-toi et lève-toi à heures régulières'**
  String get sleepActionRhythmScheduleTitle;

  /// No description provided for @sleepActionRhythmScheduleWhy.
  ///
  /// In fr, this message translates to:
  /// **'Des horaires constants, même le week-end, renforcent ton horloge biologique. C\'est la régularité, plus que la durée seule, qui détermine la qualité du sommeil.'**
  String get sleepActionRhythmScheduleWhy;

  /// No description provided for @sleepActionRhythmCyclesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Respecte tes cycles de 90 minutes'**
  String get sleepActionRhythmCyclesTitle;

  /// No description provided for @sleepActionRhythmCyclesWhy.
  ///
  /// In fr, this message translates to:
  /// **'Le sommeil se déroule par cycles d\'environ 90 min. Se réveiller en fin de cycle, plutôt qu\'en plein sommeil profond, rend le réveil bien plus facile.'**
  String get sleepActionRhythmCyclesWhy;

  /// No description provided for @sleepActionRhythmSignsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couche-toi dès les premiers signes'**
  String get sleepActionRhythmSignsTitle;

  /// No description provided for @sleepActionRhythmSignsWhy.
  ///
  /// In fr, this message translates to:
  /// **'Bâillements, paupières lourdes, yeux qui piquent : c\'est ton train du sommeil qui passe. Le rater, c\'est attendre le prochain cycle 90 min plus tard.'**
  String get sleepActionRhythmSignsWhy;

  /// No description provided for @sleepActionRhythmNapsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gère tes siestes'**
  String get sleepActionRhythmNapsTitle;

  /// No description provided for @sleepActionRhythmNapsWhy.
  ///
  /// In fr, this message translates to:
  /// **'Une sieste de 10 à 20 min en début d\'après-midi récupère sans empiéter sur la nuit. Trop longue ou trop tardive, elle sabote l\'endormissement du soir.'**
  String get sleepActionRhythmNapsWhy;

  /// No description provided for @sleepPillarEnvTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'environnement'**
  String get sleepPillarEnvTitle;

  /// No description provided for @sleepPillarEnvIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ta chambre doit devenir un sanctuaire que ton cerveau associe uniquement au repos.'**
  String get sleepPillarEnvIntro;

  /// No description provided for @sleepActionEnvBedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réserve le lit au sommeil'**
  String get sleepActionEnvBedTitle;

  /// No description provided for @sleepActionEnvBedWhy.
  ///
  /// In fr, this message translates to:
  /// **'Travailler, manger ou scroller au lit brouille l\'association mentale lit = sommeil. Ton cerveau doit apprendre qu\'entrer dans le lit signifie dormir.'**
  String get sleepActionEnvBedWhy;

  /// No description provided for @sleepActionEnvNoiseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chasse le bruit'**
  String get sleepActionEnvNoiseTitle;

  /// No description provided for @sleepActionEnvNoiseWhy.
  ///
  /// In fr, this message translates to:
  /// **'Même sans te réveiller, un bruit perturbe la profondeur du sommeil. Bouchons d\'oreilles ou bruit blanc régulier peuvent masquer les nuisances imprévisibles.'**
  String get sleepActionEnvNoiseWhy;

  /// No description provided for @sleepActionEnvBeddingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Soigne ta literie'**
  String get sleepActionEnvBeddingTitle;

  /// No description provided for @sleepActionEnvBeddingWhy.
  ///
  /// In fr, this message translates to:
  /// **'Un matelas et un oreiller adaptés évitent les micro-réveils liés à l\'inconfort. On y passe un tiers de sa vie : c\'est un investissement santé.'**
  String get sleepActionEnvBeddingWhy;

  /// No description provided for @hintOmega9.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-9 : {pct} → huile d\'olive, avocat, amandes/noisettes.'**
  String hintOmega9(String pct);

  /// No description provided for @hintOmega6.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-6 (LA) : {pct} → huiles vierges, noix, graines.'**
  String hintOmega6(String pct);

  /// No description provided for @hintOmega3Ala.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-3 ALA : {pct} → lin/chia moulus, noix, huile de colza.'**
  String hintOmega3Ala(String pct);

  /// No description provided for @hintOmega3.
  ///
  /// In fr, this message translates to:
  /// **'Oméga-3 EPA/DHA : {pct} → sardines, maquereau, hareng.'**
  String hintOmega3(String pct);

  /// No description provided for @hintEpa.
  ///
  /// In fr, this message translates to:
  /// **'EPA : {pct} → 1–2 portions poisson gras/sem.'**
  String hintEpa(String pct);

  /// No description provided for @hintDha.
  ///
  /// In fr, this message translates to:
  /// **'DHA : {pct} → sardines, maquereau, œufs enrichis.'**
  String hintDha(String pct);

  /// No description provided for @hintVitA.
  ///
  /// In fr, this message translates to:
  /// **'Vit A : {pct} → carotte/patate douce + œufs/abats.'**
  String hintVitA(String pct);

  /// No description provided for @hintVitD.
  ///
  /// In fr, this message translates to:
  /// **'Vit D : {pct} → lumière matin + sardines/œufs.'**
  String hintVitD(String pct);

  /// No description provided for @hintVitE.
  ///
  /// In fr, this message translates to:
  /// **'Vit E : {pct} → huiles vierges, amandes/noisettes.'**
  String hintVitE(String pct);

  /// No description provided for @hintVitK.
  ///
  /// In fr, this message translates to:
  /// **'Vit K : {pct} → verts + un peu d\'huile.'**
  String hintVitK(String pct);

  /// No description provided for @hintVitC.
  ///
  /// In fr, this message translates to:
  /// **'Vit C : {pct} → kiwi, agrumes, poivron cru, persil.'**
  String hintVitC(String pct);

  /// No description provided for @hintB1.
  ///
  /// In fr, this message translates to:
  /// **'B1 : {pct} → céréales complètes, légumineuses, porc.'**
  String hintB1(String pct);

  /// No description provided for @hintB2.
  ///
  /// In fr, this message translates to:
  /// **'B2 : {pct} → lait, œufs, amandes, champignons.'**
  String hintB2(String pct);

  /// No description provided for @hintB3.
  ///
  /// In fr, this message translates to:
  /// **'B3 : {pct} → volailles, poisson, arachides.'**
  String hintB3(String pct);

  /// No description provided for @hintB5.
  ///
  /// In fr, this message translates to:
  /// **'B5 : {pct} → abats, champignons, avocat.'**
  String hintB5(String pct);

  /// No description provided for @hintB6.
  ///
  /// In fr, this message translates to:
  /// **'B6 : {pct} → banane, pois chiches, volailles.'**
  String hintB6(String pct);

  /// No description provided for @hintB9.
  ///
  /// In fr, this message translates to:
  /// **'B9 : {pct} → verts feuillus, légumineuses.'**
  String hintB9(String pct);

  /// No description provided for @hintB12.
  ///
  /// In fr, this message translates to:
  /// **'B12 : {pct} → produits animaux / enrichis.'**
  String hintB12(String pct);

  /// No description provided for @hintCalcium.
  ///
  /// In fr, this message translates to:
  /// **'Calcium : {pct} → laitiers/alternatives, eaux calciques, tahini.'**
  String hintCalcium(String pct);

  /// No description provided for @hintCopper.
  ///
  /// In fr, this message translates to:
  /// **'Cuivre : {pct} → fruits de mer, cacao, noix/graines.'**
  String hintCopper(String pct);

  /// No description provided for @hintIron.
  ///
  /// In fr, this message translates to:
  /// **'Fer : {pct} → légumineuses/abats + vitamine C.'**
  String hintIron(String pct);

  /// No description provided for @hintIodine.
  ///
  /// In fr, this message translates to:
  /// **'Iode : {pct} → poissons, fruits de mer, sel iodé.'**
  String hintIodine(String pct);

  /// No description provided for @hintMagnesium.
  ///
  /// In fr, this message translates to:
  /// **'Magnésium : {pct} → amandes, chocolat noir, verts.'**
  String hintMagnesium(String pct);

  /// No description provided for @hintManganese.
  ///
  /// In fr, this message translates to:
  /// **'Manganèse : {pct} → céréales complètes, noix, thé vert.'**
  String hintManganese(String pct);

  /// No description provided for @hintPhosphorus.
  ///
  /// In fr, this message translates to:
  /// **'Phosphore : {pct} → poisson, œufs, oléagineux.'**
  String hintPhosphorus(String pct);

  /// No description provided for @hintPotassium.
  ///
  /// In fr, this message translates to:
  /// **'Potassium : {pct} → banane, avocat, verts, patate douce.'**
  String hintPotassium(String pct);

  /// No description provided for @hintSelenium.
  ///
  /// In fr, this message translates to:
  /// **'Sélénium : {pct} → poisson, fruits de mer, œufs.'**
  String hintSelenium(String pct);

  /// No description provided for @hintSodium.
  ///
  /// In fr, this message translates to:
  /// **'Sodium : {pct} → sel de qualité si transpiration.'**
  String hintSodium(String pct);

  /// No description provided for @hintZinc.
  ///
  /// In fr, this message translates to:
  /// **'Zinc : {pct} → fruits de mer, bœuf, graines de courge.'**
  String hintZinc(String pct);

  /// No description provided for @hintFibers.
  ///
  /// In fr, this message translates to:
  /// **'Fibres : {pct} → +légumes, légumineuses, fruits entiers.'**
  String hintFibers(String pct);

  /// No description provided for @hintDefault.
  ///
  /// In fr, this message translates to:
  /// **'Micros : {pct} → assiette colorée & brute.'**
  String hintDefault(String pct);

  /// No description provided for @breathGoalApaiserLabel.
  ///
  /// In fr, this message translates to:
  /// **'Apaiser'**
  String get breathGoalApaiserLabel;

  /// No description provided for @breathGoalApaiserSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Calmer le mental, faire retomber le stress'**
  String get breathGoalApaiserSubtitle;

  /// No description provided for @breathGoalRenforcerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Renforcer'**
  String get breathGoalRenforcerLabel;

  /// No description provided for @breathGoalRenforcerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Booster l\'énergie, muscler le contrôle du souffle'**
  String get breathGoalRenforcerSubtitle;

  /// No description provided for @breathGoalEquilibrerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Équilibrer'**
  String get breathGoalEquilibrerLabel;

  /// No description provided for @breathGoalEquilibrerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rythme régulier, équilibre du système nerveux'**
  String get breathGoalEquilibrerSubtitle;

  /// No description provided for @breathGoalDebuterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Débuter'**
  String get breathGoalDebuterLabel;

  /// No description provided for @breathGoalDebuterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'La base, en douceur, pour prendre ses marques'**
  String get breathGoalDebuterSubtitle;

  /// No description provided for @breathScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Respiration'**
  String get breathScreenTitle;

  /// No description provided for @breathGoalPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que tu cherches aujourd\'hui ?'**
  String get breathGoalPickerTitle;

  /// No description provided for @breathWeekCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} séance cette semaine} other{{count} séances cette semaine}}'**
  String breathWeekCount(int count);

  /// No description provided for @breathSeeAllTechniques.
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes les techniques'**
  String get breathSeeAllTechniques;

  /// No description provided for @consDuJourTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes conseils du jour'**
  String get consDuJourTitle;

  /// No description provided for @consDuJourIntro.
  ///
  /// In fr, this message translates to:
  /// **'Tes conseils personnalisés, choisis selon ta journée et tes objectifs.'**
  String get consDuJourIntro;

  /// No description provided for @consDuJourDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Ces conseils ne remplacent pas un avis médical. En cas de pathologie ou de doute, rapprochez-vous de votre professionnel de santé.'**
  String get consDuJourDisclaimer;

  /// No description provided for @consChallengeOfTheDay.
  ///
  /// In fr, this message translates to:
  /// **'Ton défi du jour'**
  String get consChallengeOfTheDay;

  /// No description provided for @consNoRecipeMatchesFilters.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette ne correspond à ces filtres pour le moment.'**
  String get consNoRecipeMatchesFilters;

  /// No description provided for @fallbackMindset1Title.
  ///
  /// In fr, this message translates to:
  /// **'🧠 Progression > perfection'**
  String get fallbackMindset1Title;

  /// No description provided for @fallbackMindset1Body.
  ///
  /// In fr, this message translates to:
  /// **'Chaque repas aligné avec ton objectif est un vote pour l\'identité que tu construis.'**
  String get fallbackMindset1Body;

  /// No description provided for @fallbackMindset2Title.
  ///
  /// In fr, this message translates to:
  /// **'💪 Constance antifragile'**
  String get fallbackMindset2Title;

  /// No description provided for @fallbackMindset2Body.
  ///
  /// In fr, this message translates to:
  /// **'Les écarts ne te définissent pas. C\'est la moyenne de la semaine qui compte.'**
  String get fallbackMindset2Body;

  /// No description provided for @fallbackCoachSedentaire1.
  ///
  /// In fr, this message translates to:
  /// **'2–3×/semaine 20–30 min…'**
  String get fallbackCoachSedentaire1;

  /// No description provided for @fallbackCoachSedentaire2.
  ///
  /// In fr, this message translates to:
  /// **'6–8k pas/j…'**
  String get fallbackCoachSedentaire2;

  /// No description provided for @fallbackCoachPerte1.
  ///
  /// In fr, this message translates to:
  /// **'Déficit léger + protéines…'**
  String get fallbackCoachPerte1;

  /// No description provided for @fallbackCoachMasse1.
  ///
  /// In fr, this message translates to:
  /// **'Surplus +10–15 %, protéines 1.6–2.2 g/kg…'**
  String get fallbackCoachMasse1;

  /// No description provided for @fallbackCoachMaintien1.
  ///
  /// In fr, this message translates to:
  /// **'3–4 séances variées/sem…'**
  String get fallbackCoachMaintien1;

  /// No description provided for @fallbackHeroHydrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'💧 Hydratation : ton boost silencieux'**
  String get fallbackHeroHydrationTitle;

  /// No description provided for @fallbackHeroHydrationTheme.
  ///
  /// In fr, this message translates to:
  /// **'Clarté mentale'**
  String get fallbackHeroHydrationTheme;

  /// No description provided for @fallbackHeroHydrationInsight.
  ///
  /// In fr, this message translates to:
  /// **'Répartis l\'eau + tisane le soir.'**
  String get fallbackHeroHydrationInsight;

  /// No description provided for @fallbackHeroOmega3Title.
  ///
  /// In fr, this message translates to:
  /// **'🐟 Oméga-3 : cerveau & membranes'**
  String get fallbackHeroOmega3Title;

  /// No description provided for @fallbackHeroOmega3Theme.
  ///
  /// In fr, this message translates to:
  /// **'Inflammation & humeur'**
  String get fallbackHeroOmega3Theme;

  /// No description provided for @fallbackHeroOmega3Insight.
  ///
  /// In fr, this message translates to:
  /// **'2 poissons gras/sem.'**
  String get fallbackHeroOmega3Insight;

  /// No description provided for @fallbackHeroFibersTitle.
  ///
  /// In fr, this message translates to:
  /// **'🌱 Fibres : microbiote'**
  String get fallbackHeroFibersTitle;

  /// No description provided for @fallbackHeroFibersTheme.
  ///
  /// In fr, this message translates to:
  /// **'Satiété'**
  String get fallbackHeroFibersTheme;

  /// No description provided for @fallbackHeroFibersInsight.
  ///
  /// In fr, this message translates to:
  /// **'Légumineuses + légumes + fruits entiers.'**
  String get fallbackHeroFibersInsight;

  /// No description provided for @fallbackHeroGenericTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseil du jour'**
  String get fallbackHeroGenericTitle;

  /// No description provided for @fallbackHeroGenericTheme.
  ///
  /// In fr, this message translates to:
  /// **'Vitalité'**
  String get fallbackHeroGenericTheme;

  /// No description provided for @fallbackHeroGenericInsight.
  ///
  /// In fr, this message translates to:
  /// **'Varie les aliments bruts colorés.'**
  String get fallbackHeroGenericInsight;

  /// No description provided for @fallbackRecipeOmega3Bowl.
  ///
  /// In fr, this message translates to:
  /// **'Bowl sardines-citron-avocat'**
  String get fallbackRecipeOmega3Bowl;

  /// No description provided for @fallbackRecipeOmega3Salad.
  ///
  /// In fr, this message translates to:
  /// **'Salade maquereau + lentilles'**
  String get fallbackRecipeOmega3Salad;

  /// No description provided for @fallbackRecipeFibersBowl.
  ///
  /// In fr, this message translates to:
  /// **'Buddha bowl légumineuses + céréale complète'**
  String get fallbackRecipeFibersBowl;
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
