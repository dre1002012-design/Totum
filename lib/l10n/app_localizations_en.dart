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
}
