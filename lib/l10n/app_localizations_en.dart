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

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonNameField => 'Name';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get barcodeEnterTitle => 'Enter the barcode';

  @override
  String get barcodeDigitsLabel => 'Barcode digits';

  @override
  String get barcodeScanScreenTitle => 'Scan a product';

  @override
  String get barcodeEnableFlash => 'Turn on flash';

  @override
  String barcodeCameraError(String error) {
    return 'Camera error: $error';
  }

  @override
  String get barcodeAimInstruction => 'Aim at the barcode';

  @override
  String get barcodeAutoDetect => 'Automatic detection';

  @override
  String get barcodeManualEntry => 'Enter the code manually';

  @override
  String get paywallTitle => 'Your TOTUM trial has ended';

  @override
  String get paywallSubtitleWeb =>
      'Your 7-day free trial has ended. 🎯\n\nYou\'ve been able to discover TOTUM in full: complete nutrition tracking, personalized wellness advice, and micronutrient analysis.\n\nTo keep taking care of yourself without interruption, switch to TOTUM Premium: a subscription of €14.99 per year — that\'s €1.25 per month — renewed automatically every year.';

  @override
  String get paywallSubtitleLoading => 'Loading price…';

  @override
  String paywallSubtitleNative(String price) {
    return 'Your 7-day free trial has ended. 🎯\n\nTo keep enjoying TOTUM with no ads, switch to TOTUM Premium: a subscription of $price, renewed automatically every year and cancellable anytime.';
  }

  @override
  String get paywallButtonSubscribe => 'Subscribe';

  @override
  String paywallButtonSubscribeWithPrice(String price) {
    return 'Subscribe — $price';
  }

  @override
  String get paywallBenefitsTitle => 'With TOTUM Premium, you keep:';

  @override
  String get paywallBenefit1 => 'Unlimited access to all features';

  @override
  String get paywallBenefit2 => 'No ads or distractions';

  @override
  String get paywallBenefit3 => 'Annual renewal — cancellable anytime';

  @override
  String get paywallStoreUnavailable =>
      'The Store is currently unavailable.\nCheck your internet connection or try restarting the app.';

  @override
  String get paywallSubscriptionNotFound =>
      'Subscription not found on the Store.';

  @override
  String get paywallFooterWeb =>
      '🔒 100% secure payment via Stripe\nAnnual subscription of €14.99, renewed automatically every year. Cancellable anytime: access remains active until the end of the period already paid for.';

  @override
  String get paywallFooterNative =>
      '🔒 Payment securely managed by Google Play.\nAnnual subscription renewed automatically. Cancellable anytime from the Play Store.';

  @override
  String get paywallChangeAccount => 'Change account';

  @override
  String paywallChangeAccountError(String error) {
    return 'Problem changing account: $error';
  }

  @override
  String get authWrongCredentials =>
      'Incorrect email or password. Check and try again.';

  @override
  String get authEmailNotConfirmed =>
      '📧 Your email hasn\'t been confirmed yet. Open the link you received by email, then log back in.';

  @override
  String get authUserAlreadyRegistered =>
      'An account already exists with this email. Try logging in instead.';

  @override
  String get authPasswordTooShort =>
      'The password must be at least 6 characters long.';

  @override
  String get authInvalidEmail => 'This email address doesn\'t look valid.';

  @override
  String get authNetworkError =>
      'No internet connection available. Check your connection and try again.';

  @override
  String get authRateLimit =>
      'Too many attempts. Wait a minute before trying again.';

  @override
  String get authGenericError =>
      'Something went wrong. Please try again in a moment.';

  @override
  String get authSignUpWelcome =>
      '🎉 Welcome! Your account has been created.\n📧 Open your inbox and click the confirmation link, then come back to log in.';

  @override
  String get authSignInSuccess => 'Signed in successfully ✅ Welcome back!';

  @override
  String get authEnterEmailFirst =>
      'First enter your email above, then tap \"Forgot password?\".';

  @override
  String get authResetPasswordSent =>
      '📧 If an account exists for this email, you\'ll receive a link to reset your password. Don\'t forget to check your spam folder.';

  @override
  String get authGoogleSignInFailed =>
      'Google sign-in didn\'t go through. Try again or use your email.';

  @override
  String get authWelcomeTitle => 'Welcome to TOTUM';

  @override
  String get authTagline =>
      'Your complete tracking companion, for total vitality.';

  @override
  String get authPricingText =>
      '7-day free trial, then a €14.99/year subscription renewed automatically. Cancellable anytime.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Enter an email';

  @override
  String get authEmailInvalid => 'Invalid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Enter a password';

  @override
  String get authPasswordMinLength => 'At least 6 characters';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authSignUpButton => 'Create an account';

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authTermsNotice =>
      'By continuing, you accept TOTUM\'s terms of use and privacy policy.';

  @override
  String get sunScreenTitle => 'Sun & vitamin D';

  @override
  String get sunSkinType1Label => 'Type I — Very fair';

  @override
  String get sunSkinType1Desc =>
      'Very pale skin, always burns, never tans. Often red hair, freckles.';

  @override
  String get sunSkinType2Label => 'Type II — Fair';

  @override
  String get sunSkinType2Desc =>
      'Fair skin, burns easily, tans little and with difficulty.';

  @override
  String get sunSkinType3Label => 'Type III — Medium';

  @override
  String get sunSkinType3Desc =>
      'Medium skin, burns moderately, tans gradually.';

  @override
  String get sunSkinType4Label => 'Type IV — Olive';

  @override
  String get sunSkinType4Desc =>
      'Olive/tan skin, rarely burns, tans well and easily.';

  @override
  String get sunSkinType5Label => 'Type V — Dark';

  @override
  String get sunSkinType5Desc =>
      'Dark brown skin, rarely burns, tans intensely.';

  @override
  String get sunSkinType6Label => 'Type VI — Very dark';

  @override
  String get sunSkinType6Desc => 'Black skin, almost never burns.';

  @override
  String get sunExposureFaceHands => 'Face & hands';

  @override
  String get sunExposureArmsFace => 'Arms & face';

  @override
  String get sunExposureArmsLegs => 'Arms & legs';

  @override
  String get sunExposureSwimwear => 'Swimwear';

  @override
  String get sunSkinPickerTitle => 'What\'s your skin type?';

  @override
  String get sunSkinPickerSubtitle =>
      'Your skin determines how fast you synthesize vitamin D in the sun. We only ask you this once.';

  @override
  String get sunLocationDisabled =>
      'Location is disabled on this device. Turn it on, or enter the UV index manually.';

  @override
  String get sunLocationDenied =>
      'Location access denied. You can enter the UV index manually.';

  @override
  String get sunUvFetchFailed => 'Couldn\'t retrieve the UV index right now.';

  @override
  String get sunLocationUnavailable =>
      'Location unavailable. Enter the UV index manually.';

  @override
  String sunValidateSnackbar(String amount) {
    return '☀️ +$amount µg of vitamin D added to your day!';
  }

  @override
  String get sunTodayEstimateLabel => 'Estimated sun vitamin D today';

  @override
  String get sunResetTooltip => 'Reset';

  @override
  String get sunUvCurrentTitle => 'Current UV index';

  @override
  String get sunRefreshLocationTooltip => 'Refresh my location';

  @override
  String get sunBelowUv3Info =>
      'Below UV 3, vitamin D synthesis is negligible. This isn\'t the right time — but enjoy the fresh air anyway.';

  @override
  String get sunUvUnknown => 'UV index unknown.';

  @override
  String get sunManualUvLabel => 'Enter manually: ';

  @override
  String get sunYourSkinTypeLabel => 'Your skin type: ';

  @override
  String get sunModifyButton => 'Change';

  @override
  String get sunExposedSkinSurface => 'Exposed skin surface';

  @override
  String get sunSunDuration => 'Time in the sun';

  @override
  String sunMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get sunSunscreenSwitchTitle => 'I was wearing sunscreen';

  @override
  String get sunSunscreenSwitchSubtitle =>
      'Sunscreen blocks 95 to 98% of vitamin D synthesis.';

  @override
  String sunEstimatedAmount(String amount) {
    return '≈ $amount µg estimated';
  }

  @override
  String sunEstimateDetail(int minutes, String skinType, String exposure) {
    return 'for $minutes min, $skinType skin, $exposure';
  }

  @override
  String get sunValidateButton => 'Log my exposure';

  @override
  String get sunGoodConditionsTitle => 'The right conditions';

  @override
  String get sunCondition1 =>
      'The UVB needed for vitamin D are only present around midday. Aim for the edges of that window (late morning, mid-afternoon): a few minutes is enough. Between 12pm and 4pm, radiation peaks — keep it brief and cautious, never a prolonged exposure.';

  @override
  String get sunCondition2 =>
      'Behind glass (window, car), the glass blocks 100% of UVB: no vitamin D is produced.';

  @override
  String get sunCondition3 =>
      'Sunglasses do NOT interfere with synthesis — it happens through the skin, so keep them on to protect your eyes.';

  @override
  String get sunCondition4 =>
      'At our latitudes, synthesis is only possible roughly from March to October. In winter, rely on diet and possibly a supplement.';

  @override
  String get sunCondition5 =>
      'Your body only produces a limited dose of vitamin D, then stops: staying longer adds nothing more, but speeds up skin aging and increases the risk of skin cancer. The goal is the strict minimum, not a tan.';

  @override
  String get sunDisclaimer =>
      'Educational estimate based on scientific models. This is not a medical measurement: only a blood test can precisely assess your vitamin D level.';

  @override
  String get sunUvLow => 'Low — negligible synthesis';

  @override
  String get sunUvModerate => 'Moderate — synthesis possible';

  @override
  String get sunUvHigh => 'High — effective synthesis, protect yourself';

  @override
  String get sunUvVeryHigh => 'Very high — a few minutes is enough';

  @override
  String get sunUvExtreme => 'Extreme — use great caution';

  @override
  String get accountScreenTitle => 'Account & Settings';

  @override
  String get accountSettingsSectionLabel => 'Settings';

  @override
  String get accountMenuAccount => 'Account';

  @override
  String get accountMenuAppearance => 'Appearance';

  @override
  String get accountMenuLanguageUnits => 'Language & units';

  @override
  String get accountMenuMyData => 'My data';

  @override
  String get accountMenuAbout => 'About';

  @override
  String get accountDefaultName => 'TOTUM account';

  @override
  String get accountStatusLifetimePremium => 'Lifetime Premium';

  @override
  String get accountStatusAnnualSubscriber => 'Annual subscriber';

  @override
  String accountStatusTrialRemaining(int days) {
    return 'Trial — ${days}d left';
  }

  @override
  String get accountStatusTrialEnded => 'Trial ended';

  @override
  String get accountSubLifetimeSubtitle =>
      'Full access, no ads — thank you for your trust.';

  @override
  String get accountSubActiveTitle => 'Annual subscription active';

  @override
  String accountSubActiveSubtitle(String date) {
    return 'Until $date · €14.99/year';
  }

  @override
  String get accountManageSubscription => 'Manage my subscription';

  @override
  String get accountManageViaStripeReceipt =>
      'To manage or cancel your subscription, use the \"Manage your subscription\" link found in your Stripe receipts.';

  @override
  String get accountTrialUnknown =>
      'We haven\'t been able to determine your trial yet. If needed, sign out and sign back in.';

  @override
  String accountTrialRemainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count days of full access to TOTUM left.',
      one: 'You have 1 day of full access to TOTUM left.',
    );
    return '$_temp0';
  }

  @override
  String get accountTrialEndedSubtitle =>
      'Your free trial has ended — subscribe to regain full access.';

  @override
  String get accountTrialInProgressTitle => 'Free trial in progress';

  @override
  String get accountTrialEndedTitle => 'Free trial ended';

  @override
  String get accountProcessing => 'Processing…';

  @override
  String accountSubscribeWithPrice(String price) {
    return 'Subscribe ($price)';
  }

  @override
  String get accountSubscribeAnnualWeb => 'Subscribe — €14.99/year';

  @override
  String get accountInAppUnavailable =>
      'In-app payment isn\'t available on this device.';

  @override
  String get accountStripeSecurePayment =>
      '100% secure payment via Stripe · renewed automatically every year, cancellable anytime.';

  @override
  String get accountProductNotFound =>
      'Premium product not found on the Store.';

  @override
  String get accountSubscriptionUnavailable =>
      'Subscription unavailable right now. Try again in a moment.';

  @override
  String get accountAlreadyOwnedRestored =>
      'You already owned TOTUM Premium on this Google account, your access has been restored.';

  @override
  String get accountUnknownError => 'Unknown error.';

  @override
  String get accountPremiumActivated =>
      'Thank you! TOTUM Premium is activated!';

  @override
  String accountActivationError(String error) {
    return 'Error during activation: $error';
  }

  @override
  String get accountSubscriptionActivated =>
      'Thank you! Your TOTUM Premium subscription is active!';

  @override
  String get accountDeleteDialogTitle => 'Delete my account';

  @override
  String get accountDeleteDialogContent =>
      'This action is irreversible: your deletion request will be recorded, and your account and all your data (journal, goals, weight history) will be permanently deleted. You\'ll be signed out immediately.';

  @override
  String get accountDeletePermanently => 'Delete permanently';

  @override
  String get accountDeletingInProgress => 'Deleting…';

  @override
  String get accountDetailsScreenTitle => 'Account';

  @override
  String get accountEmailLabel => 'Email address';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get appearanceScreenTitle => 'Appearance';

  @override
  String get appearanceThemeSectionTitle => 'Theme';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceTextSizeSectionTitle => 'Text size';

  @override
  String get languageUnitsScreenTitle => 'Language & units';

  @override
  String get languageSectionTitle => 'App language';

  @override
  String get languageSubLabel => 'Interface language';

  @override
  String get languageSubLabelHint =>
      'Applies to the whole app, including food names in search and the journal.';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get unitsSectionTitle => 'Units of measurement';

  @override
  String get unitsSubLabel => 'Weight and height';

  @override
  String get unitsSubLabelHint =>
      'Internal calculations always stay in metric.';

  @override
  String get dataExportScreenTitle => 'My data';

  @override
  String get dataExportSectionTitle => 'Export my journal';

  @override
  String get dataExportDescription =>
      'Export your food journal, goals and micronutrients over a period, in HTML format (convertible to PDF, e.g. for a healthcare professional).';

  @override
  String get dataExportPeriodHelpText => 'Period to export';

  @override
  String get dataExportSaveText => 'EXPORT';

  @override
  String get dataExportSuccessSnackbar => 'Report exported';

  @override
  String dataExportErrorSnackbar(String error) {
    return 'Export error: $error';
  }

  @override
  String get dataExportGenerating => 'Generating…';

  @override
  String get dataExportButton => 'Export my data';

  @override
  String get aboutScreenTitle => 'About';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get activityLevelSedentaryTitle => 'Sedentary';

  @override
  String get activityLevelLightTitle => 'Lightly active';

  @override
  String get activityLevelModerateTitle => 'Moderately active';

  @override
  String get activityLevelActiveTitle => 'Active';

  @override
  String get activityLevelVeryActiveTitle => 'Very active';

  @override
  String get activityLevelExtremeTitle => 'Extremely active';

  @override
  String get activityLevelSedentaryDesc =>
      'Mostly sedentary life (desk job, little walking), little to no sport.';

  @override
  String get activityLevelLightDesc =>
      'Some daily walking, and/or 1 to 3 sport sessions per week.';

  @override
  String get activityLevelModerateDesc =>
      'Good amount of daily walking (~8,000-10,000 steps), and/or 3 to 5 sport sessions per week.';

  @override
  String get activityLevelActiveDesc =>
      'Lots of daily movement (standing job), and/or near-daily sport (5-6 sessions/week).';

  @override
  String get activityLevelVeryActiveDesc =>
      'Physical job, and/or several intense sessions some days (e.g. running + weights the same day).';

  @override
  String get activityLevelExtremeDesc =>
      'Intense physical job AND near-daily high-intensity training (e.g. semi-pro athlete).';

  @override
  String get bodyFatTierEssential => 'Essential';

  @override
  String get bodyFatTierAthlete => 'Athlete';

  @override
  String get bodyFatTierFitness => 'Fitness';

  @override
  String get bodyFatTierAverage => 'Average';

  @override
  String get bodyFatTierHigh => 'High';

  @override
  String get dietStyleBalancedTitle => 'Balanced';

  @override
  String get dietStyleHighCarbTitle => 'High-carb';

  @override
  String get dietStyleHighFatTitle => 'High-fat';

  @override
  String get dietStyleKetoTitle => 'Ketogenic (Keto)';

  @override
  String get dietStyleBalancedDesc =>
      'Reference split (~30% fat / ~45% carbs of total calories): the zone associated with the lowest all-cause mortality in large cohort studies, within official bounds (AMDR).';

  @override
  String get dietStyleHighCarbDesc =>
      'Fat brought toward the lower end of the recommended range, carbs more generous — useful for high-volume endurance sports, without ever going outside official bounds.';

  @override
  String get dietStyleHighFatDesc =>
      'More fat for those who prefer it (satiety, palatability) — capped at the recommended upper limit (35% of calories), never beyond.';

  @override
  String get dietStyleKetoDesc =>
      'Carbs kept very low, fat very high — an approach validated for certain supervised therapeutic uses (e.g. epilepsy), but whose long-term cardiovascular effects in the general population remain poorly documented (studies mostly over a few weeks). Use occasionally and with judgment, not as a default setting.';

  @override
  String get profileDietOmnivore => 'Omnivore';

  @override
  String get profileDietVegetarian => 'Vegetarian';

  @override
  String get profileDietVegan => 'Vegan';

  @override
  String get goalLoseTitle => 'Fat loss';

  @override
  String get goalLoseDesc =>
      'Lose fat mass at a good pace, while preserving your muscle and energy.';

  @override
  String get goalLoseTip1 =>
      'Keep a good protein intake to protect your muscles';

  @override
  String get goalLoseTip2 => 'Move regularly — even a daily walk counts';

  @override
  String get goalLoseTip3 => 'Sleep enough: recovery is part of the result';

  @override
  String get goalLoseTip4 => 'After 8 to 10 weeks, plan a break in Maintenance';

  @override
  String get goalLoseCoach =>
      'The priority is to preserve your muscle mass while you lose fat. TOTUM automatically raises your protein target. A moderate pace is more effective and far more sustainable than an extreme diet.';

  @override
  String get goalLoseMildTitle => 'Gentle loss';

  @override
  String get goalLoseMildDesc =>
      'Lose weight gradually, without frustration or fatigue crashes. Ideal for staying the course.';

  @override
  String get goalLoseMildTip1 =>
      'A light deficit, easier to sustain day to day';

  @override
  String get goalLoseMildTip2 => 'Take care of your recovery and sleep';

  @override
  String get goalLoseMildTip3 =>
      'Keep energy for your activities and wellbeing';

  @override
  String get goalLoseMildTip4 => 'Consistency matters more than speed';

  @override
  String get goalLoseMildCoach =>
      'This gentle approach is perfect for losing weight without thinking about it constantly. Progress is slower, but that\'s exactly what makes it sustainable: patience and consistency are your best allies.';

  @override
  String get goalMaintainTitle => 'Maintenance';

  @override
  String get goalMaintainDesc =>
      'Stabilize your weight and feel good, over the long run.';

  @override
  String get goalMaintainTip1 => 'Eat according to your needs, no more no less';

  @override
  String get goalMaintainTip2 => 'Keep a regular physical activity';

  @override
  String get goalMaintainTip3 => 'Keep a good protein intake';

  @override
  String get goalMaintainTip4 =>
      'Watch your average weight over the week, not day to day';

  @override
  String get goalMaintainCoach =>
      'Your goal is no longer to lose or gain, but to keep your results and feel good. Consistency is what anchors good habits over the long term — you\'re in the zone of serenity.';

  @override
  String get goalGainMildTitle => 'Muscle gain';

  @override
  String get goalGainMildDesc =>
      'Build muscle progressively, with controlled fat gain.';

  @override
  String get goalGainMildTip1 => 'A slight surplus, just enough to build';

  @override
  String get goalGainMildTip2 => 'Pair with resistance training if you can';

  @override
  String get goalGainMildTip3 => 'A good protein intake supports your muscles';

  @override
  String get goalGainMildTip4 => 'Quality sleep speeds up progress';

  @override
  String get goalGainMildCoach =>
      'A slow, controlled progression gives a much better muscle-to-fat ratio than a fast gain. No need to force it: quality beats quantity, and your body will thank you.';

  @override
  String get goalGainTitle => 'Mass gain';

  @override
  String get goalGainDesc =>
      'Maximize your muscle and strength gains, for the most ambitious goals.';

  @override
  String get goalGainTip1 => 'A more pronounced surplus to support building';

  @override
  String get goalGainTip2 => 'Ideal if you train intensely and regularly';

  @override
  String get goalGainTip3 => 'Good recovery is essential';

  @override
  String get goalGainTip4 => 'Monitor your progress to stay on track';

  @override
  String get goalGainCoach =>
      'This mode is built for ambitious goals. Regularly check your progress to avoid excess fat gain: a controlled surplus always gives better results than an untracked excess.';

  @override
  String get profileMaintainDynamic => 'Dynamic maintenance';

  @override
  String get profileEquilibrium => 'Balance';

  @override
  String profileTargetedRateNeg(String pct) {
    return 'Target pace: −$pct %/wk';
  }

  @override
  String profileTargetedRatePos(String pct) {
    return 'Target pace: +$pct %/wk';
  }

  @override
  String profileMacroCoherenceOver(
      String computed, String diff, String pct, String kcal) {
    return 'Your macros add up to $computed kcal — $diff kcal ($pct %) MORE than the $kcal kcal shown.';
  }

  @override
  String profileMacroCoherenceUnder(
      String computed, String diff, String pct, String kcal) {
    return 'Your macros add up to $computed kcal — $diff kcal ($pct %) LESS than the $kcal kcal shown.';
  }

  @override
  String profileGoalsUpdatedSnackbar(int kcal) {
    return 'Goals updated · $kcal kcal per day';
  }

  @override
  String get profileConfirmGoals => 'Confirm my goals';

  @override
  String get profileGoalsSaved => 'Goals saved';

  @override
  String get profileBackToAuto => 'Back to automatic calculation';

  @override
  String get profileCustomizeGoals => 'Customize my goals';

  @override
  String get profileFullDetailFooter =>
      'The full detail (vitamins, minerals, fatty acids) is calculated automatically in the Overview tab.';

  @override
  String get profileTodayEyebrow => 'TODAY';

  @override
  String get profileKcalOver => 'kcal over';

  @override
  String get profileKcalRemaining => 'kcal left';

  @override
  String get profileBaseGoal => 'Base goal';

  @override
  String get profileFoodsLabel => 'Food';

  @override
  String get profileRefinedByResults => 'Refined based on your actual results';

  @override
  String profileMacroGramsOver(int amount) {
    return '+$amount g over';
  }

  @override
  String profileMacroGramsRemaining(int amount) {
    return '$amount g left';
  }

  @override
  String get profileMacronutrients => 'Macronutrients';

  @override
  String get profileCarbs => 'Carbs';

  @override
  String get profileFats => 'Fat';

  @override
  String get profileProteins => 'Protein';

  @override
  String get profilePlateToday => 'Your plate today';

  @override
  String get profilePlateGoal => 'Your plate (goal)';

  @override
  String get profileMicronutrientsFeatured => 'Featured micronutrients';

  @override
  String get profileGoalTileLabel => 'Goal';

  @override
  String get profileMeasuresTileLabel => 'Measurements';

  @override
  String get profileActivityLevelTileLabel => 'Activity level';

  @override
  String get profileDietTileLabel => 'Diet';

  @override
  String get profileMacroSplitTileLabel => 'Macro split';

  @override
  String get profileDone => 'Done';

  @override
  String profileImpactChanged(int before, int after, String diff) {
    return 'Impact on your goal: $before → $after kcal ($diff)';
  }

  @override
  String profileImpactUnchanged(int after) {
    return 'Current goal: $after kcal';
  }

  @override
  String get profileYourGoalTitle => 'Your goal';

  @override
  String get profileToRemember => 'Key points';

  @override
  String get profileCoachAdvice => 'Coach\'s advice';

  @override
  String get profileMeasuresSheetTitle => 'Your measurements';

  @override
  String get profileMale => 'Male';

  @override
  String get profileFemale => 'Female';

  @override
  String get profileAgeYears => 'Age (years)';

  @override
  String get profileHeightCm => 'Height (cm)';

  @override
  String get profileHeightIn => 'Height (in)';

  @override
  String get profileWeightKg => 'Weight (kg)';

  @override
  String get profileWeightLb => 'Weight (lb)';

  @override
  String get profileWeighInAdvice =>
      'Weigh yourself every day if possible, under the same conditions each time — ideally in the morning, fasted, right after waking up.';

  @override
  String get profileTargetWeightKg => 'Target weight (kg) — optional';

  @override
  String get profileTargetWeightLb => 'Target weight (lb) — optional';

  @override
  String get profileTargetWeightHint =>
      'Used only for the Maintenance goal: once close to your target, your calories follow your actual expenditure; if you drift away, a small automatic adjustment gently brings you back.';

  @override
  String get profileBodyFatOptional => 'Body fat — optional';

  @override
  String get profileBodyFatHint =>
      'Choose the range closest to your current physique.';

  @override
  String get profileActivitySheetTitle => 'Your activity level';

  @override
  String get profileActivitySheetDesc =>
      'Choose the description closest to YOUR typical week — daily life AND sport combined, either one is enough to place you in a tier.';

  @override
  String get profileMacroSplitSheetDesc =>
      'Doesn\'t change your calories or protein — only how the rest is split between fat and carbs.';

  @override
  String get profileInvalidNumber => 'Invalid number';

  @override
  String get profileYourEvolution => 'Your evolution';

  @override
  String get profileLast60Days => 'last 60 days';

  @override
  String get profileAdaptiveEstimate => 'adaptive estimate';

  @override
  String get profileCustomGoalsTitle => 'My custom goals';

  @override
  String get profileCustomGoalsSubtitle =>
      'These values replace the automatic calculation.';

  @override
  String get profileEnergyKcal => 'Energy (kcal)';

  @override
  String get profileProteinG => 'Protein (g)';

  @override
  String get profileCarbG => 'Carbs (g)';

  @override
  String get profileFatG => 'Fat (g)';

  @override
  String get profileFiberG => 'Fiber (g)';

  @override
  String get profileApplyGoals => 'Apply my goals';

  @override
  String get nutrientEnergy => 'Energy';

  @override
  String get nutrientProtein => 'Protein';

  @override
  String get nutrientCarbs => 'Carbs';

  @override
  String get nutrientFat => 'Fat';

  @override
  String get nutrientFiber => 'Fiber';

  @override
  String get nutrientOmega9 => 'Omega-9 (Oleic)';

  @override
  String get nutrientOmega6 => 'Omega-6 (LA)';

  @override
  String get nutrientOmega3 => 'Omega-3 (ALA)';

  @override
  String get nutrientSatFat => 'Saturated fat';

  @override
  String get nutrientSugars => 'Sugars';

  @override
  String get nutrientSalt => 'Salt';

  @override
  String get nutrientAlcohol => 'Alcohol';

  @override
  String get nutrientRetinol => 'Retinol';

  @override
  String get nutrientBetaCarotene => 'Beta-car.';

  @override
  String get nutrientCopper => 'Copper';

  @override
  String get nutrientIron => 'Iron';

  @override
  String get nutrientIodine => 'Iodine';

  @override
  String get nutrientMagnesium => 'Magnesium';

  @override
  String get nutrientManganese => 'Manganese';

  @override
  String get nutrientPhosphorus => 'Phosphorus';

  @override
  String get nutrientSelenium => 'Selenium';

  @override
  String get nutrientCholesterol => 'Cholesterol';

  @override
  String get nutrientVitaminDFull => 'Vitamin D';

  @override
  String get nutrientVitaminCFull => 'Vitamin C';

  @override
  String get nutrientVitaminKFull => 'Vitamin K';

  @override
  String get nutrientVitaminB9Full => 'Vitamin B9';

  @override
  String get nutrientVitaminB12Full => 'Vitamin B12';

  @override
  String get nutrientOmega3Marine => 'Marine omega-3';

  @override
  String get moodExcellent => 'Excellent balance!';

  @override
  String get moodGood => 'Good balance';

  @override
  String get moodCorrect => 'Decent, room to improve';

  @override
  String get moodToImprove => 'Needs improvement';

  @override
  String get moodRebalance => 'Day needs rebalancing';

  @override
  String get scorePillarVitamins => 'Vitamins';

  @override
  String get scorePillarMinerals => 'Minerals';

  @override
  String get scorePillarFattyAcids => 'Fatty acids';

  @override
  String get scorePillarHydration => 'Hydration';

  @override
  String get scorePillarWatch => 'To watch';

  @override
  String scoreCapReason(String label, int pct) {
    return '$label at $pct% of today\'s target — the score stays capped while this lasts.';
  }

  @override
  String get bilanScoreTitle => 'TOTUM Score';

  @override
  String get bilanScoreUpdatesLive => 'Updates as you add each meal';

  @override
  String get bilanScoreHowCalculated => 'How is this score calculated?';

  @override
  String bilanSafetyLimitExceeded(String list) {
    return 'Safety limit exceeded: $list';
  }

  @override
  String bilanUnderstandLabel(String label) {
    return 'Understand: $label';
  }

  @override
  String get bilanWhyLimitExists => 'Why this limit exists';

  @override
  String get bilanExcessConsequences => 'What prolonged excess can cause';

  @override
  String get bilanExcessSource => 'Where the excess comes from';

  @override
  String get bilanWhatToDo => 'What to do, concretely';

  @override
  String bilanSafetyLimitDetail(String limite, String reference) {
    return 'Safety limit: $limite  ·  $reference';
  }

  @override
  String bilanConcernedFoods(String periode) {
    return 'Foods involved $periode';
  }

  @override
  String get bilanNoFoodIdentifiedPeriod =>
      'No food identified over this period.';

  @override
  String get bilanPeriodToday => 'today';

  @override
  String get bilanPeriodThatDay => 'that day';

  @override
  String bilanPeriodLastNDays(int days) {
    return 'over the last $days days';
  }

  @override
  String bilanPeriodOnDate(String date) {
    return 'on $date';
  }

  @override
  String get bilanCarbBreakdownTitle => 'Carbohydrate breakdown';

  @override
  String get bilanCarbBreakdownIntro =>
      'Not all carbs are equal. Starch releases its energy slowly; simple sugars, quickly.';

  @override
  String get bilanNoCarbDataPeriod => 'No detailed carb data for this period.';

  @override
  String get bilanStarchLabel => 'Starch (complex carbs)';

  @override
  String get bilanStarchHint => 'Grains, legumes, tubers — lasting energy.';

  @override
  String get bilanSimpleSugarsLabel => 'Simple sugars (total)';

  @override
  String get bilanSimpleSugarsHint =>
      'Fast absorption — best from whole fruit.';

  @override
  String get bilanPolyolsHint =>
      'Bulk sweeteners — often a sign of a processed product.';

  @override
  String get bilanSimpleSugarsDetailTitle => 'Simple sugar breakdown';

  @override
  String get bilanFructoseHint => 'Sugar from fruit and honey.';

  @override
  String get bilanSaccharoseLabel => 'Sucrose';

  @override
  String get bilanSaccharoseHint => 'Table sugar (fructose + glucose).';

  @override
  String get bilanLactoseHint => 'Sugar from milk and dairy products.';

  @override
  String get bilanFruitVsSodaNote =>
      'A whole fruit and a soda can contain the same amount of fructose, but the fruit comes with fiber, water and vitamins that slow its absorption. The food matrix matters as much as the sugar itself.';

  @override
  String get dietNoteOmega3NoFish =>
      'Without fish, your best direct source of EPA/DHA is an omega-3 supplement from micro-algae — which is exactly where fish get theirs. Plant omega-3s (ALA from flax, hemp, walnuts) are still useful but convert poorly into EPA/DHA.';

  @override
  String get dietNoteB12Vegan =>
      'Vitamin B12 doesn\'t exist in plants: on a vegan diet, supplementation is essential, not optional. It\'s the one nutrient with absolute consensus on this point. Aim for a regular intake and monitor your status with a blood test.';

  @override
  String get dietNoteB12Vegetarian =>
      'On a vegetarian diet, eggs and dairy cover part of your B12 needs, but monitor your status: depending on your intake, light supplementation may help.';

  @override
  String get dietNoteIronVegetal =>
      'Plant (non-heme) iron is absorbed less efficiently than animal iron: systematically pair a vitamin C source (lemon, bell pepper, parsley) with your legumes and whole grains to multiply its absorption. Avoid tea and coffee during meals.';

  @override
  String get dietNoteZincVegetal =>
      'Phytates in grains and legumes hinder the absorption of plant zinc. Soaking, sprouting and fermentation (sourdough bread) neutralize much of this — a valuable habit on a plant-based diet.';

  @override
  String get dietNoteCalciumVegan =>
      'Without dairy, rely on plants rich in well-absorbed calcium (kale, broccoli, calcium-sulfate tofu, almonds) and calcium-rich mineral waters. Vitamin D and K2 remain essential to fix it properly into bone.';

  @override
  String get dietNoteIodineVegan =>
      'Without seafood or dairy, iodine can be lacking on a vegan diet: seaweed (in moderation, as it\'s very concentrated) and iodized salt are your main sources. Keep an eye on this often-overlooked intake.';

  @override
  String get dietNoteVitDVegan =>
      'Without oily fish or eggs, diet alone struggles to cover vitamin D on a vegan diet: sun exposure (see the dedicated page) and supplementation, ideally plant-based (lichen), should be prioritized, especially from October to April.';

  @override
  String get dietNoteProteinVegan =>
      'On a vegan diet, vary your protein sources throughout the day (legumes + whole grains, tofu, tempeh, nuts/seeds) to get all essential amino acids. Complementarity over the day is enough — no need to combine everything in a single meal.';

  @override
  String get bilanFicheUnavailable => 'Fact sheet unavailable for now.';

  @override
  String get bilanFicheBenefits => 'Health benefits';

  @override
  String get bilanFicheIntakes => 'Recommended intake';

  @override
  String get bilanFicheSafetyLimit => 'Safety limit';

  @override
  String get bilanFicheWhereToFind => 'Where to find it';

  @override
  String get bilanDietAdaptedVegan => 'Adapted to your vegan diet';

  @override
  String get bilanDietAdaptedVegetarian => 'Adapted to your vegetarian diet';

  @override
  String get bilanDidYouKnow => 'Did you know?';

  @override
  String get bilanEducationalDisclaimer =>
      'Educational information based on ANSES and EFSA references. It does not replace personalized medical advice.';

  @override
  String get bilanScoreExplainerTitle => 'How is your score calculated?';

  @override
  String get bilanScoreExplainerIntro =>
      'The TOTUM Score combines 5 pillars of your day, weighted by their importance to your health, longevity and performance:';

  @override
  String get bilanPillarFattyAcidsFull => 'Essential fatty acids';

  @override
  String get bilanPillarVitaminsDetail =>
      'Coverage of your vitamin needs relative to today\'s targets.';

  @override
  String get bilanPillarMineralsDetail =>
      'Coverage of your mineral needs (iron, magnesium, zinc...).';

  @override
  String get bilanPillarFattyAcidsDetail =>
      'Omega-3/6/9 — essential, not made by the body.';

  @override
  String get bilanPillarHydrationDetail =>
      'Water drunk + water from food, vs your target.';

  @override
  String get bilanPillarWatchDetail =>
      'Sugars, salt, saturated fat — staying under today\'s limit is the good signal.';

  @override
  String get bilanSafetyCapTitle => 'The safety cap';

  @override
  String get bilanSafetyCapExplainer =>
      'If a single \"to watch\" element strongly exceeds today\'s limit (for example well beyond double), your score is automatically capped — even if the rest of your day is perfect. A large excess all at once has a real impact on your health (heart, blood pressure), and the score needs to show that clearly rather than dilute it into an average.';

  @override
  String get bilanScoreLiveNote =>
      'Your score evolves throughout the day as you add meals — that\'s normal, it reflects what you\'ve actually eaten so far.';

  @override
  String get bilanScoreSourcesNote =>
      'Based on official recommendations (WHO, EFSA, ANSES) and international reference indexes (Healthy Eating Index, Alternate Healthy Eating Index).';

  @override
  String get bilanSunVitDTitle => 'Sun vitamin D';

  @override
  String bilanSunVitDAverageDesc(String periode) {
    return 'Estimated average $periode, synthesized by your skin in the sun';
  }

  @override
  String bilanSunVitDSingleDesc(String periode) {
    return 'Estimated $periode, synthesized by your skin in the sun';
  }

  @override
  String get bilanSunVitDAlreadyCounted =>
      'already counted in your \"Vit D\" line above, in addition to what your diet provides.';

  @override
  String get bilanSunVitDNoSession =>
      'No sun session logged for this period — only the dietary portion is counted for now.';

  @override
  String get bilanLogSunExposure => 'Log a sun exposure';

  @override
  String bilanConsumedPeriod(String periode) {
    return 'What you consumed $periode';
  }

  @override
  String get bilanNoFoodContainedNutrient =>
      'No food you ate contained this nutrient over this period. This might be exactly where to focus: check the fact sheet to find out where to get it.';

  @override
  String get bilanUnnamedFood => 'Food';

  @override
  String bilanIntakeMainFoods(String label) {
    return '$label intake: main foods';
  }

  @override
  String bilanTopContributorsIntro(String label) {
    return 'Here are the foods that contributed most to your $label intake that day, from largest to smallest.';
  }

  @override
  String get bilanNoFoodIdentifiedNutrient =>
      'No food identified for this nutrient.';

  @override
  String get bilanOccasionalExcessNote =>
      'An occasional excess usually isn\'t a concern. If it happens often, you can space out the most concentrated foods or reduce their portion.';

  @override
  String bilanDayTitle(String date) {
    return 'Report for $date';
  }

  @override
  String get bilanNoDataForDay => 'No data for this day.';

  @override
  String get bilanMacrosCardTitle => 'Macros';

  @override
  String get bilanGroupMacroTargets => 'Macro targets';

  @override
  String get bilanGroupIndicative => 'Indicative intakes';

  @override
  String bilanTargetKcal(String target) {
    return 'Target = $target kcal';
  }

  @override
  String bilanConsumedKcal(String value) {
    return 'Consumed = $value kcal';
  }

  @override
  String bilanRemainingKcal(String value) {
    return 'Remaining = $value kcal';
  }

  @override
  String bilanExceededByKcal(String value) {
    return 'Exceeded by $value kcal';
  }

  @override
  String bilanMacroProgressOvershot(
      String value, String target, String unit, String excess) {
    return '$value / $target $unit • exceeded by $excess $unit';
  }

  @override
  String bilanMacroProgressRemaining(
      String value, String target, String unit, String remaining) {
    return '$value / $target $unit • $remaining $unit left';
  }

  @override
  String bilanExceedsSafetyLimit(String ul, String unit) {
    return 'Exceeds the safety limit ($ul $unit/day)';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navJournal => 'Journal';

  @override
  String get navBilan => 'Overview';

  @override
  String get navConseils => 'Advice';

  @override
  String get bilanGeneratingReport => 'Generating report…';

  @override
  String get bilanNoDataToDisplay => 'No data to display.';

  @override
  String get bilanSpanDay => 'Day';

  @override
  String get bilanSpan7d => '7 d';

  @override
  String get bilanSpan30d => '30 d';

  @override
  String get bilanSpan90d => '90 d';

  @override
  String get bilanEnergyBalance7d => 'Your energy balance (7 days)';

  @override
  String get bilanEnergyBalance30d => 'Your energy balance (30 days)';

  @override
  String get bilanEnergyBalance90d => 'Your energy balance (90 days)';

  @override
  String get bilanEnergyBalance1d => 'Your energy balance (1 day)';

  @override
  String bilanVeryConsistent(String label, String delta) {
    return 'Very consistent: your average intake closely tracks $label over this period (gap of $delta kcal/day).';
  }

  @override
  String bilanAverageDeltaSummary(String delta, String dir, String label) {
    return 'On average, you\'re $delta kcal/day $dir $label.';
  }

  @override
  String get bilanAboveDir => 'above';

  @override
  String get bilanBelowDir => 'below';

  @override
  String get bilanYourEstimatedExpenditure => 'your estimated expenditure';

  @override
  String get bilanYourGoal => 'your goal';

  @override
  String get bilanMonthJan => 'Jan';

  @override
  String get bilanMonthFeb => 'Feb';

  @override
  String get bilanMonthMar => 'Mar';

  @override
  String get bilanMonthApr => 'Apr';

  @override
  String get bilanMonthMay => 'May';

  @override
  String get bilanMonthJun => 'Jun';

  @override
  String get bilanMonthJul => 'Jul';

  @override
  String get bilanMonthAug => 'Aug';

  @override
  String get bilanMonthSep => 'Sep';

  @override
  String get bilanMonthOct => 'Oct';

  @override
  String get bilanMonthNov => 'Nov';

  @override
  String get bilanMonthDec => 'Dec';

  @override
  String get bilanVsGoal => 'Vs. Goal';

  @override
  String get bilanVsExpenditure => 'Vs. Estimated expenditure';

  @override
  String get bilanExpenditureThatDay => 'Estimated expenditure that day';

  @override
  String get bilanGoalThatDay => 'Goal that day';

  @override
  String get bilanAverageLabel => 'Average';

  @override
  String get bilanAverageDeltaLabel => 'Average gap';

  @override
  String get bilanInTargetLabel => 'In target';

  @override
  String get bilanInTargetLegend => 'In target (±10%)';

  @override
  String get bilanModerateDeltaLegend => 'Moderate gap (±10-25%)';

  @override
  String get bilanLargeDeltaLegend => 'Large gap (>25%)';

  @override
  String get bilanGoalChangedHint =>
      'Your goal changed during this period: each bar is compared to the goal that was yours that day (tap a bar for details).';

  @override
  String get bilanTapBarHint => 'Tap a bar to see the day\'s detail.';

  @override
  String get bilanHydrationTitle => 'Hydration';

  @override
  String get bilanDrinksLabel => 'Drinks';

  @override
  String get bilanFoodsWaterLabel => 'Food';

  @override
  String get bilanHydrationGoalReached => 'Hydration goal reached, well done!';

  @override
  String get bilanHydrationReminder =>
      'Remember to drink: aim for about 1.5 L of fluids over the day';

  @override
  String get bilanHydrationAddGlasses =>
      'You can add glasses from the Journal tab';

  @override
  String get bilanTopHydratingFoods => 'Top hydrating foods:';

  @override
  String get bilanAverageSuffix => ' (average)';

  @override
  String get bilanPeriodOver7d => 'over 7 days';

  @override
  String get bilanPeriodOver30d => 'over 30 days';

  @override
  String get bilanPeriodOver90d => 'over 90 days';

  @override
  String bilanRefLabelLine(String label, String value) {
    return '\n$label: $value kcal';
  }

  @override
  String bilanAboveKcal(String value) {
    return '\n+$value kcal above';
  }

  @override
  String bilanBelowKcal(String value) {
    return '\n$value kcal below';
  }

  @override
  String get bilanRightOnTarget => '\nRight on target';

  @override
  String bilanHydrationOfTotal(String total, String target) {
    return '$total ml of a $target ml total water target';
  }

  @override
  String get nutrientVitaminEFull => 'Vitamin E';

  @override
  String get nutrientVitaminB1Full => 'Vitamin B1';

  @override
  String get nutrientVitaminB2Full => 'Vitamin B2';

  @override
  String get nutrientVitaminB3Full => 'Vitamin B3';

  @override
  String get nutrientVitaminB5Full => 'Vitamin B5';

  @override
  String get nutrientVitaminB6Full => 'Vitamin B6';

  @override
  String get nutrientVitaminAFull => 'Vitamin A';

  @override
  String get nutrientOmega3MarineFull => 'Marine omega-3 (EPA/DHA)';

  @override
  String get nutrientOmega9Short => 'Omega-9';

  @override
  String get nutrientOmega6Short => 'Omega-6';

  @override
  String get nutrientOmega3Short => 'Omega-3';

  @override
  String get consPriorityNutritionalTitle => 'Nutritional priorities';

  @override
  String get consNoDeficitToday =>
      'Great balance today!\nNo significant deficiency detected.';

  @override
  String get consPriorityIntro =>
      'Ranked by priority, factoring in the importance of each nutrient. Tap a deficiency to see the foods that address it.';

  @override
  String consCoveredToday(int percent) {
    return '$percent% of today\'s target covered';
  }

  @override
  String get consWhatYouAteToday => 'What you ate today';

  @override
  String get consNoFoodContainedTodayAction =>
      'No food you ate today contained it. This is where to focus: check the fact sheet below to find out where to get it.';

  @override
  String consWhereToFindReadFiche(String label) {
    return 'Where to find it? Read the $label fact sheet';
  }

  @override
  String get consRecipeAddedSnackbar => 'Recipe added to your recipes!';

  @override
  String get consAddRecipeError => 'Error while adding.';

  @override
  String get consHealthyScoreTitle => 'Healthy Score';

  @override
  String get consHealthyScoreIntro =>
      'A score out of 100 that rates the dish\'s overall nutritional quality, calculated from its real CIQUAL values (macros + micronutrients):';

  @override
  String get consCriteriaMicronutrients => 'Micronutrients';

  @override
  String get consCriteriaMicronutrientsDetail =>
      '20 pts — vitamin/mineral diversity';

  @override
  String get consCriteriaProteinDetail =>
      '20 pts — protein density of the dish';

  @override
  String get consCriteriaFiberDetail => '15 pts — fiber content';

  @override
  String get consCriteriaFatQuality => 'Fat quality';

  @override
  String get consCriteriaFatQualityDetail =>
      '15 pts — share of unsaturated fatty acids';

  @override
  String get consCriteriaCalorieDensity => 'Calorie density';

  @override
  String get consCriteriaCalorieDensityDetail =>
      '15 pts — penalizes dishes that are very calorie-dense by weight';

  @override
  String get consCriteriaSugarsDetail => '7.5 pts — sugar control';

  @override
  String get consCriteriaSodiumDetail => '7.5 pts — salt control';

  @override
  String get consHealthyScoreLegend =>
      '70-100: excellent  •  45-69: decent  •  <45: to limit';

  @override
  String get consHealthyScorePreworkoutNote =>
      'Pre-workout snacks are intentionally low in fiber/protein (fast digestion before exercise): a lower score there is normal, not a signal to avoid right before a session.';

  @override
  String get consFitScoreTitle => 'Fit with your day';

  @override
  String get consFitScoreIntro =>
      'A percentage showing how well this recipe\'s size and balance fit this type of meal, given what you have left to eat today and your personal goals (calories, protein, carbs, fat).';

  @override
  String get consCriteriaCalories => 'Calories';

  @override
  String get consFitCriteriaCaloriesDetail =>
      '40% — consistency with a typical portion for this meal';

  @override
  String get consFitCriteriaProteinDetail =>
      '30% — consistency with your remaining protein';

  @override
  String get consFitCriteriaCarbsDetail =>
      '15% — consistency with your remaining carbs';

  @override
  String get consFitCriteriaFatDetail =>
      '15% — consistency with your remaining fat';

  @override
  String get consFitScoreLegend =>
      'Close to 100%: a portion size that fits this meal, given what you have left today  •  Lower score: the dish is clearly too large or too light for this time of day.';

  @override
  String get consFitScoreDetail =>
      'The calculation factors in meal type (breakfast or a snack shouldn\'t weigh as much as lunch) and evolves through the day based on what you\'ve already eaten. It\'s a timing/portion indicator, not a nutritional quality one: use it alongside the Healthy Score, not instead of it.';

  @override
  String get consRecipeScreenTitle => 'TOTUM Recipe';

  @override
  String consHealthyScoreBadge(int score) {
    return 'Healthy Score $score/100';
  }

  @override
  String consFitBadge(int score) {
    return 'Fit $score% with your day';
  }

  @override
  String get consPreparationTitle => 'Preparation';

  @override
  String consRecipeValuesFor(String grams) {
    return 'Values for the recipe ($grams g)';
  }

  @override
  String get consAfterThisMeal => 'After this meal, you\'ll have left';

  @override
  String get consIngredientsTitle => 'Ingredients';

  @override
  String get consStatProt => 'Prot';

  @override
  String get consStatCarb => 'Carb';

  @override
  String get consStatFat => 'Fat';

  @override
  String get consAddedToRecipes => 'Added to your recipes';

  @override
  String get consAddToMyRecipes => 'Add to my recipes';

  @override
  String get consFindInJournalNote =>
      'Once added, find this recipe in your Journal tab to add it to your meals.';

  @override
  String get consCatAll => 'All';

  @override
  String get consCatBreakfast => 'Breakfast';

  @override
  String get consCatLunch => 'Lunch';

  @override
  String get consCatDinner => 'Dinner';

  @override
  String get consCatSnack => 'Snack';

  @override
  String get consCatPreworkout => 'Pre-workout';

  @override
  String get consTagLight => 'Light';

  @override
  String get consTagHighProtein => 'High-protein';

  @override
  String get consTagQuick => 'Quick';

  @override
  String get consTagGlutenFree => 'Gluten-free';

  @override
  String get consTagLactoseFree => 'Lactose-free';

  @override
  String get consTagPostWorkout => 'Post-workout';

  @override
  String get consRecipesTotumTitle => 'TOTUM Recipes';

  @override
  String consRecipesCountSorted(int count) {
    return '$count recipes sorted by goal';
  }

  @override
  String get consForYouChip => 'For you';

  @override
  String get consListView => 'List view';

  @override
  String get consGridView => 'Grid view';

  @override
  String get consResetFilters => 'Reset filters';

  @override
  String get consSearchByIngredient =>
      'Search by ingredient (e.g. chicken, rice...)';

  @override
  String get consForYouToday => 'For you today';

  @override
  String get consNoRecipe => 'No recipe';

  @override
  String consRecipesSelectedForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes selected for you',
      one: '1 recipe selected for you',
    );
    return '$_temp0';
  }

  @override
  String consRecipesCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String get consNoAdviceAvailable => 'No advice available.';

  @override
  String get consTabCoaching => 'Coaching';

  @override
  String get consTabVitality => 'Vitality';

  @override
  String get consTabRecipes => 'Recipes';

  @override
  String get consMedicalDisclaimer =>
      'This advice doesn\'t replace medical advice. If you have a medical condition or any doubt, consult your healthcare professional.';

  @override
  String get consGreetingNight => 'Good night';

  @override
  String get consGreetingMorning => 'Good morning';

  @override
  String get consGreetingAfternoon => 'Good afternoon';

  @override
  String get consGreetingEvening => 'Good evening';

  @override
  String get consGreetingLateNight => 'Good night';

  @override
  String get consCoachTodayLabel => 'Your TOTUM coach today';

  @override
  String get consDefaultCoachQuote =>
      'Every aligned choice today builds tomorrow\'s vitality.';

  @override
  String consScoreProvisional(int pct) {
    return 'Provisional · $pct% of your day';
  }

  @override
  String get consSeeDetail => 'See details';

  @override
  String get consPriorityOfTheDay => 'Priority of the day';

  @override
  String get consNoDeficitTodayShort =>
      'No significant deficiency today. Well done!';

  @override
  String get consTapToSeeWhereToFind => 'Tap to see where to find it';

  @override
  String get consDailyAdviceTitle => 'Today\'s advice';

  @override
  String consPersonalizedAdviceCount(int count) {
    return '$count personalized tips for today';
  }

  @override
  String get consAdviceCategories =>
      'Nutrition, movement, sleep, stress, mindset';

  @override
  String get consWellbeingTitle => 'Holistic wellbeing';

  @override
  String get consWellbeingIntro =>
      'The three pillars of your daily vitality: sleep, stress and sun exposure.';

  @override
  String get consSleepVeryShort => 'Very short';

  @override
  String get consSleepInsufficient => 'Insufficient';

  @override
  String get consSleepCorrect => 'Decent';

  @override
  String get consSleepIdeal => 'Ideal';

  @override
  String get consSleepLong => 'Long';

  @override
  String get consStressSerene => 'Serene';

  @override
  String get consStressCalm => 'Calm';

  @override
  String get consStressModerate => 'Moderate';

  @override
  String get consStressHigh => 'High';

  @override
  String get consStressVeryHigh => 'Very high';

  @override
  String get consSleepTipVeryShort =>
      'Such a short night weighs on your recovery and cravings as soon as tomorrow — make going to bed a priority tonight.';

  @override
  String get consSleepTipUnder6 =>
      'Repeatedly under 6h, the risk of fatigue and cravings increases significantly — gain ground gradually.';

  @override
  String get consSleepTipBorderline =>
      'A \"borderline acceptable\" zone according to sleep experts: just a few more minutes would tip you into the recommended range.';

  @override
  String get consSleepTipRecommended =>
      'You\'re within the recommended range for an adult — the zone most favorable to your recovery.';

  @override
  String get consSleepTipAcceptableLong =>
      'Still an acceptable zone — a natural need to sleep a bit more isn\'t a problem in itself.';

  @override
  String get consSleepTipTooLong =>
      'Beyond 10h on a recurring basis, it\'s worth checking your sleep quality if fatigue persists.';

  @override
  String get consStressTipVeryLow =>
      'Great ground for your overall recovery — take the chance to lock in what\'s working well for you.';

  @override
  String get consStressTipHealthy =>
      'A healthy level. Keep the levers that help you stay in this zone.';

  @override
  String get consStressTipModerate =>
      'Nothing alarming, but a few minutes of slow breathing can help you settle even further.';

  @override
  String get consStressTipHigh =>
      'At this level, the body is running on stress hormones — a breathing break or a walk can really make a difference today.';

  @override
  String get consStressTipVeryHigh =>
      'A level that deserves your priority attention today — start with a calm break before anything else.';

  @override
  String get consSleepPillarTitle => 'Sleep';

  @override
  String get consEveningRitualTitle => 'Evening ritual';

  @override
  String get consSleepBetterSubtitle => 'Sleep better';

  @override
  String get consStressPillarTitle => 'Stress';

  @override
  String get consBreathingTitle => 'Breathing';

  @override
  String get consAntiStressSubtitle => 'Anti-stress';

  @override
  String get consTodayAnalysisTitle => 'Your analysis today';

  @override
  String get consUpdateMyAdviceButton => 'Update my advice';

  @override
  String get consSunVitDCardTitle => 'Sun & vitamin D';

  @override
  String get consSunVitDCardIntro =>
      'A good part of your vitamin D comes from sun exposure, not just diet. Estimate today\'s synthesis to know where you stand.';

  @override
  String get consEstimateMySynthesis => 'Estimate my synthesis';

  @override
  String get breathPhaseInhale => 'Inhale';

  @override
  String get breathPhaseHold => 'Hold';

  @override
  String get breathPhaseExhale => 'Exhale';

  @override
  String get breathPhaseInhaleBelly => 'Inhale (belly)';

  @override
  String get breathPhaseInhaleTopUp => 'Inhale (top-up)';

  @override
  String get breathCoherenceName => 'Cardiac coherence';

  @override
  String get breathCoherenceDesc =>
      'A steady rhythm where inhalation and exhalation last the same time. The classic \"365\": 3 times a day, 6 breaths per minute, for 5 minutes.';

  @override
  String get breathCoherenceBenefit =>
      'The most studied anti-stress technique. It synchronizes the heart and breathing, balances the autonomic nervous system, lowers cortisol and improves heart rate variability — a key marker of health and longevity.';

  @override
  String get breathSquareName => 'Box breathing';

  @override
  String get breathSquareDesc =>
      'Four equal counts: inhale, hold with full lungs, exhale, hold with empty lungs. You mentally trace a square. Used by special forces to stay calm under pressure.';

  @override
  String get breathSquareBenefit =>
      'The two holds strengthen breath control and focus. Ideal for regaining composure before a stressful event, calming the mind and anchoring attention in the present moment.';

  @override
  String get breathWeil478Name => '4-7-8';

  @override
  String get breathWeil478Desc =>
      'Inhale for 4 seconds, hold for 7 seconds, exhale slowly over 8 seconds. Popularized by Dr. Andrew Weil, sometimes nicknamed a \"natural tranquilizer\".';

  @override
  String get breathWeil478Benefit =>
      'The long exhale combined with the hold strongly activates the parasympathetic nervous system — the one responsible for rest and recovery. Particularly effective for winding down before sleep or calming a surge of anxiety.';

  @override
  String get breathDiaphragmaticName => 'Belly breathing';

  @override
  String get breathDiaphragmaticDesc =>
      'The foundation of any breathing practice: expand your belly on the inhale (not your chest), release it on the exhale. No holds, no complex rhythm to remember.';

  @override
  String get breathDiaphragmaticBenefit =>
      'Relearns to fully use the diaphragm instead of short, shallow chest breathing — the foundation all other techniques build on. The most accessible starting point for discovering guided breathing.';

  @override
  String get breathPhysiologicalSighName => 'Physiological sigh';

  @override
  String get breathPhysiologicalSighDesc =>
      'Two short inhales through the nose, one right after the other with no exhale in between, then one long exhale through the mouth. The move the body already does naturally to \"let off steam\".';

  @override
  String get breathPhysiologicalSighBenefit =>
      'The double inhale reopens small collapsed air sacs (alveoli) in the lungs, and the long exhale that follows triggers near-immediate calm. In a comparative study, this technique outperformed box breathing, cyclic hyperventilation AND mindfulness meditation at improving mood.';

  @override
  String get consPhaseDuration => 'Duration of each phase';

  @override
  String get breathCyclicHyperventilationName => 'Cyclic hyperventilation';

  @override
  String get breathCyclicHyperventilationDesc =>
      'A series of 30 deep, rapid breaths, followed by a hold with empty lungs, then a short recovery. The whole sequence is repeated over several \"rounds\", eyes closed from start to finish — no action required during the session.';

  @override
  String get breathCyclicHyperventilationBenefit =>
      'A real energy boost: the rapid phase temporarily raises blood alkalinity, and the hold that follows builds CO2 tolerance and breath control. An intense practice, best reserved for moments when you want an energy boost or want to push your breath-control limits — not a relaxation technique.';

  @override
  String get breathCyclicHyperventilationSafetyWarning =>
      'This technique temporarily lowers blood CO2 levels and can cause dizziness, tingling or, rarely, fainting.\n\nNever practice this:\n• while standing, driving, swimming, or in/near water (documented drowning risk in case of loss of consciousness)\n• during pregnancy\n• if you have epilepsy or a history of seizures\n• if you have cardiovascular conditions\n• if you have a history of fainting or blackouts\n\nAlways practice sitting or lying down, in a safe place. If in medical doubt, ask a healthcare professional before starting.';

  @override
  String get consNumberOfRounds => 'Number of rounds';

  @override
  String get consHoldDurationPerRound => 'Hold duration per round';

  @override
  String get consNoActionDuringSession =>
      'No action needed during the session — set each round in advance based on your experience.';

  @override
  String consRoundLabel(int n) {
    return 'Round $n';
  }

  @override
  String consSessionDurationEstimate(String min) {
    return '≈ $min min session';
  }

  @override
  String get consStartButton => 'Start';

  @override
  String consRoundOf(int round, int total) {
    return 'Round $round / $total';
  }

  @override
  String get consAmpleRapidBreaths => 'Deep, rapid breaths';

  @override
  String get consHoldEmptyLungs => 'Hold, empty lungs';

  @override
  String get consCloseEyesFollowSound =>
      'Close your eyes, let the sound guide you';

  @override
  String get consInhaleAndHoldRecovery => 'Inhale and hold — recovery';

  @override
  String get consSessionComplete => 'Session complete';

  @override
  String consRoundsCompletedNote(int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds completed. Take a moment to feel it.',
      one: '1 round completed. Take a moment to feel it.',
    );
    return '$_temp0';
  }

  @override
  String get consFinishButton => 'Finish';

  @override
  String get consBeforeYouStart => 'Before you start';

  @override
  String get consReadAndUnderstand =>
      'I have read and understand these precautions';

  @override
  String get consContinueButton => 'Continue';

  @override
  String get consAdvancedProtocol => 'Advanced protocol';

  @override
  String get consStopButton => 'Stop';

  @override
  String consCycleOf(int cycle, int total) {
    return 'Cycle $cycle / $total';
  }

  @override
  String get consNumberOfCycles => 'Number of cycles';

  @override
  String get consGuidanceSounds => 'Guidance sounds';

  @override
  String get consStartSessionButton => 'Start the session';

  @override
  String get consSessionCompleteSnackbar =>
      'Session complete. Take a moment to feel it.';

  @override
  String get advFirstLeverTitle => '🎯 First lever: feed your TOTUM';

  @override
  String get advFirstLeverTheme => 'Build your personal data foundation';

  @override
  String get advFirstLeverInsight =>
      'The more meals you log, the more precise, useful and motivating the advice becomes.';

  @override
  String get advNoJournalCritique =>
      'Can\'t detect deficiencies without a journal.';

  @override
  String get advNoJournalBenefit =>
      'You\'re building your food Totem: a clear view of what you give your body.';

  @override
  String get advNoJournalSource =>
      'Log breakfast + your main meal, with detailed quantities and foods.';

  @override
  String get advNoJournalTip =>
      'Start with your \"typical\" meals, we\'ll refine on micronutrients next.';

  @override
  String get advNoJournalChrono =>
      'Without sleep/water/stress logged, the link between how you feel and your habits stays unclear.';

  @override
  String get advNoJournalAction =>
      'Tonight, note your bedtime, its duration, and your stress (1–10). Tomorrow morning: mood/energy.';

  @override
  String get advNoJournalLogTitle => '📝 Activate your holistic tracking';

  @override
  String get advNoJournalDefi24h =>
      '24h challenge: log 2 full meals + sleep, water, stress.';

  @override
  String get advNoJournalQuote => '\"What gets measured gets transformed.\"';

  @override
  String get advNoJournalMacroTitle => '⚙️ Macros pending';

  @override
  String get advNoJournalMacroBody =>
      'As soon as a meal is logged, I can check energy & protein against your goal.';

  @override
  String get advActivityCoachTitle => '🏃‍♂️ Activity & recovery coach';

  @override
  String get advActivityCoachSportif =>
      'Log your workouts + pre/post meals to fine-tune energy & timing.';

  @override
  String get advActivityCoachSedentary =>
      '2–3 slots of 20–30 min/week (brisk walk, easy cycling, light strength work).';

  @override
  String get advDefaultMindsetTitle => '🧠 Progress > perfection';

  @override
  String get advDefaultMindsetBody =>
      'Every aligned meal is a vote for the identity you\'re building.';

  @override
  String get advLogFieldSleep => 'Sleep duration (hours)';

  @override
  String get advLogFieldWater => 'Liters of water (excl. coffee/alcohol)';

  @override
  String get advLogFieldStress => 'Perceived stress (1–10)';

  @override
  String get advDashboardLogTitle => '🧭 Adjust your holistic dashboard';

  @override
  String get advOmega9Critique => 'Omega-9 below the optimal zone.';

  @override
  String get advOmega9Benefit =>
      'Cardio-metabolic support & membrane flexibility.';

  @override
  String get advOmega9Source => 'Olive oil, avocado, almonds/hazelnuts daily.';

  @override
  String get advOmega9Tip => 'Use olive oil raw or for gentle end-of-cooking.';

  @override
  String get advOmega6Critique => 'Omega-6 (LA) a bit low.';

  @override
  String get advOmega6Benefit =>
      'Membrane structure, skin & hormonal pathways.';

  @override
  String get advOmega6Source =>
      'Virgin oils (organic sunflower), assorted nuts/seeds.';

  @override
  String get advOmega6Tip => 'Avoid overheated refined oils.';

  @override
  String get advOmega3AlaCritique => 'Omega-3 ALA insufficient.';

  @override
  String get advOmega3AlaBenefit =>
      'Plant precursor of marine omega-3s EPA/DHA.';

  @override
  String get advOmega3AlaSource =>
      '1 tbsp ground flax/chia per day, or a few walnuts.';

  @override
  String get advOmega3AlaTip => 'Grind flax/chia right before eating.';

  @override
  String get advOmega3Critique => 'Plant omega-3 ALA below target.';

  @override
  String get advOmega3Benefit =>
      'Plant precursor of omega-3, anti-inflammatory.';

  @override
  String get advOmega3Source =>
      'Ground hemp/flax seeds, walnuts, rapeseed oil.';

  @override
  String get advOmega3Tip => 'Grind the seeds right before eating.';

  @override
  String get advOmega3MarineCritique => 'Marine omega-3 below target.';

  @override
  String get advOmega3MarineBenefit =>
      'Mental clarity, recovery, anti-inflammatory.';

  @override
  String get advOmega3MarineSource =>
      'Oily fish 2x/week (sardines/mackerel/herring).';

  @override
  String get advOmega3MarineTip => 'Gentle cooking + good fats.';

  @override
  String get advVitACritique => 'Vitamin A below optimal.';

  @override
  String get advVitABenefit => 'Night vision, skin/mucous membranes, immunity.';

  @override
  String get advVitASource =>
      'Carrot/sweet potato + organ meats/eggs (depending on choice).';

  @override
  String get advVitATip => 'Pair with a bit of fat for conversion.';

  @override
  String get advVitDCritique => 'Vitamin D probably insufficient.';

  @override
  String get advVitDBenefit => 'Immunity, strength, mood, bone health.';

  @override
  String get advVitDSource => 'Sardines/mackerel/whole eggs, morning light.';

  @override
  String get advVitDTip => 'Quality fats in the meal containing vit D.';

  @override
  String get advVitECritique => 'Vitamin E insufficient.';

  @override
  String get advVitEBenefit => 'Antioxidant for cell membranes.';

  @override
  String get advVitESource => 'Virgin oils, almonds, hazelnuts, seeds.';

  @override
  String get advVitETip => 'Use cold or with gentle cooking.';

  @override
  String get advVitKCritique => 'Vitamin K a bit tight.';

  @override
  String get advVitKBenefit => 'Balanced clotting & bone health.';

  @override
  String get advVitKSource => 'Green vegetables + a drizzle of oil.';

  @override
  String get advVitKTip => 'Pair leafy greens with a bit of fat.';

  @override
  String get advVitCCritique => 'Vitamin C below optimal.';

  @override
  String get advVitCBenefit => 'Antioxidant, immunity, iron absorption.';

  @override
  String get advVitCSource => 'Kiwi, citrus, raw bell pepper, parsley.';

  @override
  String get advVitCTip => 'Eat it raw or lightly cooked.';

  @override
  String get advB123Critique => 'B1/B2/B3 a bit below target.';

  @override
  String get advB123Benefit => 'Energy metabolism & nervous system.';

  @override
  String get advB123Source => 'Whole grains, legumes, fish/eggs.';

  @override
  String get advB123Tip =>
      'Cut back on ultra-processed food, low in B vitamins.';

  @override
  String get advB56Critique => 'B5/B6 below target.';

  @override
  String get advB56Benefit => 'Stress, neurotransmitters, amino acids.';

  @override
  String get advB56Source => 'Poultry, banana, chickpeas, eggs, avocado.';

  @override
  String get advB56Tip => 'Spread intake across the day.';

  @override
  String get advB9Critique => 'Folate (B9) insufficient.';

  @override
  String get advB9Benefit => 'Cell renewal & blood quality.';

  @override
  String get advB9Source => 'Leafy greens, legumes, fresh herbs.';

  @override
  String get advB9Tip => 'Have it raw or lightly steamed.';

  @override
  String get advB12Critique => 'Vitamin B12 low.';

  @override
  String get advB12Benefit => 'Nervous system & red blood cells.';

  @override
  String get advB12Source => 'Animal products or fortified foods.';

  @override
  String get advB12Tip =>
      'Strict vegan: discuss supplementation with a professional.';

  @override
  String get advCalciumCritique => 'Calcium below target.';

  @override
  String get advCalciumBenefit => 'Bone strength & cell signaling.';

  @override
  String get advCalciumSource =>
      'Dairy/alternatives, calcium-rich mineral water, tahini.';

  @override
  String get advCalciumTip => 'Spread intake + maintain good vitamin D status.';

  @override
  String get advCopperCritique => 'Copper a bit low.';

  @override
  String get advCopperBenefit => 'Collagen, blood vessels, iron metabolism.';

  @override
  String get advCopperSource => 'Seafood, cocoa, nuts/seeds.';

  @override
  String get advCopperTip => 'Pair with a varied diet.';

  @override
  String get advIronCritique => 'Iron suboptimal.';

  @override
  String get advIronBenefit => 'Muscle oxygenation & energy.';

  @override
  String get advIronSource => 'Legumes/organ meats/red meat + vitamin C.';

  @override
  String get advIronTip => 'Avoid tea/coffee right after iron-rich meals.';

  @override
  String get advIodineCritique => 'Iodine rather low.';

  @override
  String get advIodineBenefit => 'Thyroid → metabolism & body temperature.';

  @override
  String get advIodineSource =>
      'Iodized salt, fish, seafood, seaweed in moderation.';

  @override
  String get advIodineTip =>
      'Avoid excess seaweed if you have a thyroid condition.';

  @override
  String get advMagnesiumCritique => 'Magnesium insufficient.';

  @override
  String get advMagnesiumBenefit => 'Nerve/muscle relaxation, sleep.';

  @override
  String get advMagnesiumSource =>
      'Almonds, dark chocolate, leafy greens, magnesium-rich water.';

  @override
  String get advMagnesiumTip => 'Limit late coffee; pair with B6.';

  @override
  String get advManganeseCritique => 'Manganese low.';

  @override
  String get advManganeseBenefit => 'Antioxidant cofactor.';

  @override
  String get advManganeseSource => 'Whole grains, nuts, green tea (moderate).';

  @override
  String get advManganeseTip => 'Limit refined foods low in trace elements.';

  @override
  String get advPhosphorusCritique => 'Phosphorus slightly low.';

  @override
  String get advPhosphorusBenefit => 'Bone/teeth structure & energy.';

  @override
  String get advPhosphorusSource => 'Fish, eggs, nuts and seeds.';

  @override
  String get advPhosphorusTip => 'Avoid sodas with added phosphates.';

  @override
  String get advPotassiumCritique => 'Potassium insufficient.';

  @override
  String get advPotassiumBenefit =>
      'Blood pressure balance, muscle contraction.';

  @override
  String get advPotassiumSource =>
      'Banana, avocado, greens, sweet potato, legumes.';

  @override
  String get advPotassiumTip =>
      'A raw/steamed portion helps preserve minerals.';

  @override
  String get advSeleniumCritique => 'Selenium a bit tight.';

  @override
  String get advSeleniumBenefit => 'Key antioxidant + thyroid support.';

  @override
  String get advSeleniumSource => 'Fish, seafood, eggs (better absorbed).';

  @override
  String get advSeleniumTip => 'Avoid prolonged excess.';

  @override
  String get advSodiumCritique => 'Sodium a bit low vs needs.';

  @override
  String get advSodiumBenefit => 'Fluid balance, nerve conduction.';

  @override
  String get advSodiumSource =>
      'Quality salt on whole foods if sweating a lot.';

  @override
  String get advSodiumTip => 'Avoid heavily salted processed foods.';

  @override
  String get advZincCritique => 'Zinc possibly insufficient.';

  @override
  String get advZincBenefit => 'Immunity, skin, hormones.';

  @override
  String get advZincSource => 'Seafood, beef, pumpkin seeds.';

  @override
  String get advZincTip => 'Limit excess sugar.';

  @override
  String get advFibersCritique => 'Fiber below 30 g/day.';

  @override
  String get advFibersBenefit => 'Microbiome, satiety, blood sugar.';

  @override
  String get advFibersSource =>
      '+ Legumes, vegetables at every meal, whole fruit.';

  @override
  String get advFibersTip => 'Increase gradually + drink enough water.';

  @override
  String get advDefaultCritique => 'One or more micronutrients below target.';

  @override
  String get advDefaultBenefit => 'More micro density = better energy & sleep.';

  @override
  String get advDefaultSource => 'Varied whole foods, fish & eggs.';

  @override
  String get advDefaultTip => 'A colorful plate = a wider micro spectrum.';

  @override
  String get advMoveTodayDefault => 'Move a little today 😉';

  @override
  String get advPackLowSleepHighStress1 =>
      '1️⃣ 20–30 min outside (natural light) + 5 min of slow nasal breathing at the end of the day.';

  @override
  String get advPackLowSleepHighStress2 =>
      '2️⃣ Digital curfew 45–60 min before bed + light reading or a gratitude journal (3 points).';

  @override
  String get advPackLowSleepHighStress3 =>
      '3️⃣ Earlier, lighter, low-sugar dinner, then a warm shower and 4–6 breathing for 3–5 min.';

  @override
  String get advPackLowSleepHighStress4 =>
      '4️⃣ If ruminating: write down everything looping in your head on paper before bed.';

  @override
  String get advPackLowSleep1 =>
      '1️⃣ Set a realistic target bedtime (even on weekends) and stick to it for 3 nights in a row.';

  @override
  String get advPackLowSleep2 =>
      '2️⃣ Move your last coffee/black tea to no later than 2–3 pm.';

  @override
  String get advPackLowSleep3 =>
      '3️⃣ Create a short 10–15 min \"wind-down\" ritual (gentle stretching + dim lighting).';

  @override
  String get advPackLowSleep4 =>
      '4️⃣ Bedroom: cool, very dark, quiet or light white noise.';

  @override
  String get advPackHighStress1 =>
      '1️⃣ Micro-breaks: 2–3 min every 60–90 min (calm breathing + a few steps).';

  @override
  String get advPackHighStress2 =>
      '2️⃣ 5 slow breaths before each meal to bring the nervous system down.';

  @override
  String get advPackHighStress3 =>
      '3️⃣ A 10–15 min walk outside without your phone, focusing attention on your breathing.';

  @override
  String get advPackHighStress4 =>
      '4️⃣ In the evening: write down 3 things that went well today, even small ones.';

  @override
  String get advPackHighStressHydration =>
      'Hydration a bit low: spreading water through the day also helps mental clarity.';

  @override
  String get advPackStable1 =>
      '1️⃣ Keep your bed/wake rhythm, even on weekends (±1 h max).';

  @override
  String get advPackStable2 =>
      '2️⃣ Add an 8–12 min slow walk after a meal for digestion + blood sugar.';

  @override
  String get advPackStable3 =>
      '3️⃣ Plan one 15–20 min \"screen-off\" moment in the day (reading, music, nature).';

  @override
  String get advPackStable4 =>
      '4️⃣ Add one extra portion of leafy greens to support micronutrition & recovery.';

  @override
  String advChronoLowSleepHighStress(String hours, int stress) {
    return 'Short sleep (~$hours h) + high stress ($stress/10). The nervous system is drawing heavily on reserves.';
  }

  @override
  String advChronoLowSleep(String hours) {
    return 'Sleep time a bit short (~$hours h). Stacking up shortened nights ends up affecting energy and mood.';
  }

  @override
  String advChronoHighStress(String hours, int stress) {
    return 'Decent sleep (~$hours h) but high stress ($stress/10). The mind is racing.';
  }

  @override
  String advChronoStable(String hours, int stress) {
    return 'Sleep and stress levels fairly stable (≈$hours h, stress $stress/10). Time for some vitality fine-tuning.';
  }

  @override
  String get advChronoIncomplete =>
      'Log your sleep and stress level for personalized wellbeing advice, tailored to how you\'re doing right now.';

  @override
  String get advActionIncomplete =>
      'For 3 days, note each morning your sleep hours, your stress level (1–10) and your energy on waking. TOTUM will progressively fine-tune the levers suggested for you.';

  @override
  String get advMacroLossTitle => '⚖️ Smart weight loss';

  @override
  String advMacroLossHigh(String pct) {
    return 'Intake ~$pct: aim for a light, sustainable deficit (-10 to -20%).';
  }

  @override
  String advMacroLossLow(String pct) {
    return 'Intake ~$pct: if fatigue/cravings, bring it back up with whole foods.';
  }

  @override
  String advMacroLossOk(String pct) {
    return 'Energy ~$pct: consistent trajectory. Quality & fiber are the priority.';
  }

  @override
  String advMacroProteinLow(String pct) {
    return ' • Protein ~$pct: one source at every meal.';
  }

  @override
  String advMacroProteinHighSportif(String pct) {
    return ' • Generous protein ~$pct: spread over 3–4 servings.';
  }

  @override
  String get advMacroGainTitle => '🏗️ Muscle building';

  @override
  String advMacroGainLow(String pct) {
    return 'Calories ~$pct: a +10–15% surplus is recommended.';
  }

  @override
  String advMacroGainHigh(String pct) {
    return 'Surplus ~$pct: bring it back to +10–15% to limit fat gain.';
  }

  @override
  String advMacroGainOk(String pct) {
    return 'Level ~$pct: OK. Carb timing around sessions is key.';
  }

  @override
  String advMacroGainProteinLow(String pct) {
    return ' • Protein ~$pct: 1.6–2.2 g/kg/day over 3–4 meals.';
  }

  @override
  String advMacroGainProteinOk(String pct) {
    return ' • Protein coverage ~$pct.';
  }

  @override
  String get advMacroMaintainTitle => '⚙️ Maintaining your fit weight';

  @override
  String advMacroMaintainLow(String pct) {
    return 'Energy ~$pct: a bit low. Bring it up slightly if you feel fatigue.';
  }

  @override
  String advMacroMaintainHigh(String pct) {
    return 'Energy ~$pct: a bit high. Adjust extras & drinks.';
  }

  @override
  String advMacroMaintainOk(String pct) {
    return 'Energy ~$pct: aligned. Focus on quality for digestion/sleep.';
  }

  @override
  String advMacroMaintainProteinLow(String pct) {
    return ' • Protein ~$pct: keep a sufficient base.';
  }

  @override
  String advDefiHydration(String liters) {
    return 'Reach $liters L today, spread across the day.';
  }

  @override
  String get advQuoteHydration =>
      '\"A well-hydrated cell works silently for your longevity.\"';

  @override
  String get advDefiEfas =>
      'Add a real source of EFAs (oily fish or ground flax/chia + rapeseed/olive oil).';

  @override
  String get advQuoteEfas =>
      '\"Quality fats are the raw material of your brain.\"';

  @override
  String get advDefiLiposoluble =>
      '1 fat-soluble source + 10–15 min of morning light.';

  @override
  String get advQuoteLiposoluble =>
      '\"Light + fat-soluble vitamins = metabolic orchestration.\"';

  @override
  String get advDefiBVitamins =>
      'A very colorful meal + a good protein source.';

  @override
  String get advQuoteBVitamins =>
      '\"Your energy is both information code and fuel.\"';

  @override
  String get advDefiFibers =>
      '1 extra portion of vegetables + 1 portion of legumes.';

  @override
  String get advQuoteFibers => '\"Your microbiome feeds on your habits.\"';

  @override
  String get advDefiDefault =>
      'Pick an action from the Lab and apply it today.';

  @override
  String get advQuoteDefault =>
      '\"Micronutrients: the source code of your vitality.\"';

  @override
  String get coachNoData =>
      'Log your meals and I\'ll show you at a glance where you stand and what to adjust.';

  @override
  String coachEtatGoodStart(int s) {
    return 'Good start: $s/100 for what you\'ve eaten so far.';
  }

  @override
  String coachEtatStarting(int s) {
    return 'Day just starting: $s/100 for now, everything\'s still to build.';
  }

  @override
  String coachEtatExcellent(int s) {
    return 'Excellent day: $s/100. This is the level that builds your long-term health.';
  }

  @override
  String coachEtatGood(int s) {
    return 'Good day: $s/100, with a bit more room to grow.';
  }

  @override
  String coachEtatOk(int s) {
    return 'Decent day: $s/100. One targeted move and you level up.';
  }

  @override
  String coachEtatToRebalance(int s) {
    return 'Day to rebalance: $s/100. Nothing serious, one good meal turns the trend around.';
  }

  @override
  String coachProgressUp(int diff) {
    return ' Up $diff points vs your last full day 📈.';
  }

  @override
  String coachProgressDown(int diff) {
    return ' Down $diff points vs your last full day.';
  }

  @override
  String coachActionSleepCritical(String hours) {
    return ' Your priority today isn\'t on your plate: you only slept $hours h. Cravings will hit harder — lean on whole, filling foods, and aim for a longer night tonight.';
  }

  @override
  String coachActionStressHigh(int stress) {
    return ' Your stress is at $stress/10: that\'s the priority to work on. Take 5 slow breaths before each meal — it calms the mind and helps digestion.';
  }

  @override
  String coachActionDeficitMajorWithFix(String label, int pct, String fix) {
    return ' Top priority to fix: $label ($pct% of your target). Quick fix: $fix.';
  }

  @override
  String coachActionDeficitMajor(String label, int pct) {
    return ' Top priority to fix: $label ($pct% of your target).';
  }

  @override
  String coachActionSleepMedium(String hours) {
    return ' Your night was a bit short ($hours h): favor filling foods today and ease up on stimulants.';
  }

  @override
  String coachActionStressNotable(int stress) {
    return ' Your stress ($stress/10) deserves a bit of attention: a few slow breaths during the day will do you good.';
  }

  @override
  String coachActionDeficitMinorWithFix(String label, int pct, String fix) {
    return ' Small improvement point: $label ($pct% of your target). Think about $fix.';
  }

  @override
  String coachActionDeficitMinor(String label, int pct) {
    return ' Small improvement point: $label ($pct% of your target).';
  }

  @override
  String get coachActionNoneEvening =>
      ' Nothing urgent to fix: let the night do its recovery work.';

  @override
  String get coachActionNoneLoss =>
      ' Nothing to fix: stick with the protein + vegetables combo at every meal, it\'s what keeps you full.';

  @override
  String get coachActionNoneGain =>
      ' Nothing to fix: remember to spread your protein through the day to properly feed your muscle.';

  @override
  String get coachActionNoneMaintain =>
      ' Nothing to fix: keep it up with whole foods and variety, consistency is what pays off.';

  @override
  String get quickFixIron =>
      'lentils or a bit of blood sausage, with a squeeze of lemon for absorption';

  @override
  String get quickFixMagnesium =>
      'a handful of almonds or a square of dark chocolate';

  @override
  String get quickFixCalcium => 'sardines, a yogurt or a handful of almonds';

  @override
  String get quickFixZinc => 'pumpkin seeds, beef or oysters';

  @override
  String get quickFixIodine => 'fish, seafood or an egg';

  @override
  String get quickFixSelenium => 'a sardine, an egg or seafood';

  @override
  String get quickFixPotassium => 'an avocado, a sweet potato or legumes';

  @override
  String get quickFixVitC => 'a kiwi, a red pepper or a few strawberries';

  @override
  String get quickFixVitD =>
      'an oily fish (sardine, mackerel) and a bit of sunshine';

  @override
  String get quickFixVitE => 'almonds, hazelnuts or a drizzle of virgin oil';

  @override
  String get quickFixVitA => 'a carrot, sweet potato or an egg yolk';

  @override
  String get quickFixVitK =>
      'leafy greens (spinach, cabbage) or a bit of aged cheese';

  @override
  String get quickFixB9 => 'leafy greens or legumes';

  @override
  String get quickFixB12 => 'eggs, fish or meat';

  @override
  String get quickFixB6 => 'poultry, a banana or chickpeas';

  @override
  String get quickFixOmega3 => 'ground hemp or flax seeds, or walnuts';

  @override
  String get quickFixOmega3Marine => 'sardines, mackerel or herring';

  @override
  String get quickFixCopper => 'nuts, dark chocolate or seafood';

  @override
  String get quickFixManganese => 'whole grains, nuts or tea';

  @override
  String get quickFixPhosphorus => 'eggs, fish or legumes';

  @override
  String get quickFixFibers => 'legumes, a whole fruit or vegetables';

  @override
  String get dietFixMarineOmega3 =>
      'an algae-based omega-3 supplement (plant source of EPA/DHA)';

  @override
  String get dietFixB12Vegan =>
      'a vitamin B12 supplement (essential on a vegan diet)';

  @override
  String get sleepRitualTitle => 'Evening Ritual';

  @override
  String get sleepRitualIntro =>
      'Good sleep isn\'t luck, it\'s the result of good habits. Here are the levers that actually matter — check off the ones you put in place.';

  @override
  String get sleepRitualLeversHeading => 'The 6 levers of your sleep';

  @override
  String get sleepRitualLeversSubtitle =>
      'Tap a lever to see the actions and check off the ones you\'re putting in place.';

  @override
  String get sleepPillarLightTitle => 'Light';

  @override
  String get sleepPillarLightIntro =>
      'Light is the main regulator of your biological clock. Managed well, it naturally sets your sleep schedule.';

  @override
  String get sleepActionLightWakeTitle => 'Get daylight as soon as you wake up';

  @override
  String get sleepActionLightWakeWhy =>
      '10 to 30 minutes of natural light in the morning sets your internal clock and triggers, 14 to 16 h later, the evening release of melatonin. It\'s the single most powerful move for good sleep — and it happens in the morning.';

  @override
  String get sleepActionLightDimTitle => 'Dim the lights 1 to 2 h before bed';

  @override
  String get sleepActionLightDimWhy =>
      'Bright light in the evening tricks your brain into thinking it\'s still daytime and blocks melatonin. Switch to dim, warm, indirect lighting.';

  @override
  String get sleepActionLightScreensTitle => 'Cut screens or filter blue light';

  @override
  String get sleepActionLightScreensWhy =>
      'Blue light from screens suppresses melatonin the most. Night mode, blue-light-blocking glasses, or better yet: put the screen down.';

  @override
  String get sleepActionLightDarkTitle => 'Sleep in total darkness';

  @override
  String get sleepActionLightDarkWhy =>
      'Even a small light source, like a night-light or a charger LED, perceived through closed eyelids, reduces deep-sleep quality. Blackout curtains or a sleep mask.';

  @override
  String get sleepPillarTempTitle => 'Temperature';

  @override
  String get sleepPillarTempIntro =>
      'Falling asleep requires your body temperature to drop by about 1 °C. Anything that helps this cooling helps you sleep.';

  @override
  String get sleepActionTempRoomTitle => 'Keep your room around 18 °C';

  @override
  String get sleepActionTempRoomWhy =>
      'A cool room makes it easier for your body temperature to drop, which is needed to fall asleep. Too warm, and it\'s one of the most common causes of nighttime waking.';

  @override
  String get sleepActionTempShowerTitle =>
      'Take a warm shower 1 to 2 h before bed';

  @override
  String get sleepActionTempShowerWhy =>
      'Paradoxically, a warm shower dilates blood vessels and helps your body release heat afterward: your temperature drops faster, and sleep follows.';

  @override
  String get sleepActionTempExtremitiesTitle => 'Keep your extremities warm';

  @override
  String get sleepActionTempExtremitiesWhy =>
      'Cold feet constrict blood vessels and prevent your body from releasing core heat. Socks can, counterintuitively, help you fall asleep faster.';

  @override
  String get sleepPillarFoodTitle => 'Stimulants & food';

  @override
  String get sleepPillarFoodIntro =>
      'What you consume in the second half of the day weighs heavily on your night.';

  @override
  String get sleepActionFoodCaffeineTitle =>
      'Last caffeine 6 to 8 h before bed';

  @override
  String get sleepActionFoodCaffeineWhy =>
      'Caffeine blocks adenosine, the molecule that makes you sleepy, for 6 h or more. A mid-afternoon coffee cuts into deep sleep even without stopping you from falling asleep. Also watch tea, mate, and dark chocolate.';

  @override
  String get sleepActionFoodDinnerTitle =>
      'Eat a light dinner, early, 3 h before bed';

  @override
  String get sleepActionFoodDinnerWhy =>
      'Ongoing digestion raises body temperature and keeps the body busy, the opposite of what sleep needs. A light, early dinner clearly improves the depth of your night.';

  @override
  String get sleepActionFoodLiquidsTitle => 'Ease up on liquids in the evening';

  @override
  String get sleepActionFoodLiquidsWhy =>
      'Drinking too much right before bed multiplies bathroom trips at night, which fragment your sleep cycles. Hydrate mostly during the day.';

  @override
  String get sleepActionFoodChoicesTitle => 'Favor sleep-friendly foods';

  @override
  String get sleepActionFoodChoicesWhy =>
      'Some whole foods provide tryptophan, magnesium and glycine, precursors of melatonin and serotonin: almonds, walnuts, banana, oats, kiwi, oily fish.';

  @override
  String get sleepPillarMentalTitle => 'Mind & stress';

  @override
  String get sleepPillarMentalIntro =>
      'A restless mind is cause No.1 of trouble falling asleep. Calming it is a practice.';

  @override
  String get sleepActionMentalDumpTitle => 'Do a mental brain dump';

  @override
  String get sleepActionMentalDumpWhy =>
      'Write down what\'s on your mind and tomorrow\'s tasks. Getting thoughts out of your head and onto paper reduces the rumination that loops at bedtime.';

  @override
  String get sleepActionMentalCoherenceTitle =>
      'Practice a few minutes of coherent breathing';

  @override
  String get sleepActionMentalCoherenceWhy =>
      'Slowing your breath activates the parasympathetic system, the one in charge of rest. A few slow breathing cycles physiologically prepare the body for sleep.';

  @override
  String get sleepActionMentalGratitudeTitle => 'End with three gratitudes';

  @override
  String get sleepActionMentalGratitudeWhy =>
      'Thinking back on three positive moments from the day steers the mind toward calm rather than anxiety, and eases a peaceful drift to sleep.';

  @override
  String get sleepActionMentalAvoidTitle =>
      'Avoid anxiety-inducing content in the evening';

  @override
  String get sleepActionMentalAvoidWhy =>
      'News, work emails, and online debates activate your vigilance system right before sleep. Save the evening for what soothes you.';

  @override
  String get sleepPillarRhythmTitle => 'Rhythm & regularity';

  @override
  String get sleepPillarRhythmIntro =>
      'Sleep loves regularity above all else. A steady rhythm beats a long catch-up lie-in.';

  @override
  String get sleepActionRhythmScheduleTitle =>
      'Go to bed and wake up at consistent times';

  @override
  String get sleepActionRhythmScheduleWhy =>
      'Consistent hours, even on weekends, reinforce your biological clock. Regularity, more than duration alone, determines sleep quality.';

  @override
  String get sleepActionRhythmCyclesTitle => 'Respect your 90-minute cycles';

  @override
  String get sleepActionRhythmCyclesWhy =>
      'Sleep unfolds in cycles of about 90 min. Waking at the end of a cycle, rather than in deep sleep, makes waking up far easier.';

  @override
  String get sleepActionRhythmSignsTitle => 'Go to bed at the first signs';

  @override
  String get sleepActionRhythmSignsWhy =>
      'Yawning, heavy eyelids, itchy eyes: that\'s your sleep train passing by. Miss it, and you wait for the next cycle 90 min later.';

  @override
  String get sleepActionRhythmNapsTitle => 'Manage your naps';

  @override
  String get sleepActionRhythmNapsWhy =>
      'A 10 to 20 min nap in early afternoon recovers energy without cutting into your night. Too long or too late, and it sabotages your evening sleep onset.';

  @override
  String get sleepPillarEnvTitle => 'Environment';

  @override
  String get sleepPillarEnvIntro =>
      'Your bedroom should become a sanctuary your brain associates only with rest.';

  @override
  String get sleepActionEnvBedTitle => 'Reserve the bed for sleep';

  @override
  String get sleepActionEnvBedWhy =>
      'Working, eating or scrolling in bed blurs the mental association bed = sleep. Your brain needs to learn that getting into bed means sleeping.';

  @override
  String get sleepActionEnvNoiseTitle => 'Eliminate noise';

  @override
  String get sleepActionEnvNoiseWhy =>
      'Even without waking you, noise disrupts sleep depth. Earplugs or steady white noise can mask unpredictable disturbances.';

  @override
  String get sleepActionEnvBeddingTitle => 'Take care of your bedding';

  @override
  String get sleepActionEnvBeddingWhy =>
      'A suitable mattress and pillow prevent micro-awakenings caused by discomfort. You spend a third of your life in it: it\'s a health investment.';

  @override
  String hintOmega9(String pct) {
    return 'Omega-9: $pct → olive oil, avocado, almonds/hazelnuts.';
  }

  @override
  String hintOmega6(String pct) {
    return 'Omega-6 (LA): $pct → virgin oils, walnuts, seeds.';
  }

  @override
  String hintOmega3Ala(String pct) {
    return 'Omega-3 ALA: $pct → ground flax/chia, walnuts, rapeseed oil.';
  }

  @override
  String hintOmega3(String pct) {
    return 'Omega-3 EPA/DHA: $pct → sardines, mackerel, herring.';
  }

  @override
  String hintEpa(String pct) {
    return 'EPA: $pct → 1–2 servings oily fish/week.';
  }

  @override
  String hintDha(String pct) {
    return 'DHA: $pct → sardines, mackerel, fortified eggs.';
  }

  @override
  String hintVitA(String pct) {
    return 'Vit A: $pct → carrot/sweet potato + eggs/offal.';
  }

  @override
  String hintVitD(String pct) {
    return 'Vit D: $pct → morning light + sardines/eggs.';
  }

  @override
  String hintVitE(String pct) {
    return 'Vit E: $pct → virgin oils, almonds/hazelnuts.';
  }

  @override
  String hintVitK(String pct) {
    return 'Vit K: $pct → greens + a bit of oil.';
  }

  @override
  String hintVitC(String pct) {
    return 'Vit C: $pct → kiwi, citrus, raw pepper, parsley.';
  }

  @override
  String hintB1(String pct) {
    return 'B1: $pct → whole grains, legumes, pork.';
  }

  @override
  String hintB2(String pct) {
    return 'B2: $pct → milk, eggs, almonds, mushrooms.';
  }

  @override
  String hintB3(String pct) {
    return 'B3: $pct → poultry, fish, peanuts.';
  }

  @override
  String hintB5(String pct) {
    return 'B5: $pct → offal, mushrooms, avocado.';
  }

  @override
  String hintB6(String pct) {
    return 'B6: $pct → banana, chickpeas, poultry.';
  }

  @override
  String hintB9(String pct) {
    return 'B9: $pct → leafy greens, legumes.';
  }

  @override
  String hintB12(String pct) {
    return 'B12: $pct → animal products / fortified foods.';
  }

  @override
  String hintCalcium(String pct) {
    return 'Calcium: $pct → dairy/alternatives, calcium-rich water, tahini.';
  }

  @override
  String hintCopper(String pct) {
    return 'Copper: $pct → seafood, cocoa, nuts/seeds.';
  }

  @override
  String hintIron(String pct) {
    return 'Iron: $pct → legumes/offal + vitamin C.';
  }

  @override
  String hintIodine(String pct) {
    return 'Iodine: $pct → fish, seafood, iodized salt.';
  }

  @override
  String hintMagnesium(String pct) {
    return 'Magnesium: $pct → almonds, dark chocolate, greens.';
  }

  @override
  String hintManganese(String pct) {
    return 'Manganese: $pct → whole grains, nuts, green tea.';
  }

  @override
  String hintPhosphorus(String pct) {
    return 'Phosphorus: $pct → fish, eggs, nuts.';
  }

  @override
  String hintPotassium(String pct) {
    return 'Potassium: $pct → banana, avocado, greens, sweet potato.';
  }

  @override
  String hintSelenium(String pct) {
    return 'Selenium: $pct → fish, seafood, eggs.';
  }

  @override
  String hintSodium(String pct) {
    return 'Sodium: $pct → quality salt if sweating a lot.';
  }

  @override
  String hintZinc(String pct) {
    return 'Zinc: $pct → seafood, beef, pumpkin seeds.';
  }

  @override
  String hintFibers(String pct) {
    return 'Fiber: $pct → +vegetables, legumes, whole fruit.';
  }

  @override
  String hintDefault(String pct) {
    return 'Micros: $pct → colorful, whole-food plate.';
  }

  @override
  String get breathGoalApaiserLabel => 'Soothe';

  @override
  String get breathGoalApaiserSubtitle => 'Calm the mind, bring stress down';

  @override
  String get breathGoalRenforcerLabel => 'Strengthen';

  @override
  String get breathGoalRenforcerSubtitle =>
      'Boost energy, build breath control';

  @override
  String get breathGoalEquilibrerLabel => 'Balance';

  @override
  String get breathGoalEquilibrerSubtitle =>
      'Steady rhythm, balanced nervous system';

  @override
  String get breathGoalDebuterLabel => 'Start out';

  @override
  String get breathGoalDebuterSubtitle =>
      'The basics, gently, to find your footing';

  @override
  String get breathScreenTitle => 'Breathing';

  @override
  String get breathGoalPickerTitle => 'What are you looking for today?';

  @override
  String breathWeekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions this week',
      one: '$count session this week',
    );
    return '$_temp0';
  }

  @override
  String get breathSeeAllTechniques => 'See all techniques';

  @override
  String get consDuJourTitle => 'Your tips for today';

  @override
  String get consDuJourIntro =>
      'Your personalized tips, chosen based on your day and your goals.';

  @override
  String get consDuJourDisclaimer =>
      'These tips do not replace medical advice. If you have a condition or any doubt, consult your healthcare professional.';

  @override
  String get consChallengeOfTheDay => 'Your challenge of the day';

  @override
  String get consNoRecipeMatchesFilters =>
      'No recipe matches these filters for now.';

  @override
  String get fallbackMindset1Title => '🧠 Progress > perfection';

  @override
  String get fallbackMindset1Body =>
      'Every meal aligned with your goal is a vote for the identity you\'re building.';

  @override
  String get fallbackMindset2Title => '💪 Antifragile consistency';

  @override
  String get fallbackMindset2Body =>
      'Slip-ups don\'t define you. It\'s the weekly average that counts.';

  @override
  String get fallbackCoachSedentaire1 => '2–3x/week 20–30 min…';

  @override
  String get fallbackCoachSedentaire2 => '6–8k steps/day…';

  @override
  String get fallbackCoachPerte1 => 'Slight deficit + protein…';

  @override
  String get fallbackCoachMasse1 => 'Surplus +10–15%, protein 1.6–2.2 g/kg…';

  @override
  String get fallbackCoachMaintien1 => '3–4 varied sessions/week…';

  @override
  String get fallbackHeroHydrationTitle => '💧 Hydration: your silent boost';

  @override
  String get fallbackHeroHydrationTheme => 'Mental clarity';

  @override
  String get fallbackHeroHydrationInsight =>
      'Spread your water intake + herbal tea in the evening.';

  @override
  String get fallbackHeroOmega3Title => '🐟 Omega-3: brain & membranes';

  @override
  String get fallbackHeroOmega3Theme => 'Inflammation & mood';

  @override
  String get fallbackHeroOmega3Insight => '2 oily fish/week.';

  @override
  String get fallbackHeroFibersTitle => '🌱 Fiber: microbiome';

  @override
  String get fallbackHeroFibersTheme => 'Satiety';

  @override
  String get fallbackHeroFibersInsight => 'Legumes + vegetables + whole fruit.';

  @override
  String get fallbackHeroGenericTitle => 'Tip of the day';

  @override
  String get fallbackHeroGenericTheme => 'Vitality';

  @override
  String get fallbackHeroGenericInsight => 'Vary your colorful whole foods.';

  @override
  String get fallbackRecipeOmega3Bowl => 'Sardine-lemon-avocado bowl';

  @override
  String get fallbackRecipeOmega3Salad => 'Mackerel salad + lentils';

  @override
  String get fallbackRecipeFibersBowl =>
      'Buddha bowl with legumes + whole grain';

  @override
  String jrnlOverBy(String excess, String unit) {
    return 'exceeded by $excess $unit';
  }

  @override
  String jrnlRemainingBy(String remaining, String unit) {
    return '$remaining $unit left';
  }

  @override
  String get jrnlQtyLabel => 'Quantity (g)';

  @override
  String get jrnlMealDropdownLabel => 'Meal';

  @override
  String get jrnlGlucidesDetailButton => 'Carb breakdown';

  @override
  String get jrnlCompositionFor100g => 'Composition per 100 g';

  @override
  String jrnlCompositionForGrams(String grams) {
    return 'Composition (for $grams g)';
  }

  @override
  String get jrnlSearchingProduct => 'Looking up the product...';

  @override
  String get jrnlProductNotFoundTitle => 'Product not found';

  @override
  String get jrnlProductNotFoundBody =>
      'This product wasn\'t found in the Open Food Facts database.\n\nTips:\n• Check that all the barcode digits are clearly visible\n• Make sure there\'s good lighting for the scan\n• Try scanning again while holding the device steady\n\nTry again with better scanning conditions.';

  @override
  String get jrnlScannedProductFallback => 'Scanned product';

  @override
  String get jrnlTechnicalErrorTitle => 'Technical error';

  @override
  String jrnlScanErrorBody(String error) {
    return 'An error occurred: $error\n\nTry scanning again.';
  }

  @override
  String get jrnlAddToJournal => 'Add to journal';

  @override
  String jrnlAddQuoted(String name) {
    return 'Add \"$name\"';
  }

  @override
  String jrnlItemsAndKcal(int count, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · $kcal kcal';
  }

  @override
  String get jrnlTowardDay => 'To day';

  @override
  String get jrnlTowardMeal => 'To meal';

  @override
  String get jrnlRestaurantsInfoTitle =>
      'Restaurants: an occasional detour, not a staple';

  @override
  String get jrnlRestaurantsInfoP1 =>
      'These chains come from the USDA database (Foundation Foods/SR Legacy) and are mostly North American fast-food and family-dining chains — recipes and portions reflect the U.S. market.';

  @override
  String get jrnlRestaurantsInfoP2 =>
      'An average fast-food chain meal provides about 1200 kcal and 2100 mg of sodium in a single meal — well above the guidelines for one meal (roughly 700 kcal, under 770 mg of sodium).';

  @override
  String get jrnlRestaurantsInfoP3 =>
      'The U.S. Dietary Guidelines Advisory Committee places a reasonable share of \"discretionary\" calories at 5 to 15% of weekly intake for most adults. In practice, that\'s roughly 1 to 2 meals of this type per week — a single one can already represent most of that budget.';

  @override
  String get jrnlRestaurantsInfoP4 =>
      'Beyond 3 meals of this type per week, the evidence broadly agrees that this drifts noticeably away from an eating pattern oriented toward health, longevity, vitality and performance. For a gentler detour, \"healthy\"/fast-casual chains (composed salads, bowls, poke...) remain an alternative worth considering.';

  @override
  String get jrnlUnderstood => 'Got it';

  @override
  String get jrnlAboutBrandTitle => 'About this brand';

  @override
  String get jrnlAboutBrandBody =>
      'This brand comes from the USDA database (Foundation Foods/SR Legacy) — it\'s mostly sourced from the U.S. market, so its recipes and portions reflect products sold in the United States, not necessarily their French equivalent.';

  @override
  String get jrnlInformationsButton => 'Information';

  @override
  String get jrnlSearchBrand => 'Search a brand';

  @override
  String jrnlSearchWithinBrand(String name) {
    return 'Search within $name';
  }

  @override
  String get jrnlNoChainFound => 'No brand found';

  @override
  String get jrnlLoadingEllipsis => 'Loading...';

  @override
  String get jrnlNoResults => 'No results';

  @override
  String get jrnlCalorieValueUnknown => 'Calorie value not provided';

  @override
  String jrnlKcalPer100g(String kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get jrnlGenericFoodFallback => 'Food';

  @override
  String get jrnlRemoveFavorite => 'Remove from favorites';

  @override
  String get jrnlAddFavorite => 'Add to favorites';

  @override
  String jrnlItemCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String jrnlItemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
    );
    return '$_temp0';
  }

  @override
  String jrnlItemsCopiedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items copied',
      one: '1 item copied',
    );
    return '$_temp0 to $meal';
  }

  @override
  String jrnlItemsAddedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added',
      one: '1 item added',
    );
    return '$_temp0 to $meal (100 g by default, adjustable after)';
  }

  @override
  String jrnlAddedTo(String name, String meal) {
    return '\"$name\" added to $meal';
  }

  @override
  String get jrnlCustomFoodEditTitle => 'Edit a personal food';

  @override
  String get jrnlCustomFoodAddTitle => 'Add a personal food';

  @override
  String get jrnlMicronutrientsOptional => 'Micronutrients (optional)';

  @override
  String get jrnlEditRecipeTitle => 'Edit recipe';

  @override
  String get jrnlNewRecipeTitle => 'New recipe';

  @override
  String get jrnlRecipeNameField => 'Recipe name *';

  @override
  String get jrnlDescOptionalField => 'Description (optional)';

  @override
  String get jrnlRecipeTotalWeightField =>
      'Total weight of the finished recipe (g)';

  @override
  String get jrnlMacrosCalculatedFor100g =>
      'Macros will be calculated per 100g of recipe';

  @override
  String get jrnlValuesPer100gRecipe => 'Values per 100g of recipe';

  @override
  String get jrnlIngredientsTitle => 'Ingredients';

  @override
  String get jrnlSearchFoodToAdd => 'Search a food to add';

  @override
  String get jrnlNoIngredientAdded => 'No ingredient added.';

  @override
  String get jrnlEditQuantityTooltip => 'Edit quantity';

  @override
  String get jrnlRemoveTooltip => 'Remove';

  @override
  String jrnlKcalSlash100g(String kcal) {
    return '$kcal kcal/100g';
  }

  @override
  String get jrnlRecipeNameRequired => 'Give your recipe a name!';

  @override
  String get jrnlIngredientRequired => 'Add at least one ingredient.';

  @override
  String get jrnlEditMealTitle => 'Edit personal meal';

  @override
  String get jrnlNewMealTitle => 'New personal meal';

  @override
  String get jrnlMealNameField => 'Meal name *';

  @override
  String get jrnlMealTotalTitle => 'Meal total';

  @override
  String get jrnlFoodsTitle => 'Foods';

  @override
  String get jrnlMealNameRequired => 'Give this meal a name!';

  @override
  String get jrnlFoodRequired => 'Add at least one food.';

  @override
  String jrnlGramsAndKcal(String grams, String kcal) {
    return '$grams g · $kcal kcal';
  }

  @override
  String get jrnlNoFoodAdded => 'No food added.';

  @override
  String get jrnlChooseMeal => 'Choose the meal';

  @override
  String get jrnlCiqualVsUsdaTitle => 'CIQUAL vs USDA';

  @override
  String get jrnlCiqualDefaultTitle => '🇫🇷 CIQUAL — default database';

  @override
  String get jrnlCiqualDefaultBody =>
      'France\'s official nutritional composition table, published by ANSES (French Agency for Food, Environmental and Occupational Health & Safety). Covers everyday foods in France. This is Totum\'s reference database, selected by default in all searches.';

  @override
  String get jrnlUsdaReinforceTitle => '🇺🇸 USDA — as backup';

  @override
  String get jrnlUsdaReinforceBody =>
      'FoodData Central, the official U.S. government nutrition database (U.S. Department of Agriculture). Lab-analyzed foods (Foundation Foods/SR Legacy) — the same level of scientific rigor as CIQUAL, translated to French, but built around U.S. eating habits (portions, recipes, branded products).';

  @override
  String get jrnlWhyBothTitle => 'Why both?';

  @override
  String get jrnlWhyBothBody =>
      'CIQUAL doesn\'t cover everything, especially some foods of Anglo-Saxon origin. Turning on \"Include the USDA database\" expands the search to these ~7500 extra foods — every USDA result stays marked with a badge, so you always know where the data comes from.';

  @override
  String get jrnlSearchOptionsTitle => 'Food search options';

  @override
  String get jrnlMultiSelectToggleTitle => 'Enable multi-add';

  @override
  String get jrnlMultiSelectToggleDesc =>
      'Check several foods in \"Common\" and add them all at once to a meal.';

  @override
  String get jrnlCategoryTabsToggleTitle => 'Category tabs';

  @override
  String get jrnlCategoryTabsToggleDesc =>
      'Common/Favorites/Personal/Brands/Restaurant — turn off to save screen space.';

  @override
  String get jrnlSortByLabel => 'Sort by';

  @override
  String get jrnlSortFrequent => 'Most frequent';

  @override
  String get jrnlSortRecent => 'Most recent';

  @override
  String get jrnlSortAZ => 'A → Z';

  @override
  String get jrnlSortZA => 'Z → A';

  @override
  String get jrnlSearchOverridesSortHint =>
      'While searching, the best match always takes priority over this sort.';

  @override
  String get jrnlDatabaseLabel => 'Database';

  @override
  String get jrnlCiqualDefaultCheckbox => 'CIQUAL (France) — default';

  @override
  String get jrnlUsdaReinforceCheckbox => 'USDA (United States) — backup';

  @override
  String jrnlAddToMeal(String meal) {
    return 'Add to $meal';
  }

  @override
  String get jrnlSearchFood => 'Search a food';

  @override
  String get jrnlTypeToSearchFood => 'Type to search a food';

  @override
  String jrnlPersonalMealSummary(int count, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Personal meal · $_temp0 · $kcal kcal';
  }

  @override
  String get jrnlTagPersonal => 'Personal';

  @override
  String get jrnlTagRecipe => 'Recipe';

  @override
  String get jrnlMealEmptyToCopy => 'This meal is empty, nothing to copy.';

  @override
  String get jrnlCopyMealTitle => 'Copy this meal';

  @override
  String jrnlItemsFromMeal(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 from $meal';
  }

  @override
  String get jrnlToDaySegment => 'To a day';

  @override
  String get jrnlPersonalMealSegment => 'Personal meal';

  @override
  String get jrnlPersonalMealNameField => 'Personal meal name';

  @override
  String get jrnlCopyButton => 'Copy';

  @override
  String jrnlSavedToPersonalMeals(String name) {
    return '\"$name\" saved to your personal meals';
  }

  @override
  String jrnlQuantityGrams(String grams) {
    return 'Quantity: $grams g';
  }

  @override
  String get jrnlDetailNotAvailable =>
      'Full details not available for this food.';

  @override
  String get jrnlToday => 'Today';

  @override
  String get jrnlWeekdayMon => 'Mon';

  @override
  String get jrnlWeekdayTue => 'Tue';

  @override
  String get jrnlWeekdayWed => 'Wed';

  @override
  String get jrnlWeekdayThu => 'Thu';

  @override
  String get jrnlWeekdayFri => 'Fri';

  @override
  String get jrnlWeekdaySat => 'Sat';

  @override
  String get jrnlWeekdaySun => 'Sun';

  @override
  String get jrnlJournalTitle => 'Journal';

  @override
  String get jrnlAccountSettingsTooltip => 'Account & Settings';

  @override
  String get jrnlPreviousDayTooltip => 'Previous day';

  @override
  String get jrnlNextDayTooltip => 'Next day';

  @override
  String jrnlTargetKcal(String kcal) {
    return 'Target $kcal kcal';
  }

  @override
  String jrnlConsumedKcal(String kcal) {
    return 'Consumed $kcal kcal';
  }

  @override
  String jrnlRemainingKcal(String kcal) {
    return 'Remaining $kcal kcal';
  }

  @override
  String jrnlExceededByKcal(String kcal) {
    return 'Exceeded by $kcal kcal';
  }

  @override
  String get jrnlScanProductTooltip => 'Scan a product';

  @override
  String get jrnlMoreOptionsTooltip => 'More options';

  @override
  String get jrnlClearAllTitle => 'Clear everything?';

  @override
  String jrnlClearAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Delete the $_temp0 from this meal?';
  }

  @override
  String get jrnlExitSelection => 'Exit selection';

  @override
  String get jrnlSelectFoods => 'Select foods';

  @override
  String get jrnlClearAllMenuItem => 'Clear all';

  @override
  String get jrnlCheckFoodsToCopy => 'Check the foods to copy';

  @override
  String jrnlFoodsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
    );
    return '$_temp0';
  }

  @override
  String get jrnlCopySelection => 'Copy selection';

  @override
  String get jrnlMealNutritionDetailsTooltip => 'Meal nutrition details';

  @override
  String get jrnlNova1Label => 'Unprocessed or minimally processed';

  @override
  String get jrnlNova2Label => 'Processed culinary ingredient';

  @override
  String get jrnlNova3Label => 'Processed food';

  @override
  String get jrnlNova4Label => 'Ultra-processed';

  @override
  String get jrnlNova1Desc =>
      'Food in its natural state or only processed for preservation (fresh, frozen, dried, boiled...) — fruits, vegetables, meat, fish, eggs, plain milk.';

  @override
  String get jrnlNova2Desc =>
      'Substance extracted from a whole food (pressing, refining), used in small amounts for cooking or seasoning — oils, butter, sugar, salt.';

  @override
  String get jrnlNova3Desc =>
      'Whole food with added salt, sugar or oil to preserve or improve it (canning, smoking, fermenting...) — cheeses, bread, canned vegetables, artisanal cured meats.';

  @override
  String get jrnlNova4Desc =>
      'Industrial formulation made from ingredients rarely used in home cooking (additives, flavorings, texturizers) — sodas, ready meals, industrial cookies, processed cured meats.';

  @override
  String get jrnlNovaScoreTitle => 'The NOVA score';

  @override
  String get jrnlNovaScoreIntro =>
      'Classifies foods by their degree of processing — not their nutritional value. A low-calorie product can be ultra-processed, and vice versa.';

  @override
  String jrnlNovaEstimated(int score) {
    return 'This food is estimated as NOVA $score by TOTUM, based on its CIQUAL food family — the CIQUAL database doesn\'t provide an official NOVA score. Take it as an indication, not a certified measurement.';
  }

  @override
  String jrnlNovaOfficial(int score) {
    return 'This food is classified as NOVA $score by Open Food Facts (official data for the scanned product).';
  }

  @override
  String get jrnlNovaSource =>
      'Source: NOVA classification (Monteiro et al.), as used by Open Food Facts.';

  @override
  String get jrnlConfirmDeleteTooltip => 'Confirm deletion';

  @override
  String jrnlAddButtonCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get jrnlNoPersonalMealsYet => 'No personal meals yet';

  @override
  String get jrnlCreateFirstPersonalMealHint =>
      'Create your first personal meal with the + button in the bottom right,\nor from a journal meal via \"Copy this meal\" → \"Personal meal\".';

  @override
  String jrnlLibraryChipLabel(int count) {
    return 'TOTUM Library ($count)';
  }

  @override
  String get jrnlNoPersonalFoodYet => 'No personal food yet';

  @override
  String get jrnlNoRecipeYet => 'No recipe yet';

  @override
  String get jrnlCreateFirstFoodHint =>
      'Create your first food with the + button in the bottom right';

  @override
  String get jrnlCreateFirstRecipeHint =>
      'Create your first recipe with the + button in the bottom right';

  @override
  String get jrnlLibraryBadge => 'TOTUM Library';

  @override
  String get jrnlWaterTitle => 'Water';

  @override
  String jrnlAddGlassTooltip(int ml) {
    return 'Add a glass ($ml ml)';
  }

  @override
  String get jrnlOptionsTooltip => 'Options';

  @override
  String get jrnlEnterQuantityMenuItem => 'Enter a quantity';

  @override
  String get jrnlEditTargetMenuItem => 'Edit target';

  @override
  String get jrnlGlassSizeMenuItem => 'Glass size';

  @override
  String get jrnlResetToZeroMenuItem => 'Reset to zero';

  @override
  String get jrnlEnterDrankQuantityTitle => 'Enter quantity drunk';

  @override
  String get jrnlTotalDailyQuantityMl => 'Total daily quantity (in ml):';

  @override
  String get jrnlHydrationTargetTitle => 'Hydration target';

  @override
  String get jrnlWaterPerGlassMl => 'Water quantity per glass (in ml):';

  @override
  String get jrnlValidateButton => 'Confirm';

  @override
  String jrnlWaterBreakdown(int drinks, int food, int pct) {
    return 'including $drinks ml from drinks + $food ml from food · $pct% of the total target';
  }

  @override
  String jrnlPercentOfTarget(int pct) {
    return '$pct% of target';
  }

  @override
  String jrnlTargetReached(int pct) {
    return 'Target reached! ($pct%)';
  }

  @override
  String jrnlPercentGlassesLeft(int pct, int glasses) {
    return '$pct% of your target — about $glasses glass(es) left';
  }

  @override
  String get jrnlMyAccountTooltip => 'My account';

  @override
  String get jrnlFiltersSortTooltip => 'Filters and sort';

  @override
  String get jrnlAddFoodTooltip => 'Add a food';

  @override
  String get jrnlCopyAsPersonalFoodTooltip => 'Copy as personal food';

  @override
  String get jrnlTabCommon => 'Common';

  @override
  String get jrnlTabFavorites => 'Favorites';

  @override
  String get jrnlTabPersonal => 'Personal';

  @override
  String get jrnlTabBrands => 'Brands';

  @override
  String get jrnlTabRestaurant => 'Restaurant';

  @override
  String get jrnlSearchBothDb => 'Search (CIQUAL + USDA)';

  @override
  String get jrnlSearchUsdaOnly => 'Search (USDA only)';

  @override
  String get jrnlSearchCiqualOnly => 'Search (CIQUAL only)';

  @override
  String jrnlMealItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count items)',
      one: '($count item)',
    );
    return '$_temp0';
  }

  @override
  String get jrnlFilterPersonalFoods => 'Personal foods';

  @override
  String get jrnlFilterRecipes => 'Recipes';

  @override
  String get jrnlFilterMeals => 'Meals';

  @override
  String get jrnlSyncFailedWarning =>
      'No connection: this change couldn\'t be synced and may be lost. Please try again when you\'re back online.';

  @override
  String get jrnlSyncFailedRetry => 'Retry';

  @override
  String get jrnlUnknownFoodFallback => 'Food item';
}
