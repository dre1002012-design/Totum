// lib/services/meal_share.dart
//
// Données d'un repas à partager sur Instagram (carrousel, post, story,
// images pour Reel) — demande d'Alex du 25/10/2026 : "à partir de la photo
// de mon plat, un clé en main au format Instagram avec exactement les
// macros et les micronutriments essentiels, sans retravailler le visuel".
//
// Choix scientifiques et réglementaires (contenu PUBLIC, donc plus exigeant
// qu'un écran perso) :
// - Les pourcentages affichés sont calculés sur les VALEURS NUTRITIONNELLES
//   DE RÉFÉRENCE (VNR) officielles de l'étiquetage européen — règlement (UE)
//   n° 1169/2011, annexe XIII — et non sur les cibles personnelles de
//   l'utilisateur (ex. 3 220 kcal pour Alex) : un abonné doit pouvoir lire
//   "% des VNR" comme sur n'importe quel emballage.
// - Aucune allégation de type "riche en"/"source de" (encadrées par le
//   règlement (CE) n° 1924/2006, avec des conditions par 100 g) : uniquement
//   des quantités et des pourcentages factuels par portion.
// - Fibres et oméga-3 n'ont pas de VNR : comparés aux apports adéquats EFSA
//   (fibres 25 g/j ; EPA+DHA 250 mg/j), mention explicite dans le libellé.

import 'dart:math' as math;

/// Une ligne d'ingrédient du repas partagé.
class MealShareItem {
  final String name;
  final String emoji;
  final double grams;
  final double kcal;
  const MealShareItem({
    required this.name,
    required this.emoji,
    required this.grams,
    required this.kcal,
  });
}

/// Un nutriment mis en avant, avec son % de la référence.
class NutrientHighlight {
  final String key; // identifiant stable (ex. 'vitC')
  final String label; // libellé court affiché
  final double amount;
  final String unit;
  final double reference;
  final String emoji;
  const NutrientHighlight({
    required this.key,
    required this.label,
    required this.amount,
    required this.unit,
    required this.reference,
    required this.emoji,
  });
  double get percent => reference > 0 ? amount / reference * 100 : 0;
}

/// Définition d'un micronutriment comparé à une VNR.
class _VnrDef {
  final String key, labelFr, labelEn, unit, emoji;
  final double vnr;
  final double Function(Map<String, double> m) amount;
  const _VnrDef(this.key, this.labelFr, this.labelEn, this.unit, this.vnr, this.emoji, this.amount);
}

double _g(Map<String, double> m, String k) => m[k] ?? 0;

/// VNR adultes — règlement (UE) n° 1169/2011, annexe XIII, partie A.
/// Vitamine A en équivalents rétinol : rétinol + bêta-carotène / 6 (EFSA).
/// Vitamine K : K1 + K2 (la VNR porte sur la vitamine K totale).
final List<_VnrDef> _vnrDefs = [
  _VnrDef('vitA', 'Vitamine A', 'Vitamin A', 'µg', 800, '🥕',
      (m) => _g(m, 'Rétinol_µg_100g') + _g(m, 'Beta-Carotène_µg_100g') / 6),
  _VnrDef('vitD', 'Vitamine D', 'Vitamin D', 'µg', 5, '☀️', (m) => _g(m, 'Vitamine_D_µg_100g')),
  _VnrDef('vitE', 'Vitamine E', 'Vitamin E', 'mg', 12, '🌻', (m) => _g(m, 'Vitamine_E_mg_100g')),
  _VnrDef('vitK', 'Vitamine K', 'Vitamin K', 'µg', 75, '🥬',
      (m) => _g(m, 'Vitamine_K1_µg_100g') + _g(m, 'Vitamine_K2_µg_100g')),
  _VnrDef('vitC', 'Vitamine C', 'Vitamin C', 'mg', 80, '🍊', (m) => _g(m, 'Vitamine_C_mg_100g')),
  _VnrDef('b1', 'Vitamine B1', 'Vitamin B1', 'mg', 1.1, '🌾', (m) => _g(m, 'Vitamine_B1_mg_100g')),
  _VnrDef('b2', 'Vitamine B2', 'Vitamin B2', 'mg', 1.4, '🥛', (m) => _g(m, 'Vitamine_B2_mg_100g')),
  _VnrDef('b3', 'Vitamine B3', 'Vitamin B3', 'mg', 16, '🍗', (m) => _g(m, 'Vitamine_B3_mg_100g')),
  _VnrDef('b5', 'Vitamine B5', 'Vitamin B5', 'mg', 6, '🍄', (m) => _g(m, 'Vitamine_B5_mg_100g')),
  _VnrDef('b6', 'Vitamine B6', 'Vitamin B6', 'mg', 1.4, '🍌', (m) => _g(m, 'Vitamine_B6_mg_100g')),
  _VnrDef('b9', 'Vitamine B9', 'Folate', 'µg', 200, '🥦', (m) => _g(m, 'Vitamine_B9_µg_100g')),
  _VnrDef('b12', 'Vitamine B12', 'Vitamin B12', 'µg', 2.5, '🐟', (m) => _g(m, 'Vitamine_B12_µg_100g')),
  _VnrDef('ca', 'Calcium', 'Calcium', 'mg', 800, '🦴', (m) => _g(m, 'Calcium_mg_100g')),
  _VnrDef('mg', 'Magnésium', 'Magnesium', 'mg', 375, '🌰', (m) => _g(m, 'Magnésium_mg_100g')),
  _VnrDef('fe', 'Fer', 'Iron', 'mg', 14, '🩸', (m) => _g(m, 'Fer_mg_100g')),
  _VnrDef('zn', 'Zinc', 'Zinc', 'mg', 10, '🛡️', (m) => _g(m, 'Zinc_mg_100g')),
  _VnrDef('k', 'Potassium', 'Potassium', 'mg', 2000, '🥑', (m) => _g(m, 'Potassium_mg_100g')),
  _VnrDef('p', 'Phosphore', 'Phosphorus', 'mg', 700, '⚡', (m) => _g(m, 'Phosphore_mg_100g')),
  _VnrDef('se', 'Sélénium', 'Selenium', 'µg', 55, '🌱', (m) => _g(m, 'Sélénium_µg_100g')),
  _VnrDef('i', 'Iode', 'Iodine', 'µg', 150, '🌊', (m) => _g(m, 'Iode_µg_100g')),
  _VnrDef('cu', 'Cuivre', 'Copper', 'mg', 1, '🔶', (m) => _g(m, 'Cuivre_mg_100g')),
  _VnrDef('mn', 'Manganèse', 'Manganese', 'mg', 2, '🫘', (m) => _g(m, 'Manganèse_mg_100g')),
];

/// Apports de référence énergie/macros (UE 1169/2011, annexe XIII, partie B).
const double kRefKcal = 2000;
const double kRefProteinG = 50;
const double kRefCarbG = 260;
const double kRefFatG = 70;
/// Pas de VNR pour les fibres ni les oméga-3 : apports adéquats EFSA.
const double kRefFiberG = 25;
const double kRefEpaDhaMg = 250;

/// Le repas à partager, totaux déjà calculés.
class MealShareData {
  final String title;
  final DateTime date;
  final List<MealShareItem> items;
  final double kcal, protein, carbs, fat, fiber;
  /// Micronutriments TOTAUX du repas (pas pour 100 g), clés CIQUAL
  /// (ex. 'Vitamine_C_mg_100g' -> quantité totale dans le repas).
  final Map<String, double> micros;

  const MealShareData({
    required this.title,
    required this.date,
    required this.items,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.micros,
  });

  MealShareData copyWith({String? title}) => MealShareData(
        title: title ?? this.title, date: date, items: items, kcal: kcal,
        protein: protein, carbs: carbs, fat: fat, fiber: fiber, micros: micros,
      );

  /// Part de l'énergie apportée par chaque macro (Atwater 4/4/9 ; fibres
  /// non comptées, comme sur l'étiquetage). Somme = 1 si énergie > 0.
  ({double protein, double carbs, double fat}) get energySplit {
    final p = protein * 4, c = carbs * 4, f = fat * 9;
    final total = p + c + f;
    if (total <= 0) return (protein: 0, carbs: 0, fat: 0);
    return (protein: p / total, carbs: c / total, fat: f / total);
  }

  double get epaDhaMg => ((micros['EPA_g_100g'] ?? 0) + (micros['DHA_g_100g'] ?? 0)) * 1000;

  /// Micronutriments classés par % de VNR décroissant. [minPercent] filtre
  /// les apports anecdotiques (15 % = seuil "quantité significative" de la
  /// directive 90/496/CEE, reprise par le règlement 1169/2011).
  List<NutrientHighlight> highlights({bool english = false, double minPercent = 15, int max = 6}) {
    final out = <NutrientHighlight>[
      for (final d in _vnrDefs)
        NutrientHighlight(
          key: d.key,
          label: english ? d.labelEn : d.labelFr,
          amount: d.amount(micros),
          unit: d.unit,
          reference: d.vnr,
          emoji: d.emoji,
        ),
    ]..removeWhere((h) => h.percent < minPercent);
    if (epaDhaMg / kRefEpaDhaMg * 100 >= minPercent) {
      out.add(NutrientHighlight(
        key: 'epaDha', label: english ? 'Omega-3 EPA+DHA' : 'Oméga-3 EPA+DHA',
        amount: epaDhaMg, unit: 'mg', reference: kRefEpaDhaMg, emoji: '🐟',
      ));
    }
    out.sort((a, b) => b.percent.compareTo(a.percent));
    return out.take(max).toList();
  }
}

String formatAmount(double v, String unit) {
  if (unit == 'kcal' || v >= 100) return v.round().toString();
  if (v >= 10) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1).replaceAll('.0', '');
}

/// Accroche du 1er visuel / de la légende : construite UNIQUEMENT à partir
/// des chiffres réels du repas (jamais de promesse santé).
String hookFor(MealShareData d, {bool english = false}) {
  final p = d.protein.round(), fi = d.fiber.round();
  final top = d.highlights(english: english, max: 1);
  if (p >= 30 && fi >= 8) {
    return english ? '$p g protein & $fi g fiber in one plate' : '$p g de protéines et $fi g de fibres dans une seule assiette';
  }
  if (p >= 30) return english ? '$p g of protein, zero supplements' : '$p g de protéines, sans complément';
  if (fi >= 10) return english ? '$fi g of fiber in one meal' : '$fi g de fibres en un seul repas';
  if (top.isNotEmpty && top.first.percent >= 50) {
    final h = top.first;
    return english
        ? '${h.percent.round()}% of the daily ${h.label} reference'
        : '${h.percent.round()} % des VNR en ${h.label.toLowerCase()}';
  }
  return english ? 'What this plate really contains' : 'Ce que contient vraiment mon assiette';
}

/// "Le point naturo" : 2-3 constats factuels tirés des données (aucun
/// conseil médical, aucune allégation).
List<String> insightsFor(MealShareData d, {bool english = false}) {
  final out = <String>[];
  final split = d.energySplit;
  if (d.protein >= 25) {
    out.add(english
        ? '${d.protein.round()} g of protein: a solid share for satiety and muscle maintenance.'
        : '${d.protein.round()} g de protéines : une belle part pour la satiété et le maintien musculaire.');
  }
  if (d.fiber >= 8) {
    out.add(english
        ? '${d.fiber.round()} g of fiber, i.e. ${(d.fiber / kRefFiberG * 100).round()}% of the EFSA 25 g/day reference.'
        : '${d.fiber.round()} g de fibres, soit ${(d.fiber / kRefFiberG * 100).round()} % des 25 g/j recommandés par l\'EFSA.');
  }
  final hs = d.highlights(english: english, max: 3);
  if (hs.isNotEmpty) {
    final names = hs.map((h) => '${h.label} (${h.percent.round()} %)').join(', ');
    out.add(english
        ? 'Standout micronutrients: $names of reference intakes.'
        : 'Points forts : $names des apports de référence.');
  }
  if (d.epaDhaMg >= 250) {
    out.add(english
        ? '${d.epaDhaMg.round()} mg of EPA+DHA omega-3: the full EFSA daily reference.'
        : '${d.epaDhaMg.round()} mg d\'oméga-3 EPA+DHA : la référence quotidienne EFSA couverte.');
  }
  if (out.length < 2 && split.carbs > 0) {
    out.add(english
        ? 'Energy split: ${(split.protein * 100).round()}% protein, ${(split.carbs * 100).round()}% carbs, ${(split.fat * 100).round()}% fat.'
        : 'Répartition de l\'énergie : ${(split.protein * 100).round()} % protéines, ${(split.carbs * 100).round()} % glucides, ${(split.fat * 100).round()} % lipides.');
  }
  return out.take(3).toList();
}

/// Mots-dièse : 5 maximum (limite Instagram depuis décembre 2025), du plus
/// large au plus spécifique, choisis selon le contenu réel du repas.
List<String> hashtagsFor(MealShareData d, {bool english = false}) {
  final tags = <String>[];
  tags.add(english ? '#nutrition' : '#naturopathie');
  tags.add(english ? '#healthyeating' : '#alimentationsaine');
  if (d.protein >= 30) {
    tags.add(english ? '#protein' : '#proteines');
  } else if (d.fiber >= 10) {
    tags.add(english ? '#fiber' : '#fibres');
  } else {
    tags.add(english ? '#balancedmeal' : '#repasequilibre');
  }
  tags.add(english ? '#mealprep' : '#recettesaine');
  tags.add(english ? '#wholefoods' : '#micronutrition');
  return tags.take(5).toList();
}

/// Légende complète prête à coller : accroche, macros, points forts,
/// ingrédients, appel à l'enregistrement et au partage (les 2 signaux que
/// le responsable d'Instagram, Adam Mosseri, cite parmi les plus
/// déterminants avec le temps de visionnage), puis 5 mots-dièse max.
String captionFor(MealShareData d, {bool english = false, String handle = ''}) {
  final b = StringBuffer();
  b.writeln('${d.title} 🍽️');
  b.writeln(hookFor(d, english: english));
  b.writeln();
  b.writeln('⚡ ${d.kcal.round()} kcal · 🥩 ${english ? 'P' : 'P'} ${d.protein.round()} g · '
      '🌾 ${english ? 'C' : 'G'} ${d.carbs.round()} g · 🫒 ${english ? 'F' : 'L'} ${d.fat.round()} g · '
      '🌿 ${english ? 'Fiber' : 'Fibres'} ${d.fiber.round()} g');
  final hs = d.highlights(english: english, max: 4);
  if (hs.isNotEmpty) {
    b.writeln();
    b.writeln(english ? '✨ Standout micronutrients (% of EU reference values):' : '✨ Micronutriments phares (% des VNR) :');
    for (final h in hs) {
      b.writeln('${h.emoji} ${h.label} : ${formatAmount(h.amount, h.unit)} ${h.unit} (${h.percent.round()} %)');
    }
  }
  if (d.items.isNotEmpty) {
    b.writeln();
    b.writeln(english ? '🥣 Ingredients:' : '🥣 Ingrédients :');
    for (final it in d.items) {
      b.writeln('• ${it.grams.round()} g ${english ? it.name : _withDe(it.name)}');
    }
  }
  b.writeln();
  b.writeln(english ? '💾 Save it for your next plate' : '💾 Enregistre-le pour ta prochaine assiette');
  b.writeln(english ? '✈️ Send it to someone looking for balanced meal ideas' : '✈️ Envoie-le à quelqu\'un qui cherche des idées de repas équilibrés');
  b.writeln(english ? '💬 How would you make it?' : '💬 Et toi, tu le préparerais comment ?');
  b.writeln();
  b.writeln(english
      ? 'Values computed with Totum (ANSES-CIQUAL database), per serving.'
      : 'Valeurs calculées avec Totum (base ANSES-CIQUAL), pour la portion.');
  if (handle.trim().isNotEmpty) b.writeln(handle.trim());
  b.writeln();
  b.write(hashtagsFor(d, english: english).join(' '));
  return b.toString();
}

/// "de pâtes" / "d'avocat" / "d'huile" — élision devant voyelle ou h muet.
String _withDe(String name) {
  if (name.isEmpty) return name;
  final first = name[0].toLowerCase();
  final lower = name[0].toLowerCase() + name.substring(1);
  return 'aàâeéèêiîoôuûyh'.contains(first) ? "d'$lower" : 'de $lower';
}

/// Nom court d'un ingrédient pour un visuel (les noms CIQUAL complets sont
/// trop longs pour une carte) : partie avant la première virgule ou
/// parenthèse, capitalisée.
String shortFoodName(String name) {
  var n = name.split(RegExp(r'[,(]')).first.trim();
  if (n.isEmpty) n = name.trim();
  if (n.length > 34) n = '${n.substring(0, 33).trimRight()}…';
  return n.isEmpty ? n : n[0].toUpperCase() + n.substring(1);
}

/// Construit un [MealShareData] à partir des entrées du journal.
/// [lookup] retrouve l'aliment complet (pour ses micros pour 100 g et son
/// pictogramme) à partir de l'id de l'entrée.
MealShareData buildMealShareData({
  required String title,
  required DateTime date,
  required List<Map<String, dynamic>> entries,
  required ({Map<String, double> micros100, String? emoji, String displayName})? Function(String id, String name) lookup,
}) {
  double kcal = 0, p = 0, c = 0, f = 0, fi = 0;
  final micros = <String, double>{};
  final items = <MealShareItem>[];
  for (final e in entries) {
    double num_(String k) => (e[k] as num?)?.toDouble() ?? 0.0;
    final grams = num_('grams');
    kcal += num_('kcal');
    p += num_('prot');
    c += num_('carb');
    f += num_('fat');
    fi += num_('fiber');
    final id = (e['id'] ?? '').toString();
    final rawName = (e['name'] ?? '').toString();
    final food = lookup(id, rawName);
    if (food != null) {
      food.micros100.forEach((k, v) {
        micros[k] = (micros[k] ?? 0) + v * grams / 100.0;
      });
    }
    items.add(MealShareItem(
      name: shortFoodName(food?.displayName ?? rawName),
      emoji: food?.emoji ?? '🍽️',
      grams: grams,
      kcal: num_('kcal'),
    ));
  }
  // Ingrédients les plus présents d'abord (poids), plus lisible sur un visuel.
  items.sort((a, b) => b.grams.compareTo(a.grams));
  return MealShareData(
    title: title, date: date, items: items,
    kcal: kcal, protein: p, carbs: c, fat: f, fiber: fi,
    micros: micros,
  );
}

/// Taille max d'une liste d'ingrédients lisible sur un visuel 1080 px.
int maxIngredientsOnSlide(int available) => math.min(available, 9);
