// lib/widgets/meal_share_slides.dart
//
// Visuels de partage d'un repas / d'une journée (v2, 26/10/2026 — retour
// d'Alex : "plus de modernité, une vraie valeur ajoutée, rivaliser avec les
// meilleurs comptes de naturopathes"). Données et sources :
// services/meal_share.dart. Widgets PURS (aucune dépendance au thème de
// l'app ni à Localizations) : rendus hors écran à la taille exacte.
//
// Structure du carrousel (8 visuels, "une idée par visuel" : accroche ->
// chiffres -> valeur pédagogique -> appel à l'action) :
//  1. Couverture : photo pleine largeur, titre chiffré, 3 chiffres clés
//  2. L'assiette en chiffres : kcal, macros (% de l'énergie), fibres
//  3. Micronutriments en vedette : 6 jauges + source n°1 dans l'assiette
//  4. Acides gras essentiels : ALA, LA, EPA+DHA, rapport oméga-6/oméga-3
//  5. À quoi ils servent : rôles (allégations UE autorisées)
//  6. La recette : ingrédients, quantités, kcal
//  7. À compléter dans la journée : essentiels peu couverts + aliments
//  8. Ce que j'en retiens + appel à l'action (Totum ou compte perso)
//
// Tailles logiques -> pixels exportés :
//  - flux (carrousel, post) : 360 × 450 ×3 = 1080 × 1350 (4:5), marges ≥ 20
//    pour le recadrage 3:4 de la grille du profil ;
//  - story / Reel : 360 × 640 ×3 = 1080 × 1920, zones Instagram libres ;
//  - paysage (site, Facebook, LinkedIn) : 400 × 210 ×3 = 1200 × 630 ;
//  - bannière Play Store (feature graphic) : 512 × 250 ×2 = 1024 × 500.

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

/// Palette d'un visuel. Ambiances "Totum" = charte de l'app (accent orange
/// unique) ; ambiances "Naturo" = tons naturels pour un compte de
/// naturopathe/coach (vert sauge, terracotta), toujours sobres et lisibles.
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
  static const naturoSage = SharePalette(
    id: 'naturo_sage', bg: Color(0xFFEEF1E8), card: Colors.white, text: Color(0xFF1F2A1E),
    textSoft: Color(0xFF5E6B58), accent: Color(0xFF3F6B4F), accentSoft: Color(0xFFDCE6D5),
    track: Color(0xFFDDE3D6), accent2: Color(0xFFC8693F),
  );
  static const naturoLinen = SharePalette(
    id: 'naturo_linen', bg: Color(0xFFF6EFE6), card: Color(0xFFFFFCF8), text: Color(0xFF2B211B),
    textSoft: Color(0xFF7A6A5C), accent: Color(0xFFB85C38), accentSoft: Color(0xFFF1DCCB),
    track: Color(0xFFEADFD2), accent2: Color(0xFF6E8B5E),
  );
  static const all = [totumCream, totumNight, naturoSage, naturoLinen];
}

enum ShareSlideKind {
  cover, overview, micros, fats, roles, ingredients, gaps, cta,
  story, post, landscape, banner,
}

/// Les 8 visuels d'un carrousel, dans l'ordre de lecture.
const carouselKinds = [
  ShareSlideKind.cover,
  ShareSlideKind.overview,
  ShareSlideKind.micros,
  ShareSlideKind.fats,
  ShareSlideKind.roles,
  ShareSlideKind.ingredients,
  ShareSlideKind.gaps,
  ShareSlideKind.cta,
];

class MealShareSlide extends StatelessWidget {
  final ShareSlideKind kind;
  final MealShareData data;
  final SharePalette palette;
  final AppLocalizations l10n;
  final bool english;
  final ui.Image? photo;
  final String handle;
  final ShareBrand brand;
  final bool showTotumMark;
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
    this.brand = ShareBrand.coach,
    this.showTotumMark = true,
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

  /// Pixels exportés : 1080 de large pour les formats Instagram, 1200 pour
  /// le paysage, 1024 pour la bannière Play Store.
  double get exportScale => kind == ShareSlideKind.banner ? 2 : kShareExportScale;

  SharePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    Widget body = switch (kind) {
      ShareSlideKind.cover => _cover(),
      ShareSlideKind.overview => _overview(),
      ShareSlideKind.micros => _micros(),
      ShareSlideKind.fats => _fats(),
      ShareSlideKind.roles => _roles(),
      ShareSlideKind.ingredients => _ingredients(),
      ShareSlideKind.gaps => _gaps(),
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
          style: TextStyle(color: p.text, fontSize: 13, height: 1.25, decoration: TextDecoration.none,
              fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
          child: SizedBox.fromSize(
            size: logicalSize,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: p.bg)),
                  Positioned(right: -80, top: -80, child: _blob(210, p.accent.withValues(alpha: p.dark ? 0.14 : 0.09))),
                  Positioned(left: -60, bottom: -70, child: _blob(170, p.accent2.withValues(alpha: p.dark ? 0.10 : 0.08))),
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
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: p.accent)),
      );

  Widget _counter({bool onPhoto = false}) => (index == null || count == null)
      ? const SizedBox.shrink()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: onPhoto ? Colors.black.withValues(alpha: 0.35) : p.card.withValues(alpha: 0.8),
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

  Widget _brandMark({bool light = false}) {
    final c = light ? Colors.white : p.text;
    if (brand == ShareBrand.totum) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('TOTUM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 2.2, color: c)),
      ]);
    }
    return Text(handle.trim(), maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: c));
  }

  Widget _footer({String? right}) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Row(
          children: [
            Expanded(child: Align(alignment: Alignment.centerLeft, child: _brandMark())),
            if (right != null)
              Text(right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: p.accent))
            else if (showTotumMark && brand == ShareBrand.coach)
              Text(english ? 'Computed with Totum' : 'Calculé avec Totum',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: p.textSoft)),
          ],
        ),
      );

  Widget _foot(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 7),
        child: Text(text, style: TextStyle(fontSize: 7.5, height: 1.3, color: p.textSoft)),
      );

  Widget _photoOrMosaic({required double height, double radius = 22}) {
    final img = photo;
    if (img != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(height: height, width: double.infinity, child: RawImage(image: img, fit: BoxFit.cover)),
      );
    }
    final emojis = data.items.map((e) => e.emoji).toSet().take(6).toList();
    if (emojis.isEmpty) emojis.add('🍽️');
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
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12, runSpacing: 6,
        children: [for (final e in emojis) Text(e, style: TextStyle(fontSize: emojis.length <= 3 ? 54 : 40))],
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
    final frac = (h.percent / 100).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size, height: size,
          child: CustomPaint(
            painter: _RingPainter(fraction: frac, color: p.accent, track: p.track, stroke: size * 0.11),
            child: Center(child: Text(h.emoji, style: TextStyle(fontSize: size * 0.34))),
          ),
        ),
        const SizedBox(height: 4),
        Text('${h.percent.round()} %',
            style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.w900, height: 1, color: p.accent)),
        const SizedBox(height: 2),
        Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: TextStyle(fontSize: size * 0.165, fontWeight: FontWeight.w800, height: 1.1)),
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
    final hook = hookFor(data, english: english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 232,
          child: Stack(
            children: [
              Positioned.fill(child: _photoOrMosaic(height: 232, radius: 0)),
              // Fondu de la photo vers le fond : texte toujours lisible.
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
                  _kicker(data.isFullDay ? (english ? 'My day' : 'Ma journée') : l10n.shareKickerMyPlate, onPhoto: true),
                  const Spacer(),
                  _counter(onPhoto: photo != null),
                ]),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 0), child: _title(hook.headline, size: 24, lines: 3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Text(hook.subline, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.textSoft)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            _stat(fmtNum(data.kcal, english: english), 'kcal', color: p.accent),
            const SizedBox(width: 7),
            _stat('${data.protein.round()} g', english ? 'protein' : 'protéines'),
            const SizedBox(width: 7),
            _stat('${data.essentialsAtLeast(30)}', english ? 'essentials ≥ 30 %' : 'essentiels ≥ 30 %'),
          ]),
        ),
        _footer(right: count != null ? (english ? 'Swipe  →' : 'Fais défiler  →') : null),
      ],
    );
  }

  // ── 2. L'assiette en chiffres ────────────────────────────────────────

  Widget _overview() {
    final split = data.energySplit;
    final rows = [
      (l10n.shareProtein, data.protein, split.protein, p.accent),
      (l10n.shareCarbs, data.carbs, split.carbs, p.accent2),
      (l10n.shareFat, data.fat, split.fat, Color.lerp(p.accent, p.track, 0.55)!),
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
                          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, height: 1, color: p.text)),
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
                            Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                            Text('${r.$2.round()} g', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          ]),
                          const SizedBox(height: 3),
                          _bar(r.$3, height: 6, color: r.$4),
                          const SizedBox(height: 2),
                          Text(l10n.shareEnergyShare((r.$3 * 100).round()),
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
              const Text('🌿', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
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

  // ── 3. Micronutriments en vedette ────────────────────────────────────

  Widget _micros() {
    final hs = data.highlights(english: english, max: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(l10n.shareKickerMicros),
        Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 0), child: _title(l10n.shareMicrosTitle)),
        const Spacer(),
        if (hs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(l10n.shareNoMicroHighlight,
                style: TextStyle(fontSize: 13, color: p.textSoft, fontWeight: FontWeight.w600)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 14,
              children: [for (final h in hs) SizedBox(width: 110, child: _ring(h, size: 64))],
            ),
          ),
        const Spacer(),
        _foot(l10n.shareVnrFootnote),
        _footer(),
      ],
    );
  }

  // ── 4. Acides gras essentiels ────────────────────────────────────────

  Widget _fats() {
    final fa = data.fattyAcids;
    final ratio = fa.laAlaRatio;
    final ratioOk = ratio != null && ratio <= kMaxLaAlaRatio;
    Widget row(String emoji, String label, String amount, double frac, String hint) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 26, child: Text(emoji, style: const TextStyle(fontSize: 16))),
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
    String pct(double v, double ref) => '${(v / ref * 100).round()} %';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(english ? 'Essential fats' : 'Acides gras essentiels'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _title(english ? 'The fats your body can\'t make' : 'Les graisses que ton corps ne fabrique pas', size: 21),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [
            row('🐟', english ? 'Omega-3 EPA+DHA' : 'Oméga-3 EPA+DHA', '${fmtNum(fa.epaDhaMg, english: english)} mg',
                fa.epaDhaMg / kRefEpaDhaMg,
                english ? '${pct(fa.epaDhaMg, kRefEpaDhaMg)} of 500 mg/day · heart, brain' : '${pct(fa.epaDhaMg, kRefEpaDhaMg)} des 500 mg/j · cœur, cerveau'),
            row('🌱', english ? 'Omega-3 ALA' : 'Oméga-3 ALA', '${fmtNum(fa.alaG, decimals: 1, english: english)} g', fa.alaG / kRefAlaG,
                english ? '${pct(fa.alaG, kRefAlaG)} of 2.2 g/day · flax, walnut, rapeseed' : '${pct(fa.alaG, kRefAlaG)} des 2,2 g/j · lin, noix, colza'),
            row('🌻', english ? 'Omega-6 LA' : 'Oméga-6 LA', '${fmtNum(fa.laG, decimals: 1, english: english)} g', fa.laG / kRefLaG,
                english ? '${pct(fa.laG, kRefLaG)} of 8.9 g/day · often in excess' : '${pct(fa.laG, kRefLaG)} des 8,9 g/j · souvent en excès'),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ratioOk ? p.accent : p.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(english ? 'ω6 / ω3 RATIO' : 'RAPPORT ω6 / ω3',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1,
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
                          ? (english ? '✓ Within the ANSES target (< 5). The modern Western diet is often 15 or more.'
                              : '✓ Dans la cible ANSES (< 5). L\'alimentation moderne dépasse souvent 15.')
                          : (english ? 'Above the ANSES target (< 5): add flax, walnuts or rapeseed oil.'
                              : 'Au-dessus de la cible ANSES (< 5) : ajoute lin, noix ou huile de colza.'),
                  style: TextStyle(fontSize: 9.5, height: 1.25, fontWeight: FontWeight.w700,
                      color: ratioOk ? Colors.white : p.text),
                ),
              ),
            ]),
          ),
        ),
        const Spacer(),
        _foot(english
            ? 'References: ANSES 2011 (adult, 2,000 kcal) — ALA 1% of energy, LA 4%, EPA+DHA 500 mg/day.'
            : 'Références : ANSES 2011 (adulte, 2 000 kcal) — ALA 1 % de l\'énergie, LA 4 %, EPA+DHA 500 mg/j.'),
        _footer(),
      ],
    );
  }

  // ── 5. À quoi ils servent ────────────────────────────────────────────

  Widget _roles() {
    final hs = data.highlights(english: english, max: 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(english ? 'Their roles' : 'Leurs rôles'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
          child: _title(english ? 'What they do for you' : 'Ce qu\'ils font pour toi'),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            for (final h in hs)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 32, height: 32, alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
                    child: Text(h.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text('${h.label} · ${h.def.title(english)}', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                        ),
                        Text('${h.percent.round()} %',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: p.accent)),
                      ]),
                      const SizedBox(height: 2),
                      Text(h.def.role(english), maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, height: 1.3, color: p.textSoft, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        const Spacer(),
        _foot(english
            ? 'Authorised EU health claims (Regulation (EU) 432/2012). A varied diet and a healthy lifestyle matter.'
            : 'Allégations de santé autorisées (règlement UE 432/2012). Une alimentation variée et un mode de vie sain sont importants.'),
        _footer(),
      ],
    );
  }

  // ── 6. La recette ────────────────────────────────────────────────────

  Widget _ingredients() {
    final shown = data.items.take(maxIngredientsOnSlide(data.items.length)).toList();
    final more = data.items.length - shown.length;
    final totalG = data.items.fold<double>(0, (a, e) => a + e.grams);
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
                  padding: const EdgeInsets.symmetric(vertical: 5),
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
                        Text('${shown[i].kcal.round()} kcal',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: p.textSoft)),
                      ]),
                    ),
                    Text('${shown[i].grams.round()} g',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: p.accent)),
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

  // ── 7. À compléter dans la journée ───────────────────────────────────

  Widget _gaps() {
    final gaps = data.gaps(english: english, max: 3);
    final covered = data.covered(english: english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(english ? 'Balance' : 'L\'équilibre'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
          child: _title(gaps.isEmpty
              ? (english ? 'A remarkably complete plate' : 'Une assiette remarquablement complète')
              : data.isFullDay
                  ? (english ? 'To strengthen tomorrow' : 'À renforcer demain')
                  : (english ? 'To round it off at your other meals' : 'À compléter dans tes autres repas'), size: 21),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
          child: Text(
            english
                ? 'Well chosen, real food covers almost all your needs.'
                : 'Bien choisie, l\'alimentation couvre presque tous tes besoins.',
            style: TextStyle(fontSize: 11, color: p.textSoft, fontWeight: FontWeight.w700),
          ),
        ),
        // Déjà couverts : la preuve visuelle que l'alimentation suffit.
        if (covered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(english ? '✓ ALREADY WELL COVERED (${covered.length})' : '✓ DÉJÀ BIEN COUVERTS (${covered.length})',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: p.accent)),
                const SizedBox(height: 6),
                Wrap(spacing: 5, runSpacing: 5, children: [
                  for (final c in covered.take(10))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(99)),
                      child: Text('${c.emoji} ${c.label}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                ]),
              ]),
            ),
          ),
        if (gaps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              english
                  ? 'Every essential I track is already well covered here.'
                  : 'Tous les essentiels que je suis sont déjà bien couverts ici.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              for (final g in gaps)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                  decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(g.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                      Text('${g.percent.round()} %',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.textSoft)),
                    ]),
                    const SizedBox(height: 3),
                    Text(g.def.foods(english), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.accent)),
                  ]),
                ),
            ]),
          ),
        const Spacer(),
        _footer(),
      ],
    );
  }

  // ── 8. Ce que j'en retiens + appel à l'action ────────────────────────

  Widget _cta() {
    final ins = insightsFor(data, english: english);
    final cta = ctaFor(brand, handle, english: english);
    final fa = data.fattyAcids;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _top(l10n.shareKickerNaturo),
        Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 6), child: _title(l10n.shareNaturoTitle, size: 21)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [
            for (final t in ins)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 18, height: 18, alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                    child: const Text('✓', style: TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(t, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.28))),
                ]),
              ),
          ]),
        ),
        const Spacer(),
        // Récapitulatif chiffré (le visuel "résumé" est celui qu'on enregistre).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _stat(fmtNum(data.kcal, english: english), 'kcal', color: p.accent),
            const SizedBox(width: 6),
            _stat('${data.protein.round()} g', l10n.shareProteinShort),
            const SizedBox(width: 6),
            _stat('${data.fiber.round()} g', l10n.shareFiber),
            const SizedBox(width: 6),
            _stat('${fmtNum(fa.epaDhaMg, english: english)} mg', 'EPA+DHA'),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(18)),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cta.main, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, height: 1.15)),
                const SizedBox(height: 3),
                Text(cta.sub, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, height: 1.25)),
                const SizedBox(height: 7),
                Text(english ? '💾 Save it   ✈️ Send it to someone who cares' : '💾 Enregistre   ✈️ Envoie-le à quelqu\'un qui compte',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _footer(),
      ],
    );
  }

  // ── Post unique, story, paysage, bannière ────────────────────────────

  Widget _post() {
    final hs = data.highlights(english: english, max: 3);
    final hook = hookFor(data, english: english);
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
            Positioned(left: 22, top: 20, child: _kicker(l10n.shareKickerMyPlate, onPhoto: true)),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 0), child: _title(hook.headline, size: 19)),
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
    final hs = data.highlights(english: english, max: 3);
    final hook = hookFor(data, english: english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30), // barre de profil Instagram
        Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 0), child: _kicker(l10n.shareKickerMyPlate)),
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
    final hs = data.highlights(english: english, max: 3);
    final hook = hookFor(data, english: english);
    return Row(children: [
      SizedBox(width: 170, child: _photoOrMosaic(height: 210, radius: 0)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kicker(l10n.shareKickerMyPlate),
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
                child: Text('${fmtNum(data.kcal, english: english)} kcal · P ${data.protein.round()} g', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: p.accent)),
              ),
              const SizedBox(width: 6),
              Flexible(child: _brandMark()),
            ]),
          ]),
        ),
      ),
    ]);
  }

  /// Bannière Play Store (feature graphic) 1024 × 500 : promotion de l'app
  /// à partir d'une vraie assiette analysée. Aucun texte essentiel dans les
  /// bords (Google peut recadrer les coins arrondis).
  Widget _banner() {
    final hs = data.highlights(english: english, max: 3);
    return Row(children: [
      Expanded(
        flex: 11,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 12, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('TOTUM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3, color: p.text)),
            ]),
            const SizedBox(height: 12),
            Text(english ? 'Every plate, decoded.' : 'Chaque assiette, décryptée.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.6, color: p.text)),
            const SizedBox(height: 6),
            Text(
              english ? 'Macros, micronutrients and essential fats — for health and longevity.'
                  : 'Macros, micronutriments et acides gras essentiels — pour ta santé et ta longévité.',
              style: TextStyle(fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w600, color: p.textSoft),
            ),
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
