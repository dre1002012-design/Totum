// lib/screens/barcode_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanScreen extends StatelessWidget {
  final void Function(String barcode) onBarcode;

  const BarcodeScanScreen({super.key, required this.onBarcode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un produit')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;

          final value = barcodes.first.rawValue;
          if (value == null) return;

          onBarcode(value);
          Navigator.of(context).pop(); // on ferme l’écran de scan une fois le code lu
        },
      ),
    );
  }
}
