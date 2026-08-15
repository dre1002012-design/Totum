// lib/services/totum_score.dart
// Service partagé du Score TOTUM, utilisé par le Bilan ET les Conseils.
// Ne dépend d'aucun écran : il reçoit les 5 sous-scores déjà calculés.

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/totum_style.dart';
import 'nutrient_labels.dart';

class SubScore {
  final String label;
  final double score; // 0-100
  final String emoji;
  const SubScore(this.label, this.score, this.emoji);
}

class TotumScore {
  final double global;         // 0-100
  final List<SubScore> parts;
  final List<String> warnings; // dépassements de limites de sécurité
  final double dayFraction;    // 1.0 = journée complète, < 1 = provisoire
  // Rempli quand un dépassement sévère d'un élément "à surveiller" (AG
  // saturés/sucres/sel) plafonne la note globale, quel que soit le reste —
  // voir computeTotumScoreFromValues et _kWatchSeverityCaps (Priorité 24).
  final String? capReason;
  const TotumScore({
    required this.global,
    required this.parts,
    required this.warnings,
    this.dayFraction = 1.0,
    this.capReason,
  });

  /// Le score porte-t-il sur une journée encore incomplète ?
  bool get isProvisional => dayFraction < 0.995;

  /// Part de la journée renseignée, en pourcentage entier.
  int get dayPercent => (dayFraction * 100).round();

  String get letter {
    if (global >= 85) return 'A';
    if (global >= 70) return 'B';
    if (global >= 55) return 'C';
    if (global >= 40) return 'D';
    return 'E';
  }

  /// Couleur restreinte à la charte (accent + positif/négatif) : un score
  /// est un delta directionnel vis-à-vis des objectifs santé, pas une simple
  /// progression — voir règle 5 de la charte graphique.
  Color get color {
    if (global >= 70) return TotumColors.positive;
    if (global >= 40) return TotumColors.accent;
    return TotumColors.negative;
  }

  String moodFor(AppLocalizations l10n) {
    if (global >= 85) return l10n.moodExcellent;
    if (global >= 70) return l10n.moodGood;
    if (global >= 55) return l10n.moodCorrect;
    if (global >= 40) return l10n.moodToImprove;
    return l10n.moodRebalance;
  }
}

String _emojiFor(double s) {
  if (s >= 70) return '🟢';
  if (s >= 55) return '🟠';
  if (s >= 40) return '🟠';
  return '🔴';
}

/// Plafonds de sécurité (Priorité 24, 10/08/2026) — un dépassement SÉVÈRE
/// d'un seul élément "à surveiller" (AG saturés/sucres/sel) plafonne la note
/// GLOBALE, quels que soient les autres sous-scores. Corrige une faille
/// concrète relevée par Alex : +1 kg de fromage → 696 % de la cible en AG
/// saturés, 378 % en sel, note globale pourtant restée en "B" (83).
///
/// Pourquoi un plafond dédié plutôt qu'une simple pondération plus lourde :
/// les index de référence eux-mêmes (Healthy Eating Index HEI-2020, USDA ;
/// Alternate Healthy Eating Index, Harvard) fonctionnent comme une SOMME/
/// MOYENNE pondérée de composants indépendants — par construction
/// mathématique, un seul composant en excès sévère ne peut jamais faire
/// chuter fortement le total si les autres composants sont bons (son poids
/// individuel plafonne mécaniquement les dégâts qu'il peut causer). C'est
/// exactement le bug relevé par Alex, hérité de la même architecture. Un
/// plafond dédié est nécessaire pour refléter la réalité physiologique :
/// - Sodium : relation dose-réponse LINÉAIRE avec le risque cardiovasculaire/
///   AVC, confirmée par plusieurs méta-analyses dose-réponse (2020-2024) ;
///   l'OMS recommande <2 g de sodium/j (optimum ~1,5 g), sans plafond "sûr"
///   au-delà duquel le risque cesse d'augmenter.
/// - Graisses saturées : une SEULE prise alimentaire riche en graisses
///   saturées altère déjà mesurablement la fonction endothéliale (méta-
///   analyse de 131 études, effet aigu dès quelques heures) — pas seulement
///   un risque statistique dilué sur le long terme.
/// Un excès ponctuel sévère mérite donc un signal immédiat et net, pas une
/// moyenne qui l'absorbe silencieusement.
const List<(double ratio, double cap)> _kWatchSeverityCaps = [
  (5.0, 20.0),  // ≥500 % de la cible du jour → plafond profond "E"
  (3.0, 39.0),  // ≥300 % → plafond "E" (juste sous 40)
  (2.0, 54.0),  // ≥200 % → plafond "D" (juste sous 55)
  (1.5, 69.0),  // ≥150 % → plafond "C" (juste sous 70, jamais B/A)
];

double? _capFor(double worstRatio) {
  for (final tier in _kWatchSeverityCaps) {
    if (worstRatio >= tier.$1) return tier.$2;
  }
  return null;
}

/// Calcule le score TOTUM à partir des 5 sous-scores (déjà en 0-100),
/// de la liste des dépassements de limites de sécurité (vitamines/minéraux)
/// et du pire ratio observé parmi les éléments "à surveiller" (pour le
/// plafond de sécurité ci-dessus).
///
/// Pondération (révisée Priorité 24, inspirée de la part accordée aux
/// composants "à limiter" dans le Healthy Eating Index — environ 30 % du
/// score total sur les composants de modération) :
/// Vitamines 22 / Minéraux 22 / Acides gras essentiels 18 / Hydratation 13
/// / À surveiller 25 — la part "à surveiller" est montée de 15 à 25 % pour
/// mieux refléter son poids réel dans le risque santé, en complément (pas en
/// remplacement) du plafond de sécurité ci-dessus.
TotumScore computeTotumScoreFromValues({
  required double vitamines,
  required double mineraux,
  required double acidesGras,
  required double hydratation,
  required double surveiller,
  required List<String> warnings,
  required AppLocalizations l10n,
  double dayFraction = 1.0,
  double watchWorstRatio = 0.0,
  String? watchWorstLabel,
}) {
  final rawGlobal = vitamines * 0.22 +
      mineraux * 0.22 +
      acidesGras * 0.18 +
      hydratation * 0.13 +
      surveiller * 0.25;

  final cap = _capFor(watchWorstRatio);
  final global = cap != null ? rawGlobal.clamp(0.0, cap) : rawGlobal;
  final capReason = (cap != null && watchWorstLabel != null)
      ? l10n.scoreCapReason(
          nutrientDisplayLabel(watchWorstLabel, l10n), (watchWorstRatio * 100).round())
      : null;

  return TotumScore(
    global: global.clamp(0, 100),
    dayFraction: dayFraction,
    parts: [
      SubScore(l10n.scorePillarVitamins, vitamines, _emojiFor(vitamines)),
      SubScore(l10n.scorePillarMinerals, mineraux, _emojiFor(mineraux)),
      SubScore(l10n.scorePillarFattyAcids, acidesGras, _emojiFor(acidesGras)),
      SubScore(l10n.scorePillarHydration, hydratation, _emojiFor(hydratation)),
      SubScore(l10n.scorePillarWatch, surveiller, _emojiFor(surveiller)),
    ],
    warnings: warnings,
    capReason: capReason,
  );
}