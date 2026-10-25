// lib/services/export/share_images_io.dart
//
// Version ANDROID / iOS : écrit les PNG dans le dossier temporaire puis
// ouvre la feuille de partage native — Instagram y apparaît directement
// (carrousel si plusieurs images, story/publication sinon).

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> shareOrDownloadPngs(List<(Uint8List, String)> files, {String? subject}) async {
  final dir = await getTemporaryDirectory();
  final xfiles = <XFile>[];
  for (final (bytes, name) in files) {
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes, flush: true);
    xfiles.add(XFile(f.path, mimeType: 'image/png'));
  }
  await Share.shareXFiles(xfiles, subject: subject);
  return true;
}
