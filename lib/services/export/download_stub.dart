// lib/services/export/download_stub.dart
//
// Stub — jamais exécuté directement. L'import conditionnel dans
// journal_export.dart choisit download_web.dart (web) ou download_io.dart
// (Android/iOS) à la compilation.

Future<void> saveAndShareHtml(String content, String filename) async {
  throw UnsupportedError('Export non supporté sur cette plateforme');
}
