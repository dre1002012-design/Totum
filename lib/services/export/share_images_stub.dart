// lib/services/export/share_images_stub.dart
//
// Stub — jamais exécuté directement. L'import conditionnel de
// meal_share_screen.dart choisit share_images_web.dart (web) ou
// share_images_io.dart (Android/iOS/desktop) à la compilation.

import 'dart:typed_data';

/// Enregistre des images PNG sur l'appareil : galerie photos (mobile) ou
/// téléchargement (web). Renvoie le nombre d'images enregistrées, ou -1 si
/// l'accès aux photos a été refusé.
Future<int> savePngsToDevice(List<(Uint8List, String)> files) async {
  throw UnsupportedError('Enregistrement non supporté sur cette plateforme');
}
