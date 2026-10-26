// lib/screens/meal_share_screen.dart
//
// Partage d'un repas ou d'une journée — fonction GÉNÉRALISTE (27/10/2026) :
// tout utilisateur crée des visuels (carrousel, post, story, Reel, paysage,
// bannière) puis choisit lui-même où les envoyer.
//
// BUG CORRIGÉ (27/10/2026, retour d'Alex : "le partage ne fonctionne pas,
// ni en local ni sur Instagram") — 2 causes :
// 1. sur le web, l'ancienne version ne partageait jamais : elle lançait des
//    téléchargements automatiques, que les navigateurs bloquent (plusieurs
//    fichiers sans geste de l'utilisateur ; Safari iOS les ignore souvent) ;
// 2. un navigateur n'autorise le partage que juste après un toucher : créer
//    8 images PUIS partager dans la foulée faisait expirer l'autorisation.
// Parcours en 2 temps, comme les meilleures apps : "Créer les visuels"
// (rendu), puis fiche de résultat avec "Partager…" (nouveau geste -> menu de
// partage du téléphone : Instagram, Facebook, WhatsApp...), "Enregistrer
// sur l'appareil" (galerie sur mobile, téléchargement sur le web) et
// "Copier la légende".
//
// Pas de connexion directe à un compte Instagram : l'API de publication de
// Meta exige un compte professionnel et une validation de l'app — inadapté
// à une app grand public ; le menu de partage natif donne déjà accès au fil,
// aux stories et aux messages Instagram, sans connexion.

import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  static const _paletteKey = 'share_palette_v3';
  static const _markKey = 'share_totum_mark_v1';

  late MealShareData _data = widget.data;
  late final TextEditingController _titleCtrl = TextEditingController(text: widget.data.title);
  final TextEditingController _handleCtrl = TextEditingController();
  final PageController _pageCtrl = PageController();
  _ShareFormat _format = _ShareFormat.carousel;
  SharePalette _palette = SharePalette.totumCream;
  bool _showMark = true;
  ui.Image? _photo;
  int _page = 0;
  bool _rendering = false;

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
      _palette = SharePalette.all.firstWhere((p) => p.id == pid, orElse: () => SharePalette.totumCream);
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

  String _paletteName(SharePalette p) {
    final en = _english;
    return switch (p.id) {
      'totum_cream' => 'Totum',
      'totum_night' => en ? 'Totum night' : 'Totum nuit',
      'nature' => 'Nature',
      'linen' => en ? 'Linen' : 'Lin',
      'ocean' => en ? 'Ocean' : 'Océan',
      _ => en ? 'Minimal' : 'Épuré',
    };
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
      _ShareFormat.reel => [for (final k in carouselKinds) make(k, reel: true)],
      _ShareFormat.post => [make(ShareSlideKind.post)],
      _ShareFormat.story => [make(ShareSlideKind.story)],
      _ShareFormat.landscape => [make(ShareSlideKind.landscape)],
      _ShareFormat.banner => [make(ShareSlideKind.banner)],
    };
  }

  String _caption() => captionFor(_data, english: _english, handle: _handle, mentionTotum: _showMark);

  Future<void> _pickPhoto() async {
    try {
      // Galerie uniquement : sélecteur système, aucune permission caméra.
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
      _snack(context.l10n.shareError(e.toString()));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _copyCaption() async {
    final copied = context.l10n.shareCaptionCopied;
    await Clipboard.setData(ClipboardData(text: _caption()));
    _snack(copied);
  }

  /// Rendu d'un visuel à sa taille exacte. Méthode principale : pipeline
  /// hors écran. Plan B (si une plateforme la refuse) : rendu dans un calque
  /// placé hors de la zone visible, puis capture — technique de capture
  /// d'écran standard, fiable partout.
  Future<ui.Image> _render(MealShareSlide slide, ui.FlutterView view, OverlayState overlay) async {
    try {
      return await renderWidgetToImage(slide,
          logicalSize: slide.logicalSize, pixelRatio: slide.exportScale, view: view);
    } catch (_) {
      final key = GlobalKey();
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -slide.logicalSize.width - 4000, top: 0,
          child: RepaintBoundary(key: key, child: SizedBox.fromSize(size: slide.logicalSize, child: slide)),
        ),
      );
      overlay.insert(entry);
      try {
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) throw StateError('écran fermé');
        final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return await ro.toImage(pixelRatio: slide.exportScale);
      } finally {
        entry.remove();
      }
    }
  }

  Future<void> _create() async {
    if (_rendering) return;
    final l10n = context.l10n;
    setState(() => _rendering = true);
    // Tout ce qui dépend du contexte est capturé AVANT la 1re attente.
    final view = View.of(context);
    final overlay = Overlay.of(context);
    final slides = _slides();
    final caption = _caption();
    try {
      await _savePrefs();
      final files = <(Uint8List, String)>[];
      final stamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < slides.length; i++) {
        final img = await _render(slides[i], view, overlay);
        files.add((await imageToPng(img), 'totum_${_format.name}_${stamp}_${i + 1}.png'));
      }
      // Copie automatique de la légende, au mieux : certains navigateurs
      // (Safari) la refusent hors d'un geste — ça ne doit JAMAIS bloquer la
      // suite (le bouton "Copier la légende" reste dans la fiche).
      try {
        await Clipboard.setData(ClipboardData(text: caption));
      } catch (_) {}
      if (!mounted) return;
      setState(() => _rendering = false);
      await _showReadySheet(files);
    } catch (e) {
      _snack(l10n.shareError(e.toString()));
    } finally {
      if (mounted && _rendering) setState(() => _rendering = false);
    }
  }

  /// Partage via le menu natif (Android/iOS) ou l'API de partage du
  /// navigateur (web) — appelé DIRECTEMENT depuis un geste.
  Future<void> _share(List<(Uint8List, String)> files, BuildContext anchorCtx) async {
    final l10n = context.l10n;
    final box = anchorCtx.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final xfiles = <XFile>[];
      if (kIsWeb) {
        for (final (bytes, name) in files) {
          xfiles.add(XFile.fromData(bytes, mimeType: 'image/png', name: name));
        }
      } else {
        final dir = await getTemporaryDirectory();
        for (final (bytes, name) in files) {
          final f = File('${dir.path}/$name');
          await f.writeAsBytes(bytes, flush: true);
          xfiles.add(XFile(f.path, mimeType: 'image/png', name: name));
        }
      }
      await Share.shareXFiles(xfiles, sharePositionOrigin: origin);
    } catch (_) {
      _snack(l10n.shareShareUnavailable);
    }
  }

  Future<void> _save(List<(Uint8List, String)> files) async {
    final l10n = context.l10n;
    try {
      final n = await savePngsToDevice(files);
      if (n < 0) {
        _snack(l10n.shareSaveDenied);
      } else {
        _snack(kIsWeb ? l10n.shareDownloaded(n) : l10n.shareSavedToGallery(n));
      }
    } catch (e) {
      _snack(l10n.shareError(e.toString()));
    }
  }

  Future<void> _showReadySheet(List<(Uint8List, String)> files) async {
    final l10n = context.l10n;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Défilable : sur un petit écran, "Partager…" ne doit jamais sortir de
      // l'écran (bug trouvé par le test du parcours, 27/10/2026).
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shareReadyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(l10n.shareReadyHint, style: TextStyle(fontSize: 12.5, height: 1.4, color: TotumColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Builder(
                  builder: (thumbCtx) => GestureDetector(
                    // Un seul visuel (ex. pour une story) : partage direct.
                    onTap: () => _share([files[i]], thumbCtx),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(files[i].$1, height: 150, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.shareShareOne, style: TextStyle(fontSize: 11, color: TotumColors.textMuted)),
            const SizedBox(height: 14),
            Builder(
              builder: (btnCtx) => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _share(files, btnCtx),
                  style: FilledButton.styleFrom(
                    backgroundColor: TotumColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l10n.shareShareButton),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _save(files),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TotumColors.accent,
                  side: const BorderSide(color: TotumColors.accent),
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.shareSaveButton),
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: _copyCaption,
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l10n.shareCopyCaption),
                style: TextButton.styleFrom(foregroundColor: TotumColors.accent),
              ),
            ),
          ],
        ),
      ),
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
      _ShareFormat.banner: (l10n.shareFormatBanner, Icons.web_asset),
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

  Widget _paletteSelector() => SizedBox(
        height: 62,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final p in SharePalette.all)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _palette = p),
                  child: Column(children: [
                    Container(
                      width: 38, height: 38,
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
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
                          const SizedBox(width: 2),
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: p.accent2, shape: BoxShape.circle)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_paletteName(p),
                        style: TextStyle(fontSize: 10.5, fontWeight: _palette.id == p.id ? FontWeight.w800 : FontWeight.w600,
                            color: _palette.id == p.id ? TotumColors.accent : TotumColors.textSecondary)),
                  ]),
                ),
              ),
          ],
        ),
      );

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
          Text(l10n.sharePaletteLabel, style: TextStyle(fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
          const SizedBox(height: 8),
          _paletteSelector(),
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
                  const Icon(Icons.tips_and_updates_outlined, size: 18, color: TotumColors.accent),
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
            onPressed: _rendering ? null : _create,
            style: FilledButton.styleFrom(
              backgroundColor: TotumColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            icon: _rendering
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(_rendering ? l10n.shareExporting : l10n.shareCreateButton(slides.length)),
          ),
        ),
      ),
    );
  }
}
