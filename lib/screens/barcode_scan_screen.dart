import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../l10n/l10n_ext.dart';

class BarcodeScanScreen extends StatefulWidget {
  final void Function(String barcode) onBarcode;

  const BarcodeScanScreen({super.key, required this.onBarcode});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with WidgetsBindingObserver {
  bool _scanProcessed = false;

  // ── Nouveau : stabilisation du code avant validation ─────────────────
  String? _lastCode;
  int _confirmCount = 0;
  // Audit scanner web vs natif (Priorité 40, retour d'Alex : "ça fonctionne
  // une fois sur deux" sur la web app) : mobile_scanner utilise ML Kit en
  // natif (Android/iOS) mais ZXing-js sur web — 2 moteurs de décodage
  // différents, pas juste 2 réglages (limitation du package, pas un bug
  // Totum : scanWindow lui-même n'est pas supporté sur web pour cette
  // raison). ZXing valide déjà les checksums EAN/UPC en interne à chaque
  // décodage réussi (contrairement à ML Kit, plus sujet aux lectures
  // partielles) — exiger 2 lectures consécutives identiques est donc une
  // sécurité utile en natif mais une contrainte inutile sur web, qui
  // aggrave la perception de lenteur/échec sans gain de fiabilité réel.
  static const int _requiredConfirms = kIsWeb ? 1 : 2;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // ← était noDuplicates, on passe à normal
    returnImage: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Priorité 69/71 (retour d'Alex, crash confirmé à 2 reprises : "...
    // attempt to invoke virtual method ... on a null object reference") —
    // classe de bug connue du plugin mobile_scanner (callback natif de
    // détection encore "en vol" au moment où le contrôleur est arrêté/
    // détruit). Le passage à mobile_scanner 7.4.0 (Priorité 71) apporte
    // plusieurs correctifs directement sur cette classe de crash (rework
    // CameraX/Impeller, correction de la race start/stop, correction du
    // dispose croisé entre contrôleurs) — gardé en plus, en ceinture et
    // bretelles, ce garde-fou applicatif. `dispose()` du contrôleur est
    // devenu asynchrone depuis mobile_scanner 6 ; `State.dispose()` doit
    // rester synchrone (contrat du framework), donc on ne l'attend pas mais
    // on ne laisse jamais une erreur dedans remonter et faire planter la
    // fermeture de l'écran.
    _controller.dispose().catchError((_) {});
    super.dispose();
  }

  // Priorité 69 : autre déclencheur connu du même crash — l'OS peut
  // reprendre la caméra pendant que l'app est mise en arrière-plan (appel,
  // notification, changement d'app) ; sans arrêt explicite ici, l'analyse
  // continue de tourner sur une caméra que le système a déjà coupée. Arrêt
  // à la mise en pause, redémarrage au retour — jamais laissé planter
  // l'écran si le contrôleur est dans un état inattendu à ce moment-là.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _controller.stop().catchError((_) {});
        break;
      case AppLifecycleState.resumed:
        if (!_scanProcessed) {
          _controller.start().catchError((_) {});
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_scanProcessed) return;
    if (!mounted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    // ── Stabilisation : on exige 2 détections consécutives du même code ─
    if (value == _lastCode) {
      _confirmCount++;
    } else {
      _lastCode = value;
      _confirmCount = 1;
    }

    if (_confirmCount < _requiredConfirms) return;

    // ── Code confirmé → on valide ────────────────────────────────────────
    // Priorité 69 : `_scanProcessed = true` AVANT tout arrêt caméra —
    // bloque immédiatement tout appel ré-entrant de ce callback (le flux
    // caméra peut encore livrer une frame en cours d'analyse pendant qu'on
    // arrête). On arrête explicitement l'analyse (`stop()`) et on laisse le
    // temps à la plateforme de vraiment couper la caméra AVANT de fermer
    // l'écran/détruire le contrôleur — inverse de l'ancien comportement qui
    // popait immédiatement pendant que le callback natif de détection était
    // encore en train de "redescendre" côté Kotlin, cause la plus probable
    // du crash confirmé par Alex.
    setState(() => _scanProcessed = true);
    _finishScan(value);
  }

  Future<void> _finishScan(String value) async {
    try {
      await _controller.stop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onBarcode(value);
  }

  /// Solution de repli (audit scanner Priorité 40, retour d'Alex) : le
  /// décodage caméra sur web (ZXing-js) n'atteint jamais la fiabilité de
  /// ML Kit en natif — limitation du moteur, pas un réglage à ajuster.
  /// Plutôt que de laisser un utilisateur bloqué face à une caméra qui ne
  /// coopère pas, il peut saisir le code-barres à la main (chiffres visibles
  /// sous le code, même sans arriver à le scanner).
  Future<void> _openManualEntry() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.barcodeEnterTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.barcodeDigitsLabel,
            hintText: 'ex. 3017620422003',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _scanProcessed = true);
    await _finishScan(code);
  }


  @override
  Widget build(BuildContext context) {
    // Zone de scan carrée
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 280,
      height: 280,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.l10n.barcodeScanScreenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          // Bouton Flash
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              tooltip: context.l10n.barcodeEnableFlash,
              onPressed: () {
                try {
                  _controller.toggleTorch();
                } catch (_) {}
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Caméra
          MobileScanner(
            controller: _controller,
            scanWindow: kIsWeb ? null : scanWindow,
            onDetect: _handleDetection,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.l10n.barcodeCameraError(error.toString()),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          
          // Cadre visuel
          CustomPaint(
            painter: _ScannerOverlay(scanWindow),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  context.l10n.barcodeAimInstruction,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.barcodeAutoDetect,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                // Repli manuel (voir _openManualEntry) — surtout utile sur
                // web, où le décodage caméra est moins fiable qu'en natif.
                TextButton.icon(
                  onPressed: _openManualEntry,
                  icon: const Icon(Icons.keyboard, color: Colors.white70, size: 18),
                  label: Text(context.l10n.barcodeManualEntry,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends CustomPainter {
  final Rect scanWindow;
  _ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)));

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawPath(backgroundPath, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawPath(cutoutPath, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)), borderPaint);
    
    final laserPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(scanWindow.left + 20, scanWindow.center.dy),
      Offset(scanWindow.right - 20, scanWindow.center.dy),
      laserPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}