// lib/services/export/share_images_io.dart
//
// Version ANDROID / iOS : enregistre les visuels dans la galerie photos
// (paquet gal — MediaStore sur Android, Photos sur iOS), d'où l'utilisateur
// les publie ensuite où il veut. Le partage direct (Instagram, WhatsApp...)
// passe, lui, par la feuille de partage native (share_plus), voir
// meal_share_screen.dart.

import 'dart:typed_data';

import 'package:gal/gal.dart';

Future<int> savePngsToDevice(List<(Uint8List, String)> files) async {
  if (!await Gal.hasAccess()) {
    if (!await Gal.requestAccess()) return -1;
  }
  for (final (bytes, name) in files) {
    await Gal.putImageBytes(bytes, name: name.replaceAll(RegExp(r'\.png$'), ''));
  }
  return files.length;
}
