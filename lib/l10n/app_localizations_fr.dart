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
}
