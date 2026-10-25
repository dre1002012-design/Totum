// lib/widgets/meal_share_slides.dart
//
// Visuels Instagram d'un repas (voir services/meal_share.dart pour les
// données et leurs sources). Widgets PURS : aucune dépendance au thème de
// l'app ni à un ancêtre Localizations — ils sont rendus hors écran à la
// taille exacte attendue par Instagram (voir meal_share_screen.dart).
//
// Tailles logiques ×3 = pixels exportés :
// - carrousel / post : 360 × 450 -> 1080 × 1350 (4:5). Le contenu important
//   reste à ≥ 20 px des bords gauche/droit : la grille du profil recadre
//   désormais chaque post en 3:4 (1080 × 1440 visibles sur une largeur de
//   1012 px pour un 4:5), on ne perd donc rien d'essentiel en vignette.
// - story / images de Reel : 360 × 640 -> 1080 × 1920 (9:16), zones de
//   sécurité haut (~60 px logiques) et bas (~110 px) laissées libres de
//   tout texte essentiel (barre de profil et légende d'Instagram).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/meal_share.dart';

const Size kShareSizeFeed = Size(360, 450);
const Size kShareSizeStory = Size(360, 640);
const double kShareExportScale = 3; // 360 -> 1080 px

/// Palette d'un visuel — 3 ambiances, toutes construites sur l'accent
/// unique de la charte Totum (aucune nouvelle teinte de marque).
class SharePalette {
  final String id;
  final Color bg, card, text, textSoft, accent, accentSoft, track;
  const SharePalette({
    required this.id, required this.bg, required this.card, required this.text,
    required this.textSoft, required this.accent, required this.accentSoft, required this.track,
  });

  static const cream = SharePalette(
    id: 'cream', bg: Color(0xFFFBF6EF), card: Colors.white, text: Color(0xFF1E1A16),
    textSoft: Color(0xFF6F655B), accent: Color(0xFFFF7A00), accentSoft: Color(0xFFFFE7CC),
    track: Color(0xFFF1E7DB),
  );
  static const night = SharePalette(
    id: 'night', bg: Color(0xFF15130F), card: Color(0xFF221F1A), text: Color(0xFFF7F2EA),
    textSoft: Color(0xFFB9AE9F), accent: Color(0xFFFF8A1F), accentSoft: Color(0xFF3A2A18),
    track: Color(0xFF34302A),
  );
  static const sage = SharePalette(
    id: 'sage', bg: Color(0xFFEEF2EA), card: Colors.white, text: Color(0xFF1C2419),
    textSoft: Color(0xFF5D6B58), accent: Color(0xFFFF7A00), accentSoft: Color(0xFFDDE6D6),
    track: Color(0xFFDCE3D6),
  );
  static const all = [cream, sage, night];
}

enum ShareSlideKind { cover, macros, micros, ingredients, naturo, story, post }

/// Les 5 visuels d'un carrousel, dans l'ordre (accroche -> valeur ->
/// appel à l'action) — structure "1 idée par visuel" des carrousels les plus
/// enregistrés.
const carouselKinds = [
  ShareSlideKind.cover,
  ShareSlideKind.macros,
  ShareSlideKind.micros,
  ShareSlideKind.ingredients,
  ShareSlideKind.naturo,
];

class MealShareSlide extends StatelessWidget {
  final ShareSlideKind kind;
  final MealShareData data;
  final SharePalette palette;
  final AppLocalizations l10n;
  final bool english;
  final ui.Image? photo;
  final String handle;
  final bool showTotumMark;
  /// Position dans le carrousel (1-based) et nombre de visuels ; `null` hors
  /// carrousel (post unique, story).
  final int? index;
  final int? count;
  /// Visuel de carrousel posé dans un cadre 9:16 (images pour un Reel).
  final bool reelFrame;
  /// Police explicite (tests de capture uniquement) ; `null` = police
  /// système de la plateforme, comme le reste de l'app.
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
    this.index,
    this.count,
    this.reelFrame = false,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  Size get logicalSize =>
      (kind == ShareSlideKind.story || reelFrame) ? kShareSizeStory : kShareSizeFeed;

  @override
  Widget build(BuildContext context) {
    final pal = palette;
    Widget body = switch (kind) {
      ShareSlideKind.cover => _cover(),
      ShareSlideKind.macros => _macros(),
      ShareSlideKind.micros => _micros(),
      ShareSlideKind.ingredients => _ingredients(),
      ShareSlideKind.naturo => _naturo(),
      ShareSlideKind.story => _story(),
      ShareSlideKind.post => _post(),
    };
    if (reelFrame && kind != ShareSlideKind.story) {
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
          style: TextStyle(color: pal.text, fontSize: 13, height: 1.25, decoration: TextDecoration.none,
              fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
          child: SizedBox.fromSize(
            size: logicalSize,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: pal.bg)),
                  // Motif discret de marque : 2 cercles d'accent très doux.
                  Positioned(
                    right: -70, top: -70,
                    child: _blob(190, pal.accent.withValues(alpha: 0.10)),
                  ),
                  Positioned(
                    left: -50, bottom: -60,
                    child: _blob(150, pal.accent.withValues(alpha: 0.07)),
                  ),
                  Positioned.fill(child: body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color c) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  // ── Éléments communs ─────────────────────────────────────────────────

  Widget _topBar({String? kicker}) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Row(
          children: [
            if (kicker != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(99)),
                child: Text(kicker.toUpperCase(),
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800,
                        letterSpacing: 1.1, color: palette.accent)),
              ),
            const Spacer(),
            if (index != null && count != null)
              Text('$index/$count',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textSoft)),
          ],
        ),
      );

  Widget _footer({bool swipe = false}) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(handle.trim(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: palette.text)),
            ),
            if (swipe)
              Text(english ? 'Swipe  →' : 'Fais défiler  →',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: palette.accent))
            else if (showTotumMark)
              Text(english ? 'Computed with Totum' : 'Calculé avec Totum',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: palette.textSoft)),
          ],
        ),
      );

  Widget _title(String text, {double size = 22}) => Text(text,
      maxLines: 2, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1.08,
          letterSpacing: -0.4, color: palette.text));

  Widget _photoOrMosaic({required double height, double radius = 22}) {
    final img = photo;
    if (img != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height, width: double.infinity,
          child: RawImage(image: img, fit: BoxFit.cover),
        ),
      );
    }
    // Sans photo : mosaïque des pictogrammes des ingrédients.
    final emojis = data.items.map((e) => e.emoji).toSet().take(6).toList();
    if (emojis.isEmpty) emojis.add('🍽️');
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10, runSpacing: 6,
        children: [for (final e in emojis) Text(e, style: TextStyle(fontSize: emojis.length <= 3 ? 52 : 40))],
      ),
    );
  }

  Widget _kcalBlock({double big = 34}) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${data.kcal.round()}',
              style: TextStyle(fontSize: big, fontWeight: FontWeight.w900, height: 0.95,
                  color: palette.accent, letterSpacing: -1)),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('kcal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.text)),
          ),
        ],
      );

  Widget _macroChip(String label, double grams) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${grams.round()} g', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: palette.textSoft)),
          ],
        ),
      );

  Widget _macroRow() => Row(
        children: [
          _kcalBlock(),
          const Spacer(),
          _macroChip(l10n.shareProteinShort, data.protein),
          const SizedBox(width: 6),
          _macroChip(l10n.shareCarbsShort, data.carbs),
          const SizedBox(width: 6),
          _macroChip(l10n.shareFatShort, data.fat),
        ],
      );

  Widget _microBar(NutrientHighlight h, {bool compact = false}) {
    final frac = (h.percent / 100).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 3.5 : 7),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(h.emoji, style: TextStyle(fontSize: compact ? 14 : 16))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(h.label,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: compact ? 11.5 : 12.5, fontWeight: FontWeight.w800)),
                    ),
                    Text('${formatAmount(h.amount, h.unit)} ${h.unit}',
                        style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w600, color: palette.textSoft)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: compact ? 6 : 7,
                    color: palette.track,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: frac,
                      heightFactor: 1,
                      child: ColoredBox(color: palette.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text('${h.percent.round()} %',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w900, color: palette.accent)),
          ),
        ],
      ),
    );
  }

  // ── Visuels ──────────────────────────────────────────────────────────

  Widget _cover() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(kicker: l10n.shareKickerMyPlate),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _photoOrMosaic(height: 208),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: _title(data.title),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 5, 22, 0),
            child: Text(hookFor(data, english: english),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: palette.textSoft)),
          ),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 12), child: _macroRow()),
          _footer(swipe: count != null),
        ],
      );

  Widget _macros() {
    final split = data.energySplit;
    final rows = [
      (l10n.shareProtein, data.protein, split.protein, palette.accent),
      (l10n.shareCarbs, data.carbs, split.carbs, palette.accent.withValues(alpha: 0.55)),
      (l10n.shareFat, data.fat, split.fat, palette.accent.withValues(alpha: 0.28)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(kicker: l10n.shareKickerMacros),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(l10n.shareMacrosTitle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Text(l10n.shareMacrosSubtitle,
              style: TextStyle(fontSize: 11.5, color: palette.textSoft, fontWeight: FontWeight.w600)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              SizedBox(
                width: 136, height: 136,
                child: CustomPaint(
                  painter: _DonutPainter(
                    fractions: [split.protein, split.carbs, split.fat],
                    colors: [for (final r in rows) r.$4],
                    track: palette.track,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${data.kcal.round()}',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: palette.text, height: 1)),
                        Text('kcal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSoft)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10,
                                decoration: BoxDecoration(color: r.$4, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.$1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                  Text(l10n.shareEnergyShare((r.$3 * 100).round()),
                                      style: TextStyle(fontSize: 10, color: palette.textSoft, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Text('${r.$2.round()} g',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.shareFiber,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
                Text('${data.fiber.round()} g',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Text(l10n.shareOfEfsaFiber((data.fiber / kRefFiberG * 100).round()),
                    style: TextStyle(fontSize: 10, color: palette.textSoft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Text(l10n.shareMacrosFootnote,
              style: TextStyle(fontSize: 8.5, color: palette.textSoft)),
        ),
        _footer(),
      ],
    );
  }

  Widget _micros() {
    final hs = data.highlights(english: english, max: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(kicker: l10n.shareKickerMicros),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(l10n.shareMicrosTitle),
        ),
        const SizedBox(height: 10),
        if (hs.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Text(l10n.shareNoMicroHighlight,
                style: TextStyle(fontSize: 13, color: palette.textSoft, fontWeight: FontWeight.w600)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(children: [for (final h in hs) _microBar(h)]),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Text(l10n.shareVnrFootnote, style: TextStyle(fontSize: 8.5, color: palette.textSoft)),
        ),
        _footer(),
      ],
    );
  }

  Widget _ingredients() {
    final shown = data.items.take(maxIngredientsOnSlide(data.items.length)).toList();
    final more = data.items.length - shown.length;
    final totalG = data.items.fold<double>(0, (a, e) => a + e.grams);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(kicker: l10n.shareKickerRecipe),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(l10n.shareIngredientsTitle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
          child: Text(l10n.shareIngredientsSubtitle(totalG.round()),
              style: TextStyle(fontSize: 11.5, color: palette.textSoft, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              for (final it in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28, alignment: Alignment.center,
                        decoration: BoxDecoration(color: palette.card, shape: BoxShape.circle),
                        child: Text(it.emoji, style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            Text('${it.kcal.round()} kcal',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: palette.textSoft)),
                          ],
                        ),
                      ),
                      Text('${it.grams.round()} g',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: palette.accent)),
                    ],
                  ),
                ),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.shareMoreIngredients(more),
                        style: TextStyle(fontSize: 11, color: palette.textSoft, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        _footer(),
      ],
    );
  }

  Widget _naturo() {
    final ins = insightsFor(data, english: english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(kicker: l10n.shareKickerNaturo),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
          child: _title(l10n.shareNaturoTitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              for (final t in ins)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        width: 18, height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                        child: const Text('✓', style: TextStyle(fontSize: 11, height: 1,
                            fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.32))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(color: palette.accent, borderRadius: BorderRadius.circular(18)),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.shareCtaSave, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(l10n.shareCtaSend, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _footer(),
      ],
    );
  }

  Widget _post() {
    final hs = data.highlights(english: english, max: 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(kicker: l10n.shareKickerMyPlate),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _photoOrMosaic(height: 160),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(data.title, size: 20),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 10, 22, 4), child: _macroRow()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [for (final h in hs) _microBar(h, compact: true)]),
        ),
        const Spacer(),
        _footer(),
      ],
    );
  }

  Widget _story() {
    final hs = data.highlights(english: english, max: 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30), // zone de la barre de profil Instagram
        _topBar(kicker: l10n.shareKickerMyPlate),
        // La photo prend toute la hauteur restante : la story est pleine
        // quel que soit le nombre de micronutriments mis en avant.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: LayoutBuilder(
              builder: (_, c) => _photoOrMosaic(height: c.maxHeight, radius: 26),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: _title(data.title, size: 22),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 5, 22, 0),
          child: Text(hookFor(data, english: english),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: palette.textSoft)),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 14, 22, 6), child: _macroRow()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [for (final h in hs) _microBar(h, compact: true)]),
        ),
        const SizedBox(height: 10),
        _footer(),
        const SizedBox(height: 80), // zone de réponse/légende Instagram
      ],
    );
  }
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
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    var start = -math.pi / 2;
    const gap = 0.05;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * math.pi * 2;
      if (sweep <= gap) continue;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fractions != fractions || old.colors != colors || old.track != track;
}
