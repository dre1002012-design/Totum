// lib/services/export/share_images_web.dart
//
// Version WEB : télécharge chaque PNG (même mécanique que download_web.dart
// pour le rapport HTML — package:web, API officielle actuelle).

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> shareOrDownloadPngs(List<(Uint8List, String)> files, {String? subject}) async {
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
    web.URL.revokeObjectURL(url);
  }
  return false;
}
