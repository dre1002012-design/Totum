// lib/services/units.dart
//
// Conversion et formatage kg/cm <-> unités impériales. Le stockage (local et
// Supabase) reste TOUJOURS en métrique — ce fichier n'affecte que l'affichage
// et la saisie, jamais la persistance ni les calculs (mêmes principes que
// pour les portions USDA, voir docs/TODO.md Priorité 40).

enum UnitSystem { metric, imperial }

const double _kgPerLb = 0.45359237;
const double _cmPerIn = 2.54;

class Units {
  Units._();

  static double kgToLb(double kg) => kg / _kgPerLb;
  static double lbToKg(double lb) => lb * _kgPerLb;
  static double cmToIn(double cm) => cm / _cmPerIn;
  static double inToCm(double inches) => inches * _cmPerIn;

  static String weightUnitLabel(UnitSystem s) => s == UnitSystem.imperial ? 'lb' : 'kg';
  static String heightUnitLabel(UnitSystem s) => s == UnitSystem.imperial ? 'in' : 'cm';

  /// Valeur poids à afficher dans un champ de saisie, dans l'unité choisie.
  static double displayWeight(double kg, UnitSystem s) => s == UnitSystem.imperial ? kgToLb(kg) : kg;

  /// Valeur taille à afficher dans un champ de saisie, dans l'unité choisie.
  static double displayHeight(double cm, UnitSystem s) => s == UnitSystem.imperial ? cmToIn(cm) : cm;

  /// Convertit une valeur saisie dans l'unité choisie vers le kg de stockage.
  static double weightToKg(double displayed, UnitSystem s) => s == UnitSystem.imperial ? lbToKg(displayed) : displayed;

  /// Convertit une valeur saisie dans l'unité choisie vers le cm de stockage.
  static double heightToCm(double displayed, UnitSystem s) => s == UnitSystem.imperial ? inToCm(displayed) : displayed;

  /// Trim un nombre à 2 décimales max, sans zéros inutiles (ex. 72.5 reste
  /// "72.5", jamais "72.50" ; 70.0 devient "70") — PUBLIC et partagé (21/08/2026)
  /// : avant, 3 implémentations quasi identiques de ce même arrondi vivaient
  /// séparément (`profile_screen.dart` × 2, `units.dart`), exactement le
  /// pattern "logique dupliquée qui dérive" déjà documenté ailleurs dans ce
  /// projet (`docs/KNOWN_ISSUES.md`) — une seule source désormais.
  static String trimDecimals(double v, {int maxDecimals = 2}) {
    var s = v.toStringAsFixed(maxDecimals);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Affichage lecture-seule d'un poids (dashboard, graphiques).
  ///
  /// BUG CORRIGÉ (21/08/2026, retour d'Alex — "je lui ai rentré 72,75 et ça
  /// m'affiche 72,8 partout") : plafonné à 1 décimale, perdait silencieusement
  /// le 2e chiffre saisi. 2 décimales désormais partout où un poids est
  /// affiché (zéros inutiles retirés, comme dans le champ de saisie Mesures).
  static String formatWeight(double kg, UnitSystem s) {
    if (s == UnitSystem.imperial) return '${trimDecimals(kgToLb(kg))} lb';
    return '${trimDecimals(kg)} kg';
  }

  /// Affichage lecture-seule d'une taille (dashboard) — format pied'pouce"
  /// en impérial, cohérent avec l'usage courant (contrairement au champ de
  /// saisie qui reste un nombre simple en pouces, plus simple à éditer).
  static String formatHeight(double cm, UnitSystem s) {
    if (s == UnitSystem.imperial) {
      // Priorité 66 (audit global, test unitaire) : arrondir le total de
      // pouces D'ABORD, puis en dériver pieds/pouces, jamais l'inverse —
      // sinon un total comme 71.5 po (5 pi 11.5 po) affichait "5'12"" au
      // lieu de "6'0"" (pieds tronqués puis pouces arrondis SÉPARÉMENT,
      // chacun pouvant déborder sur l'autre).
      final totalInRounded = cmToIn(cm).round();
      final ft = totalInRounded ~/ 12;
      final inch = totalInRounded % 12;
      return '$ft\'$inch"';
    }
    return '${cm.round()} cm';
  }
}
