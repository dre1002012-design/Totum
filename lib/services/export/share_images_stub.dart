// lib/services/export/share_images_stub.dart
//
// Stub — jamais exécuté directement. L'import conditionnel dans
// meal_share_screen.dart choisit share_images_web.dart (web) ou
// share_images_io.dart (Android/iOS) à la compilation.

import 'dart:typed_data';

/// Partage (mobile) ou télécharge (web) une série d'images PNG.
/// Renvoie `true` si la feuille de partage native a été ouverte, `false`
/// si les fichiers ont été téléchargés (web).
Future<bool> shareOrDownloadPngs(List<(Uint8List, String)> files, {String? subject}) async {
  throw UnsupportedError('Partage non supporté sur cette plateforme');
}
