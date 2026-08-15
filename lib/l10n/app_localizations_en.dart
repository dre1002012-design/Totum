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
}
