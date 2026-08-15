// lib/services/export/download_io.dart
//
// Version ANDROID / iOS : écrit le fichier HTML dans le dossier temporaire
// puis ouvre la feuille de partage native (mail, Drive, WhatsApp…).
// Idéal pour envoyer le rapport à un professionnel de santé.

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareHtml(String content, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/html')],
    subject: 'Rapport de suivi nutritionnel TOTUM',
  );
}
