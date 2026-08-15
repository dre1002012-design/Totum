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

  @override
  String get paywallTitle => 'Ton essai TOTUM est terminé';

  @override
  String get paywallSubtitleWeb =>
      'Ton essai gratuit de 7 jours est arrivé à son terme. 🎯\n\nTu as pu découvrir TOTUM dans son intégralité : suivi nutritionnel complet, conseils bien-être personnalisés et analyse de tes micronutriments.\n\nPour continuer à prendre soin de toi sans interruption, passe à TOTUM Premium : abonnement de 14,99 € par an — soit 1,25 € par mois — renouvelé automatiquement chaque année.';

  @override
  String get paywallSubtitleLoading => 'Chargement du prix en cours…';

  @override
  String paywallSubtitleNative(String price) {
    return 'Ton essai gratuit de 7 jours est arrivé à son terme. 🎯\n\nPour continuer à profiter de TOTUM sans aucune publicité, passe à TOTUM Premium : abonnement de $price, renouvelé automatiquement chaque année et annulable à tout moment.';
  }

  @override
  String get paywallButtonSubscribe => 'S\'abonner';

  @override
  String paywallButtonSubscribeWithPrice(String price) {
    return 'S\'abonner — $price';
  }

  @override
  String get paywallBenefitsTitle => 'Avec TOTUM Premium, tu gardes :';

  @override
  String get paywallBenefit1 => 'Accès illimité à toutes les fonctions';

  @override
  String get paywallBenefit2 => 'Aucune publicité ni distraction';

  @override
  String get paywallBenefit3 =>
      'Renouvellement annuel — annulable à tout moment';

  @override
  String get paywallStoreUnavailable =>
      'Le Store n\'est pas disponible pour le moment.\nVérifie ta connexion internet ou essaie de relancer l\'application.';

  @override
  String get paywallSubscriptionNotFound =>
      'Abonnement introuvable sur le Store.';

  @override
  String get paywallFooterWeb =>
      '🔒 Paiement 100 % sécurisé via Stripe\nAbonnement annuel de 14,99 €, renouvelé automatiquement chaque année. Annulable à tout moment : l\'accès reste actif jusqu\'à la fin de la période déjà payée.';

  @override
  String get paywallFooterNative =>
      '🔒 Paiement géré de manière sécurisée par Google Play.\nAbonnement annuel renouvelé automatiquement. Annulable à tout moment depuis le Play Store.';

  @override
  String get paywallChangeAccount => 'Changer de compte';

  @override
  String paywallChangeAccountError(String error) {
    return 'Problème lors du changement de compte : $error';
  }

  @override
  String get authWrongCredentials =>
      'Email ou mot de passe incorrect. Vérifie et réessaie.';

  @override
  String get authEmailNotConfirmed =>
      '📧 Ton email n\'est pas encore confirmé. Ouvre le lien reçu par mail, puis reconnecte-toi.';

  @override
  String get authUserAlreadyRegistered =>
      'Un compte existe déjà avec cet email. Essaie de te connecter.';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get authInvalidEmail => 'Cette adresse email ne semble pas valide.';

  @override
  String get authNetworkError =>
      'Connexion internet indisponible. Vérifie ta connexion et réessaie.';

  @override
  String get authRateLimit =>
      'Trop de tentatives. Patiente une minute avant de réessayer.';

  @override
  String get authGenericError =>
      'Une erreur est survenue. Réessaie dans un instant.';

  @override
  String get authSignUpWelcome =>
      '🎉 Bienvenue ! Ton compte est créé.\n📧 Ouvre ta boîte mail et clique sur le lien de confirmation, puis reviens te connecter ici.';

  @override
  String get authSignInSuccess => 'Connexion réussie ✅ Bon retour parmi nous !';

  @override
  String get authEnterEmailFirst =>
      'Entre d\'abord ton email ci-dessus, puis appuie sur « Mot de passe oublié ».';

  @override
  String get authResetPasswordSent =>
      '📧 Si un compte existe pour cet email, tu vas recevoir un lien pour réinitialiser ton mot de passe. Pense à vérifier tes spams.';

  @override
  String get authGoogleSignInFailed =>
      'La connexion avec Google n\'a pas abouti. Réessaie ou utilise ton email.';

  @override
  String get authWelcomeTitle => 'Bienvenue sur TOTUM';

  @override
  String get authTagline =>
      'Ton compagnon de suivi complet, pour une vitalité totale.';

  @override
  String get authPricingText =>
      'Essai gratuit 7 jours, puis abonnement 14,99 €/an renouvelé automatiquement. Annulable à tout moment.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Entre un email';

  @override
  String get authEmailInvalid => 'Email invalide';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordRequired => 'Entre un mot de passe';

  @override
  String get authPasswordMinLength => 'Au moins 6 caractères';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authSignInButton => 'Se connecter';

  @override
  String get authSignUpButton => 'Créer un compte';

  @override
  String get authOr => 'ou';

  @override
  String get authContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authTermsNotice =>
      'En continuant, tu acceptes les conditions d\'utilisation et la politique de confidentialité de TOTUM.';

  @override
  String get sunScreenTitle => 'Soleil & vitamine D';

  @override
  String get sunSkinType1Label => 'Type I — Très claire';

  @override
  String get sunSkinType1Desc =>
      'Peau très pâle, brûle toujours, ne bronze jamais. Souvent cheveux roux, taches de rousseur.';

  @override
  String get sunSkinType2Label => 'Type II — Claire';

  @override
  String get sunSkinType2Desc =>
      'Peau claire, brûle facilement, bronze peu et difficilement.';

  @override
  String get sunSkinType3Label => 'Type III — Intermédiaire';

  @override
  String get sunSkinType3Desc =>
      'Peau moyenne, brûle modérément, bronze progressivement.';

  @override
  String get sunSkinType4Label => 'Type IV — Mate';

  @override
  String get sunSkinType4Desc =>
      'Peau mate/olivâtre, brûle peu, bronze bien et facilement.';

  @override
  String get sunSkinType5Label => 'Type V — Foncée';

  @override
  String get sunSkinType5Desc =>
      'Peau brun foncé, brûle rarement, bronze intensément.';

  @override
  String get sunSkinType6Label => 'Type VI — Très foncée';

  @override
  String get sunSkinType6Desc => 'Peau noire, ne brûle quasiment jamais.';

  @override
  String get sunExposureFaceHands => 'Visage & mains';

  @override
  String get sunExposureArmsFace => 'Bras & visage';

  @override
  String get sunExposureArmsLegs => 'Bras & jambes';

  @override
  String get sunExposureSwimwear => 'Maillot de bain';

  @override
  String get sunSkinPickerTitle => 'Quel est ton type de peau ?';

  @override
  String get sunSkinPickerSubtitle =>
      'Ta peau détermine la vitesse à laquelle tu synthétises la vitamine D au soleil. On te le demande une seule fois.';

  @override
  String get sunLocationDisabled =>
      'Localisation désactivée sur l\'appareil. Active-la, ou saisis l\'UV index à la main.';

  @override
  String get sunLocationDenied =>
      'Localisation refusée. Tu peux saisir l\'UV index à la main.';

  @override
  String get sunUvFetchFailed =>
      'Impossible de récupérer l\'UV index pour l\'instant.';

  @override
  String get sunLocationUnavailable =>
      'Localisation indisponible. Saisis l\'UV index à la main.';

  @override
  String sunValidateSnackbar(String amount) {
    return '☀️ +$amount µg de vitamine D ajoutés à ta journée !';
  }

  @override
  String get sunTodayEstimateLabel => 'Vitamine D solaire estimée aujourd\'hui';

  @override
  String get sunResetTooltip => 'Réinitialiser';

  @override
  String get sunUvCurrentTitle => 'UV index actuel';

  @override
  String get sunRefreshLocationTooltip => 'Actualiser ma position';

  @override
  String get sunBelowUv3Info =>
      'En dessous de UV 3, la synthèse de vitamine D est négligeable. Ce n\'est pas le bon moment — mais profite quand même du grand air.';

  @override
  String get sunUvUnknown => 'UV index inconnu.';

  @override
  String get sunManualUvLabel => 'Saisir manuellement : ';

  @override
  String get sunYourSkinTypeLabel => 'Ton type de peau : ';

  @override
  String get sunModifyButton => 'Modifier';

  @override
  String get sunExposedSkinSurface => 'Surface de peau exposée';

  @override
  String get sunSunDuration => 'Durée au soleil';

  @override
  String sunMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get sunSunscreenSwitchTitle => 'J\'avais de la crème solaire';

  @override
  String get sunSunscreenSwitchSubtitle =>
      'La crème bloque 95 à 98 % de la synthèse de vitamine D.';

  @override
  String sunEstimatedAmount(String amount) {
    return '≈ $amount µg estimés';
  }

  @override
  String sunEstimateDetail(int minutes, String skinType, String exposure) {
    return 'pour $minutes min, peau $skinType, $exposure';
  }

  @override
  String get sunValidateButton => 'Valider mon exposition';

  @override
  String get sunGoodConditionsTitle => 'Les bonnes conditions';

  @override
  String get sunCondition1 =>
      'Les UVB nécessaires à la vitamine D ne sont présents qu\'au milieu de journée. Vise plutôt les bords de ce créneau (fin de matinée, milieu d\'après-midi) : quelques minutes suffisent. Entre 12h et 16h, le rayonnement est à son pic — bref et prudent, jamais une exposition prolongée.';

  @override
  String get sunCondition2 =>
      'Derrière une vitre (fenêtre, voiture), le verre bloque 100 % des UVB : aucune vitamine D produite.';

  @override
  String get sunCondition3 =>
      'Les lunettes de soleil ne gênent PAS la synthèse : elle se fait par la peau, garde-les pour protéger tes yeux.';

  @override
  String get sunCondition4 =>
      'Sous nos latitudes, la synthèse n\'est possible qu\'environ de mars à octobre. L\'hiver, mise sur l\'alimentation et éventuellement un complément.';

  @override
  String get sunCondition5 =>
      'Ton corps ne produit qu\'une dose limitée de vitamine D, puis s\'arrête : rester plus longtemps n\'apporte rien de plus, mais accélère le vieillissement de la peau et augmente le risque de cancer cutané. L\'objectif est le strict nécessaire, pas le bronzage.';

  @override
  String get sunDisclaimer =>
      'Estimation pédagogique fondée sur des modèles scientifiques. Ce n\'est pas une mesure médicale : seule une prise de sang évalue précisément ton taux de vitamine D.';

  @override
  String get sunUvLow => 'Faible — synthèse négligeable';

  @override
  String get sunUvModerate => 'Modéré — synthèse possible';

  @override
  String get sunUvHigh => 'Élevé — synthèse efficace, protège-toi';

  @override
  String get sunUvVeryHigh => 'Très élevé — quelques minutes suffisent';

  @override
  String get sunUvExtreme => 'Extrême — grande prudence';

  @override
  String get accountScreenTitle => 'Compte & Paramètres';

  @override
  String get accountSettingsSectionLabel => 'Réglages';

  @override
  String get accountMenuAccount => 'Compte';

  @override
  String get accountMenuAppearance => 'Apparence';

  @override
  String get accountMenuLanguageUnits => 'Langue & unités';

  @override
  String get accountMenuMyData => 'Mes données';

  @override
  String get accountMenuAbout => 'À propos';

  @override
  String get accountDefaultName => 'Compte TOTUM';

  @override
  String get accountStatusLifetimePremium => 'Premium à vie';

  @override
  String get accountStatusAnnualSubscriber => 'Abonné·e annuel';

  @override
  String accountStatusTrialRemaining(int days) {
    return 'Essai — $days j restants';
  }

  @override
  String get accountStatusTrialEnded => 'Essai terminé';

  @override
  String get accountSubLifetimeSubtitle =>
      'Accès complet, sans publicité — merci pour ta confiance.';

  @override
  String get accountSubActiveTitle => 'Abonnement annuel actif';

  @override
  String accountSubActiveSubtitle(String date) {
    return 'Jusqu\'au $date · 14,99 €/an';
  }

  @override
  String get accountManageSubscription => 'Gérer mon abonnement';

  @override
  String get accountManageViaStripeReceipt =>
      'Pour gérer ou annuler ton abonnement, utilise le lien « Gérer votre abonnement » présent dans tes reçus Stripe.';

  @override
  String get accountTrialUnknown =>
      'Nous n\'avons pas encore pu déterminer ton essai. Si besoin, déconnecte-toi puis reconnecte-toi.';

  @override
  String accountTrialRemainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il te reste $count jours d\'accès complet à TOTUM.',
      one: 'Il te reste 1 jour d\'accès complet à TOTUM.',
    );
    return '$_temp0';
  }

  @override
  String get accountTrialEndedSubtitle =>
      'Ton essai gratuit est terminé — abonne-toi pour retrouver un accès complet.';

  @override
  String get accountTrialInProgressTitle => 'Essai gratuit en cours';

  @override
  String get accountTrialEndedTitle => 'Essai gratuit terminé';

  @override
  String get accountProcessing => 'Traitement en cours…';

  @override
  String accountSubscribeWithPrice(String price) {
    return 'S\'abonner ($price)';
  }

  @override
  String get accountSubscribeAnnualWeb => 'S\'abonner — 14,99 €/an';

  @override
  String get accountInAppUnavailable =>
      'Le paiement in-app n\'est pas disponible sur cet appareil.';

  @override
  String get accountStripeSecurePayment =>
      'Paiement 100 % sécurisé via Stripe · renouvelé automatiquement chaque année, annulable à tout moment.';

  @override
  String get accountProductNotFound =>
      'Produit Premium introuvable sur le Store.';

  @override
  String get accountSubscriptionUnavailable =>
      'Abonnement non disponible pour le moment. Réessaie dans quelques instants.';

  @override
  String get accountAlreadyOwnedRestored =>
      'Tu possédais déjà TOTUM Premium sur ce compte Google, ton accès a été restauré.';

  @override
  String get accountUnknownError => 'Erreur inconnue.';

  @override
  String get accountPremiumActivated => 'Merci ! TOTUM Premium est activé !';

  @override
  String accountActivationError(String error) {
    return 'Erreur lors de l\'activation : $error';
  }

  @override
  String get accountSubscriptionActivated =>
      'Merci ! Ton abonnement TOTUM Premium est actif !';

  @override
  String get accountDeleteDialogTitle => 'Supprimer mon compte';

  @override
  String get accountDeleteDialogContent =>
      'Cette action est irréversible : ta demande de suppression sera enregistrée, ton compte et toutes tes données (journal, objectifs, historique de poids) seront supprimés définitivement. Tu seras déconnecté immédiatement.';

  @override
  String get accountDeletePermanently => 'Supprimer définitivement';

  @override
  String get accountDeletingInProgress => 'Suppression…';

  @override
  String get accountDetailsScreenTitle => 'Compte';

  @override
  String get accountEmailLabel => 'Adresse courriel';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get appearanceScreenTitle => 'Apparence';

  @override
  String get appearanceThemeSectionTitle => 'Thème';

  @override
  String get appearanceThemeLight => 'Clair';

  @override
  String get appearanceThemeDark => 'Sombre';

  @override
  String get appearanceThemeSystem => 'Système';

  @override
  String get appearanceTextSizeSectionTitle => 'Taille du texte';

  @override
  String get languageUnitsScreenTitle => 'Langue & unités';

  @override
  String get languageSectionTitle => 'Langue de l\'application';

  @override
  String get languageSubLabel => 'Langue de l\'interface';

  @override
  String get languageSubLabelHint =>
      'S\'applique à toute l\'application, y compris les noms d\'aliments dans la recherche et le journal.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get unitsSectionTitle => 'Unités de mesure';

  @override
  String get unitsSubLabel => 'Poids et taille';

  @override
  String get unitsSubLabelHint =>
      'Les calculs internes restent toujours en métrique.';

  @override
  String get dataExportScreenTitle => 'Mes données';

  @override
  String get dataExportSectionTitle => 'Exporter mon journal';

  @override
  String get dataExportDescription =>
      'Exporte ton journal alimentaire, tes objectifs et tes micronutriments sur une période, au format HTML (convertible en PDF, ex. pour un professionnel de santé).';

  @override
  String get dataExportPeriodHelpText => 'Période à exporter';

  @override
  String get dataExportSaveText => 'EXPORTER';

  @override
  String get dataExportSuccessSnackbar => 'Rapport exporté';

  @override
  String dataExportErrorSnackbar(String error) {
    return 'Erreur export : $error';
  }

  @override
  String get dataExportGenerating => 'Génération…';

  @override
  String get dataExportButton => 'Exporter mes données';

  @override
  String get aboutScreenTitle => 'À propos';

  @override
  String get aboutVersionLabel => 'Version';
}
