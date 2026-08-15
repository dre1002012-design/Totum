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
  String get commonAdd => 'Ajouter';

  @override
  String get commonNameField => 'Nom';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

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

  @override
  String get activityLevelSedentaryTitle => 'Sédentaire';

  @override
  String get activityLevelLightTitle => 'Légèrement actif';

  @override
  String get activityLevelModerateTitle => 'Modérément actif';

  @override
  String get activityLevelActiveTitle => 'Actif';

  @override
  String get activityLevelVeryActiveTitle => 'Très actif';

  @override
  String get activityLevelExtremeTitle => 'Extrêmement actif';

  @override
  String get activityLevelSedentaryDesc =>
      'Vie plutôt sédentaire (bureau, peu de marche), pas ou très peu de sport.';

  @override
  String get activityLevelLightDesc =>
      'Un peu de marche au quotidien, et/ou 1 à 3 séances de sport par semaine.';

  @override
  String get activityLevelModerateDesc =>
      'Bonne marche au quotidien (~8 000-10 000 pas), et/ou 3 à 5 séances de sport par semaine.';

  @override
  String get activityLevelActiveDesc =>
      'Beaucoup de mouvement au quotidien (métier debout), et/ou sport quasi quotidien (5-6 séances/semaine).';

  @override
  String get activityLevelVeryActiveDesc =>
      'Métier physique, et/ou plusieurs séances intenses certains jours (ex. course + muscu le même jour).';

  @override
  String get activityLevelExtremeDesc =>
      'Métier physique intense ET entraînement quasi quotidien à haute intensité (ex. sportif semi-pro).';

  @override
  String get bodyFatTierEssential => 'Essentiel';

  @override
  String get bodyFatTierAthlete => 'Athlète';

  @override
  String get bodyFatTierFitness => 'Fitness';

  @override
  String get bodyFatTierAverage => 'Moyen';

  @override
  String get bodyFatTierHigh => 'Élevé';

  @override
  String get dietStyleBalancedTitle => 'Équilibré';

  @override
  String get dietStyleHighCarbTitle => 'Riche en glucides';

  @override
  String get dietStyleHighFatTitle => 'Riche en lipides';

  @override
  String get dietStyleKetoTitle => 'Cétogène (Keto)';

  @override
  String get dietStyleBalancedDesc =>
      'Répartition de référence (~30 % lipides / ~45 % glucides des calories totales) : la zone associée à la mortalité totale la plus basse dans les grandes études de cohorte, dans les bornes officielles (AMDR).';

  @override
  String get dietStyleHighCarbDesc =>
      'Lipides ramenés vers le bas de la fourchette recommandée, glucides plus généreux — utile pour les sports d\'endurance à fort volume, sans jamais sortir des bornes officielles.';

  @override
  String get dietStyleHighFatDesc =>
      'Lipides plus présents pour qui les préfère (satiété, appétence) — plafonnés à la limite haute recommandée (35 % des calories), jamais au-delà.';

  @override
  String get dietStyleKetoDesc =>
      'Glucides maintenus très bas, lipides très élevés — approche validée pour certains usages thérapeutiques encadrés (ex. épilepsie), mais dont les effets cardiovasculaires à long terme en population générale restent peu documentés (études majoritairement sur quelques semaines). À utiliser ponctuellement et avec discernement, pas comme réglage par défaut.';

  @override
  String get profileDietOmnivore => 'Omnivore';

  @override
  String get profileDietVegetarian => 'Végétarien';

  @override
  String get profileDietVegan => 'Végétalien';

  @override
  String get goalLoseTitle => 'Perte de gras';

  @override
  String get goalLoseDesc =>
      'Perdre de la masse grasse à un bon rythme, tout en préservant tes muscles et ton énergie.';

  @override
  String get goalLoseTip1 =>
      'Garde un bon apport en protéines pour protéger tes muscles';

  @override
  String get goalLoseTip2 =>
      'Bouge régulièrement — même une marche quotidienne compte';

  @override
  String get goalLoseTip3 =>
      'Dors suffisamment : la récupération fait partie du résultat';

  @override
  String get goalLoseTip4 =>
      'Après 8 à 10 semaines, prévois une pause en Maintien';

  @override
  String get goalLoseCoach =>
      'La priorité est de préserver ta masse musculaire pendant que tu perds du gras. TOTUM relève automatiquement ta cible en protéines. Un rythme modéré est plus efficace et bien plus durable qu\'un régime extrême.';

  @override
  String get goalLoseMildTitle => 'Perte en douceur';

  @override
  String get goalLoseMildDesc =>
      'Perdre du poids progressivement, sans frustration ni coup de fatigue. Idéal pour tenir dans le temps.';

  @override
  String get goalLoseMildTip1 =>
      'Un déficit léger, plus facile à tenir au quotidien';

  @override
  String get goalLoseMildTip2 =>
      'Prends soin de ta récupération et de ton sommeil';

  @override
  String get goalLoseMildTip3 =>
      'Garde de l\'énergie pour tes activités et ta forme';

  @override
  String get goalLoseMildTip4 => 'La régularité compte plus que la vitesse';

  @override
  String get goalLoseMildCoach =>
      'Cette approche tout en douceur est parfaite pour perdre du poids sans y penser en permanence. La progression est plus lente, mais c\'est justement ce qui la rend durable : patience et constance sont tes meilleures alliées.';

  @override
  String get goalMaintainTitle => 'Maintien';

  @override
  String get goalMaintainDesc =>
      'Stabiliser ton poids et te sentir bien, sur la durée.';

  @override
  String get goalMaintainTip1 =>
      'Mange à hauteur de tes besoins, ni plus ni moins';

  @override
  String get goalMaintainTip2 => 'Garde une activité physique régulière';

  @override
  String get goalMaintainTip3 => 'Conserve un bon apport en protéines';

  @override
  String get goalMaintainTip4 =>
      'Observe ton poids moyen sur la semaine, pas au jour le jour';

  @override
  String get goalMaintainCoach =>
      'Ton objectif n\'est plus de perdre ou de prendre, mais de conserver tes résultats et de te sentir bien. C\'est la régularité qui ancre les bonnes habitudes sur le long terme — tu es dans la zone de la sérénité.';

  @override
  String get goalGainMildTitle => 'Prise de muscle';

  @override
  String get goalGainMildDesc =>
      'Développer tes muscles progressivement, avec une prise de gras maîtrisée.';

  @override
  String get goalGainMildTip1 =>
      'Un léger surplus, juste ce qu\'il faut pour construire';

  @override
  String get goalGainMildTip2 =>
      'Associe à une activité de renforcement si tu le peux';

  @override
  String get goalGainMildTip3 =>
      'Un bon apport en protéines soutient tes muscles';

  @override
  String get goalGainMildTip4 => 'Un sommeil de qualité accélère les progrès';

  @override
  String get goalGainMildCoach =>
      'Une progression lente et maîtrisée donne un bien meilleur ratio muscle/graisse qu\'une prise rapide. Inutile de forcer : la qualité prime sur la quantité, et ton corps te remerciera.';

  @override
  String get goalGainTitle => 'Prise de masse';

  @override
  String get goalGainDesc =>
      'Maximiser ta prise de muscle et de force, pour les objectifs les plus ambitieux.';

  @override
  String get goalGainTip1 =>
      'Un surplus plus marqué pour soutenir la construction';

  @override
  String get goalGainTip2 =>
      'Idéal si tu t\'entraînes intensément et régulièrement';

  @override
  String get goalGainTip3 => 'Une bonne récupération est essentielle';

  @override
  String get goalGainTip4 =>
      'Surveille ton évolution pour rester sur la bonne voie';

  @override
  String get goalGainCoach =>
      'Ce mode est fait pour les objectifs ambitieux. Contrôle régulièrement ton évolution pour éviter une prise de graisse superflue : un surplus maîtrisé donne toujours de meilleurs résultats qu\'un excès non suivi.';

  @override
  String get profileMaintainDynamic => 'Maintien dynamique';

  @override
  String get profileEquilibrium => 'Équilibre';

  @override
  String profileTargetedRateNeg(String pct) {
    return 'Rythme visé : −$pct %/sem';
  }

  @override
  String profileTargetedRatePos(String pct) {
    return 'Rythme visé : +$pct %/sem';
  }

  @override
  String profileMacroCoherenceOver(
      String computed, String diff, String pct, String kcal) {
    return 'Tes macros représentent $computed kcal — $diff kcal ($pct %) DE PLUS que les $kcal kcal indiquées.';
  }

  @override
  String profileMacroCoherenceUnder(
      String computed, String diff, String pct, String kcal) {
    return 'Tes macros représentent $computed kcal — $diff kcal ($pct %) DE MOINS que les $kcal kcal indiquées.';
  }

  @override
  String profileGoalsUpdatedSnackbar(int kcal) {
    return 'Objectifs mis à jour · $kcal kcal par jour';
  }

  @override
  String get profileConfirmGoals => 'Confirmer mes objectifs';

  @override
  String get profileGoalsSaved => 'Objectifs enregistrés';

  @override
  String get profileBackToAuto => 'Revenir au calcul automatique';

  @override
  String get profileCustomizeGoals => 'Personnaliser mes objectifs';

  @override
  String get profileFullDetailFooter =>
      'Le détail complet (vitamines, minéraux, acides gras) se calcule automatiquement dans l\'onglet Bilan.';

  @override
  String get profileTodayEyebrow => 'AUJOURD\'HUI';

  @override
  String get profileKcalOver => 'kcal dépassé';

  @override
  String get profileKcalRemaining => 'kcal restant';

  @override
  String get profileBaseGoal => 'Objectif de base';

  @override
  String get profileFoodsLabel => 'Aliments';

  @override
  String get profileRefinedByResults => 'Affiné selon tes résultats réels';

  @override
  String profileMacroGramsOver(int amount) {
    return '+$amount g dépassé';
  }

  @override
  String profileMacroGramsRemaining(int amount) {
    return '$amount g restants';
  }

  @override
  String get profileMacronutrients => 'Macronutriments';

  @override
  String get profileCarbs => 'Glucides';

  @override
  String get profileFats => 'Lipides';

  @override
  String get profileProteins => 'Protéines';

  @override
  String get profilePlateToday => 'Ton assiette aujourd\'hui';

  @override
  String get profilePlateGoal => 'Ton assiette (objectif)';

  @override
  String get profileMicronutrientsFeatured => 'Micronutriments en vedette';

  @override
  String get profileGoalTileLabel => 'Objectif';

  @override
  String get profileMeasuresTileLabel => 'Mesures';

  @override
  String get profileActivityLevelTileLabel => 'Niveau d\'activité';

  @override
  String get profileDietTileLabel => 'Régime alimentaire';

  @override
  String get profileMacroSplitTileLabel => 'Répartition des macros';

  @override
  String get profileDone => 'Terminé';

  @override
  String profileImpactChanged(int before, int after, String diff) {
    return 'Impact sur ton objectif : $before → $after kcal ($diff)';
  }

  @override
  String profileImpactUnchanged(int after) {
    return 'Objectif actuel : $after kcal';
  }

  @override
  String get profileYourGoalTitle => 'Ton objectif';

  @override
  String get profileToRemember => 'À retenir';

  @override
  String get profileCoachAdvice => 'Conseil du coach';

  @override
  String get profileMeasuresSheetTitle => 'Tes mesures';

  @override
  String get profileMale => 'Homme';

  @override
  String get profileFemale => 'Femme';

  @override
  String get profileAgeYears => 'Âge (ans)';

  @override
  String get profileHeightCm => 'Taille (cm)';

  @override
  String get profileHeightIn => 'Taille (in)';

  @override
  String get profileWeightKg => 'Poids (kg)';

  @override
  String get profileWeightLb => 'Poids (lb)';

  @override
  String get profileWeighInAdvice =>
      'Pèse-toi si possible tous les jours, dans les mêmes conditions à chaque fois — idéalement le matin à jeun, au lever.';

  @override
  String get profileTargetWeightKg => 'Poids cible (kg) — optionnel';

  @override
  String get profileTargetWeightLb => 'Poids cible (lb) — optionnel';

  @override
  String get profileTargetWeightHint =>
      'Utilisé uniquement pour l\'objectif Maintien : une fois proche de ta cible, tes calories suivent ta dépense réelle ; si tu t\'en éloignes, un léger ajustement automatique t\'y ramène doucement.';

  @override
  String get profileBodyFatOptional => 'Masse grasse — optionnel';

  @override
  String get profileBodyFatHint =>
      'Choisis la plage la plus proche de ta silhouette actuelle.';

  @override
  String get profileActivitySheetTitle => 'Ton niveau d\'activité';

  @override
  String get profileActivitySheetDesc =>
      'Choisis la description la plus proche de TA semaine type — quotidien ET sport confondus, l\'un ou l\'autre suffit à te situer dans un palier.';

  @override
  String get profileMacroSplitSheetDesc =>
      'Ne change ni tes calories ni tes protéines — seulement comment le reste se répartit entre lipides et glucides.';

  @override
  String get profileInvalidNumber => 'Nombre invalide';

  @override
  String get profileYourEvolution => 'Ton évolution';

  @override
  String get profileLast60Days => '60 derniers jours';

  @override
  String get profileAdaptiveEstimate => 'estimation adaptative';

  @override
  String get profileCustomGoalsTitle => 'Mes objectifs personnalisés';

  @override
  String get profileCustomGoalsSubtitle =>
      'Ces valeurs remplacent le calcul automatique.';

  @override
  String get profileEnergyKcal => 'Énergie (kcal)';

  @override
  String get profileProteinG => 'Protéines (g)';

  @override
  String get profileCarbG => 'Glucides (g)';

  @override
  String get profileFatG => 'Lipides (g)';

  @override
  String get profileFiberG => 'Fibres (g)';

  @override
  String get profileApplyGoals => 'Appliquer mes objectifs';

  @override
  String get nutrientEnergy => 'Énergie';

  @override
  String get nutrientProtein => 'Protéines';

  @override
  String get nutrientCarbs => 'Glucides';

  @override
  String get nutrientFat => 'Lipides';

  @override
  String get nutrientFiber => 'Fibres';

  @override
  String get nutrientOmega9 => 'Oméga 9 (Oléique)';

  @override
  String get nutrientOmega6 => 'Oméga 6 (LA)';

  @override
  String get nutrientOmega3 => 'Oméga 3 (ALA)';

  @override
  String get nutrientSatFat => 'AG saturés';

  @override
  String get nutrientSugars => 'Sucres';

  @override
  String get nutrientSalt => 'Sel';

  @override
  String get nutrientAlcohol => 'Alcool';

  @override
  String get nutrientRetinol => 'Rétinol';

  @override
  String get nutrientBetaCarotene => 'Bêta-car.';

  @override
  String get nutrientCopper => 'Cuivre';

  @override
  String get nutrientIron => 'Fer';

  @override
  String get nutrientIodine => 'Iode';

  @override
  String get nutrientMagnesium => 'Magnésium';

  @override
  String get nutrientManganese => 'Manganèse';

  @override
  String get nutrientPhosphorus => 'Phosphore';

  @override
  String get nutrientSelenium => 'Sélénium';

  @override
  String get nutrientCholesterol => 'Cholestérol';

  @override
  String get nutrientVitaminDFull => 'Vitamine D';

  @override
  String get nutrientVitaminCFull => 'Vitamine C';

  @override
  String get nutrientVitaminKFull => 'Vitamine K';

  @override
  String get nutrientVitaminB9Full => 'Vitamine B9';

  @override
  String get nutrientVitaminB12Full => 'Vitamine B12';

  @override
  String get nutrientOmega3Marine => 'Oméga 3 marins';

  @override
  String get moodExcellent => 'Excellent équilibre !';

  @override
  String get moodGood => 'Bon équilibre';

  @override
  String get moodCorrect => 'Correct, peut mieux faire';

  @override
  String get moodToImprove => 'À améliorer';

  @override
  String get moodRebalance => 'Journée à rééquilibrer';

  @override
  String get scorePillarVitamins => 'Vitamines';

  @override
  String get scorePillarMinerals => 'Minéraux';

  @override
  String get scorePillarFattyAcids => 'Acides gras';

  @override
  String get scorePillarHydration => 'Hydratation';

  @override
  String get scorePillarWatch => 'À surveiller';

  @override
  String scoreCapReason(String label, int pct) {
    return '$label à $pct % de ta cible du jour — la note est plafonnée tant que ça dure.';
  }

  @override
  String get bilanScoreTitle => 'Score TOTUM';

  @override
  String get bilanScoreUpdatesLive => 'Se met à jour à chaque repas ajouté';

  @override
  String get bilanScoreHowCalculated => 'Comment est calculée cette note ?';

  @override
  String bilanSafetyLimitExceeded(String list) {
    return 'Limite de sécurité dépassée : $list';
  }

  @override
  String bilanUnderstandLabel(String label) {
    return 'Comprendre : $label';
  }

  @override
  String get bilanWhyLimitExists => 'Pourquoi cette limite existe';

  @override
  String get bilanExcessConsequences =>
      'Ce qu\'un excès prolongé peut provoquer';

  @override
  String get bilanExcessSource => 'D\'où vient le dépassement';

  @override
  String get bilanWhatToDo => 'Que faire concrètement';

  @override
  String bilanSafetyLimitDetail(String limite, String reference) {
    return 'Limite de sécurité : $limite  ·  $reference';
  }

  @override
  String bilanConcernedFoods(String periode) {
    return 'Les aliments concernés $periode';
  }

  @override
  String get bilanNoFoodIdentifiedPeriod =>
      'Aucun aliment identifié sur cette période.';

  @override
  String get bilanPeriodToday => 'aujourd\'hui';

  @override
  String get bilanPeriodThatDay => 'ce jour-là';

  @override
  String bilanPeriodLastNDays(int days) {
    return 'sur les $days derniers jours';
  }

  @override
  String bilanPeriodOnDate(String date) {
    return 'le $date';
  }

  @override
  String get bilanCarbBreakdownTitle => 'Répartition des glucides';

  @override
  String get bilanCarbBreakdownIntro =>
      'Tous les glucides ne se valent pas. L\'amidon libère son énergie lentement ; les sucres simples, rapidement.';

  @override
  String get bilanNoCarbDataPeriod =>
      'Aucune donnée de glucides détaillée pour cette période.';

  @override
  String get bilanStarchLabel => 'Amidon (glucides complexes)';

  @override
  String get bilanStarchHint =>
      'Céréales, légumineuses, tubercules — énergie durable.';

  @override
  String get bilanSimpleSugarsLabel => 'Sucres simples (total)';

  @override
  String get bilanSimpleSugarsHint =>
      'Assimilation rapide — à privilégier via les fruits entiers.';

  @override
  String get bilanPolyolsHint =>
      'Édulcorants de masse — souvent signe d\'un produit transformé.';

  @override
  String get bilanSimpleSugarsDetailTitle => 'Détail des sucres simples';

  @override
  String get bilanFructoseHint => 'Sucre des fruits et du miel.';

  @override
  String get bilanSaccharoseLabel => 'Saccharose';

  @override
  String get bilanSaccharoseHint => 'Le sucre de table (fructose + glucose).';

  @override
  String get bilanLactoseHint => 'Sucre du lait et des produits laitiers.';

  @override
  String get bilanFruitVsSodaNote =>
      'Un fruit entier et un soda peuvent contenir le même fructose, mais le fruit l\'accompagne de fibres, d\'eau et de vitamines qui en ralentissent l\'absorption. La matrice compte autant que le sucre.';

  @override
  String get dietNoteOmega3NoFish =>
      'Sans poisson, ta meilleure source directe d\'EPA/DHA est un complément d\'oméga 3 issu de micro-algues — c\'est justement là que les poissons puisent les leurs. Les oméga 3 végétaux (ALA du lin, chanvre, noix) restent utiles mais se convertissent mal en EPA/DHA.';

  @override
  String get dietNoteB12Vegan =>
      'La vitamine B12 n\'existe pas dans le végétal : en régime végétalien, une supplémentation est indispensable, pas optionnelle. C\'est le seul nutriment qui fait consensus absolu sur ce point. Vise une prise régulière et surveille ton statut par une prise de sang.';

  @override
  String get dietNoteB12Vegetarian =>
      'En régime végétarien, les œufs et les produits laitiers couvrent une partie de tes besoins en B12, mais surveille ton statut : selon ta consommation, une supplémentation légère peut être utile.';

  @override
  String get dietNoteIronVegetal =>
      'Le fer végétal (non héminique) s\'absorbe moins bien que le fer animal : associe systématiquement une source de vitamine C (citron, poivron, persil) à tes légumineuses et céréales complètes pour en multiplier l\'absorption. Évite thé et café pendant le repas.';

  @override
  String get dietNoteZincVegetal =>
      'Les phytates des céréales et légumineuses freinent l\'absorption du zinc végétal. Le trempage, la germination et la fermentation (pain au levain) les neutralisent en grande partie — un réflexe précieux en régime végétal.';

  @override
  String get dietNoteCalciumVegan =>
      'Sans produits laitiers, mise sur les végétaux riches en calcium bien absorbé (chou kale, brocoli, tofu au sulfate de calcium, amandes) et les eaux minérales calciques. La vitamine D et la K2 restent essentielles pour bien le fixer sur l\'os.';

  @override
  String get dietNoteIodineVegan =>
      'Sans produits de la mer ni laitages, l\'iode peut manquer en régime végétalien : les algues (avec modération, car très concentrées) et le sel iodé sont tes principales sources. Surveille cet apport souvent négligé.';

  @override
  String get dietNoteVitDVegan =>
      'Sans poisson gras ni œufs, l\'alimentation couvre difficilement la vitamine D en régime végétalien : le soleil (voir la page dédiée) et une supplémentation, idéalement d\'origine végétale (lichen), sont à privilégier, surtout d\'octobre à avril.';

  @override
  String get dietNoteProteinVegan =>
      'En régime végétalien, varie tes sources de protéines dans la journée (légumineuses + céréales complètes, tofu, tempeh, oléagineux) pour obtenir tous les acides aminés essentiels. La complémentarité sur la journée suffit, pas besoin de tout combiner à chaque repas.';

  @override
  String get bilanFicheUnavailable => 'Fiche non disponible pour le moment.';

  @override
  String get bilanFicheBenefits => 'Bénéfices santé';

  @override
  String get bilanFicheIntakes => 'Apports conseillés';

  @override
  String get bilanFicheSafetyLimit => 'Limite de sécurité';

  @override
  String get bilanFicheWhereToFind => 'Où en trouver';

  @override
  String get bilanDietAdaptedVegan => 'Adapté à ton régime végétalien';

  @override
  String get bilanDietAdaptedVegetarian => 'Adapté à ton régime végétarien';

  @override
  String get bilanDidYouKnow => 'Le savais-tu ?';

  @override
  String get bilanEducationalDisclaimer =>
      'Informations éducatives basées sur les références ANSES et EFSA. Elles ne remplacent pas un avis médical personnalisé.';

  @override
  String get bilanScoreExplainerTitle => 'Comment est calculée ta note ?';

  @override
  String get bilanScoreExplainerIntro =>
      'Le Score TOTUM combine 5 piliers de ta journée, pondérés selon leur importance pour ta santé, ta longévité et ta performance :';

  @override
  String get bilanPillarFattyAcidsFull => 'Acides gras essentiels';

  @override
  String get bilanPillarVitaminsDetail =>
      'Couverture de tes besoins en vitamines par rapport à tes objectifs du jour.';

  @override
  String get bilanPillarMineralsDetail =>
      'Couverture de tes besoins en minéraux (fer, magnésium, zinc...).';

  @override
  String get bilanPillarFattyAcidsDetail =>
      'Oméga-3/6/9 — indispensables, non fabriqués par le corps.';

  @override
  String get bilanPillarHydrationDetail =>
      'Eau bue + eau apportée par les aliments, vs ton objectif.';

  @override
  String get bilanPillarWatchDetail =>
      'Sucres, sel, graisses saturées — rester sous la limite du jour est le bon signal.';

  @override
  String get bilanSafetyCapTitle => 'Le plafond de sécurité';

  @override
  String get bilanSafetyCapExplainer =>
      'Si un seul élément \"à surveiller\" dépasse fortement ta limite du jour (par exemple bien au-delà du double), ta note est automatiquement plafonnée — même si tout le reste de ta journée est parfait. Un excès important d\'un coup a un vrai impact sur ta santé (cœur, tension), la note doit le montrer clairement, pas le diluer dans une moyenne.';

  @override
  String get bilanScoreLiveNote =>
      'Ta note évolue au fil de la journée, à mesure que tu ajoutes tes repas — c\'est normal, elle reflète ce que tu as réellement mangé jusqu\'ici.';

  @override
  String get bilanScoreSourcesNote =>
      'Fondé sur les recommandations officielles (OMS, EFSA, ANSES) et les index de référence internationaux (Healthy Eating Index, Alternate Healthy Eating Index).';

  @override
  String get bilanSunVitDTitle => 'Vitamine D solaire';

  @override
  String bilanSunVitDAverageDesc(String periode) {
    return 'Moyenne estimée $periode, synthétisée par ta peau au soleil';
  }

  @override
  String bilanSunVitDSingleDesc(String periode) {
    return 'Estimée $periode, synthétisée par ta peau au soleil';
  }

  @override
  String get bilanSunVitDAlreadyCounted =>
      'déjà comptés dans ta ligne \"Vit D\" ci-dessus, en plus de ce que t\'apporte l\'alimentation.';

  @override
  String get bilanSunVitDNoSession =>
      'Aucune session au soleil enregistrée sur cette période — seule la part alimentaire est comptée pour l\'instant.';

  @override
  String get bilanLogSunExposure => 'Enregistrer une exposition au soleil';

  @override
  String bilanConsumedPeriod(String periode) {
    return 'Ce que tu as consommé $periode';
  }

  @override
  String get bilanNoFoodContainedNutrient =>
      'Aucun aliment consommé ne contenait ce nutriment sur cette période. C\'est peut-être là qu\'il faut agir : consulte la fiche pour savoir où le trouver.';

  @override
  String get bilanUnnamedFood => 'Aliment';

  @override
  String bilanIntakeMainFoods(String label) {
    return 'Apport en $label : aliments principaux';
  }

  @override
  String bilanTopContributorsIntro(String label) {
    return 'Voici les aliments qui ont le plus contribué à ton apport en $label ce jour-là, du plus grand au plus petit.';
  }

  @override
  String get bilanNoFoodIdentifiedNutrient =>
      'Aucun aliment identifié pour ce nutriment.';

  @override
  String get bilanOccasionalExcessNote =>
      'Un dépassement ponctuel n\'est généralement pas préoccupant. Si cela se répète souvent, tu peux espacer les aliments les plus concentrés ou en réduire la portion.';

  @override
  String bilanDayTitle(String date) {
    return 'Bilan du $date';
  }

  @override
  String get bilanNoDataForDay => 'Aucune donnée pour ce jour.';

  @override
  String get bilanMacrosCardTitle => 'Macros';

  @override
  String get bilanGroupMacroTargets => 'Macro-cibles';

  @override
  String get bilanGroupIndicative => 'Apports indicatifs';

  @override
  String bilanTargetKcal(String target) {
    return 'Objectif = $target kcal';
  }

  @override
  String bilanConsumedKcal(String value) {
    return 'Consommé = $value kcal';
  }

  @override
  String bilanRemainingKcal(String value) {
    return 'Restant = $value kcal';
  }

  @override
  String bilanExceededByKcal(String value) {
    return 'Dépassé de $value kcal';
  }

  @override
  String bilanMacroProgressOvershot(
      String value, String target, String unit, String excess) {
    return '$value / $target $unit • dépassé de $excess $unit';
  }

  @override
  String bilanMacroProgressRemaining(
      String value, String target, String unit, String remaining) {
    return '$value / $target $unit • reste $remaining $unit';
  }

  @override
  String bilanExceedsSafetyLimit(String ul, String unit) {
    return 'Dépasse la limite de sécurité ($ul $unit/jour)';
  }

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navJournal => 'Journal';

  @override
  String get navBilan => 'Bilan';

  @override
  String get navConseils => 'Conseils';

  @override
  String get bilanGeneratingReport => 'Génération du rapport…';

  @override
  String get bilanNoDataToDisplay => 'Aucune donnée à afficher.';

  @override
  String get bilanSpanDay => 'Jour';

  @override
  String get bilanSpan7d => '7 j';

  @override
  String get bilanSpan30d => '30 j';

  @override
  String get bilanSpan90d => '90 j';

  @override
  String get bilanEnergyBalance7d => 'Ton équilibre énergétique (7 jours)';

  @override
  String get bilanEnergyBalance30d => 'Ton équilibre énergétique (30 jours)';

  @override
  String get bilanEnergyBalance90d => 'Ton équilibre énergétique (90 jours)';

  @override
  String get bilanEnergyBalance1d => 'Ton équilibre énergétique (1 jour)';

  @override
  String bilanVeryConsistent(String label, String delta) {
    return 'Très régulier : ton apport moyen colle à $label sur cette période (écart de $delta kcal/j).';
  }

  @override
  String bilanAverageDeltaSummary(String delta, String dir, String label) {
    return 'En moyenne, tu es à $delta kcal/j $dir de $label.';
  }

  @override
  String get bilanAboveDir => 'au-dessus';

  @override
  String get bilanBelowDir => 'en dessous';

  @override
  String get bilanYourEstimatedExpenditure => 'ta dépense estimée';

  @override
  String get bilanYourGoal => 'ton objectif';

  @override
  String get bilanMonthJan => 'Jan';

  @override
  String get bilanMonthFeb => 'Fév';

  @override
  String get bilanMonthMar => 'Mar';

  @override
  String get bilanMonthApr => 'Avr';

  @override
  String get bilanMonthMay => 'Mai';

  @override
  String get bilanMonthJun => 'Juin';

  @override
  String get bilanMonthJul => 'Juil';

  @override
  String get bilanMonthAug => 'Août';

  @override
  String get bilanMonthSep => 'Sep';

  @override
  String get bilanMonthOct => 'Oct';

  @override
  String get bilanMonthNov => 'Nov';

  @override
  String get bilanMonthDec => 'Déc';

  @override
  String get bilanVsGoal => 'Vs. Objectif';

  @override
  String get bilanVsExpenditure => 'Vs. Dépense estimée';

  @override
  String get bilanExpenditureThatDay => 'Dépense estimée ce jour-là';

  @override
  String get bilanGoalThatDay => 'Objectif ce jour-là';

  @override
  String get bilanAverageLabel => 'Moyenne';

  @override
  String get bilanAverageDeltaLabel => 'Écart moyen';

  @override
  String get bilanInTargetLabel => 'Dans la cible';

  @override
  String get bilanInTargetLegend => 'Dans la cible (±10 %)';

  @override
  String get bilanModerateDeltaLegend => 'Écart modéré (±10-25 %)';

  @override
  String get bilanLargeDeltaLegend => 'Écart important (>25 %)';

  @override
  String get bilanGoalChangedHint =>
      'Ton objectif a changé pendant cette période : chaque barre est comparée à l\'objectif qui était le tien ce jour-là (touche une barre pour le détail).';

  @override
  String get bilanTapBarHint => 'Touche une barre pour voir le détail du jour.';

  @override
  String get bilanHydrationTitle => 'Hydratation';

  @override
  String get bilanDrinksLabel => 'Boissons';

  @override
  String get bilanFoodsWaterLabel => 'Aliments';

  @override
  String get bilanHydrationGoalReached =>
      'Objectif d\'hydratation atteint, bravo !';

  @override
  String get bilanHydrationReminder =>
      'Pense à boire : vise environ 1,5 L de boissons sur la journée';

  @override
  String get bilanHydrationAddGlasses =>
      'Tu peux ajouter des verres depuis l\'onglet Journal';

  @override
  String get bilanTopHydratingFoods => 'Principaux aliments hydratants :';

  @override
  String get bilanAverageSuffix => ' (moyenne)';

  @override
  String get bilanPeriodOver7d => 'sur 7 jours';

  @override
  String get bilanPeriodOver30d => 'sur 30 jours';

  @override
  String get bilanPeriodOver90d => 'sur 90 jours';

  @override
  String bilanRefLabelLine(String label, String value) {
    return '\n$label : $value kcal';
  }

  @override
  String bilanAboveKcal(String value) {
    return '\n+$value kcal au-dessus';
  }

  @override
  String bilanBelowKcal(String value) {
    return '\n$value kcal en dessous';
  }

  @override
  String get bilanRightOnTarget => '\nPile dans la cible';

  @override
  String bilanHydrationOfTotal(String total, String target) {
    return '$total ml sur un objectif de $target ml d\'eau totale';
  }

  @override
  String get nutrientVitaminEFull => 'Vitamine E';

  @override
  String get nutrientVitaminB1Full => 'Vitamine B1';

  @override
  String get nutrientVitaminB2Full => 'Vitamine B2';

  @override
  String get nutrientVitaminB3Full => 'Vitamine B3';

  @override
  String get nutrientVitaminB5Full => 'Vitamine B5';

  @override
  String get nutrientVitaminB6Full => 'Vitamine B6';

  @override
  String get nutrientVitaminAFull => 'Vitamine A';

  @override
  String get nutrientOmega3MarineFull => 'Oméga 3 marins (EPA/DHA)';

  @override
  String get nutrientOmega9Short => 'Oméga 9';

  @override
  String get nutrientOmega6Short => 'Oméga 6';

  @override
  String get nutrientOmega3Short => 'Oméga 3';

  @override
  String get consPriorityNutritionalTitle => 'Priorités nutritionnelles';

  @override
  String get consNoDeficitToday =>
      'Bel équilibre aujourd\'hui !\nAucune carence marquée détectée.';

  @override
  String get consPriorityIntro =>
      'Classées par priorité, en tenant compte de l\'importance de chaque nutriment. Touche une carence pour voir les aliments qui la comblent.';

  @override
  String consCoveredToday(int percent) {
    return '$percent % de ta cible couverte aujourd\'hui';
  }

  @override
  String get consWhatYouAteToday => 'Ce que tu as consommé aujourd\'hui';

  @override
  String get consNoFoodContainedTodayAction =>
      'Aucun aliment consommé aujourd\'hui n\'en contenait. C\'est là qu\'il faut agir : consulte la fiche ci-dessous pour savoir où le trouver.';

  @override
  String consWhereToFindReadFiche(String label) {
    return 'Où en trouver ? Lire la fiche $label';
  }

  @override
  String get consRecipeAddedSnackbar => 'Recette ajoutée à tes recettes !';

  @override
  String get consAddRecipeError => 'Erreur lors de l\'ajout.';

  @override
  String get consHealthyScoreTitle => 'Healthy Score';

  @override
  String get consHealthyScoreIntro =>
      'Une note sur 100 qui évalue la qualité nutritionnelle globale du plat, calculée sur ses vraies valeurs CIQUAL (macros + micronutriments) :';

  @override
  String get consCriteriaMicronutrients => 'Micronutriments';

  @override
  String get consCriteriaMicronutrientsDetail =>
      '20 pts — diversité vitamines/minéraux';

  @override
  String get consCriteriaProteinDetail => '20 pts — densité protéique du plat';

  @override
  String get consCriteriaFiberDetail => '15 pts — apport en fibres';

  @override
  String get consCriteriaFatQuality => 'Qualité des lipides';

  @override
  String get consCriteriaFatQualityDetail =>
      '15 pts — part d\'acides gras insaturés';

  @override
  String get consCriteriaCalorieDensity => 'Densité calorique';

  @override
  String get consCriteriaCalorieDensityDetail =>
      '15 pts — pénalise les plats très caloriques au poids';

  @override
  String get consCriteriaSugarsDetail => '7,5 pts — maîtrise des sucres';

  @override
  String get consCriteriaSodiumDetail => '7,5 pts — maîtrise du sel';

  @override
  String get consHealthyScoreLegend =>
      '70-100 : excellent  •  45-69 : correct  •  <45 : à limiter';

  @override
  String get consHealthyScorePreworkoutNote =>
      'Les collations Pré-workout sont volontairement pauvres en fibres/protéines (digestion rapide avant l\'effort) : un score plus bas y est normal, pas un signal à éviter juste avant une séance.';

  @override
  String get consFitScoreTitle => 'Fit avec ta journée';

  @override
  String get consFitScoreIntro =>
      'Un pourcentage qui indique à quel point la taille et l\'équilibre de cette recette sont cohérents pour ce type de repas, compte tenu de ce qu\'il te reste à manger aujourd\'hui et de tes objectifs personnels (calories, protéines, glucides, lipides).';

  @override
  String get consCriteriaCalories => 'Calories';

  @override
  String get consFitCriteriaCaloriesDetail =>
      '40 % — cohérence avec une portion type de ce repas';

  @override
  String get consFitCriteriaProteinDetail =>
      '30 % — cohérence avec tes protéines restantes';

  @override
  String get consFitCriteriaCarbsDetail =>
      '15 % — cohérence avec tes glucides restants';

  @override
  String get consFitCriteriaFatDetail =>
      '15 % — cohérence avec tes lipides restants';

  @override
  String get consFitScoreLegend =>
      'Proche de 100 % : une taille de portion cohérente pour ce repas, compte tenu de ce qu\'il te reste aujourd\'hui  •  Score plus bas : le plat est nettement trop copieux ou trop léger pour ce moment de la journée.';

  @override
  String get consFitScoreDetail =>
      'Le calcul tient compte du type de repas (un petit-déjeuner ou une collation ne doivent pas peser aussi lourd qu\'un déjeuner) et évolue au fil de la journée selon ce que tu as déjà mangé. C\'est un indicateur de timing/portion, pas de qualité nutritionnelle : regarde-le en complément du Healthy Score, pas à sa place.';

  @override
  String get consRecipeScreenTitle => 'Recette TOTUM';

  @override
  String consHealthyScoreBadge(int score) {
    return 'Healthy Score $score/100';
  }

  @override
  String consFitBadge(int score) {
    return 'Fit $score% avec ta journée';
  }

  @override
  String get consPreparationTitle => 'Préparation';

  @override
  String consRecipeValuesFor(String grams) {
    return 'Valeurs pour la recette ($grams g)';
  }

  @override
  String get consAfterThisMeal => 'Après ce repas, il te restera';

  @override
  String get consIngredientsTitle => 'Ingrédients';

  @override
  String get consStatProt => 'Prot';

  @override
  String get consStatCarb => 'Gluc';

  @override
  String get consStatFat => 'Lip';

  @override
  String get consAddedToRecipes => 'Ajoutée à tes recettes';

  @override
  String get consAddToMyRecipes => 'Ajouter à mes recettes';

  @override
  String get consFindInJournalNote =>
      'Une fois ajoutée, retrouve cette recette dans ton onglet Journal pour l\'intégrer à tes repas.';

  @override
  String get consCatAll => 'Toutes';

  @override
  String get consCatBreakfast => 'Petit-déjeuner';

  @override
  String get consCatLunch => 'Déjeuner';

  @override
  String get consCatDinner => 'Dîner';

  @override
  String get consCatSnack => 'Collation';

  @override
  String get consCatPreworkout => 'Pré-workout';

  @override
  String get consTagLight => 'Léger';

  @override
  String get consTagHighProtein => 'Hyperprotéiné';

  @override
  String get consTagQuick => 'Rapide';

  @override
  String get consTagGlutenFree => 'Sans gluten';

  @override
  String get consTagLactoseFree => 'Sans lactose';

  @override
  String get consTagPostWorkout => 'Post-training';

  @override
  String get consRecipesTotumTitle => 'Recettes TOTUM';

  @override
  String consRecipesCountSorted(int count) {
    return '$count recettes triées par objectif';
  }

  @override
  String get consForYouChip => 'Pour toi';

  @override
  String get consListView => 'Affichage liste';

  @override
  String get consGridView => 'Affichage grille';

  @override
  String get consResetFilters => 'Réinitialiser les filtres';

  @override
  String get consSearchByIngredient =>
      'Chercher par ingrédient (ex. poulet, riz...)';

  @override
  String get consForYouToday => 'Pour toi aujourd\'hui';

  @override
  String get consNoRecipe => 'Aucune recette';

  @override
  String consRecipesSelectedForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recettes sélectionnées pour toi',
      one: '1 recette sélectionnée pour toi',
    );
    return '$_temp0';
  }

  @override
  String consRecipesCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recettes',
      one: '1 recette',
    );
    return '$_temp0';
  }

  @override
  String get consNoAdviceAvailable => 'Aucun conseil disponible.';

  @override
  String get consTabCoaching => 'Coaching';

  @override
  String get consTabVitality => 'Vitalité';

  @override
  String get consTabRecipes => 'Recettes';

  @override
  String get consMedicalDisclaimer =>
      'Ces conseils ne remplacent pas un avis médical. En cas de pathologie ou de doute, rapprochez-vous de votre professionnel de santé.';

  @override
  String get consGreetingNight => 'Belle nuit';

  @override
  String get consGreetingMorning => 'Bonjour';

  @override
  String get consGreetingAfternoon => 'Bel après-midi';

  @override
  String get consGreetingEvening => 'Bonne soirée';

  @override
  String get consGreetingLateNight => 'Bonne nuit';

  @override
  String get consCoachTodayLabel => 'Ton coach TOTUM du jour';

  @override
  String get consDefaultCoachQuote =>
      'Chaque choix aligné aujourd\'hui construit ta vitalité de demain.';

  @override
  String consScoreProvisional(int pct) {
    return 'Provisoire · $pct % de ta journée';
  }

  @override
  String get consSeeDetail => 'Voir le détail';

  @override
  String get consPriorityOfTheDay => 'Priorité du jour';

  @override
  String get consNoDeficitTodayShort =>
      'Aucune carence marquée aujourd\'hui. Beau travail !';

  @override
  String get consTapToSeeWhereToFind => 'Appuie pour voir où en trouver';

  @override
  String get consDailyAdviceTitle => 'Conseils du jour';

  @override
  String consPersonalizedAdviceCount(int count) {
    return '$count conseils personnalisés pour aujourd\'hui';
  }

  @override
  String get consAdviceCategories =>
      'Nutrition, mouvement, sommeil, stress, mindset';

  @override
  String get consWellbeingTitle => 'Bien-être holistique';

  @override
  String get consWellbeingIntro =>
      'Les trois piliers de ta vitalité au quotidien : sommeil, stress et exposition au soleil.';

  @override
  String get consSleepVeryShort => 'Très court';

  @override
  String get consSleepInsufficient => 'Insuffisant';

  @override
  String get consSleepCorrect => 'Correct';

  @override
  String get consSleepIdeal => 'Idéal';

  @override
  String get consSleepLong => 'Long';

  @override
  String get consStressSerene => 'Serein';

  @override
  String get consStressCalm => 'Calme';

  @override
  String get consStressModerate => 'Modéré';

  @override
  String get consStressHigh => 'Élevé';

  @override
  String get consStressVeryHigh => 'Très élevé';

  @override
  String get consSleepTipVeryShort =>
      'Une nuit aussi courte pèse sur ta récupération et tes fringales dès demain — priorise le coucher ce soir.';

  @override
  String get consSleepTipUnder6 =>
      'Sous 6h de façon répétée, le risque de fatigue et de fringales augmente nettement — regagne du terrain progressivement.';

  @override
  String get consSleepTipBorderline =>
      'Zone \"limite acceptable\" pour les experts du sommeil : quelques minutes de plus suffiraient à basculer dans la zone recommandée.';

  @override
  String get consSleepTipRecommended =>
      'Tu es dans la fourchette recommandée pour un adulte — la zone la plus favorable à ta récupération.';

  @override
  String get consSleepTipAcceptableLong =>
      'Toujours une zone jugée acceptable — un besoin naturel de dormir un peu plus n\'est pas un problème en soi.';

  @override
  String get consSleepTipTooLong =>
      'Au-delà de 10h de façon récurrente, ça vaut la peine de vérifier la qualité de ton sommeil si la fatigue persiste.';

  @override
  String get consStressTipVeryLow =>
      'Un très bon terrain pour ta récupération globale — profites-en pour ancrer ce qui fonctionne bien pour toi.';

  @override
  String get consStressTipHealthy =>
      'Un niveau sain. Garde les leviers qui t\'aident à rester dans cette zone.';

  @override
  String get consStressTipModerate =>
      'Rien d\'alarmant, mais quelques minutes de respiration lente peuvent t\'aider à redescendre encore.';

  @override
  String get consStressTipHigh =>
      'À ce niveau, le corps carbure aux hormones du stress — une pause respiration ou une marche peuvent vraiment faire la différence aujourd\'hui.';

  @override
  String get consStressTipVeryHigh =>
      'Un niveau qui mérite ton attention en priorité aujourd\'hui — commence par une pause calme avant toute autre chose.';

  @override
  String get consSleepPillarTitle => 'Sommeil';

  @override
  String get consEveningRitualTitle => 'Rituel du soir';

  @override
  String get consSleepBetterSubtitle => 'Mieux dormir';

  @override
  String get consStressPillarTitle => 'Stress';

  @override
  String get consBreathingTitle => 'Respiration';

  @override
  String get consAntiStressSubtitle => 'Anti-stress';

  @override
  String get consTodayAnalysisTitle => 'Ton analyse du jour';

  @override
  String get consUpdateMyAdviceButton => 'Mettre à jour mes conseils';

  @override
  String get consSunVitDCardTitle => 'Soleil & vitamine D';

  @override
  String get consSunVitDCardIntro =>
      'Une bonne partie de ta vitamine D vient de l\'exposition au soleil, pas seulement de l\'alimentation. Estime ta synthèse du jour pour savoir où tu en es.';

  @override
  String get consEstimateMySynthesis => 'Estimer ma synthèse';

  @override
  String get breathPhaseInhale => 'Inspire';

  @override
  String get breathPhaseHold => 'Retiens';

  @override
  String get breathPhaseExhale => 'Expire';

  @override
  String get breathPhaseInhaleBelly => 'Inspire (ventre)';

  @override
  String get breathPhaseInhaleTopUp => 'Inspire (complément)';

  @override
  String get breathCoherenceName => 'Cohérence cardiaque';

  @override
  String get breathCoherenceDesc =>
      'Un rythme régulier où l\'inspiration et l\'expiration durent le même temps. Le classique « 365 » : 3 fois par jour, 6 respirations par minute, pendant 5 minutes.';

  @override
  String get breathCoherenceBenefit =>
      'La technique anti-stress la plus étudiée. Elle synchronise le cœur et la respiration, équilibre le système nerveux autonome, fait baisser le cortisol et améliore la variabilité cardiaque — un marqueur clé de santé et de longévité.';

  @override
  String get breathSquareName => 'Respiration carrée';

  @override
  String get breathSquareDesc =>
      'Quatre temps égaux : inspire, retiens poumons pleins, expire, retiens poumons vides. On dessine mentalement un carré. Utilisée par les forces spéciales pour rester calme sous pression.';

  @override
  String get breathSquareBenefit =>
      'Les deux rétentions renforcent le contrôle du souffle et la concentration. Idéale pour retrouver son sang-froid avant un événement stressant, calmer le mental et ancrer l\'attention dans l\'instant.';

  @override
  String get breathWeil478Name => '4-7-8';

  @override
  String get breathWeil478Desc =>
      'Inspire 4 secondes, retiens 7 secondes, expire lentement sur 8 secondes. Popularisée par le Dr Andrew Weil, parfois surnommée \"calmant naturel\".';

  @override
  String get breathWeil478Benefit =>
      'L\'expiration longue associée à la rétention active fortement le système nerveux parasympathique — celui du repos et de la récupération. Particulièrement efficace pour redescendre avant le sommeil ou calmer une montée d\'anxiété.';

  @override
  String get breathDiaphragmaticName => 'Respiration ventrale';

  @override
  String get breathDiaphragmaticDesc =>
      'La base de toute pratique respiratoire : on gonfle le ventre à l\'inspire (pas la poitrine), on le relâche à l\'expire. Aucune rétention, aucun rythme complexe à retenir.';

  @override
  String get breathDiaphragmaticBenefit =>
      'Réapprend à utiliser pleinement le diaphragme plutôt qu\'une respiration thoracique courte et superficielle — la base sur laquelle s\'appuient toutes les autres techniques. Le point de départ le plus accessible pour découvrir la respiration guidée.';

  @override
  String get breathPhysiologicalSighName => 'Soupir physiologique';

  @override
  String get breathPhysiologicalSighDesc =>
      'Deux inspirations courtes par le nez, l\'une après l\'autre sans expirer entre les deux, puis une longue expiration par la bouche. Le geste que le corps fait déjà naturellement pour \"souffler\".';

  @override
  String get breathPhysiologicalSighBenefit =>
      'La double inspiration rouvre les petits sacs pulmonaires (alvéoles) affaissés, l\'expiration longue qui suit déclenche un apaisement quasi immédiat. Dans une étude comparative, cette technique a fait mieux que la respiration carrée, l\'hyperventilation cyclique ET la méditation de pleine conscience pour améliorer l\'humeur.';

  @override
  String get consPhaseDuration => 'Durée de chaque phase';

  @override
  String get breathCyclicHyperventilationName => 'Hyperventilation cyclique';

  @override
  String get breathCyclicHyperventilationDesc =>
      'Une série de 30 respirations amples et rapides, suivie d\'une rétention poumons vides, puis d\'une courte récupération. On répète l\'ensemble sur plusieurs \"rounds\", les yeux fermés du début à la fin — aucune action requise pendant la séance.';

  @override
  String get breathCyclicHyperventilationBenefit =>
      'Un vrai coup de fouet : la phase rapide augmente temporairement l\'alcalinité du sang, la rétention qui suit entraîne la tolérance au CO2 et le contrôle du souffle. Une pratique intense, à réserver aux moments où vous cherchez de l\'énergie ou à repousser vos limites de contrôle respiratoire — pas une technique de détente.';

  @override
  String get breathCyclicHyperventilationSafetyWarning =>
      'Cette technique fait momentanément baisser le taux de CO2 dans le sang et peut provoquer des étourdissements, des picotements ou, rarement, un évanouissement.\n\nÀ ne jamais pratiquer :\n• en étant debout, en conduisant, en nageant ou dans/près de l\'eau (risque de noyade documenté en cas de perte de connaissance)\n• en cas de grossesse\n• en cas d\'épilepsie ou d\'antécédents de convulsions\n• en cas de troubles cardiovasculaires\n• en cas de malaises ou évanouissements déjà connus\n\nPratiquez toujours assis ou allongé, dans un endroit sûr. En cas de doute médical, demandez l\'avis d\'un professionnel de santé avant de commencer.';

  @override
  String get consNumberOfRounds => 'Nombre de rounds';

  @override
  String get consHoldDurationPerRound => 'Durée de rétention par round';

  @override
  String get consNoActionDuringSession =>
      'Aucune action à faire pendant la séance — réglez chaque round à l\'avance selon votre expérience.';

  @override
  String consRoundLabel(int n) {
    return 'Round $n';
  }

  @override
  String consSessionDurationEstimate(String min) {
    return '≈ $min min de séance';
  }

  @override
  String get consStartButton => 'Commencer';

  @override
  String consRoundOf(int round, int total) {
    return 'Round $round / $total';
  }

  @override
  String get consAmpleRapidBreaths => 'Respirations amples et rapides';

  @override
  String get consHoldEmptyLungs => 'Retenez, poumons vides';

  @override
  String get consCloseEyesFollowSound =>
      'Fermez les yeux, laissez-vous guider par le son';

  @override
  String get consInhaleAndHoldRecovery => 'Inspirez et retenez — récupération';

  @override
  String get consSessionComplete => 'Séance terminée';

  @override
  String consRoundsCompletedNote(int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds complétés. Prends un instant pour ressentir.',
      one: '1 round complété. Prends un instant pour ressentir.',
    );
    return '$_temp0';
  }

  @override
  String get consFinishButton => 'Terminer';

  @override
  String get consBeforeYouStart => 'Avant de commencer';

  @override
  String get consReadAndUnderstand =>
      'J\'ai lu et je comprends ces précautions';

  @override
  String get consContinueButton => 'Continuer';

  @override
  String get consAdvancedProtocol => 'Protocole avancé';

  @override
  String get consStopButton => 'Arrêter';

  @override
  String consCycleOf(int cycle, int total) {
    return 'Cycle $cycle / $total';
  }

  @override
  String get consNumberOfCycles => 'Nombre de cycles';

  @override
  String get consGuidanceSounds => 'Sons de guidage';

  @override
  String get consStartSessionButton => 'Commencer la séance';

  @override
  String get consSessionCompleteSnackbar =>
      'Séance terminée. Prends un instant pour ressentir.';

  @override
  String get advFirstLeverTitle => '🎯 Premier levier : nourrir ton TOTUM';

  @override
  String get advFirstLeverTheme => 'Construire ta base de données personnelle';

  @override
  String get advFirstLeverInsight =>
      'Plus tu enregistres tes repas, plus les conseils deviennent précis, utiles et motivants.';

  @override
  String get advNoJournalCritique =>
      'Impossible de détecter des déficits sans journal.';

  @override
  String get advNoJournalBenefit =>
      'Tu construis ton Totem alimentaire : vision claire de ce que tu offres à ton corps.';

  @override
  String get advNoJournalSource =>
      'Enregistre petit-déj + repas principal, avec quantités & aliments détaillés.';

  @override
  String get advNoJournalTip =>
      'Commence par tes repas « typiques », on raffinera ensuite sur les micronutriments.';

  @override
  String get advNoJournalChrono =>
      'Sans sommeil/eau/stress renseignés, le lien sensations ↔ hygiène de vie reste flou.';

  @override
  String get advNoJournalAction =>
      'Ce soir, note heure de coucher, durée, stress (1–10). Demain matin : humeur/énergie.';

  @override
  String get advNoJournalLogTitle => '📝 Active ton suivi holistique';

  @override
  String get advNoJournalDefi24h =>
      'Défi 24h : renseigne 2 repas complets + sommeil, eau, stress.';

  @override
  String get advNoJournalQuote => '« Ce qui se mesure se transforme. »';

  @override
  String get advNoJournalMacroTitle => '⚙️ Macros en attente';

  @override
  String get advNoJournalMacroBody =>
      'Dès qu\'un repas est saisi, je peux vérifier énergie & protéines vs ton objectif.';

  @override
  String get advActivityCoachTitle => '🏃‍♂️ Coach activité & récupération';

  @override
  String get advActivityCoachSportif =>
      'Note tes entraînements + repas pré/post pour affiner énergie & timing.';

  @override
  String get advActivityCoachSedentary =>
      '2–3 créneaux de 20–30 min/semaine (marche rapide, vélo doux, renfo).';

  @override
  String get advDefaultMindsetTitle => '🧠 Progression > perfection';

  @override
  String get advDefaultMindsetBody =>
      'Chaque repas aligné est un vote pour ton identité.';

  @override
  String get advLogFieldSleep => 'Durée de sommeil (heures)';

  @override
  String get advLogFieldWater => 'Litres d\'eau (hors café/alcool)';

  @override
  String get advLogFieldStress => 'Stress ressenti (1–10)';

  @override
  String get advDashboardLogTitle => '🧭 Ajuste ton tableau de bord holistique';

  @override
  String get advOmega9Critique => 'Oméga-9 en dessous de la zone optimale.';

  @override
  String get advOmega9Benefit =>
      'Soutien cardio-métabolique & souplesse membranaire.';

  @override
  String get advOmega9Source =>
      'Huile d\'olive, avocat, amandes/noisettes au quotidien.';

  @override
  String get advOmega9Tip =>
      'Utilise l\'huile d\'olive à cru/fin de cuisson douce.';

  @override
  String get advOmega6Critique => 'Oméga-6 (LA) un peu bas.';

  @override
  String get advOmega6Benefit =>
      'Structure membranaire, peau & voies hormonales.';

  @override
  String get advOmega6Source =>
      'Huiles vierges (tournesol bio), noix/graines variées.';

  @override
  String get advOmega6Tip => 'Évite les huiles raffinées surchauffées.';

  @override
  String get advOmega3AlaCritique => 'Oméga-3 ALA insuffisants.';

  @override
  String get advOmega3AlaBenefit =>
      'Précurseur végétal des oméga-3 marins EPA/DHA.';

  @override
  String get advOmega3AlaSource =>
      '1 c.s lin/chia moulus/jour ou quelques noix.';

  @override
  String get advOmega3AlaTip => 'Mouds le lin/chia juste avant de consommer.';

  @override
  String get advOmega3Critique => 'Oméga-3 ALA (végétaux) sous la cible.';

  @override
  String get advOmega3Benefit =>
      'Précurseur végétal des oméga-3, anti-inflammatoire.';

  @override
  String get advOmega3Source =>
      'Graines de chanvre/lin moulues, noix, huile de colza.';

  @override
  String get advOmega3Tip => 'Mouds les graines juste avant de consommer.';

  @override
  String get advOmega3MarineCritique => 'Oméga-3 marins sous la cible.';

  @override
  String get advOmega3MarineBenefit =>
      'Clarté mentale, récupération, anti-inflammation.';

  @override
  String get advOmega3MarineSource =>
      '2×/sem poisson gras (sardines/maquereau/hareng).';

  @override
  String get advOmega3MarineTip => 'Cuisson douce + bons lipides.';

  @override
  String get advVitACritique => 'Vitamine A en dessous de l\'optimum.';

  @override
  String get advVitABenefit => 'Vision nocturne, peau/muqueuses, immunité.';

  @override
  String get advVitASource =>
      'Carotte/patate douce + abats/œufs (selon choix).';

  @override
  String get advVitATip => 'Associe à un peu de gras pour conversion.';

  @override
  String get advVitDCritique => 'Vitamine D probablement insuffisante.';

  @override
  String get advVitDBenefit => 'Immunité, force, humeur, santé osseuse.';

  @override
  String get advVitDSource => 'Sardines/maquereau/œufs entiers, lumière matin.';

  @override
  String get advVitDTip => 'Lipides de qualité au repas contenant vit D.';

  @override
  String get advVitECritique => 'Vitamine E insuffisante.';

  @override
  String get advVitEBenefit => 'Antioxydant des membranes cellulaires.';

  @override
  String get advVitESource => 'Huiles vierges, amandes, noisettes, graines.';

  @override
  String get advVitETip => 'Utilisation à froid/cuisson douce.';

  @override
  String get advVitKCritique => 'Vitamine K un peu juste.';

  @override
  String get advVitKBenefit => 'Coagulation équilibrée & santé osseuse.';

  @override
  String get advVitKSource => 'Légumes verts + un filet d\'huile.';

  @override
  String get advVitKTip => 'Associe verts feuillus à un peu de lipides.';

  @override
  String get advVitCCritique => 'Vitamine C sous optimal.';

  @override
  String get advVitCBenefit => 'Antioxydant, immunité, absorption du fer.';

  @override
  String get advVitCSource => 'Kiwi, agrumes, poivron cru, persil.';

  @override
  String get advVitCTip => 'Consomme plutôt cru/peu cuit.';

  @override
  String get advB123Critique => 'B1/B2/B3 un peu en deçà.';

  @override
  String get advB123Benefit => 'Métabolisme énergétique & système nerveux.';

  @override
  String get advB123Source =>
      'Céréales complètes, légumineuses, poissons/œufs.';

  @override
  String get advB123Tip => 'Réduis l\'ultra-transformé pauvre en B.';

  @override
  String get advB56Critique => 'B5/B6 sous la cible.';

  @override
  String get advB56Benefit => 'Stress, neurotransmetteurs, AA.';

  @override
  String get advB56Source => 'Volailles, banane, pois chiches, œufs, avocat.';

  @override
  String get advB56Tip => 'Répartis sur la journée.';

  @override
  String get advB9Critique => 'Folates (B9) insuffisants.';

  @override
  String get advB9Benefit => 'Renouvellement cellulaire & qualité du sang.';

  @override
  String get advB9Source => 'Verts feuillus, légumineuses, herbes fraîches.';

  @override
  String get advB9Tip => 'Part crue ou vapeur douce.';

  @override
  String get advB12Critique => 'Vitamine B12 basse.';

  @override
  String get advB12Benefit => 'Système nerveux & globules rouges.';

  @override
  String get advB12Source => 'Produits animaux ou aliments enrichis.';

  @override
  String get advB12Tip => 'Vegan strict : discuter supplémentation pro.';

  @override
  String get advCalciumCritique => 'Calcium sous la cible.';

  @override
  String get advCalciumBenefit =>
      'Solidité osseuse & signalisation cellulaire.';

  @override
  String get advCalciumSource =>
      'Laitiers/alternatives, eaux calciques, tahini.';

  @override
  String get advCalciumTip => 'Répartis + statut vit D correct.';

  @override
  String get advCopperCritique => 'Cuivre un peu faible.';

  @override
  String get advCopperBenefit => 'Collagène, vaisseaux, métabolisme du fer.';

  @override
  String get advCopperSource => 'Fruits de mer, cacao, noix/graines.';

  @override
  String get advCopperTip => 'Associe à alimentation variée.';

  @override
  String get advIronCritique => 'Fer sous-optimal.';

  @override
  String get advIronBenefit => 'Oxygénation musculaire & énergie.';

  @override
  String get advIronSource => 'Légumineuses/abats/viandes + vit C.';

  @override
  String get advIronTip => 'Évite thé/café juste après repas riches en fer.';

  @override
  String get advIodineCritique => 'Iode plutôt bas.';

  @override
  String get advIodineBenefit => 'Thyroïde → métabolisme & température.';

  @override
  String get advIodineSource =>
      'Sel iodé, poissons, fruits de mer, algues raisonnées.';

  @override
  String get advIodineTip => 'Évite excès d\'algues si pathologie thyroïde.';

  @override
  String get advMagnesiumCritique => 'Magnésium insuffisant.';

  @override
  String get advMagnesiumBenefit => 'Relaxation nerveuse/musculaire, sommeil.';

  @override
  String get advMagnesiumSource =>
      'Amandes, chocolat noir, verts feuillus, eaux magnésiennes.';

  @override
  String get advMagnesiumTip => 'Limite café tardif ; associe B6.';

  @override
  String get advManganeseCritique => 'Manganèse bas.';

  @override
  String get advManganeseBenefit => 'Cofacteur antioxydant.';

  @override
  String get advManganeseSource =>
      'Céréales complètes, noix, thé vert (modéré).';

  @override
  String get advManganeseTip => 'Limite raffinés pauvres en oligo-éléments.';

  @override
  String get advPhosphorusCritique => 'Phosphore légèrement bas.';

  @override
  String get advPhosphorusBenefit => 'Structure os/dents & énergie.';

  @override
  String get advPhosphorusSource => 'Poisson, œufs, oléagineux.';

  @override
  String get advPhosphorusTip => 'Évite sodas aux phosphates ajoutés.';

  @override
  String get advPotassiumCritique => 'Potassium insuffisant.';

  @override
  String get advPotassiumBenefit =>
      'Équilibre tensionnel, contraction musculaire.';

  @override
  String get advPotassiumSource =>
      'Banane, avocat, verts, patate douce, légumineuses.';

  @override
  String get advPotassiumTip => 'Une part crue/vapeur pour préserver minéraux.';

  @override
  String get advSeleniumCritique => 'Sélénium un peu juste.';

  @override
  String get advSeleniumBenefit => 'Antioxydant clé + thyroïde.';

  @override
  String get advSeleniumSource =>
      'Poisson, fruits de mer, œufs (mieux absorbés).';

  @override
  String get advSeleniumTip => 'Évite les excès prolongés.';

  @override
  String get advSodiumCritique => 'Sodium un peu bas vs besoins.';

  @override
  String get advSodiumBenefit => 'Hydrique, conduction nerveuse.';

  @override
  String get advSodiumSource =>
      'Sel de qualité sur aliments bruts si transpiration.';

  @override
  String get advSodiumTip => 'Évite ultra-salés transformés.';

  @override
  String get advZincCritique => 'Zinc possiblement insuffisant.';

  @override
  String get advZincBenefit => 'Immunité, peau, hormones.';

  @override
  String get advZincSource => 'Fruits de mer, bœuf, graines de courge.';

  @override
  String get advZincTip => 'Limite excès de sucre.';

  @override
  String get advFibersCritique => 'Fibres sous 30 g/j.';

  @override
  String get advFibersBenefit => 'Microbiote, satiété, glycémie.';

  @override
  String get advFibersSource =>
      '+Légumineuses, légumes à chaque repas, fruits entiers.';

  @override
  String get advFibersTip => 'Monte progressivement + eau suffisante.';

  @override
  String get advDefaultCritique =>
      'Un ou plusieurs micronutriments sous la cible.';

  @override
  String get advDefaultBenefit =>
      'Plus de densité micro = énergie & sommeil meilleurs.';

  @override
  String get advDefaultSource => 'Aliments bruts variés, poissons & œufs.';

  @override
  String get advDefaultTip => 'Assiette colorée = spectre micro plus large.';

  @override
  String get advMoveTodayDefault => 'Bouge un peu aujourd\'hui 😉';

  @override
  String get advPackLowSleepHighStress1 =>
      '1️⃣ 20–30 min dehors (lumière naturelle) + 5 min de respiration nasale lente en fin de journée.';

  @override
  String get advPackLowSleepHighStress2 =>
      '2️⃣ Couvre-feu digital 45–60 min avant le coucher + lecture légère ou journal de gratitude (3 points).';

  @override
  String get advPackLowSleepHighStress3 =>
      '3️⃣ Dîner plus tôt, léger et peu sucré, puis douche tiède et respiration 4–6 pendant 3–5 min.';

  @override
  String get advPackLowSleepHighStress4 =>
      '4️⃣ Si ruminations : noter tout ce qui tourne en boucle sur papier avant d\'aller au lit.';

  @override
  String get advPackLowSleep1 =>
      '1️⃣ Fixer une heure de coucher cible réaliste (même le week-end) et s\'y tenir 3 soirs de suite.';

  @override
  String get advPackLowSleep2 =>
      '2️⃣ Avancer le dernier café/thé noir au plus tard 14–15 h.';

  @override
  String get advPackLowSleep3 =>
      '3️⃣ Créer un petit rituel de \"décompression\" de 10–15 min (étirements doux + lumière tamisée).';

  @override
  String get advPackLowSleep4 =>
      '4️⃣ Chambre : fraîche, très sombre, silencieuse ou bruit blanc léger.';

  @override
  String get advPackHighStress1 =>
      '1️⃣ Micro-pauses : 2–3 min toutes les 60–90 min (respiration calme + quelques pas).';

  @override
  String get advPackHighStress2 =>
      '2️⃣ 5 respirations lentes avant chaque repas pour faire redescendre le système nerveux.';

  @override
  String get advPackHighStress3 =>
      '3️⃣ Marche de 10–15 min en extérieur sans téléphone, en portant l\'attention sur la respiration.';

  @override
  String get advPackHighStress4 =>
      '4️⃣ Le soir : écrire 3 choses qui se sont bien passées dans la journée, même si elles sont petites.';

  @override
  String get advPackHighStressHydration =>
      'Hydratation un peu basse : répartir l\'eau sur la journée aide aussi la clarté mentale.';

  @override
  String get advPackStable1 =>
      '1️⃣ Maintiens ton rythme de coucher et de lever, même le week-end (±1 h max).';

  @override
  String get advPackStable2 =>
      '2️⃣ Ajoute 8–12 min de marche lente après un repas pour digestion + glycémie.';

  @override
  String get advPackStable3 =>
      '3️⃣ Prévois 1 moment \"off écran\" de 15–20 min dans la journée (lecture, musique, nature).';

  @override
  String get advPackStable4 =>
      '4️⃣ Introduis 1 portion de légumes verts en plus pour soutenir micronutrition & récupération.';

  @override
  String advChronoLowSleepHighStress(String hours, int stress) {
    return 'Sommeil court (~$hours h) + stress élevé ($stress/10). Le système nerveux tire fort sur les réserves.';
  }

  @override
  String advChronoLowSleep(String hours) {
    return 'Temps de sommeil un peu court (~$hours h). L\'empilement de nuits raccourcies finit par impacter énergie et humeur.';
  }

  @override
  String advChronoHighStress(String hours, int stress) {
    return 'Sommeil convenable (~$hours h) mais stress élevé ($stress/10). Le mental tourne vite.';
  }

  @override
  String advChronoStable(String hours, int stress) {
    return 'Sommeil et niveau de stress plutôt stables (≈$hours h, stress $stress/10). On peut jouer le \"fine tuning\" vitalité.';
  }

  @override
  String get advChronoIncomplete =>
      'Renseigne ton sommeil et ton niveau de stress pour des conseils bien-être personnalisés, adaptés à ta forme du moment.';

  @override
  String get advActionIncomplete =>
      'Pendant 3 jours, note chaque matin tes heures de sommeil, ton niveau de stress (1–10) et ton énergie au réveil. TOTUM affinera progressivement les leviers proposés pour toi.';

  @override
  String get advMacroLossTitle => '⚖️ Perte de poids intelligente';

  @override
  String advMacroLossHigh(String pct) {
    return 'Apport ~$pct : vise un déficit léger (-10 à -20 %) durable.';
  }

  @override
  String advMacroLossLow(String pct) {
    return 'Apport ~$pct : si fatigue/fringales, remonte avec aliments bruts.';
  }

  @override
  String advMacroLossOk(String pct) {
    return 'Énergie ~$pct : trajectoire cohérente. Qualité & fibres = priorité.';
  }

  @override
  String advMacroProteinLow(String pct) {
    return ' • Protéines ~$pct : une source à chaque repas.';
  }

  @override
  String advMacroProteinHighSportif(String pct) {
    return ' • Protéines généreuses ~$pct : répartis sur 3–4 prises.';
  }

  @override
  String get advMacroGainTitle => '🏗️ Construction musculaire';

  @override
  String advMacroGainLow(String pct) {
    return 'Calories ~$pct : surplus +10–15 % conseillé.';
  }

  @override
  String advMacroGainHigh(String pct) {
    return 'Surplus ~$pct : ramène vers +10–15 % pour limiter la prise de gras.';
  }

  @override
  String advMacroGainOk(String pct) {
    return 'Niveau ~$pct : OK. Timing glucides autour séances = clé.';
  }

  @override
  String advMacroGainProteinLow(String pct) {
    return ' • Protéines ~$pct : 1.6–2.2 g/kg/j sur 3–4 repas.';
  }

  @override
  String advMacroGainProteinOk(String pct) {
    return ' • Couverture protéique ~$pct.';
  }

  @override
  String get advMacroMaintainTitle => '⚙️ Maintien du poids de forme';

  @override
  String advMacroMaintainLow(String pct) {
    return 'Énergie ~$pct : un peu basse. Remonte légèrement si fatigue.';
  }

  @override
  String advMacroMaintainHigh(String pct) {
    return 'Énergie ~$pct : un peu haute. Ajuste extras & boissons.';
  }

  @override
  String advMacroMaintainOk(String pct) {
    return 'Énergie ~$pct : alignée. Joue la qualité pour digestion/sommeil.';
  }

  @override
  String advMacroMaintainProteinLow(String pct) {
    return ' • Protéines ~$pct : garde un socle suffisant.';
  }

  @override
  String advDefiHydration(String liters) {
    return 'Atteins $liters L aujourd\'hui, répartis sur la journée.';
  }

  @override
  String get advQuoteHydration =>
      '« Une cellule bien hydratée travaille en silence pour ta longévité. »';

  @override
  String get advDefiEfas =>
      'Ajoute une vraie source d\'EFAs (poisson gras ou lin/chia moulus + huile colza/olive).';

  @override
  String get advQuoteEfas =>
      '« Les lipides de qualité sont la matière première de ton cerveau. »';

  @override
  String get advDefiLiposoluble =>
      '1 source liposoluble + lumière du matin 10–15 min.';

  @override
  String get advQuoteLiposoluble =>
      '« Lumière + liposolubles = orchestration métabolique. »';

  @override
  String get advDefiBVitamins =>
      'Repas très coloré + une bonne source protéique.';

  @override
  String get advQuoteBVitamins =>
      '« Ton énergie, c\'est du code info + du carburant. »';

  @override
  String get advDefiFibers =>
      '1 portion de légumes en plus + 1 portion de légumineuses.';

  @override
  String get advQuoteFibers =>
      '« Ton microbiote se nourrit de tes habitudes. »';

  @override
  String get advDefiDefault =>
      'Choisis une action du Labo et applique-la aujourd\'hui.';

  @override
  String get advQuoteDefault =>
      '« Les micronutriments, code source de ta vitalité. »';

  @override
  String get coachNoData =>
      'Renseigne tes repas et je te dis en un coup d\'œil où tu en es et quoi ajuster.';

  @override
  String coachEtatGoodStart(int s) {
    return 'Bon début : $s/100 sur ce que tu as déjà mangé.';
  }

  @override
  String coachEtatStarting(int s) {
    return 'Journée qui démarre : $s/100 pour l\'instant, tout reste à construire.';
  }

  @override
  String coachEtatExcellent(int s) {
    return 'Excellente journée : $s/100. C\'est ce niveau-là qui construit ta santé sur le long terme.';
  }

  @override
  String coachEtatGood(int s) {
    return 'Bonne journée : $s/100, avec encore un peu de marge.';
  }

  @override
  String coachEtatOk(int s) {
    return 'Journée correcte : $s/100. Un geste ciblé et tu passes un cap.';
  }

  @override
  String coachEtatToRebalance(int s) {
    return 'Journée à rééquilibrer : $s/100. Rien de grave, un bon repas inverse la tendance.';
  }

  @override
  String coachProgressUp(int diff) {
    return ' En hausse de $diff points vs ta dernière journée 📈.';
  }

  @override
  String coachProgressDown(int diff) {
    return ' En baisse de $diff points vs ta dernière journée.';
  }

  @override
  String coachActionSleepCritical(String hours) {
    return ' Ta priorité aujourd\'hui n\'est pas dans l\'assiette : tu n\'as dormi que $hours h. Tes fringales seront plus fortes — mise sur du brut et du rassasiant, et vise une nuit plus longue ce soir.';
  }

  @override
  String coachActionStressHigh(int stress) {
    return ' Ton stress est à $stress/10 : c\'est le point à travailler en priorité. Prends 5 respirations lentes avant chaque repas — ça apaise le mental et améliore ta digestion.';
  }

  @override
  String coachActionDeficitMajorWithFix(String label, int pct, String fix) {
    return ' Le point à corriger en priorité : $label ($pct% de ta cible). Le réflexe : $fix.';
  }

  @override
  String coachActionDeficitMajor(String label, int pct) {
    return ' Le point à corriger en priorité : $label ($pct% de ta cible).';
  }

  @override
  String coachActionSleepMedium(String hours) {
    return ' Ta nuit a été un peu courte ($hours h) : privilégie du rassasiant aujourd\'hui et lève le pied sur les excitants.';
  }

  @override
  String coachActionStressNotable(int stress) {
    return ' Ton stress ($stress/10) mérite un peu d\'attention : quelques respirations lentes dans la journée te feront du bien.';
  }

  @override
  String coachActionDeficitMinorWithFix(String label, int pct, String fix) {
    return ' Petit point d\'amélioration : $label ($pct% de ta cible). Pense à $fix.';
  }

  @override
  String coachActionDeficitMinor(String label, int pct) {
    return ' Petit point d\'amélioration : $label ($pct% de ta cible).';
  }

  @override
  String get coachActionNoneEvening =>
      ' Rien à corriger d\'urgence : laisse la nuit faire son travail de récupération.';

  @override
  String get coachActionNoneLoss =>
      ' Rien à corriger : garde le cap avec le duo protéines + légumes à chaque repas, c\'est lui qui tient la satiété.';

  @override
  String get coachActionNoneGain =>
      ' Rien à corriger : pense à répartir tes protéines sur la journée pour bien nourrir ton muscle.';

  @override
  String get coachActionNoneMaintain =>
      ' Rien à corriger : garde le cap avec du brut et de la variété, c\'est la régularité qui paie.';

  @override
  String get quickFixIron =>
      'des lentilles ou un peu de boudin, avec un filet de citron pour l\'absorption';

  @override
  String get quickFixMagnesium =>
      'une poignée d\'amandes ou un carré de chocolat noir';

  @override
  String get quickFixCalcium =>
      'des sardines, un yaourt ou une poignée d\'amandes';

  @override
  String get quickFixZinc => 'des graines de courge, du bœuf ou des huîtres';

  @override
  String get quickFixIodine => 'du poisson, des fruits de mer ou un œuf';

  @override
  String get quickFixSelenium => 'une sardine, un œuf ou des fruits de mer';

  @override
  String get quickFixPotassium =>
      'un avocat, une patate douce ou des légumineuses';

  @override
  String get quickFixVitC => 'un kiwi, un poivron rouge ou quelques fraises';

  @override
  String get quickFixVitD =>
      'un poisson gras (sardine, maquereau) et un peu de soleil';

  @override
  String get quickFixVitE =>
      'des amandes, des noisettes ou un filet d\'huile vierge';

  @override
  String get quickFixVitA =>
      'une carotte, de la patate douce ou du jaune d\'œuf';

  @override
  String get quickFixVitK =>
      'des légumes verts (épinard, chou) ou un peu de fromage affiné';

  @override
  String get quickFixB9 => 'des légumes verts à feuilles ou des légumineuses';

  @override
  String get quickFixB12 => 'des œufs, du poisson ou de la viande';

  @override
  String get quickFixB6 => 'de la volaille, une banane ou des pois chiches';

  @override
  String get quickFixOmega3 =>
      'des graines de chanvre ou de lin moulues, ou des noix';

  @override
  String get quickFixOmega3Marine => 'des sardines, du maquereau ou du hareng';

  @override
  String get quickFixCopper =>
      'des oléagineux, du chocolat noir ou des fruits de mer';

  @override
  String get quickFixManganese =>
      'des céréales complètes, des oléagineux ou du thé';

  @override
  String get quickFixPhosphorus => 'des œufs, du poisson ou des légumineuses';

  @override
  String get quickFixFibers =>
      'des légumineuses, un fruit entier ou des légumes';

  @override
  String get dietFixMarineOmega3 =>
      'un complément d\'oméga 3 issu de micro-algues (source végétale d\'EPA/DHA)';

  @override
  String get dietFixB12Vegan =>
      'un complément de vitamine B12 (indispensable en régime végétalien)';

  @override
  String get sleepRitualTitle => 'Rituel du soir';

  @override
  String get sleepRitualIntro =>
      'Un sommeil de qualité n\'est pas une chance, c\'est le résultat de bonnes habitudes. Voici les leviers qui comptent vraiment — coche ceux que tu mets en place.';

  @override
  String get sleepRitualLeversHeading => 'Les 6 leviers de ton sommeil';

  @override
  String get sleepRitualLeversSubtitle =>
      'Appuie sur un levier pour voir les gestes et cocher ceux que tu mets en place.';

  @override
  String get sleepPillarLightTitle => 'La lumière';

  @override
  String get sleepPillarLightIntro =>
      'La lumière est le principal régulateur de ton horloge biologique. Bien gérée, elle cale ton sommeil naturellement.';

  @override
  String get sleepActionLightWakeTitle =>
      'Vois la lumière du jour dès le réveil';

  @override
  String get sleepActionLightWakeWhy =>
      '10 à 30 minutes de lumière naturelle le matin calent ton horloge interne et déclenchent, 14 à 16 h plus tard, la sécrétion de mélatonine du soir. C\'est le geste le plus puissant pour bien dormir — et il se fait le matin.';

  @override
  String get sleepActionLightDimTitle =>
      'Baisse les lumières 1 à 2 h avant le coucher';

  @override
  String get sleepActionLightDimWhy =>
      'Une lumière vive le soir fait croire à ton cerveau qu\'il fait encore jour et bloque la mélatonine. Passe en éclairage tamisé, chaud, indirect.';

  @override
  String get sleepActionLightScreensTitle =>
      'Coupe les écrans ou filtre la lumière bleue';

  @override
  String get sleepActionLightScreensWhy =>
      'La lumière bleue des écrans est celle qui supprime le plus la mélatonine. Mode nuit, lunettes anti-lumière bleue, ou mieux : pose l\'écran.';

  @override
  String get sleepActionLightDarkTitle => 'Dors dans l\'obscurité totale';

  @override
  String get sleepActionLightDarkWhy =>
      'La moindre source lumineuse, même une veilleuse ou une LED de chargeur, perçue à travers les paupières, réduit la qualité du sommeil profond. Rideaux occultants ou masque.';

  @override
  String get sleepPillarTempTitle => 'La température';

  @override
  String get sleepPillarTempIntro =>
      'S\'endormir exige que la température de ton corps baisse d\'environ 1 °C. Tout ce qui favorise ce refroidissement aide à dormir.';

  @override
  String get sleepActionTempRoomTitle => 'Garde ta chambre autour de 18 °C';

  @override
  String get sleepActionTempRoomWhy =>
      'Une chambre fraîche facilite la baisse de température corporelle nécessaire à l\'endormissement. Trop chaude, elle est l\'une des causes les plus fréquentes de réveils nocturnes.';

  @override
  String get sleepActionTempShowerTitle =>
      'Prends une douche tiède 1 à 2 h avant';

  @override
  String get sleepActionTempShowerWhy =>
      'Paradoxalement, une douche tiède dilate les vaisseaux et aide le corps à évacuer sa chaleur ensuite : la température chute plus vite, et l\'endormissement suit.';

  @override
  String get sleepActionTempExtremitiesTitle => 'Garde les extrémités au chaud';

  @override
  String get sleepActionTempExtremitiesWhy =>
      'Des pieds froids resserrent les vaisseaux et empêchent le corps d\'évacuer sa chaleur centrale. Des chaussettes peuvent, contre l\'intuition, aider à s\'endormir plus vite.';

  @override
  String get sleepPillarFoodTitle => 'Stimulants & alimentation';

  @override
  String get sleepPillarFoodIntro =>
      'Ce que tu consommes dans la seconde partie de journée pèse lourd sur ta nuit.';

  @override
  String get sleepActionFoodCaffeineTitle =>
      'Dernière caféine 6 à 8 h avant le coucher';

  @override
  String get sleepActionFoodCaffeineWhy =>
      'La caféine bloque l\'adénosine, la molécule qui te rend somnolent, pendant 6 h et plus. Un café de milieu d\'après-midi ampute le sommeil profond sans même t\'empêcher de t\'endormir. Pense aussi au thé, au maté, au chocolat noir.';

  @override
  String get sleepActionFoodDinnerTitle => 'Dîne léger et tôt, 3 h avant';

  @override
  String get sleepActionFoodDinnerWhy =>
      'Une digestion en cours élève la température du corps et mobilise l\'organisme, à l\'opposé de ce que demande le sommeil. Un dîner léger et précoce améliore nettement la profondeur de la nuit.';

  @override
  String get sleepActionFoodLiquidsTitle => 'Modère les liquides en soirée';

  @override
  String get sleepActionFoodLiquidsWhy =>
      'Trop boire juste avant de dormir multiplie les réveils nocturnes pour aller aux toilettes, qui fragmentent les cycles. Hydrate-toi surtout en journée.';

  @override
  String get sleepActionFoodChoicesTitle =>
      'Mise sur les aliments favorables au sommeil';

  @override
  String get sleepActionFoodChoicesWhy =>
      'Certains aliments bruts apportent du tryptophane, du magnésium et de la glycine, précurseurs de la mélatonine et de la sérotonine : amandes, noix, banane, flocons d\'avoine, kiwi, poisson gras.';

  @override
  String get sleepPillarMentalTitle => 'Mental & stress';

  @override
  String get sleepPillarMentalIntro =>
      'Un mental agité est la cause n°1 des difficultés d\'endormissement. L\'apaiser est un entraînement.';

  @override
  String get sleepActionMentalDumpTitle => 'Fais une décharge mentale';

  @override
  String get sleepActionMentalDumpWhy =>
      'Note sur papier ce qui t\'préoccupe et tes tâches du lendemain. Sortir les pensées de ta tête pour les poser ailleurs réduit la rumination qui tourne en boucle au coucher.';

  @override
  String get sleepActionMentalCoherenceTitle =>
      'Pratique quelques minutes de cohérence cardiaque';

  @override
  String get sleepActionMentalCoherenceWhy =>
      'Ralentir le souffle active le système parasympathique, celui du repos. Quelques cycles de respiration lente préparent physiologiquement le corps au sommeil.';

  @override
  String get sleepActionMentalGratitudeTitle => 'Termine sur trois gratitudes';

  @override
  String get sleepActionMentalGratitudeWhy =>
      'Repenser à trois moments positifs de la journée oriente le mental vers le calme plutôt que vers l\'anxiété, et facilite un endormissement serein.';

  @override
  String get sleepActionMentalAvoidTitle =>
      'Évite les contenus anxiogènes le soir';

  @override
  String get sleepActionMentalAvoidWhy =>
      'Actualités, mails de travail, débats en ligne activent le système de vigilance juste avant de dormir. Réserve la soirée à ce qui apaise.';

  @override
  String get sleepPillarRhythmTitle => 'Rythme & régularité';

  @override
  String get sleepPillarRhythmIntro =>
      'Le sommeil aime la régularité plus que tout. Un rythme stable vaut mieux qu\'une longue grasse matinée de rattrapage.';

  @override
  String get sleepActionRhythmScheduleTitle =>
      'Couche-toi et lève-toi à heures régulières';

  @override
  String get sleepActionRhythmScheduleWhy =>
      'Des horaires constants, même le week-end, renforcent ton horloge biologique. C\'est la régularité, plus que la durée seule, qui détermine la qualité du sommeil.';

  @override
  String get sleepActionRhythmCyclesTitle =>
      'Respecte tes cycles de 90 minutes';

  @override
  String get sleepActionRhythmCyclesWhy =>
      'Le sommeil se déroule par cycles d\'environ 90 min. Se réveiller en fin de cycle, plutôt qu\'en plein sommeil profond, rend le réveil bien plus facile.';

  @override
  String get sleepActionRhythmSignsTitle =>
      'Couche-toi dès les premiers signes';

  @override
  String get sleepActionRhythmSignsWhy =>
      'Bâillements, paupières lourdes, yeux qui piquent : c\'est ton train du sommeil qui passe. Le rater, c\'est attendre le prochain cycle 90 min plus tard.';

  @override
  String get sleepActionRhythmNapsTitle => 'Gère tes siestes';

  @override
  String get sleepActionRhythmNapsWhy =>
      'Une sieste de 10 à 20 min en début d\'après-midi récupère sans empiéter sur la nuit. Trop longue ou trop tardive, elle sabote l\'endormissement du soir.';

  @override
  String get sleepPillarEnvTitle => 'L\'environnement';

  @override
  String get sleepPillarEnvIntro =>
      'Ta chambre doit devenir un sanctuaire que ton cerveau associe uniquement au repos.';

  @override
  String get sleepActionEnvBedTitle => 'Réserve le lit au sommeil';

  @override
  String get sleepActionEnvBedWhy =>
      'Travailler, manger ou scroller au lit brouille l\'association mentale lit = sommeil. Ton cerveau doit apprendre qu\'entrer dans le lit signifie dormir.';

  @override
  String get sleepActionEnvNoiseTitle => 'Chasse le bruit';

  @override
  String get sleepActionEnvNoiseWhy =>
      'Même sans te réveiller, un bruit perturbe la profondeur du sommeil. Bouchons d\'oreilles ou bruit blanc régulier peuvent masquer les nuisances imprévisibles.';

  @override
  String get sleepActionEnvBeddingTitle => 'Soigne ta literie';

  @override
  String get sleepActionEnvBeddingWhy =>
      'Un matelas et un oreiller adaptés évitent les micro-réveils liés à l\'inconfort. On y passe un tiers de sa vie : c\'est un investissement santé.';

  @override
  String hintOmega9(String pct) {
    return 'Oméga-9 : $pct → huile d\'olive, avocat, amandes/noisettes.';
  }

  @override
  String hintOmega6(String pct) {
    return 'Oméga-6 (LA) : $pct → huiles vierges, noix, graines.';
  }

  @override
  String hintOmega3Ala(String pct) {
    return 'Oméga-3 ALA : $pct → lin/chia moulus, noix, huile de colza.';
  }

  @override
  String hintOmega3(String pct) {
    return 'Oméga-3 EPA/DHA : $pct → sardines, maquereau, hareng.';
  }

  @override
  String hintEpa(String pct) {
    return 'EPA : $pct → 1–2 portions poisson gras/sem.';
  }

  @override
  String hintDha(String pct) {
    return 'DHA : $pct → sardines, maquereau, œufs enrichis.';
  }

  @override
  String hintVitA(String pct) {
    return 'Vit A : $pct → carotte/patate douce + œufs/abats.';
  }

  @override
  String hintVitD(String pct) {
    return 'Vit D : $pct → lumière matin + sardines/œufs.';
  }

  @override
  String hintVitE(String pct) {
    return 'Vit E : $pct → huiles vierges, amandes/noisettes.';
  }

  @override
  String hintVitK(String pct) {
    return 'Vit K : $pct → verts + un peu d\'huile.';
  }

  @override
  String hintVitC(String pct) {
    return 'Vit C : $pct → kiwi, agrumes, poivron cru, persil.';
  }

  @override
  String hintB1(String pct) {
    return 'B1 : $pct → céréales complètes, légumineuses, porc.';
  }

  @override
  String hintB2(String pct) {
    return 'B2 : $pct → lait, œufs, amandes, champignons.';
  }

  @override
  String hintB3(String pct) {
    return 'B3 : $pct → volailles, poisson, arachides.';
  }

  @override
  String hintB5(String pct) {
    return 'B5 : $pct → abats, champignons, avocat.';
  }

  @override
  String hintB6(String pct) {
    return 'B6 : $pct → banane, pois chiches, volailles.';
  }

  @override
  String hintB9(String pct) {
    return 'B9 : $pct → verts feuillus, légumineuses.';
  }

  @override
  String hintB12(String pct) {
    return 'B12 : $pct → produits animaux / enrichis.';
  }

  @override
  String hintCalcium(String pct) {
    return 'Calcium : $pct → laitiers/alternatives, eaux calciques, tahini.';
  }

  @override
  String hintCopper(String pct) {
    return 'Cuivre : $pct → fruits de mer, cacao, noix/graines.';
  }

  @override
  String hintIron(String pct) {
    return 'Fer : $pct → légumineuses/abats + vitamine C.';
  }

  @override
  String hintIodine(String pct) {
    return 'Iode : $pct → poissons, fruits de mer, sel iodé.';
  }

  @override
  String hintMagnesium(String pct) {
    return 'Magnésium : $pct → amandes, chocolat noir, verts.';
  }

  @override
  String hintManganese(String pct) {
    return 'Manganèse : $pct → céréales complètes, noix, thé vert.';
  }

  @override
  String hintPhosphorus(String pct) {
    return 'Phosphore : $pct → poisson, œufs, oléagineux.';
  }

  @override
  String hintPotassium(String pct) {
    return 'Potassium : $pct → banane, avocat, verts, patate douce.';
  }

  @override
  String hintSelenium(String pct) {
    return 'Sélénium : $pct → poisson, fruits de mer, œufs.';
  }

  @override
  String hintSodium(String pct) {
    return 'Sodium : $pct → sel de qualité si transpiration.';
  }

  @override
  String hintZinc(String pct) {
    return 'Zinc : $pct → fruits de mer, bœuf, graines de courge.';
  }

  @override
  String hintFibers(String pct) {
    return 'Fibres : $pct → +légumes, légumineuses, fruits entiers.';
  }

  @override
  String hintDefault(String pct) {
    return 'Micros : $pct → assiette colorée & brute.';
  }

  @override
  String get breathGoalApaiserLabel => 'Apaiser';

  @override
  String get breathGoalApaiserSubtitle =>
      'Calmer le mental, faire retomber le stress';

  @override
  String get breathGoalRenforcerLabel => 'Renforcer';

  @override
  String get breathGoalRenforcerSubtitle =>
      'Booster l\'énergie, muscler le contrôle du souffle';

  @override
  String get breathGoalEquilibrerLabel => 'Équilibrer';

  @override
  String get breathGoalEquilibrerSubtitle =>
      'Rythme régulier, équilibre du système nerveux';

  @override
  String get breathGoalDebuterLabel => 'Débuter';

  @override
  String get breathGoalDebuterSubtitle =>
      'La base, en douceur, pour prendre ses marques';

  @override
  String get breathScreenTitle => 'Respiration';

  @override
  String get breathGoalPickerTitle =>
      'Qu\'est-ce que tu cherches aujourd\'hui ?';

  @override
  String breathWeekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances cette semaine',
      one: '$count séance cette semaine',
    );
    return '$_temp0';
  }

  @override
  String get breathSeeAllTechniques => 'Voir toutes les techniques';

  @override
  String get consDuJourTitle => 'Tes conseils du jour';

  @override
  String get consDuJourIntro =>
      'Tes conseils personnalisés, choisis selon ta journée et tes objectifs.';

  @override
  String get consDuJourDisclaimer =>
      'Ces conseils ne remplacent pas un avis médical. En cas de pathologie ou de doute, rapprochez-vous de votre professionnel de santé.';

  @override
  String get consChallengeOfTheDay => 'Ton défi du jour';

  @override
  String get consNoRecipeMatchesFilters =>
      'Aucune recette ne correspond à ces filtres pour le moment.';

  @override
  String get fallbackMindset1Title => '🧠 Progression > perfection';

  @override
  String get fallbackMindset1Body =>
      'Chaque repas aligné avec ton objectif est un vote pour l\'identité que tu construis.';

  @override
  String get fallbackMindset2Title => '💪 Constance antifragile';

  @override
  String get fallbackMindset2Body =>
      'Les écarts ne te définissent pas. C\'est la moyenne de la semaine qui compte.';

  @override
  String get fallbackCoachSedentaire1 => '2–3×/semaine 20–30 min…';

  @override
  String get fallbackCoachSedentaire2 => '6–8k pas/j…';

  @override
  String get fallbackCoachPerte1 => 'Déficit léger + protéines…';

  @override
  String get fallbackCoachMasse1 => 'Surplus +10–15 %, protéines 1.6–2.2 g/kg…';

  @override
  String get fallbackCoachMaintien1 => '3–4 séances variées/sem…';

  @override
  String get fallbackHeroHydrationTitle =>
      '💧 Hydratation : ton boost silencieux';

  @override
  String get fallbackHeroHydrationTheme => 'Clarté mentale';

  @override
  String get fallbackHeroHydrationInsight =>
      'Répartis l\'eau + tisane le soir.';

  @override
  String get fallbackHeroOmega3Title => '🐟 Oméga-3 : cerveau & membranes';

  @override
  String get fallbackHeroOmega3Theme => 'Inflammation & humeur';

  @override
  String get fallbackHeroOmega3Insight => '2 poissons gras/sem.';

  @override
  String get fallbackHeroFibersTitle => '🌱 Fibres : microbiote';

  @override
  String get fallbackHeroFibersTheme => 'Satiété';

  @override
  String get fallbackHeroFibersInsight =>
      'Légumineuses + légumes + fruits entiers.';

  @override
  String get fallbackHeroGenericTitle => 'Conseil du jour';

  @override
  String get fallbackHeroGenericTheme => 'Vitalité';

  @override
  String get fallbackHeroGenericInsight => 'Varie les aliments bruts colorés.';

  @override
  String get fallbackRecipeOmega3Bowl => 'Bowl sardines-citron-avocat';

  @override
  String get fallbackRecipeOmega3Salad => 'Salade maquereau + lentilles';

  @override
  String get fallbackRecipeFibersBowl =>
      'Buddha bowl légumineuses + céréale complète';

  @override
  String jrnlOverBy(String excess, String unit) {
    return 'dépassé de $excess $unit';
  }

  @override
  String jrnlRemainingBy(String remaining, String unit) {
    return 'reste $remaining $unit';
  }

  @override
  String get jrnlQtyLabel => 'Quantité (g)';

  @override
  String get jrnlMealDropdownLabel => 'Repas';

  @override
  String get jrnlGlucidesDetailButton => 'Détail des glucides';

  @override
  String get jrnlCompositionFor100g => 'Composition pour 100 g';

  @override
  String jrnlCompositionForGrams(String grams) {
    return 'Composition (pour $grams g)';
  }

  @override
  String get jrnlSearchingProduct => 'Recherche du produit...';

  @override
  String get jrnlProductNotFoundTitle => 'Produit non trouvé';

  @override
  String get jrnlProductNotFoundBody =>
      'Ce produit n\'a pas été trouvé dans la base Open Food Facts.\n\nConseils :\n• Vérifiez que tous les chiffres du code-barres sont bien visibles\n• Assurez-vous d\'une bonne luminosité lors du scan\n• Essayez de scanner à nouveau en tenant l\'appareil stable\n\nRéessayez en améliorant les conditions de scan.';

  @override
  String get jrnlScannedProductFallback => 'Produit scanné';

  @override
  String get jrnlTechnicalErrorTitle => 'Erreur technique';

  @override
  String jrnlScanErrorBody(String error) {
    return 'Une erreur est survenue : $error\n\nRéessayez en scannant à nouveau.';
  }

  @override
  String get jrnlAddToJournal => 'Ajouter au journal';

  @override
  String jrnlAddQuoted(String name) {
    return 'Ajouter \"$name\"';
  }

  @override
  String jrnlItemsAndKcal(int count, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
    );
    return '$_temp0 · $kcal kcal';
  }

  @override
  String get jrnlTowardDay => 'Vers le jour';

  @override
  String get jrnlTowardMeal => 'Vers le repas';

  @override
  String get jrnlRestaurantsInfoTitle =>
      'Restaurants : un écart occasionnel, pas un pilier';

  @override
  String get jrnlRestaurantsInfoP1 =>
      'Ces enseignes viennent de la base USDA (Foundation Foods/SR Legacy) et sont très majoritairement des chaînes de restauration rapide et familiale nord-américaines — recettes et portions reflètent le marché américain.';

  @override
  String get jrnlRestaurantsInfoP2 =>
      'Un repas moyen en chaîne de restauration rapide apporte environ 1200 kcal et 2100 mg de sodium en un seul repas — bien au-dessus des repères pour un repas isolé (environ 700 kcal, moins de 770 mg de sodium).';

  @override
  String get jrnlRestaurantsInfoP3 =>
      'Le comité américain des recommandations alimentaires (Dietary Guidelines Advisory Committee) situe la part raisonnable de calories \"plaisir\" entre 5 et 15% des apports hebdomadaires pour la plupart des adultes. Concrètement, ça représente environ 1 à 2 repas de ce type par semaine — un seul peut déjà représenter l\'essentiel de ce budget.';

  @override
  String get jrnlRestaurantsInfoP4 =>
      'Au-delà de 3 repas de ce type par semaine, la littérature s\'accorde à dire que ça s\'éloigne nettement d\'une alimentation orientée santé, longévité, vitalité et performance. Pour un écart plus doux, les enseignes \"healthy\"/fast-casual (salades composées, bols, poke...) restent une alternative à considérer.';

  @override
  String get jrnlUnderstood => 'Compris';

  @override
  String get jrnlAboutBrandTitle => 'À propos de cette enseigne';

  @override
  String get jrnlAboutBrandBody =>
      'Cette marque vient de la base USDA (Foundation Foods/SR Legacy) — elle est essentiellement issue du marché américain, ses recettes et portions reflètent donc les produits vendus aux États-Unis, pas nécessairement leur équivalent vendu en France.';

  @override
  String get jrnlInformationsButton => 'Informations';

  @override
  String get jrnlSearchBrand => 'Rechercher une enseigne';

  @override
  String jrnlSearchWithinBrand(String name) {
    return 'Rechercher dans $name';
  }

  @override
  String get jrnlNoChainFound => 'Aucune enseigne trouvée';

  @override
  String get jrnlLoadingEllipsis => 'Chargement...';

  @override
  String get jrnlNoResults => 'Aucun résultat';

  @override
  String get jrnlCalorieValueUnknown => 'Valeur calorique non communiquée';

  @override
  String jrnlKcalPer100g(String kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get jrnlGenericFoodFallback => 'Aliment';

  @override
  String get jrnlRemoveFavorite => 'Retirer des favoris';

  @override
  String get jrnlAddFavorite => 'Ajouter aux favoris';

  @override
  String jrnlItemCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
    );
    return '$_temp0';
  }

  @override
  String jrnlItemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments sélectionnés',
      one: '1 aliment sélectionné',
    );
    return '$_temp0';
  }

  @override
  String jrnlItemsCopiedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments copiés',
      one: '1 aliment copié',
    );
    return '$_temp0 vers $meal';
  }

  @override
  String jrnlItemsAddedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments ajoutés',
      one: '1 aliment ajouté',
    );
    return '$_temp0 à $meal (100 g par défaut, ajustable ensuite)';
  }

  @override
  String jrnlAddedTo(String name, String meal) {
    return '\"$name\" ajouté à $meal';
  }

  @override
  String get jrnlCustomFoodEditTitle => 'Modifier un aliment perso';

  @override
  String get jrnlCustomFoodAddTitle => 'Ajouter un aliment perso';

  @override
  String get jrnlMicronutrientsOptional => 'Micronutriments (optionnel)';

  @override
  String get jrnlEditRecipeTitle => 'Modifier la recette';

  @override
  String get jrnlNewRecipeTitle => 'Nouvelle recette';

  @override
  String get jrnlRecipeNameField => 'Nom de la recette *';

  @override
  String get jrnlDescOptionalField => 'Description (optionnel)';

  @override
  String get jrnlRecipeTotalWeightField =>
      'Poids total de la recette finie (g)';

  @override
  String get jrnlMacrosCalculatedFor100g =>
      'Les macros seront calculées pour 100g de recette';

  @override
  String get jrnlValuesPer100gRecipe => 'Valeurs pour 100g de recette';

  @override
  String get jrnlIngredientsTitle => 'Ingrédients';

  @override
  String get jrnlSearchFoodToAdd => 'Rechercher un aliment à ajouter';

  @override
  String get jrnlNoIngredientAdded => 'Aucun ingrédient ajouté.';

  @override
  String get jrnlEditQuantityTooltip => 'Modifier la quantité';

  @override
  String get jrnlRemoveTooltip => 'Retirer';

  @override
  String jrnlKcalSlash100g(String kcal) {
    return '$kcal kcal/100g';
  }

  @override
  String get jrnlRecipeNameRequired => 'Donne un nom à ta recette !';

  @override
  String get jrnlIngredientRequired => 'Ajoute au moins un ingrédient.';

  @override
  String get jrnlEditMealTitle => 'Modifier le repas perso';

  @override
  String get jrnlNewMealTitle => 'Nouveau repas perso';

  @override
  String get jrnlMealNameField => 'Nom du repas *';

  @override
  String get jrnlMealTotalTitle => 'Total du repas';

  @override
  String get jrnlFoodsTitle => 'Aliments';

  @override
  String get jrnlMealNameRequired => 'Donne un nom à ce repas !';

  @override
  String get jrnlFoodRequired => 'Ajoute au moins un aliment.';

  @override
  String jrnlGramsAndKcal(String grams, String kcal) {
    return '$grams g · $kcal kcal';
  }

  @override
  String get jrnlNoFoodAdded => 'Aucun aliment ajouté.';

  @override
  String get jrnlChooseMeal => 'Choisir le repas';

  @override
  String get jrnlCiqualVsUsdaTitle => 'CIQUAL vs USDA';

  @override
  String get jrnlCiqualDefaultTitle => '🇫🇷 CIQUAL — base par défaut';

  @override
  String get jrnlCiqualDefaultBody =>
      'Table de composition nutritionnelle officielle française, publiée par l\'ANSES (Agence nationale de sécurité sanitaire). Couvre les aliments du quotidien en France. C\'est la base de référence de Totum, sélectionnée par défaut dans toutes les recherches.';

  @override
  String get jrnlUsdaReinforceTitle => '🇺🇸 USDA — en renfort';

  @override
  String get jrnlUsdaReinforceBody =>
      'FoodData Central, la base nutritionnelle officielle du gouvernement américain (U.S. Department of Agriculture). Aliments analysés en laboratoire (Foundation Foods/SR Legacy) — même niveau d\'exigence scientifique que CIQUAL, traduite en français, mais pensée pour les habitudes alimentaires américaines (portions, recettes, produits de marque).';

  @override
  String get jrnlWhyBothTitle => 'Pourquoi les deux ?';

  @override
  String get jrnlWhyBothBody =>
      'CIQUAL ne couvre pas tout, notamment certains aliments d\'origine anglo-saxonne. Activer \"Inclure la base USDA\" élargit la recherche à ces ~7500 aliments supplémentaires — chaque résultat USDA reste identifié par un badge, pour toujours savoir d\'où vient la donnée.';

  @override
  String get jrnlSearchOptionsTitle => 'Options de recherche d\'aliments';

  @override
  String get jrnlMultiSelectToggleTitle => 'Activer l\'ajout multiple';

  @override
  String get jrnlMultiSelectToggleDesc =>
      'Coche plusieurs aliments dans \"Commun\" et ajoute-les d\'un coup à un repas.';

  @override
  String get jrnlCategoryTabsToggleTitle => 'Onglets de catégorie';

  @override
  String get jrnlCategoryTabsToggleDesc =>
      'Commun/Favoris/Perso/Marques/Restaurant — désactive pour gagner de la place.';

  @override
  String get jrnlSortByLabel => 'Trier par';

  @override
  String get jrnlSortFrequent => 'Le + fréquent';

  @override
  String get jrnlSortRecent => 'Le + récent';

  @override
  String get jrnlSortAZ => 'A → Z';

  @override
  String get jrnlSortZA => 'Z → A';

  @override
  String get jrnlSearchOverridesSortHint =>
      'Pendant une recherche, la meilleure correspondance prime toujours sur ce tri.';

  @override
  String get jrnlDatabaseLabel => 'Base de données';

  @override
  String get jrnlCiqualDefaultCheckbox => 'CIQUAL (France) — par défaut';

  @override
  String get jrnlUsdaReinforceCheckbox => 'USDA (États-Unis) — en renfort';

  @override
  String jrnlAddToMeal(String meal) {
    return 'Ajouter à $meal';
  }

  @override
  String get jrnlSearchFood => 'Rechercher un aliment';

  @override
  String get jrnlTypeToSearchFood => 'Tape pour rechercher un aliment';

  @override
  String jrnlPersonalMealSummary(int count, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
    );
    return 'Repas perso · $_temp0 · $kcal kcal';
  }

  @override
  String get jrnlTagPersonal => 'Perso';

  @override
  String get jrnlTagRecipe => 'Recette';

  @override
  String get jrnlMealEmptyToCopy => 'Ce repas est vide, rien à copier.';

  @override
  String get jrnlCopyMealTitle => 'Copier ce repas';

  @override
  String jrnlItemsFromMeal(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
    );
    return '$_temp0 de $meal';
  }

  @override
  String get jrnlToDaySegment => 'Vers un jour';

  @override
  String get jrnlPersonalMealSegment => 'Repas perso';

  @override
  String get jrnlPersonalMealNameField => 'Nom du repas perso';

  @override
  String get jrnlCopyButton => 'Copier';

  @override
  String jrnlSavedToPersonalMeals(String name) {
    return '\"$name\" enregistré dans tes repas perso';
  }

  @override
  String jrnlQuantityGrams(String grams) {
    return 'Quantité : $grams g';
  }

  @override
  String get jrnlDetailNotAvailable =>
      'Détail complet non disponible pour cet aliment.';

  @override
  String get jrnlToday => 'Aujourd\'hui';

  @override
  String get jrnlWeekdayMon => 'Lun';

  @override
  String get jrnlWeekdayTue => 'Mar';

  @override
  String get jrnlWeekdayWed => 'Mer';

  @override
  String get jrnlWeekdayThu => 'Jeu';

  @override
  String get jrnlWeekdayFri => 'Ven';

  @override
  String get jrnlWeekdaySat => 'Sam';

  @override
  String get jrnlWeekdaySun => 'Dim';

  @override
  String get jrnlJournalTitle => 'Journal';

  @override
  String get jrnlAccountSettingsTooltip => 'Compte & Paramètres';

  @override
  String get jrnlPreviousDayTooltip => 'Jour précédent';

  @override
  String get jrnlNextDayTooltip => 'Jour suivant';

  @override
  String jrnlTargetKcal(String kcal) {
    return 'Objectif $kcal kcal';
  }

  @override
  String jrnlConsumedKcal(String kcal) {
    return 'Consommé $kcal kcal';
  }

  @override
  String jrnlRemainingKcal(String kcal) {
    return 'Restant $kcal kcal';
  }

  @override
  String jrnlExceededByKcal(String kcal) {
    return 'Dépassé de $kcal kcal';
  }

  @override
  String get jrnlScanProductTooltip => 'Scanner un produit';

  @override
  String get jrnlMoreOptionsTooltip => 'Plus d\'options';

  @override
  String get jrnlClearAllTitle => 'Tout supprimer ?';

  @override
  String jrnlClearAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
    );
    return 'Supprimer les $_temp0 de ce repas ?';
  }

  @override
  String get jrnlExitSelection => 'Quitter la sélection';

  @override
  String get jrnlSelectFoods => 'Sélectionner des aliments';

  @override
  String get jrnlClearAllMenuItem => 'Tout supprimer';

  @override
  String get jrnlCheckFoodsToCopy => 'Cochez les aliments à copier';

  @override
  String jrnlFoodsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments sélectionnés',
      one: '1 aliment sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get jrnlCopySelection => 'Copier la sélection';

  @override
  String get jrnlMealNutritionDetailsTooltip =>
      'Détails nutritionnels du repas';
}
