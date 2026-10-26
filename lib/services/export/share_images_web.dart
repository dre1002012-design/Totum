// lib/services/export/share_images_web.dart
//
// Version WEB : télécharge chaque PNG (package:web, API officielle). À
// appeler directement depuis un geste de l'utilisateur (bouton
// "Enregistrer") — un téléchargement lancé après un long traitement
// asynchrone est bloqué par les navigateurs (bug du 26/10/2026).

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<int> savePngsToDevice(List<(Uint8List, String)> files) async {
  for (final (bytes, name) in files) {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = name
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    // Laisse le navigateur démarrer le téléchargement avant de révoquer
    // l'URL (sinon certains navigateurs annulent le fichier).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    web.URL.revokeObjectURL(url);
  }
  return files.length;
}
