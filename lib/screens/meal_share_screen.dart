// lib/screens/meal_share_screen.dart
//
// "Partager sur Instagram" — demande d'Alex (25/10/2026, compte de
// naturopathe) : à partir d'un repas du journal (et de la photo du plat),
// produire un contenu Instagram clé en main, sans retouche : carrousel,
// post, story ou images pour un Reel, avec les macros et les
// micronutriments réels du repas, plus la légende prête à coller.
//
// Données et sources : services/meal_share.dart. Visuels :
// widgets/meal_share_slides.dart. Export : rendu hors écran en 1080 px
// (services/widget_image_renderer.dart), puis feuille de partage native
// (Instagram y apparaît directement) ou téléchargement sur le web.

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

enum _ShareFormat { carousel, post, story, reel }

class MealShareScreen extends StatefulWidget {
  final MealShareData data;
  const MealShareScreen({super.key, required this.data});

  @override
  State<MealShareScreen> createState() => _MealShareScreenState();
}

class _MealShareScreenState extends State<MealShareScreen> {
  static const _handleKey = 'share_instagram_handle_v1';
  static const _paletteKey = 'share_palette_v1';
  static const _markKey = 'share_totum_mark_v1';

  late MealShareData _data = widget.data;
  late final TextEditingController _titleCtrl = TextEditingController(text: widget.data.title);
  final TextEditingController _handleCtrl = TextEditingController();
  final PageController _pageCtrl = PageController();
  _ShareFormat _format = _ShareFormat.carousel;
  SharePalette _palette = SharePalette.cream;
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
      final pid = sp.getString(_paletteKey);
      _palette = SharePalette.all.firstWhere((p) => p.id == pid, orElse: () => SharePalette.cream);
      _showMark = sp.getBool(_markKey) ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_handleKey, _handleCtrl.text.trim());
    await sp.setString(_paletteKey, _palette.id);
    await sp.setBool(_markKey, _showMark);
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
          photo: _photo, handle: _handle, showTotumMark: _showMark,
          index: index, count: count, reelFrame: reel,
        );
    return switch (_format) {
      _ShareFormat.carousel => [
          for (var i = 0; i < carouselKinds.length; i++)
            make(carouselKinds[i], index: i + 1, count: carouselKinds.length),
        ],
      _ShareFormat.reel => [
          for (var i = 0; i < carouselKinds.length; i++) make(carouselKinds[i], reel: true),
        ],
      _ShareFormat.post => [make(ShareSlideKind.post)],
      _ShareFormat.story => [make(ShareSlideKind.story)],
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

  Future<void> _copyCaption() async {
    await Clipboard.setData(ClipboardData(text: captionFor(_data, english: _english, handle: _handle)));
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
    final english = _english;
    try {
      await _savePrefs();
      final files = <(Uint8List, String)>[];
      final stamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < slides.length; i++) {
        final img = await renderWidgetToImage(slides[i],
            logicalSize: slides[i].logicalSize, pixelRatio: kShareExportScale, view: view);
        files.add((await imageToPng(img), 'totum_${_format.name}_${stamp}_${i + 1}.png'));
      }
      // La légende part dans le presse-papiers : Instagram ignore le texte
      // transmis par la feuille de partage, il suffit de la coller.
      await Clipboard.setData(ClipboardData(text: captionFor(_data, english: english, handle: _handle)));
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

  Widget _formatSelector() {
    final l10n = context.l10n;
    final labels = {
      _ShareFormat.carousel: (l10n.shareFormatCarousel, Icons.view_carousel_outlined),
      _ShareFormat.post: (l10n.shareFormatPost, Icons.crop_portrait),
      _ShareFormat.story: (l10n.shareFormatStory, Icons.amp_stories_outlined),
      _ShareFormat.reel: (l10n.shareFormatReel, Icons.movie_outlined),
    };
    return SegmentedButton<_ShareFormat>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: TotumColors.accentSoft,
        selectedForegroundColor: TotumColors.accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        visualDensity: VisualDensity.compact,
      ),
      segments: [
        for (final e in labels.entries)
          ButtonSegment(value: e.key, label: Text(e.value.$1), icon: Icon(e.value.$2, size: 18)),
      ],
      selected: {_format},
      onSelectionChanged: (s) {
        setState(() { _format = s.first; _page = 0; });
        if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
      },
    );
  }

  String _formatDescription() {
    final l10n = context.l10n;
    return switch (_format) {
      _ShareFormat.carousel => l10n.shareFormatCarouselDesc,
      _ShareFormat.post => l10n.shareFormatPostDesc,
      _ShareFormat.story => l10n.shareFormatStoryDesc,
      _ShareFormat.reel => l10n.shareFormatReelDesc,
    };
  }

  Widget _preview(List<MealShareSlide> slides) {
    final size = slides.first.logicalSize;
    return LayoutBuilder(builder: (context, c) {
      // Aperçu : largeur de l'écran, plafonné en hauteur pour laisser voir
      // les réglages sous l'aperçu.
      final maxH = MediaQuery.of(context).size.height * 0.52;
      var w = c.maxWidth * 0.86;
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
    final caption = captionFor(_data, english: _english, handle: _handle);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareScreenTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _formatSelector(),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
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
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: p.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _palette.id == p.id ? TotumColors.accent : TotumColors.outlineStrong,
                          width: _palette.id == p.id ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
