// lib/services/breath_background_session.dart
//
// Continuité audio en veille écran (Android : service au premier plan +
// wake lock ; iOS : catégorie AVAudioSession .playback + UIBackgroundModes
// "audio") et gestion des interruptions système (appel entrant) — concern
// séparé du moteur de synthèse (BreathAudioEngine). Activé/désactivé
// UNIQUEMENT pendant une séance de respiration active (startSession/
// stopSession), sans aucun impact sur le reste du cycle de vie de l'app.
//
// Volontairement pas de code natif écrit à la main : `flutter_foreground_task`
// gère le service Android (API 100% Dart), `audio_session` gère la session
// AVAudioSession/AudioFocus des deux côtés.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'breath_audio_engine.dart';

class BreathBackgroundSession {
  final BreathAudioEngine _audio;
  BreathBackgroundSession(this._audio);

  StreamSubscription<audio_session.AudioInterruptionEvent>? _interruptionSub;
  bool _foregroundTaskInitialized = false;
  bool _active = false;

  bool get _supportsBackground =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void _ensureForegroundTaskInit() {
    if (_foregroundTaskInitialized || !Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'totum_respiration',
        channelName: 'Séance de respiration',
        channelDescription: 'Maintient le son de la séance en cours pendant que l\'écran est verrouillé.',
        onlyAlertOnce: true,
        // Pas de son/vibration pour cette notification technique — la
        // musique de la séance est le seul son voulu ici.
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
    _foregroundTaskInitialized = true;
  }

  /// À appeler depuis `_start()` de RespirationScreen.
  Future<void> start() async {
    if (_active || !_supportsBackground) return;
    try {
      final session = await audio_session.AudioSession.instance;
      await session.configure(const audio_session.AudioSessionConfiguration(
        avAudioSessionCategory: audio_session.AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            audio_session.AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: audio_session.AVAudioSessionMode.defaultMode,
        androidAudioAttributes: audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.music,
          usage: audio_session.AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      await session.setActive(true);
      _interruptionSub = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _audio.duck();
        } else {
          _audio.resume();
        }
      });

      if (Platform.isAndroid) {
        _ensureForegroundTaskInit();
        await FlutterForegroundTask.startService(
          notificationTitle: 'Totum — Respiration',
          notificationText: 'Séance en cours',
          serviceTypes: const [ForegroundServiceTypes.mediaPlayback],
        );
      }
      _active = true;
    } catch (e) {
      debugPrint('BreathBackgroundSession.start() : $e');
    }
  }

  /// À appeler depuis `_stop()`/`_finish()`/`dispose()` de RespirationScreen.
  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    try {
      await _interruptionSub?.cancel();
      _interruptionSub = null;
      if (Platform.isAndroid) {
        await FlutterForegroundTask.stopService();
      }
      final session = await audio_session.AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('BreathBackgroundSession.stop() : $e');
    }
  }
}
