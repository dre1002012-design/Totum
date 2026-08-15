package com.totumapp.totum

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (et non FlutterActivity) : requis par Health Connect
// pour afficher l'écran système de justification des permissions sur
// Android 14+ (androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE).
class MainActivity : FlutterFragmentActivity() {
}
