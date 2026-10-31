// lib/widgets/meal_share_slides.dart
//
// Visuels de partage d'un repas / d'une journée. Données et références :
// services/meal_share.dart. Widgets PURS (aucune dépendance au thème de
// l'app ni à Localizations) : rendus hors écran à la taille exacte.
//
// Révision du 27/10/2026 (retour d'Alex) :
// - fonction GÉNÉRALISTE : aucun compte ni marque imposé — @compte
//   optionnel, mention Totum discrète et désactivable ;
// - plus aucun emoji pour représenter un nutriment (aucun n'était juste :
//   un poisson pour la B12 ET les oméga-3, une châtaigne pour le
//   sélénium...) : badges à symbole explicite, façon infographie
//   nutritionnelle — Mg, Zn, Se, K, Ca, Fe, I pour les minéraux ; "VIT" + D,
//   C, B12... pour les vitamines ; ω3/ω6 pour les acides gras. Les emojis
//   restent réservés aux ALIMENTS (pictogrammes Ciqual) ;
// - mentions de référence courtes et homogènes (VNR UE, repères ANSES).
//
// Version 2.0 (31/10/2026, retour d'Alex : « plus impactant, parlant à
// tout le monde, aucun symbole chimique, nutriments vraiment pertinents ») :
// noms complets, apports conseillés ANSES, nutriments choisis par
// pertinence santé (pas par pourcentage brut), fonctions du corps, part de
// chaque aliment. Carrousel (9 visuels, une idée par visuel) :
//  1. Couverture (accroche + 3 stars)  2. L'énergie (macros)
//  3. Ce que ce repas apporte à ton corps  4. Les stars et d'où elles
//  viennent  5. Vitamines  6. Minéraux  7. Les bonnes graisses
//  8. Dans l'assiette (atout de chaque aliment)  9. L'essentiel + à compléter
//
// Tailles logiques -> pixels exportés :
//  - flux (carrousel, post) : 360 × 450 ×3 = 1080 × 1350 (4:5) ;
//  - story / Reel : 360 × 640 ×3 = 1080 × 1920 (9:16), zones libres ;
//  - paysage : 400 × 210 ×3 = 1200 × 630 (site, Facebook, LinkedIn) ;
//  - bannière : 512 × 250 ×2 = 1024 × 500 (en-tête de site, Play Store).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/meal_share.dart';

const Size kShareSizeFeed = Size(360, 450);
const Size kShareSizeStory = Size(360, 640);
const Size kShareSizeLandscape = Size(400, 210);
const Size kShareSizeBanner = Size(512, 250);
const double kShareExportScale = 3; // 360 -> 1080 px

/// Palette d'un visuel. Les 2 premières = charte Totum (proposées par
/// défaut) ; les suivantes = ambiances généralistes, toujours sobres et
/// très lisibles (contraste texte/fond élevé).
class SharePalette {
  final String id;
  final Color bg, card, text, textSoft, accent, accentSoft, track, accent2;
  final bool dark;
  const SharePalette({
    required this.id, required this.bg, required this.card, required this.text,
    required this.textSoft, required this.accent, required this.accentSoft, required this.track,
    required this.accent2, this.dark = false,
  });

  static const totumCream = SharePalette(
    id: 'totum_cream', bg: Color(0xFFFBF6EF), card: Colors.white, text: Color(0xFF1E1A16),
    textSoft: Color(0xFF6F655B), accent: Color(0xFFFF7A00), accentSoft: Color(0xFFFFE7CC),
    track: Color(0xFFF1E7DB), accent2: Color(0xFFFFB066),
  );
  static const totumNight = SharePalette(
    id: 'totum_night', bg: Color(0xFF14120F), card: Color(0xFF221F1A), text: Color(0xFFF7F2EA),
    textSoft: Color(0xFFB9AE9F), accent: Color(0xFFFF8A1F), accentSoft: Color(0xFF3A2A18),
    track: Color(0xFF34302A), accent2: Color(0xFFFFC27A), dark: true,
  );
  static const nature = SharePalette(
    id: 'nature', bg: Color(0xFFEEF1E8), card: Colors.white, text: Color(0xFF1F2A1E),
    textSoft: Color(0xFF5E6B58), accent: Color(0xFF3F6B4F), accentSoft: Color(0xFFDCE6D5),
    track: Color(0xFFDDE3D6), accent2: Color(0xFFC8693F),
  );
  static const linen = SharePalette(
    id: 'linen', bg: Color(0xFFF6EFE6), card: Color(0xFFFFFCF8), text: Color(0xFF2B211B),
    textSoft: Color(0xFF7A6A5C), accent: Color(0xFFB85C38), accentSoft: Color(0xFFF1DCCB),
    track: Color(0xFFEADFD2), accent2: Color(0xFF6E8B5E),
  );
  static const ocean = SharePalette(
    id: 'ocean', bg: Color(0xFFEDF4F6), card: Colors.white, text: Color(0xFF12262E),
    textSoft: Color(0xFF557079), accent: Color(0xFF1F6F8B), accentSoft: Color(0xFFD5E8EE),
    track: Color(0xFFD9E5E9), accent2: Color(0xFFE7A23B),
  );
  static const minimal = SharePalette(
    id: 'minimal', bg: Colors.white, card: Color(0xFFF4F4F2), text: Color(0xFF111111),
    textSoft: Color(0xFF66666A), accent: Color(0xFF111111), accentSoft: Color(0xFFEDEDEB),
    track: Color(0xFFE4E4E1), accent2: Color(0xFFFF7A00),
  );
  static const all = [totumCream, totumNight, nature, linen, ocean, minimal];
}

enum ShareSlideKind {
  cover, overview, systems, stars, vitamins, minerals, fats, ingredients, cta,
  story, post, landscape, banner,
}

/// Les 9 visuels d'un carrousel, dans l'ordre de lecture.
const carouselKinds = [
  ShareSlideKind.cover,
  ShareSlideKind.overview,
  ShareSlideKind.systems,
  ShareSlideKind.stars,
  ShareSlideKind.vitamins,
  ShareSlideKind.minerals,
  ShareSlideKind.fats,
  ShareSlideKind.ingredients,
  ShareSlideKind.cta,
];

class MealShareSlide extends StatelessWidget {
  final ShareSlideKind kind;
  final MealShareData data;
  final SharePalette palette;
  final AppLocalizations l10n;
  final bool english;
  final ui.Image? photo;
  /// @compte de l'utilisateur, optionnel.
  final String handle;
  /// Mention discrète "Analysé avec Totum" (désactivable).
  final bool showTotumMark;
  /// Angle éditorial (sport, satiété, longévité…) — voir [ShareFocus].
  final ShareFocus focus;
  final int? index;
  final int? count;
  /// Visuel de carrousel posé dans un cadre 9:16 (images pour un Reel).
  final bool reelFrame;
  /// Police explicite (tests de capture uniquement).
  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  const MealShareSlide({
    super.key,
    required this.kind,
    required this.data,
    required this.palette,
    required this.l10n,
    this.english = false,
    this.photo,
    this.handle = '',
    this.showTotumMark = true,
    this.focus = ShareFocus.balance,
    this.index,
    this.count,
    this.reelFrame = false,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  Size get logicalSize => switch (kind) {
        ShareSlideKind.story => kShareSizeStory,
        ShareSlideKind.landscape => kShareSizeLandscape,
        ShareSlideKind.banner => kShareSizeBanner,
        _ => reelFrame ? kShareSizeStory : kShareSizeFeed,
      };

  /// Pixels exportés : 1080 de large (Instagram), 1200 (paysage), 1024
  /// (bannière).
  double get exportScale => kind == ShareSlideKind.banner ? 2 : kShareExportScale;

  SharePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    Widget body = switch (kind) {
      ShareSlideKind.cover => _cover(),
      ShareSlideKind.overview => _overview(),
      ShareSlideKind.systems => _systems(),
      ShareSlideKind.stars => _stars(),
      ShareSlideKind.vitamins => _panelSlide(NutrientKind.vitamin),
      ShareSlideKind.minerals => _panelSlide(NutrientKind.mineral),
      ShareSlideKind.fats => _fats(),
      ShareSlideKind.ingredients => _ingredients(),
      ShareSlideKind.cta => _cta(),
      ShareSlideKind.story => _story(),
      ShareSlideKind.post => _post(),
      ShareSlideKind.landscape => _landscape(),
      ShareSlideKind.banner => _banner(),
    };
    if (reelFrame && logicalSize == kShareSizeStory && kind != ShareSlideKind.story) {
      body = Column(
        children: [
          const SizedBox(height: 95),
          SizedBox.fromSize(size: kShareSizeFeed, child: body),
          const Spacer(),
        ],
      );
    }
    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          // Police embarquée (pubspec : TotumShare) — jamais la police système.
          style: TextStyle(color: p.text, fontSize: 13, height: 1.25, decoration: TextDecoration.none,
              fontFamily: fontFamily ?? 'TotumShare', fontFamilyFallback: fontFamilyFallback),
          child: SizedBox.fromSize(
            size: logicalSize,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: p.bg)),
                  Positioned(right: -80, top: -80, child: _blob(210, p.accent.withValues(alpha: p.dark ? 0.14 : 0.07))),
                  Positioned(left: -60, bottom: -70, child: _blob(170, p.accent2.withValues(alpha: p.dark ? 0.10 : 0.07))),
                  Positioned.fill(child: body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Briques ──────────────────────────────────────────────────────────

  Widget _blob(double size, Color c) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _kicker(String text, {bool onPhoto = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: onPhoto ? Colors.white.withValues(alpha: 0.92) : p.accentSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.3,
                color: onPhoto && p.dark ? const Color(0xFF14120F) : p.accent)),
      );

  Widget _counter({bool onPhoto = false}) => (index == null || count == null)
      ? const SizedBox.shrink()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: onPhoto ? Colors.black.withValues(alpha: 0.35) : p.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$index/$count',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: onPhoto ? Colors.white : p.textSoft)),
        );

  Widget _top(String kicker) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Row(children: [Flexible(child: _kicker(kicker)), const SizedBox(width: 8), _counter()]),
      );

  Widget _title(String text, {double size = 23, int lines = 2}) => Text(text,
      maxLines: lines, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.6, color: p.text));

  /// Pourcentage au format de la langue (« 64 % » / « 64% »).
  String _pct(double v) => english ? '${v.round()}%' : '${v.round()} %';

  String _refNote() => english
      ? '% of the daily recommended intake for an adult (ANSES), per serving. Values from the Ciqual table (ANSES).'
      : '% de l\'apport conseillé de la journée pour un adulte (ANSES), pour la portion. Valeurs de la table Ciqual (ANSES).';

  /// Anneau de pourcentage : % au centre (plafonné à un tour complet).
  Widget _pctRing(double percent, {double size = 52}) => SizedBox(
        width: size, height: size,
        child: CustomPaint(
          painter: _RingPainter(fraction: (percent / 100).clamp(0.0, 1.0), color: p.accent, track: p.track, stroke: size * 0.1),
          child: Center(
            child: Text(_pct(percent),
                style: TextStyle(fontSize: size * (percent >= 100 ? 0.22 : 0.26), fontWeight: FontWeight.w900, height: 1, color: p.text)),
          ),
        ),
      );

  Widget _totumMark({bool light = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: p.dark || light ? const Color(0xFFFF8A1F) : const Color(0xFFFF7A00), shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(english ? 'Analysed with Totum' : 'Analysé avec Totum',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: light ? Colors.white : p.textSoft)),
      ]);

  /// Pied de page : @compte (si renseigné) à gauche ; mention Totum (si
  /// activée) ou "Fais défiler" à droite.
  Widget _footer({String? right}) {
    final h = handle.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            Expanded(
              child: h.isNotEmpty
                  ? Text(h, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: p.text))
                  : (showTotumMark && right != null
                      ? Align(alignment: Alignment.centerLeft, child: _totumMark())
                      : const SizedBox.shrink()),
            ),
            if (right != null)
              Text(right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: p.accent))
            else if (showTotumMark)
              _totumMark(),
          ],
        ),
      ),
    );
  }

  Widget _foot(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 7),
        child: Text(text, style: TextStyle(fontSize: 7.5, height: 1.3, color: p.textSoft)),
      );

  Widget _photoOrMosaic({required double height, double radius = 22, Alignment plateAlign = Alignment.center}) {
    final img = photo;
    if (img != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(height: height, width: double.infinity, child: RawImage(image: img, fit: BoxFit.cover)),
      );
    }
    // Sans photo (31/10/2026) : une assiette stylisée vue du dessus — les
    // pictogrammes des ALIMENTS du repas disposés en cercle, l'ingrédient
    // principal (le plus lourd) au centre.
    final emojis = data.items.map((e) => e.emoji).toSet().take(7).toList();
    if (emojis.isEmpty) emojis.add('🍽️');
    final plate = height * 0.72;
    final around = emojis.skip(1).toList();
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [p.accentSoft, Color.lerp(p.accentSoft, p.accent2, 0.35)!],
        ),
      ),
      alignment: plateAlign,
      child: SizedBox(
        width: plate, height: plate,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.card,
                  border: Border.all(color: p.track, width: plate * 0.045),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: p.dark ? 0.35 : 0.10),
                        blurRadius: 18, offset: const Offset(0, 8)),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(emojis.first, style: TextStyle(fontSize: plate * (around.isEmpty ? 0.42 : 0.3))),
            ),
            for (var i = 0; i < around.length; i++)
              Align(
                alignment: Alignment(
                  0.6 * math.cos(-math.pi / 2 + 2 * math.pi * i / around.length),
                  0.6 * math.sin(-math.pi / 2 + 2 * math.pi * i / around.length),
                ),
                child: Text(around[i], style: TextStyle(fontSize: plate * 0.17)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, {Color? color}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              FittedBox(
                child: Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, height: 1, color: color ?? p.text)),
              ),
              const SizedBox(height: 3),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: p.textSoft)),
            ],
          ),
        ),
      );

  Widget _ring(NutrientHighlight h, {double size = 62, bool showSource = true}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pctRing(h.percent, size: size),
        const SizedBox(height: 4),
        Text(h.label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: TextStyle(fontSize: math.max(7.0, size * 0.165), fontWeight: FontWeight.w800, height: 1.1)),
        if (showSource && h.topSourceName != null)
          Text('${h.topSourceEmoji ?? ''} ${h.topSourceName}', maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: size * 0.14, fontWeight: FontWeight.w600, color: p.textSoft)),
      ],
    );
  }

  Widget _bar(double fraction, {double height = 7, Color? color}) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: height,
          color: p.track,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            heightFactor: 1,
            child: ColoredBox(color: color ?? p.accent),
          ),
        ),
      );

  // ── 1. Couverture ────────────────────────────────────────────────────

  Widget _cover() {
    final hook = hookFor(data, english: english, focus: focus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 184,
          child: Stack(
            children: [
              Positioned.fill(child: _photoOrMosaic(height: 184, radius: 0, plateAlign: const Alignment(0, 0.9))),
              if (photo != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: const [0.55, 1],
                      colors: [p.bg.withValues(alpha: 0), p.bg],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22, right: 22, top: 20,
                child: Row(children: [
                  Flexible(child: _kicker(data.title, onPhoto: true)),
                  const SizedBox(width: 8),
                  _counter(onPhoto: photo != null),
                ]),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 2, 22, 0), child: _title(hook.headline, size: 22.5, lines: 3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Text(hook.subline, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.textSoft)),
        ),
        _starPills(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            for (final (i, st) in _coverStats().indexed) ...[
              if (i > 0) const SizedBox(width: 7),
              _stat(st.$1, st.$2, color: i == 0 ? p.accent : null),
            ],
          ]),
        ),
        _footer(right: count != null ? (english ? 'Swipe  →' : 'Fais défiler  →') : null),
      ],
    );
  }

  /// Les 3 stars du repas en pastilles (nom complet + %), sous l'accroche.
  Widget _starPills() {
    final hs = data.highlights(english: english, max: 3, focus: focus);
    if (hs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 0),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        for (final h in hs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: p.track),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(h.label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 5),
              Text(_pct(h.percent), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: p.accent)),
            ]),
          ),
      ]),
    );
  }

  /// Les 3 chiffres de la couverture, selon l'angle choisi.
  List<(String, String)> _coverStats() {
    final kcal = (fmtNum(data.kcal, english: english), 'kcal');
    final prot = ('${data.protein.round()} g', l10n.shareProteinShort);
    final fib = ('${data.fiber.round()} g', l10n.shareFiber);
    switch (focus) {
      case ShareFocus.sport:
        return [kcal, prot, ('${data.carbs.round()} g', l10n.shareCarbsShort)];
      case ShareFocus.satiety:
        return [kcal, prot, fib];
      case ShareFocus.longevity:
        final raw = data.rawShare;
        return [
          ('${data.plantCount}', english ? 'plants' : 'végétaux'),
          fib,
          raw != null
              ? ('${(raw * 100).round()} %', english ? 'raw foods' : 'aliments bruts')
              : (fmtNum(data.epaDhaMg, english: english), 'mg ω3'),
        ];
      case ShareFocus.balance:
        return [kcal, prot, fib];
    }
  }

  // ── 2. L'énergie ─────────────────────────────────────────────────────

  Widget _overview() {
    final split = data.energySplit;
    final eggs = data.equivalent('protein');
    final sugars = data.micros['Sucres_g_100g'] ?? 0;
    final sat = data.micros['AG_saturés_g_100g'] ?? 0;
    final rows = [
      (l10n.shareProtein, data.protein, split.protein, p.accent,
          eggs == null ? '' : (english ? ' · ≈ ${eggs.count.round()} eggs 🥚' : ' · ≈ ${eggs.count.round()} œufs 🥚')),
      (l10n.shareCarbs, data.carbs, split.carbs, p.accent2,
          english ? ' · sugars ${fmtNum(sugars, english: true)} g' : ' · dont sucres ${fmtNum(sugars)} g'),
      (l10n.shareFat, data.fat, split.fat, Color.lerp(p.accent, p.track, 0.55)!,
          english ? ' · saturated ${fmtNum(sat, decimals: 1, english: true)} g' : ' · dont saturées ${fmtNum(sat, decimals: 1)} g'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(l10n.shareKickerMacros),
        Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 0), child: _title(l10n.shareMacrosTitle)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              SizedBox(
                width: 132, height: 132,
                child: CustomPaint(
                  painter: _DonutPainter(fractions: [split.protein, split.carbs, split.fat],
                      colors: [for (final r in rows) r.$4], track: p.track),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(fmtNum(data.kcal, english: english),
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1, color: p.text)),
                      Text('kcal', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.textSoft)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(width: 9, height: 9,
                                decoration: BoxDecoration(color: r.$4, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                            Text('${r.$2.round()} g', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          ]),
                          const SizedBox(height: 3),
                          _bar(r.$3, height: 6, color: r.$4),
                          const SizedBox(height: 2),
                          Text('${l10n.shareEnergyShare((r.$3 * 100).round())}${r.$5}',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 8.5, color: p.textSoft, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: Text(l10n.shareFiber, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800))),
              Text('${data.fiber.round()} g', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Text(l10n.shareOfEfsaFiber((data.fiber / kRefFiberG * 100).round()),
                  style: TextStyle(fontSize: 9.5, color: p.textSoft, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const Spacer(flex: 2),
        _foot(l10n.shareMacrosFootnote),
        _footer(),
      ],
    );
  }

  // ── 3. Ton corps : les grandes fonctions nourries ───────────────────

  IconData _systemIcon(BodySystem s) => switch (s) {
        BodySystem.brain => Icons.psychology_outlined,
        BodySystem.energy => Icons.bolt,
        BodySystem.immunity => Icons.shield_outlined,
        BodySystem.bones => Icons.accessibility_new,
        BodySystem.heart => Icons.favorite_border,
        BodySystem.hormones => Icons.science_outlined,
        BodySystem.cells => Icons.eco_outlined,
        BodySystem.skin => Icons.visibility_outlined,
      };

  Widget _systemTile(BodySystemScore s) => Container(
        padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(
              width: 26, height: 26,
              child: CustomPaint(
                painter: _RingPainter(fraction: (s.coverage / 100).clamp(0.0, 1.0), color: p.accent, track: p.track, stroke: 3.5),
                child: Center(child: Icon(_systemIcon(s.system), size: 12.5, color: p.accent)),
              ),
            ),
            const Spacer(),
            Text(_pct(s.coverage), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, height: 1, color: p.text)),
          ]),
          const SizedBox(height: 3),
          Text(bodySystemLabel(s.system, english), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.8, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 1),
          Text(s.top.isEmpty ? '—' : s.top.map((h) => h.label).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 7.8, fontWeight: FontWeight.w700, color: p.textSoft)),
        ]),
      );

  Widget _systems() {
    final sys = data.bodySystems(english: english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(english ? 'Your body' : 'Ton corps'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(english ? 'What this meal brings to your body' : 'Ce que ce repas apporte à ton corps', size: 21),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(children: [
            for (var r = 0; r * 2 < sys.length; r++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  Expanded(child: _systemTile(sys[r * 2])),
                  const SizedBox(width: 7),
                  Expanded(child: r * 2 + 1 < sys.length ? _systemTile(sys[r * 2 + 1]) : const SizedBox.shrink()),
                ]),
              ),
          ]),
        ),
        const Spacer(),
        _foot(english
            ? 'Average coverage of the nutrients that contribute to each function (EU-authorised health claims, Reg. 432/2012), as % of the adult recommended intake (ANSES).'
            : 'Couverture moyenne des nutriments qui contribuent à chaque fonction (allégations de santé autorisées dans l\'UE, règlement 432/2012), en % de l\'apport conseillé adulte (ANSES).'),
        _footer(),
      ],
    );
  }

  // ── 4. Les stars de l'assiette, et d'où elles viennent ───────────────

  static const _segmentAlphas = [1.0, 0.62, 0.38, 0.22];

  Widget _contributionBar(List<({MealShareItem item, double share})> parts) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 8,
          child: Row(children: [
            for (var i = 0; i < parts.length && i < 4; i++)
              Expanded(
                flex: math.max(1, (parts[i].share * 1000).round()),
                child: Container(
                  margin: EdgeInsets.only(right: i < parts.length - 1 ? 1.5 : 0),
                  color: p.accent.withValues(alpha: _segmentAlphas[i]),
                ),
              ),
          ]),
        ),
      );

  Widget _starCard(NutrientHighlight h) {
    final parts = data.contributions(h.def).where((c) => c.share >= 0.01).take(4).toList();
    final eq = data.equivalent(h.key);
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _pctRing(h.percent, size: 52),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, height: 1.1)),
            Text(h.def.title(english), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: p.accent)),
            const SizedBox(height: 5),
            _contributionBar(parts),
            const SizedBox(height: 3),
            Text(
              parts.take(3).map((c) => '${c.item.emoji} ${c.item.name} ${_pct(c.share * 100)}').join('   '),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 7.8, fontWeight: FontWeight.w700, color: p.textSoft),
            ),
            if (eq != null)
              Text(
                english
                    ? '≈ as much as ${eq.count.round()} ${eq.eq.unitEn} ${eq.eq.emoji}'
                    : '≈ autant que ${eq.count.round()} ${eq.eq.unitFr} ${eq.eq.emoji}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8.2, fontWeight: FontWeight.w800),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _stars() {
    final hs = data.highlights(english: english, max: 3, focus: focus);
    final missing = data.itemsWithoutMicroData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(english ? 'Star nutrients' : 'Les stars de l\'assiette'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(english ? 'Its strong points, and where they come from' : 'Ses points forts, et d\'où ils viennent', size: 20),
        ),
        const Spacer(),
        if (hs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(l10n.shareNoMicroHighlight,
                style: TextStyle(fontSize: 13, color: p.textSoft, fontWeight: FontWeight.w600)),
          )
        else
          for (final h in hs) _starCard(h),
        const Spacer(),
        if (missing > 0)
          _foot(english
              ? '$missing ingredient(s) without micronutrient data: values are underestimated.'
              : '$missing ingrédient(s) sans données de micronutriments : valeurs sous-estimées.'),
        _foot(_refNote()),
        _footer(),
      ],
    );
  }

  // ── 5-6. Tableaux complets : vitamines, minéraux ────────────────────

  Widget _panelSlide(NutrientKind kind) {
    final rows = data.panel(kind, english: english);
    final vit = kind == NutrientKind.vitamin;
    final rowH = vit ? 21.0 : 31.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(vit ? (english ? 'Vitamins' : 'Vitamines') : (english ? 'Minerals' : 'Minéraux')),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 2),
          child: _title(vit
              ? (english ? 'Every vitamin, at a glance' : 'Toutes les vitamines, d\'un coup d\'œil')
              : (english ? 'Every mineral, at a glance' : 'Tous les minéraux, d\'un coup d\'œil'), size: 20),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Text(english ? '% of the daily recommended intake' : '% de l\'apport conseillé de la journée',
              style: TextStyle(fontSize: 10.5, color: p.textSoft, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [
            for (final h in rows)
              SizedBox(
                height: rowH,
                child: Row(children: [
                  SizedBox(
                    width: 112,
                    child: Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: vit ? 9.8 : 11, fontWeight: FontWeight.w800)),
                  ),
                  Expanded(
                    child: _bar(h.percent / 100,
                        height: vit ? 8 : 10,
                        color: h.percent >= 100
                            ? p.accent
                            : h.percent >= 25
                                ? p.accent.withValues(alpha: 0.7)
                                : p.accent.withValues(alpha: 0.35)),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(_pct(h.percent), textAlign: TextAlign.right,
                        style: TextStyle(fontSize: vit ? 10 : 11.5, fontWeight: FontWeight.w900,
                            color: h.percent >= 25 ? p.text : p.textSoft)),
                  ),
                ]),
              ),
          ]),
        ),
        const Spacer(),
        _foot(_refNote()),
        _footer(),
      ],
    );
  }

  // ── 7. Les bonnes graisses ───────────────────────────────────────────

  Widget _fats() {
    final fa = data.fattyAcids;
    final ratio = fa.laAlaRatio;
    final ratioOk = ratio != null && ratio <= kMaxLaAlaRatio;
    final sat = data.micros['AG_saturés_g_100g'] ?? 0;
    final satShare = data.kcal > 0 ? sat * 9 / data.kcal * 100 : 0.0;
    Widget row(String label, String amount, double frac, String hint) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
              child: Icon(Icons.water_drop, size: 15, color: p.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                  Text(amount, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 4),
                _bar(frac),
                const SizedBox(height: 2),
                Text(hint, style: TextStyle(fontSize: 8.5, color: p.textSoft, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        );
    String pct(double v, double ref) => _pct(v / ref * 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(english ? 'Good fats' : 'Les bonnes graisses'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(english ? 'The fats your body can\'t make' : 'Les graisses que ton corps ne fabrique pas', size: 21),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [
            row(english ? 'Marine omega-3 (EPA+DHA)' : 'Oméga-3 marins (EPA+DHA)', '${fmtNum(fa.epaDhaMg, english: english)} mg',
                fa.epaDhaMg / kRefEpaDhaMg,
                english ? '${pct(fa.epaDhaMg, kRefEpaDhaMg)} of the 500 mg a day · heart & brain' : '${pct(fa.epaDhaMg, kRefEpaDhaMg)} des 500 mg par jour · cœur et cerveau'),
            row(english ? 'Plant omega-3 (ALA)' : 'Oméga-3 végétal (ALA)', '${fmtNum(fa.alaG, decimals: 1, english: english)} g', fa.alaG / kRefAlaG,
                english ? '${pct(fa.alaG, kRefAlaG)} of the 2.2 g a day · flax, walnut, rapeseed' : '${pct(fa.alaG, kRefAlaG)} des 2,2 g par jour · lin, noix, colza'),
            row(english ? 'Omega-6' : 'Oméga-6', '${fmtNum(fa.laG, decimals: 1, english: english)} g', fa.laG / kRefLaG,
                english ? '${pct(fa.laG, kRefLaG)} of the 8.9 g a day · to balance with omega-3' : '${pct(fa.laG, kRefLaG)} des 8,9 g par jour · à équilibrer avec les oméga-3'),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ratioOk ? p.accent : p.card, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(english ? 'OMEGA-6 / OMEGA-3' : 'OMÉGA-6 / OMÉGA-3',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.0,
                        color: ratioOk ? Colors.white.withValues(alpha: 0.85) : p.textSoft)),
                Text(ratio == null ? '—' : fmtNum(ratio, decimals: 1, english: english),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.05,
                        color: ratioOk ? Colors.white : p.text)),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  ratio == null
                      ? (english ? 'Not enough data on this plate.' : 'Pas assez de données sur cette assiette.')
                      : ratioOk
                          ? (english ? '✓ Within the recommended balance (below 5).' : '✓ Dans l\'équilibre recommandé (moins de 5).')
                          : (english ? 'Above the recommended balance (below 5): add flax, walnuts or rapeseed oil.'
                              : 'Au-dessus de l\'équilibre recommandé (moins de 5) : ajoute lin, noix ou huile de colza.'),
                  style: TextStyle(fontSize: 10, height: 1.25, fontWeight: FontWeight.w700,
                      color: ratioOk ? Colors.white : p.text),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            english
                ? 'Saturated fats: ${fmtNum(sat, decimals: 1, english: true)} g, i.e. ${satShare.round()}% of the energy (benchmark: under 12%).'
                : 'Graisses saturées : ${fmtNum(sat, decimals: 1)} g, soit ${satShare.round()} % de l\'énergie (repère : moins de 12 %).',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: p.textSoft),
          ),
        ),
        const Spacer(),
        _foot(english ? 'ANSES guidelines for adults (2,000 kcal).' : 'Repères ANSES pour un adulte (2 000 kcal).'),
        _footer(),
      ],
    );
  }

  // ── 8. Dans l'assiette : chaque aliment et son atout ─────────────────

  /// L'atout d'un ingrédient : le nutriment pertinent dont il apporte la
  /// plus grande part (au moins 35 %) dans ce repas.
  String? _superpower(MealShareItem it) {
    NutrientHighlight? best;
    double bestShare = 0, bestScore = 0;
    for (final h in data.highlights(english: english, max: 10, focus: focus)) {
      final total = h.amount;
      if (total <= 0) continue;
      final share = h.def.amount(it.micros) / total;
      final score = share * nutrientRelevance(h, focus: focus);
      if (share >= 0.35 && score > bestScore) {
        best = h;
        bestShare = share;
        bestScore = score;
      }
    }
    if (best == null) return null;
    return english
        ? 'Asset: ${lowerFirst(best.label)} · ${_pct(bestShare * 100)} of the total'
        : 'Atout : ${lowerFirst(best.label)} · ${_pct(bestShare * 100)} du total';
  }

  Widget _ingredients() {
    final shown = data.items.take(maxIngredientsOnSlide(data.items.length)).toList();
    final more = data.items.length - shown.length;
    final totalG = data.items.fold<double>(0, (a, e) => a + e.grams);
    final compact = shown.length > 6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(l10n.shareKickerRecipe),
        Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 0), child: _title(l10n.shareIngredientsTitle)),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
          child: Text(l10n.shareIngredientsSubtitle(totalG.round()),
              style: TextStyle(fontSize: 11, color: p.textSoft, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.track),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28, alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
                      child: Text(shown[i].emoji, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(shown[i].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        Text(_superpower(shown[i]) ?? '${fmtNum(shown[i].kcal, english: english)} kcal',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 8.6, fontWeight: FontWeight.w700,
                                color: _superpower(shown[i]) != null ? p.accent : p.textSoft)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${fmtNum(shown[i].grams, english: english)} g',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: p.text)),
                      Text('${fmtNum(shown[i].kcal, english: english)} kcal',
                          style: TextStyle(fontSize: 8.2, fontWeight: FontWeight.w600, color: p.textSoft)),
                    ]),
                  ]),
                ),
              ],
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Text(l10n.shareMoreIngredients(more),
                      style: TextStyle(fontSize: 10.5, color: p.textSoft, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ),
        const Spacer(),
        _footer(),
      ],
    );
  }

  // ── 9. L'essentiel + à compléter + appel à l'action ─────────────────

  Widget _cta() {
    final ins = insightsFor(data, english: english, focus: focus);
    final gaps = data.gaps(english: english, max: 2);
    final h = handle.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(l10n.shareKickerNaturo),
        Padding(padding: const EdgeInsets.fromLTRB(22, 10, 22, 4), child: _title(l10n.shareNaturoTitle, size: 20)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [
            for (final t in ins)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 18, height: 18, alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                    child: const Text('✓', style: TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.25))),
                ]),
              ),
          ]),
        ),
        if (gaps.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  data.isFullDay
                      ? (english ? 'TO STRENGTHEN TOMORROW' : 'À RENFORCER DEMAIN')
                      : (english ? 'TO ROUND OFF THE DAY' : 'POUR COMPLÉTER LA JOURNÉE'),
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: p.accent),
                ),
                for (final g in gaps)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${g.label} : ', style: const TextStyle(fontWeight: FontWeight.w900)),
                        TextSpan(text: g.def.foods(english)),
                      ]),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ),
              ]),
            ),
          ),
        ],
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _stat(fmtNum(data.kcal, english: english), 'kcal', color: p.accent),
            const SizedBox(width: 6),
            _stat('${data.protein.round()} g', l10n.shareProteinShort),
            const SizedBox(width: 6),
            _stat('${data.fiber.round()} g', l10n.shareFiber),
            const SizedBox(width: 6),
            _stat('${data.essentialsAtLeast(25)}/${essentialNutrients.length}', english ? 'essentials' : 'essentiels'),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(18)),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.shareCtaSave, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, height: 1.15)),
                const SizedBox(height: 3),
                Text(l10n.shareCtaSend, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.25)),
                if (h.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(english ? 'More decoded plates on $h' : 'D\'autres assiettes décryptées sur $h',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _foot(_refNote()),
        _footer(),
      ],
    );
  }

  // ── Post unique, story, paysage, bannière ────────────────────────────

  Widget _post() {
    final hs = data.highlights(english: english, max: 3, focus: focus);
    final hook = hookFor(data, english: english, focus: focus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          child: Stack(children: [
            Positioned.fill(child: _photoOrMosaic(height: 190, radius: 0)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: const [0.5, 1], colors: [p.bg.withValues(alpha: 0), p.bg]),
                ),
              ),
            ),
            Positioned(left: 22, right: 22, top: 20, child: Align(alignment: Alignment.centerLeft, child: _kicker(data.title, onPhoto: true))),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 0), child: _title(hook.headline, size: 17.5, lines: 3)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _stat(fmtNum(data.kcal, english: english), 'kcal', color: p.accent),
            const SizedBox(width: 6),
            _stat('${data.protein.round()} g', l10n.shareProteinShort),
            const SizedBox(width: 6),
            _stat('${data.carbs.round()} g', l10n.shareCarbsShort),
            const SizedBox(width: 6),
            _stat('${data.fat.round()} g', l10n.shareFatShort),
          ]),
        ),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final h in hs) SizedBox(width: 100, child: _ring(h, size: 50, showSource: false)),
        ]),
        const Spacer(),
        _footer(),
      ],
    );
  }

  Widget _story() {
    final hs = data.highlights(english: english, max: 3, focus: focus);
    final hook = hookFor(data, english: english, focus: focus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30), // barre de profil Instagram
        Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 0), child: _kicker(data.title)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: LayoutBuilder(builder: (_, c) => _photoOrMosaic(height: c.maxHeight, radius: 26)),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 14, 22, 0), child: _title(hook.headline, size: 22, lines: 3)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _stat(fmtNum(data.kcal, english: english), 'kcal', color: p.accent),
            const SizedBox(width: 6),
            _stat('${data.protein.round()} g', l10n.shareProteinShort),
            const SizedBox(width: 6),
            _stat('${data.fiber.round()} g', l10n.shareFiber),
          ]),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final h in hs) SizedBox(width: 105, child: _ring(h, size: 54)),
        ]),
        const SizedBox(height: 10),
        _footer(),
        const SizedBox(height: 80), // zone de réponse/légende Instagram
      ],
    );
  }

  /// Paysage 1200 × 630 : site web, Facebook, LinkedIn, aperçu de lien.
  Widget _landscape() {
    final hs = data.highlights(english: english, max: 3, focus: focus);
    final hook = hookFor(data, english: english, focus: focus);
    return Row(children: [
      SizedBox(width: 170, child: _photoOrMosaic(height: 210, radius: 0)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kicker(data.title),
            const SizedBox(height: 8),
            Text(hook.headline, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.3, color: p.text)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (final h in hs) SizedBox(width: 62, child: _ring(h, size: 34, showSource: false)),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                child: Text('${fmtNum(data.kcal, english: english)} kcal · ${data.protein.round()} g ${english ? 'protein' : 'prot.'}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: p.accent)),
              ),
              if (showTotumMark) ...[const SizedBox(width: 6), _totumMark()],
            ]),
          ]),
        ),
      ),
    ]);
  }

  /// Bannière 1024 × 500 : en-tête de site, couverture, fiche Play Store.
  /// Aucun texte essentiel dans les bords (recadrage possible).
  Widget _banner() {
    final hs = data.highlights(english: english, max: 3, focus: focus);
    final hook = hookFor(data, english: english, focus: focus);
    return Row(children: [
      Expanded(
        flex: 11,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 12, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kicker(data.title),
            const SizedBox(height: 12),
            Text(hook.headline, maxLines: 4, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.5, color: p.text)),
            const SizedBox(height: 8),
            Text(hook.subline, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w600, color: p.textSoft)),
            const Spacer(),
            if (showTotumMark) _totumMark(),
          ]),
        ),
      ),
      Expanded(
        flex: 9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 22, 18),
          child: Stack(children: [
            Positioned.fill(
              child: photo != null
                  ? _photoOrMosaic(height: 214, radius: 22)
                  : Column(children: [
                      Expanded(child: LayoutBuilder(builder: (_, c) => _photoOrMosaic(height: c.maxHeight, radius: 22))),
                      const SizedBox(height: 74),
                    ]),
            ),
            Positioned(
              left: 8, right: 8, bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: p.card.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (final h in hs) SizedBox(width: 58, child: _ring(h, size: 30, showSource: false)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double fraction, stroke;
  final Color color, track;
  _RingPainter({required this.fraction, required this.color, required this.track, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track);
    if (fraction <= 0) return;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track || old.stroke != stroke;
}

class _DonutPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  final Color track;
  _DonutPainter({required this.fractions, required this.colors, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.15;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track);
    var start = -math.pi / 2;
    const gap = 0.05;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * math.pi * 2;
      if (sweep <= gap) continue;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fractions != fractions || old.colors != colors || old.track != track;
}
