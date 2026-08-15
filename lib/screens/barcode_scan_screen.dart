import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BarcodeScanScreen extends StatefulWidget {
  final void Function(String barcode) onBarcode;

  const BarcodeScanScreen({super.key, required this.onBarcode});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    setState(() => _scanProcessed = true);
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
        title: const Text('Saisir le code-barres'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Chiffres du code-barres',
            hintText: 'ex. 3017620422003',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _scanProcessed = true);
    Navigator.of(context).pop();
    widget.onBarcode(code);
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
        title: const Text('Scanner un produit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          // Bouton Flash
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              tooltip: "Activer le flash",
              onPressed: () => _controller.toggleTorch(),
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
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Erreur caméra: $error',
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
                const Text(
                  "Visez le code-barre",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Détection automatique",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                // Repli manuel (voir _openManualEntry) — surtout utile sur
                // web, où le décodage caméra est moins fiable qu'en natif.
                TextButton.icon(
                  onPressed: _openManualEntry,
                  icon: const Icon(Icons.keyboard, color: Colors.white70, size: 18),
                  label: const Text('Saisir le code manuellement',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
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