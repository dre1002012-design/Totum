// lib/screens/meal_share_screen.dart
//
// "Partager sur Instagram" (et réseaux, site, Play Store) — demande d'Alex
// (25-26/10/2026, naturopathe & coach) : à partir d'un repas ou d'une
// journée du journal (et de la photo du plat), un contenu clé en main, sans
// retouche, pour son compte perso OU pour le compte de l'app Totum.
//
// Données et sources : services/meal_share.dart. Visuels :
// widgets/meal_share_slides.dart. Export : rendu hors écran à la taille
// exacte de chaque format (services/widget_image_renderer.dart), puis
// feuille de partage native (Instagram y apparaît directement) ou
// téléchargement sur le web.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_ext.dart';
import '../services/meal_share.dart';
import '../services/widget_image_renderer.dart';
import '../theme/totum_style.dart';
import '../widgets/meal_share_slides.dart';
import '../services/export/share_images_stub.dart'
    if (dart.library.html) '../services/export/share_images_web.dart'
    if (dart.library.io) '../services/export/share_images_io.dart';

enum _ShareFormat { carousel, post, story, reel, landscape, banner }

class MealShareScreen extends StatefulWidget {
  final MealShareData data;
  const MealShareScreen({super.key, required this.data});

  @override
  State<MealShareScreen> createState() => _MealShareScreenState();
}

class _MealShareScreenState extends State<MealShareScreen> {
  static const _handleKey = 'share_instagram_handle_v1';
  static const _paletteKey = 'share_palette_v2';
  static const _markKey = 'share_totum_mark_v1';
  static const _brandKey = 'share_brand_v1';

  late MealShareData _data = widget.data;
  late final TextEditingController _titleCtrl = TextEditingController(text: widget.data.title);
  final TextEditingController _handleCtrl = TextEditingController();
  final PageController _pageCtrl = PageController();
  _ShareFormat _format = _ShareFormat.carousel;
  ShareBrand _brand = ShareBrand.coach;
  SharePalette _palette = SharePalette.naturoSage;
  bool _showMark = true;
  ui.Image? _photo;
  int _page = 0;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _handleCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _handleCtrl.text = sp.getString(_handleKey) ?? '';
      _brand = sp.getString(_brandKey) == 'totum' ? ShareBrand.totum : ShareBrand.coach;
      final pid = sp.getString(_paletteKey);
      _palette = SharePalette.all.firstWhere((p) => p.id == pid, orElse: () => _defaultPalette(_brand));
      _showMark = sp.getBool(_markKey) ?? true;
    });
  }

  SharePalette _defaultPalette(ShareBrand b) =>
      b == ShareBrand.totum ? SharePalette.totumCream : SharePalette.naturoSage;

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_handleKey, _handleCtrl.text.trim());
    await sp.setString(_paletteKey, _palette.id);
    await sp.setBool(_markKey, _showMark);
    await sp.setString(_brandKey, _brand == ShareBrand.totum ? 'totum' : 'coach');
  }

  bool get _english => Localizations.localeOf(context).languageCode == 'en';

  String get _handle {
    final h = _handleCtrl.text.trim();
    if (h.isEmpty) return '';
    return h.startsWith('@') ? h : '@$h';
  }

  /// Visuels du format choisi, dans l'ordre de publication.
  List<MealShareSlide> _slides() {
    final l10n = context.l10n;
    MealShareSlide make(ShareSlideKind k, {int? index, int? count, bool reel = false}) => MealShareSlide(
          kind: k, data: _data, palette: _palette, l10n: l10n, english: _english,
          photo: _photo, handle: _handle, brand: _brand, showTotumMark: _showMark,
          index: index, count: count, reelFrame: reel,
        );
    return switch (_format) {
      _ShareFormat.carousel => [
          for (var i = 0; i < carouselKinds.length; i++)
            make(carouselKinds[i], index: i + 1, count: carouselKinds.length),
        ],
      _ShareFormat.reel => [for (final k in carouselKinds) make(k, reel: true)],
      _ShareFormat.post => [make(ShareSlideKind.post)],
      _ShareFormat.story => [make(ShareSlideKind.story)],
      _ShareFormat.landscape => [make(ShareSlideKind.landscape)],
      _ShareFormat.banner => [make(ShareSlideKind.banner)],
    };
  }

  Future<void> _pickPhoto() async {
    try {
      // Galerie uniquement : sélecteur système, aucune permission caméra
      // supplémentaire (la photo du plat est déjà dans la pellicule).
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 2160, maxHeight: 2160, imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _photo = frame.image);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.shareError(e.toString()))),
      );
    }
  }

  String _caption({bool? english}) =>
      captionFor(_data, english: english ?? _english, handle: _handle, brand: _brand);

  Future<void> _copyCaption() async {
    await Clipboard.setData(ClipboardData(text: _caption()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.shareCaptionCopied), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _export() async {
    if (_exporting) return;
    final l10n = context.l10n;
    setState(() => _exporting = true);
    // Tout ce qui dépend du contexte est capturé AVANT la 1re attente.
    final view = View.of(context);
    final slides = _slides();
    final caption = _caption();
    try {
      await _savePrefs();
      final files = <(Uint8List, String)>[];
      final stamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < slides.length; i++) {
        final img = await renderWidgetToImage(slides[i],
            logicalSize: slides[i].logicalSize, pixelRatio: slides[i].exportScale, view: view);
        files.add((await imageToPng(img), 'totum_${_format.name}_${stamp}_${i + 1}.png'));
      }
      // La légende part dans le presse-papiers : Instagram ignore le texte
      // transmis par la feuille de partage, il suffit de la coller.
      await Clipboard.setData(ClipboardData(text: caption));
      final shared = await shareOrDownloadPngs(files, subject: _data.title);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(shared ? l10n.shareCaptionCopied : l10n.shareDownloaded(files.length)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shareError(e.toString()))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: TotumColors.textSecondary)),
      );

  Widget _brandSelector() {
    final l10n = context.l10n;
    return SegmentedButton<ShareBrand>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: TotumColors.accentSoft,
        selectedForegroundColor: TotumColors.accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
      segments: [
        ButtonSegment(value: ShareBrand.coach, label: Text(l10n.shareBrandCoach), icon: const Icon(Icons.spa_outlined, size: 18)),
        ButtonSegment(value: ShareBrand.totum, label: Text(l10n.shareBrandTotum), icon: const Icon(Icons.storefront_outlined, size: 18)),
      ],
      selected: {_brand},
      onSelectionChanged: (s) => setState(() {
        _brand = s.first;
        _palette = _defaultPalette(_brand);
      }),
    );
  }

  Widget _formatSelector() {
    final l10n = context.l10n;
    final labels = {
      _ShareFormat.carousel: (l10n.shareFormatCarousel, Icons.view_carousel_outlined),
      _ShareFormat.post: (l10n.shareFormatPost, Icons.crop_portrait),
      _ShareFormat.story: (l10n.shareFormatStory, Icons.amp_stories_outlined),
      _ShareFormat.reel: (l10n.shareFormatReel, Icons.movie_outlined),
      _ShareFormat.landscape: (l10n.shareFormatLandscape, Icons.crop_landscape),
      _ShareFormat.banner: (l10n.shareFormatBanner, Icons.shop_outlined),
    };
    return Wrap(
      spacing: 8, runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final e in labels.entries)
          ChoiceChip(
            avatar: Icon(e.value.$2, size: 17, color: _format == e.key ? TotumColors.accent : TotumColors.textSecondary),
            label: Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            selected: _format == e.key,
            showCheckmark: false,
            selectedColor: TotumColors.accentSoft,
            onSelected: (_) {
              setState(() { _format = e.key; _page = 0; });
              if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
            },
          ),
      ],
    );
  }

  String _formatDescription() {
    final l10n = context.l10n;
    return switch (_format) {
      _ShareFormat.carousel => l10n.shareFormatCarouselDesc,
      _ShareFormat.post => l10n.shareFormatPostDesc,
      _ShareFormat.story => l10n.shareFormatStoryDesc,
      _ShareFormat.reel => l10n.shareFormatReelDesc,
      _ShareFormat.landscape => l10n.shareFormatLandscapeDesc,
      _ShareFormat.banner => l10n.shareFormatBannerDesc,
    };
  }

  Widget _preview(List<MealShareSlide> slides) {
    final size = slides.first.logicalSize;
    return LayoutBuilder(builder: (context, c) {
      // Aperçu : largeur de l'écran, plafonné en hauteur pour laisser voir
      // les réglages sous l'aperçu.
      final maxH = MediaQuery.of(context).size.height * 0.52;
      var w = c.maxWidth * 0.9;
      var h = w * size.height / size.width;
      if (h > maxH) {
        h = maxH;
        w = h * size.width / size.height;
      }
      return Column(
        children: [
          SizedBox(
            height: h,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Center(
                child: Container(
                  width: w, height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FittedBox(fit: BoxFit.contain, child: slides[i]),
                ),
              ),
            ),
          ),
          if (slides.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 7, height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? TotumColors.accent : TotumColors.outlineStrong,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = _slides();
    final caption = _caption();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareScreenTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _sectionLabel(l10n.shareBrandLabel),
          _brandSelector(),
          const SizedBox(height: 14),
          _formatSelector(),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(_formatDescription(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
          ),
          _preview(slides),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_photo == null ? l10n.shareAddPhoto : l10n.shareChangePhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TotumColors.accent,
                    side: const BorderSide(color: TotumColors.accent),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              if (_photo != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.shareRemovePhoto,
                  onPressed: () => setState(() => _photo = null),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: l10n.shareDishNameLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _data = _data.copyWith(title: v.trim().isEmpty ? widget.data.title : v.trim())),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _handleCtrl,
            decoration: InputDecoration(
              labelText: l10n.shareHandleLabel,
              hintText: l10n.shareHandleHint,
              prefixIcon: const Icon(Icons.alternate_email, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(l10n.sharePaletteLabel,
                  style: TextStyle(fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
              const SizedBox(width: 12),
              for (final p in SharePalette.all)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _palette = p),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: p.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _palette.id == p.id ? TotumColors.accent : TotumColors.outlineStrong,
                          width: _palette.id == p.id ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
                          const SizedBox(width: 2),
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: p.accent2, shape: BoxShape.circle)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_brand == ShareBrand.coach)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shareTotumMarkToggle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: _showMark,
              activeThumbColor: TotumColors.accent,
              onChanged: (v) => setState(() => _showMark = v),
            ),
          const SizedBox(height: 6),
          TotumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notes, size: 18, color: TotumColors.accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.shareCaptionLabel, style: const TextStyle(fontWeight: FontWeight.w800))),
                    TextButton.icon(
                      onPressed: _copyCaption,
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(l10n.shareCopyCaption),
                      style: TextButton.styleFrom(foregroundColor: TotumColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(caption, style: TextStyle(fontSize: 12.5, height: 1.4, color: TotumColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TotumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.trending_up, size: 18, color: TotumColors.accent),
                  const SizedBox(width: 8),
                  Text(l10n.shareTipsTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Text(l10n.shareTipsBody, style: TextStyle(fontSize: 12.5, height: 1.4, color: TotumColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _exporting ? null : _export,
            style: FilledButton.styleFrom(
              backgroundColor: TotumColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            icon: _exporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.ios_share),
            label: Text(_exporting ? l10n.shareExporting : l10n.shareExportButton(slides.length)),
          ),
        ),
      ),
    );
  }
}
