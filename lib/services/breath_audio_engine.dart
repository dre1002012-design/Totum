// lib/services/breath_audio_engine.dart
//
// Moteur audio du module Respiration — Priorité 46 (retour d'Alex après 2
// tours d'échec de la synthèse temps réel dans le navigateur : "le son est
// nul... c'est stressant... marche pas bien, une fois sur deux").
//
// Architecture REVUE EN PROFONDEUR : abandon complet de la génération PCM
// en temps réel (streaming buffer, accumulateur de phase, filtre passe-bas
// automatisé — tout ça supprimé). Recherché ce que font les vraies apps de
// référence (RespiRelax, citée par Alex, et la plupart des apps de
// cohérence cardiaque) : PAS de synthèse continue à balayage de fréquence —
// un simple carillon aux transitions de phase, posé sur une nappe de fond
// fixe qui boucle indépendamment du timing. Les 4 fichiers sont pré-rendus
// une fois pour toutes hors-ligne (voir scripts/generate_breath_sounds.py),
// puis simplement CHARGÉS ET JOUÉS ici — le code le plus simple et le plus
// éprouvé de tout le package flutter_soloud (`loadAsset`/`play`), à
// l'opposé de l'usage exotique du streaming PCM qui s'est montré fragile.
//
// Pourquoi ça résout aussi le problème de durée variable (le point de
// départ du cahier des charges initial) : le carillon est un son COURT et
// FIXE, découplé de la durée réelle de la phase — que l'inspire dure 3s ou
// 8s, le même carillon sonne au début, sans déformation ni resynthèse. La
// nappe de fond, elle, joue en continu du début à la fin de la séance,
// jamais retriggée par phase — donc aucune des instabilités précédentes
// (buffer qui se vide entre deux appels, etc.) ne peut se reproduire :
// il n'y a plus qu'UN SEUL départ de lecture par son, jamais de ré-
// alimentation en cours de route.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_soloud/flutter_soloud.dart';

/// Les 5 types de phase que le module Respiration peut traverser. Distingue
/// explicitement rétention "poumons pleins" et "poumons vides" (l'ancien
/// code réutilisait la même clé `'hold'` pour les deux). [inhaleTopUp]
/// (2e inspiration du soupir physiologique) réutilise simplement le
/// carillon d'inspire — un fichier pré-rendu n'a pas besoin de la logique
/// de continuité qu'exigeait la synthèse temps réel.
enum BreathPhaseType { inhale, inhaleTopUp, holdFull, holdEmpty, exhale }

class BreathAudioEngine {
  final SoLoud _soloud = SoLoud.instance;
  bool _engineReady = false;
  bool _sessionActive = false;

  AudioSource? _inhaleChime;
  AudioSource? _exhaleChime;
  AudioSource? _ambientLoop;
  // Priorité 47 (13/08/2026, sons fournis par Alex) : variante dédiée pour
  // l'hyperventilation (rythme rapide, ~1 respiration/s) — optionnelle, pas
  // encore fournie au moment d'écrire ce correctif. `startPhase(fast: true)`
  // retombe automatiquement sur le carillon classique tant qu'elle est
  // absente (voir _loadOptional ci-dessous) : rien ne casse si ces 2
  // fichiers manquent, ils seront simplement pris en compte dès qu'ajoutés
  // à assets/sounds/ (déclaré en dossier entier dans pubspec.yaml).
  AudioSource? _hypervInhaleChime;
  AudioSource? _hypervExhaleChime;
  // Priorité 53 (14/08/2026, retour d'Alex) : métronome doux pendant les
  // rétentions, en plus de la nappe de fond qui continue sans interruption
  // — appelé une fois par seconde par l'écran (voir _RespirationScreenState
  // ._runPhase()), pas de logique de programmation ici, juste un son court
  // rejoué à la demande. Optionnel (comme les variantes hyperventilation) :
  // rien ne casse s'il manque.
  AudioSource? _metronomeTick;
  SoundHandle? _ambientHandle;

  bool get isReady => _engineReady;

  /// Charge un son optionnel sans faire échouer le reste de l'init si le
  /// fichier est absent (ex. variantes hyperventilation pas encore fournies).
  Future<AudioSource?> _loadOptional(String path) async {
    try {
      return await _soloud.loadAsset(path);
    } catch (e) {
      debugPrint('BreathAudioEngine._loadOptional($path) : absent ou invalide ($e)');
      return null;
    }
  }

  /// Initialise le moteur SoLoud et charge les sons une seule fois
  /// (idempotent). Repli silencieux : si l'audio n'est pas disponible, le
  /// module Respiration reste pleinement utilisable, juste sans son. Les 4
  /// sons "classiques" restent obligatoires (init global marqué en échec
  /// s'ils manquent) ; les 2 variantes hyperventilation sont optionnelles.
  Future<void> init() async {
    if (_engineReady) return;
    try {
      await _soloud.init();
      _inhaleChime = await _soloud.loadAsset('assets/sounds/breath_inhale_chime.mp3');
      _exhaleChime = await _soloud.loadAsset('assets/sounds/breath_exhale_chime.mp3');
      _ambientLoop = await _soloud.loadAsset('assets/sounds/breath_ambient_loop.mp3');
      _hypervInhaleChime = await _loadOptional('assets/sounds/breath_hyperv_inhale_chime.mp3');
      _hypervExhaleChime = await _loadOptional('assets/sounds/breath_hyperv_exhale_chime.mp3');
      _metronomeTick = await _loadOptional('assets/sounds/breath_metronome_tick.wav');
      _engineReady = true;
    } catch (e) {
      debugPrint('BreathAudioEngine.init() : audio indisponible ($e)');
      _engineReady = false;
    }
  }

  /// Démarre une session. [enabled] reflète le réglage "son" de l'écran —
  /// si false, on ne joue rien (économie batterie réelle). [startAmbient]
  /// (Priorité 55, 14/08/2026, retour d'Alex sur l'hyperventilation :
  /// "laisse le son d'ambiance uniquement sur les rétentions, pas pendant
  /// les respirations rapides") : les techniques classiques veulent la
  /// nappe de fond dès le début de la séance (comportement historique,
  /// inchangé) ; l'écran Wim Hof, lui, démarre la session SANS nappe (les
  /// carillons rapides restent actifs via `_sessionActive`) et pilote
  /// lui-même `startAmbient()`/`stopAmbient()` au fil des phases.
  Future<void> startSession({bool enabled = true, bool startAmbient = true}) async {
    if (!enabled || !_engineReady) return;
    _sessionActive = true;
    if (startAmbient) await this.startAmbient();
  }

  /// Lance (ou relance) la nappe de fond en boucle — sans effet si elle
  /// joue déjà ou si la session n'est pas active.
  Future<void> startAmbient() async {
    if (!_sessionActive || _ambientLoop == null || _ambientHandle != null) return;
    try {
      _ambientHandle = await _soloud.play(_ambientLoop!, volume: 0.9, looping: true);
    } catch (e) {
      debugPrint('BreathAudioEngine.startAmbient() : $e');
    }
  }

  /// Arrête la nappe de fond (fondu court) sans mettre fin à la session —
  /// les carillons de phase restent jouables ensuite via `startPhase()`.
  Future<void> stopAmbient() async {
    final handle = _ambientHandle;
    if (handle == null) return;
    _ambientHandle = null;
    try {
      _soloud.fadeVolume(handle, 0, const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 420));
      await _soloud.stop(handle);
    } catch (e) {
      debugPrint('BreathAudioEngine.stopAmbient() : $e');
    }
  }

  /// Joue le carillon de transition correspondant à [type] — un son court
  /// et fixe, indépendant de [durationSeconds] (gardé dans la signature
  /// pour ne rien changer côté écrans appelants, mais plus utilisé ici :
  /// c'est justement ce découplage qui rend cette approche insensible à
  /// n'importe quelle durée de phase configurée par l'utilisateur).
  ///
  /// [fast] (Priorité 47) : contexte hyperventilation (respirations toutes
  /// les ~1s) — utilise la variante dédiée `_hypervInhaleChime`/
  /// `_hypervExhaleChime` si disponible, sinon retombe sur le carillon
  /// classique.
  ///
  /// Rétentions (Priorité 51, 14/08/2026, retour d'Alex — test réel avec
  /// ses propres sons) : plus AUCUN carillon pendant `holdFull`/`holdEmpty`,
  /// juste la nappe de fond qui continue sans interruption — le carillon de
  /// rétention testé en conditions réelles se superposait mal à l'ambiance
  /// ("ça rend pas bien").
  Future<void> startPhase({
    required BreathPhaseType type,
    required int durationSeconds,
    bool fast = false,
  }) async {
    if (!_sessionActive) return;
    if (type == BreathPhaseType.holdFull || type == BreathPhaseType.holdEmpty) return;
    final source = switch (type) {
      BreathPhaseType.inhale || BreathPhaseType.inhaleTopUp =>
        (fast ? _hypervInhaleChime : null) ?? _inhaleChime,
      BreathPhaseType.exhale => (fast ? _hypervExhaleChime : null) ?? _exhaleChime,
      BreathPhaseType.holdFull || BreathPhaseType.holdEmpty => null, // déjà écarté ci-dessus
    };
    if (source == null) return;
    try {
      // Priorité 57 (retour d'Alex sur le Wim Hof, 2e demande d'augmenter
      // le volume : "augmente encore un peu") : 1.0 → 1.25. Les carillons
      // rapides sont désormais les SEULS repères sonores directionnels de
      // la respiration rapide (toute voix retirée) — au-delà de 1.0, SoLoud
      // amplifie plutôt que plafonner, léger risque de saturation assumé
      // pour bien marquer la distinction inspire/expire. Carillons
      // classiques inchangés (0.85).
      await _soloud.play(source, volume: fast ? 1.25 : 0.85);
    } catch (e) {
      debugPrint('BreathAudioEngine.startPhase() : $e');
    }
  }

  /// Tic de métronome doux pendant une rétention (Priorité 53) — à appeler
  /// une fois par seconde par l'écran pendant `holdFull`/`holdEmpty`
  /// uniquement. Volume nettement plus bas que les carillons de transition :
  /// un simple repère de rythme en fond, jamais un événement à part entière.
  Future<void> playTick() async {
    if (!_sessionActive || _metronomeTick == null) return;
    try {
      // Priorité 55 (retour d'Alex : "un peu plus fort, sans être ultra
      // fort") : 0.35 → 0.55, toujours nettement sous les carillons (0.85).
      await _soloud.play(_metronomeTick!, volume: 0.55);
    } catch (e) {
      debugPrint('BreathAudioEngine.playTick() : $e');
    }
  }

  /// Fin de session : fondu de la nappe de fond puis arrêt.
  Future<void> stopSession() async {
    if (!_sessionActive) return;
    _sessionActive = false;
    await stopAmbient();
  }

  /// Fondu + pause sur interruption système (appel entrant) — voir
  /// breath_background_session.dart. [resume] relance simplement le volume,
  /// aucun état de synthèse à restaurer (plus de génération temps réel).
  void duck() {
    if (!_sessionActive || _ambientHandle == null) return;
    _soloud.fadeVolume(_ambientHandle!, 0, const Duration(milliseconds: 300));
  }

  void resume() {
    if (!_sessionActive || _ambientHandle == null) return;
    _soloud.fadeVolume(_ambientHandle!, 0.9, const Duration(milliseconds: 300));
  }

  /// Libération complète — à appeler dans le `dispose()` de l'écran. Ne
  /// décharge pas les `AudioSource` (réutilisées d'une séance à l'autre
  /// tant que l'engine reste initialisé) ni ne fait `deinit()` (même choix
  /// que précédemment : plus robuste sur web de garder le moteur en vie).
  ///
  /// Bug corrigé (14/08/2026, retour d'Alex : "quand on sort de la page, le
  /// son continue") : arrêt IMMÉDIAT et synchrone, contrairement à
  /// [stopSession] (fondu progressif de 400ms + délai de 420ms avant le
  /// stop réel — pensé pour un bouton "Stop" explicite en cours de séance,
  /// où l'écran reste affiché le temps du fondu). Ici l'écran est déjà en
  /// train de disparaître : on ne veut plus dépendre d'un `Future`
  /// "fire-and-forget" de ~800ms au total pour être sûr que le son s'arrête
  /// vraiment.
  Future<void> dispose() async {
    _sessionActive = false;
    try {
      if (_ambientHandle != null) {
        await _soloud.stop(_ambientHandle!);
      }
    } catch (e) {
      debugPrint('BreathAudioEngine.dispose() : $e');
    } finally {
      _ambientHandle = null;
    }
  }
}
