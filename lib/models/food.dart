class Food {
  final String id;
  final String name;
  final String? brand;

  // macros / base (pour 100 g)
  final double kcal100;
  final double p100; // protéines
  final double c100; // glucides
  final double f100; // lipides

  // autres colonnes numériques (pour 100 g) -> dynamiques
  final Map<String, double> extras100;

  const Food({
    required this.id,
    required this.name,
    this.brand,
    required this.kcal100,
    required this.p100,
    required this.c100,
    required this.f100,
    required this.extras100,
  });

  double _scaled(double per100, double g) => (per100 * g) / 100.0;

  // calculs pour quantité (g)
  double kcalFor(double g) => _scaled(kcal100, g);
  double protFor(double g) => _scaled(p100, g);
  double carbFor(double g) => _scaled(c100, g);
  double fatFor(double g)  => _scaled(f100, g);

  Map<String, double> extrasFor(double g) {
    final out = <String, double>{};
    extras100.forEach((k, v) => out[k] = _scaled(v, g));
    return out;
  }
}
