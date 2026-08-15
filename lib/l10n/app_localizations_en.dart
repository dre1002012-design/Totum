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
}
