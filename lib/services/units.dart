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

  /// Affichage lecture-seule d'un poids (dashboard, graphiques).
  static String formatWeight(double kg, UnitSystem s) {
    if (s == UnitSystem.imperial) return '${kgToLb(kg).toStringAsFixed(1)} lb';
    final trimmed = kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    return '$trimmed kg';
  }

  /// Affichage lecture-seule d'une taille (dashboard) — format pied'pouce"
  /// en impérial, cohérent avec l'usage courant (contrairement au champ de
  /// saisie qui reste un nombre simple en pouces, plus simple à éditer).
  static String formatHeight(double cm, UnitSystem s) {
    if (s == UnitSystem.imperial) {
      final totalIn = cmToIn(cm);
      final ft = (totalIn / 12).floor();
      final inch = (totalIn - ft * 12).round();
      return '$ft\'$inch"';
    }
    return '${cm.round()} cm';
  }
}
