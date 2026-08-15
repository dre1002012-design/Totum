// lib/l10n/l10n_ext.dart
//
// Raccourci `context.l10n.xxx` plutôt que `AppLocalizations.of(context).xxx`
// répété sur ~1100 sites d'appel à travers toute l'app (Priorité 62).
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
