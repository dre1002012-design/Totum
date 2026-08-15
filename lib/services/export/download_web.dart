// lib/services/export/download_web.dart
//
// Version WEB : déclenche un téléchargement direct du fichier HTML
// dans le navigateur. Migré de `dart:html` (déprécié) vers `package:web` +
// `dart:js_interop` (Priorité 58, 14/08/2026) — même comportement, API
// officielle actuelle recommandée par l'équipe Flutter.

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> saveAndShareHtml(String content, String filename) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/html;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
