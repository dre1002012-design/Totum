import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ═══════════════════════════════════════════════════════════════════════
///  SOLEIL & VITAMINE D — page dédiée, autonome.
///
///  Estime la vitamine D synthétisée par la peau selon :
///   - l'UV index réel (Open-Meteo, via géolocalisation)
///   - le type de peau (Fitzpatrick I à VI)
///   - la durée d'exposition et la surface de peau exposée
///
///  L'apport estimé est stocké par jour en SharedPreferences sous la clé
///  `vitd_sun_ug_<date>`, que le Bilan additionne au suivi alimentaire.
///
///  IMPORTANT : estimation PÉDAGOGIQUE, jamais une mesure médicale.
/// ═══════════════════════════════════════════════════════════════════════

const Color _kSun = Color(0xFFF9A825);

/// Clé de stockage de la vitamine D solaire pour une date donnée.
String sunVitDKey(DateTime d) =>
    'vitd_sun_ug_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Lit la vitamine D solaire (µg) déjà enregistrée pour une date —
/// synchronisée sur Supabase (table `sun_vitamin_d`) quand disponible, avant
/// tout stockée uniquement en local (SharedPreferences), donc perdue à la
/// désinstallation de l'app ou en changeant d'appareil (bug confirmé
/// signalé par Alex). Repli silencieux sur le local si hors-ligne ou si la
/// table n'existe pas encore côté projet.
Future<double> readSunVitD(DateTime day) async {
  final sp = await SharedPreferences.getInstance();
  final local = sp.getDouble(sunVitDKey(day)) ?? 0.0;
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return local;
    final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final row = await client
        .from('sun_vitamin_d')
        .select('vit_d_ug')
        .eq('user_id', user.id)
        .eq('date', dateKey)
        .maybeSingle();
    if (row == null) return local;
    final remote = (row['vit_d_ug'] as num?)?.toDouble() ?? 0.0;
    if (remote != local) await sp.setDouble(sunVitDKey(day), remote);
    return remote;
  } catch (_) {
    return local;
  }
}

Future<void> _saveSunVitD(DateTime day, double totalUg) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setDouble(sunVitDKey(day), totalUg);
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    await client.from('sun_vitamin_d').upsert(
        {'user_id': user.id, 'date': dateKey, 'vit_d_ug': totalUg});
  } catch (_) {}
}

/// Les 6 types de peau Fitzpatrick, avec leur temps de référence (minutes)
/// pour synthétiser ~1000 UI (25 µg) à UV index élevé (~8-10), peau des
/// bras et jambes exposée. Valeurs dérivées de la littérature (modèles UV).
class SkinType {
  final int index; // 0..5
  final String label;
  final String desc;
  final double refMinutes; // minutes pour ~25 µg à UV ~9
  const SkinType(this.index, this.label, this.desc, this.refMinutes);
}

const List<SkinType> kSkinTypes = [
  SkinType(0, 'Type I — Très claire',
      'Peau très pâle, brûle toujours, ne bronze jamais. Souvent cheveux roux, taches de rousseur.', 6),
  SkinType(1, 'Type II — Claire',
      'Peau claire, brûle facilement, bronze peu et difficilement.', 7),
  SkinType(2, 'Type III — Intermédiaire',
      'Peau moyenne, brûle modérément, bronze progressivement.', 9),
  SkinType(3, 'Type IV — Mate',
      'Peau mate/olivâtre, brûle peu, bronze bien et facilement.', 12),
  SkinType(4, 'Type V — Foncée',
      'Peau brun foncé, brûle rarement, bronze intensément.', 16),
  SkinType(5, 'Type VI — Très foncée',
      'Peau noire, ne brûle quasiment jamais.', 26),
];

/// Fraction de la surface corporelle exposée selon la tenue.
class ExposureLevel {
  final String label;
  final double bodyFraction; // part de peau exposée (0..1)
  final IconData icon;
  const ExposureLevel(this.label, this.bodyFraction, this.icon);
}

const List<ExposureLevel> kExposureLevels = [
  ExposureLevel('Visage & mains', 0.10, Icons.face),
  ExposureLevel('Bras & visage', 0.25, Icons.front_hand),
  ExposureLevel('Bras & jambes', 0.40, Icons.accessibility_new),
  ExposureLevel('Maillot de bain', 0.70, Icons.pool),
];

class SunVitaminDScreen extends StatefulWidget {
  const SunVitaminDScreen({super.key});

  @override
  State<SunVitaminDScreen> createState() => _SunVitaminDScreenState();
}

class _SunVitaminDScreenState extends State<SunVitaminDScreen> {
  int? _skinIndex; // null tant que non choisi
  int _exposureIndex = 2; // bras & jambes par défaut
  int _minutes = 15;

  double? _uvIndex; // null = inconnu
  bool _loadingUv = false;
  String? _uvError;
  bool _usedSunscreen = false;

  double _todaySunVitD = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      final s = sp.getInt('profile_skin_type');
      _skinIndex = s;
      _exposureIndex = sp.getInt('sun_exposure_pref') ?? 2;
    });
    _todaySunVitD = await readSunVitD(DateTime.now());
    if (mounted) setState(() {});
    _fetchUv();
  }

  Future<void> _saveSkin(int i) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('profile_skin_type', i);
    setState(() => _skinIndex = i);
  }

  // ── Récupération de l'UV index via Open-Meteo ──────────────────────────
  Future<void> _fetchUv() async {
    setState(() {
      _loadingUv = true;
      _uvError = null;
    });
    try {
      // 1) Le service de localisation est-il activé sur l'appareil ?
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        setState(() {
          _uvError =
              'Localisation désactivée sur l\'appareil. Active-la, ou saisis l\'UV index à la main.';
          _loadingUv = false;
        });
        return;
      }
      // 2) Permission (demande explicite, indispensable sur Android)
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _uvError = 'Localisation refusée. Tu peux saisir l\'UV index à la main.';
          _loadingUv = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 12));
      // 2) Appel Open-Meteo (UV index courant, gratuit, sans clé)
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${pos.latitude}&longitude=${pos.longitude}'
        '&current=uv_index',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final uv = (data['current']?['uv_index'] as num?)?.toDouble();
        setState(() {
          _uvIndex = uv;
          _loadingUv = false;
        });
      } else {
        setState(() {
          _uvError = 'Impossible de récupérer l\'UV index pour l\'instant.';
          _loadingUv = false;
        });
      }
    } catch (e) {
      setState(() {
        _uvError = 'Localisation indisponible. Saisis l\'UV index à la main.';
        _loadingUv = false;
      });
    }
  }

  // ── Le calcul de vitamine D estimée ────────────────────────────────────
  /// Renvoie la vitamine D estimée (µg) pour les réglages courants.
  double _estimateVitD() {
    if (_skinIndex == null || _uvIndex == null) return 0;
    final uv = _uvIndex!;
    if (uv < 3) return 0; // en dessous de UV 3, synthèse négligeable

    final skin = kSkinTypes[_skinIndex!];
    final exposure = kExposureLevels[_exposureIndex];

    // Référence : refMinutes → 25 µg à UV 9, sur bras & jambes (0.40).
    // Vitesse de synthèse (µg/min) à UV 9 pour CETTE peau, surface pleine :
    const refUv = 9.0;
    const refDose = 25.0; // µg (~1000 UI)
    const refFraction = 0.40; // bras & jambes = base de la refMinutes
    final ratePerMinAtRef =
        (refDose / skin.refMinutes) * (exposure.bodyFraction / refFraction);

    // Ajustement linéaire par l'UV réel (proportionnel, plafonné à UV 11).
    final uvFactor = (uv / refUv).clamp(0.0, 11.0 / refUv);

    double vitD = ratePerMinAtRef * uvFactor * _minutes;

    // La crème solaire bloque l'essentiel de la synthèse (95-98%).
    if (_usedSunscreen) vitD *= 0.05;

    // Plafond physiologique : la peau limite naturellement sa production.
    // On borne à ~50 µg (~2000 UI) par session, au-delà c'est irréaliste.
    return vitD.clamp(0.0, 50.0);
  }

  Future<void> _validateSession() async {
    final vitD = _estimateVitD();
    if (vitD <= 0) return;
    final sp = await SharedPreferences.getInstance();
    final key = sunVitDKey(DateTime.now());
    final current = sp.getDouble(key) ?? 0.0;
    final total = (current + vitD).clamp(0.0, 100.0);
    await _saveSunVitD(DateTime.now(), total);
    await sp.setInt('sun_exposure_pref', _exposureIndex);
    setState(() => _todaySunVitD = total);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '☀️ +${vitD.toStringAsFixed(1)} µg de vitamine D ajoutés à ta journée !'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetToday() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(sunVitDKey(DateTime.now()));
    await _saveSunVitD(DateTime.now(), 0.0);
    setState(() => _todaySunVitD = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      appBar: AppBar(
        title: const Text('Soleil & vitamine D'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _skinIndex == null ? _buildSkinPicker() : _buildMain(),
    );
  }

  // ── Premier lancement : choix du type de peau ──────────────────────────
  Widget _buildSkinPicker() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kSun.withValues(alpha: 0.14), _kSun.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quel est ton type de peau ?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text(
                'Ta peau détermine la vitesse à laquelle tu synthétises la vitamine D au soleil. On te le demande une seule fois.',
                style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final s in kSkinTypes) ...[
          _skinCard(s),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _skinCard(SkinType s) {
    return GestureDetector(
      onTap: () => _saveSkin(s.index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _skinToneColor(s.index),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(s.desc,
                      style: const TextStyle(
                          fontSize: 12, height: 1.4, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Color _skinToneColor(int i) {
    const tones = [
      Color(0xFFFFE0BD),
      Color(0xFFF1C27D),
      Color(0xFFE0AC69),
      Color(0xFFC68642),
      Color(0xFF8D5524),
      Color(0xFF5C3317),
    ];
    return tones[i.clamp(0, 5)];
  }

  // ── Écran principal ────────────────────────────────────────────────────
  Widget _buildMain() {
    final skin = kSkinTypes[_skinIndex!];
    final vitD = _estimateVitD();
    final canSynth = (_uvIndex ?? 0) >= 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Total du jour
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kSun, Color(0xFFFFB74D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kSun.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.white, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_todaySunVitD.toStringAsFixed(1)} µg',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'Vitamine D solaire estimée aujourd\'hui',
                      style: TextStyle(color: Colors.white, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (_todaySunVitD > 0)
                IconButton(
                  onPressed: _resetToday,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Réinitialiser',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // UV index
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_twilight, color: _kSun, size: 20),
                  const SizedBox(width: 8),
                  const Text('UV index actuel',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (_loadingUv)
                    const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      onPressed: _fetchUv,
                      icon: const Icon(Icons.my_location, size: 20),
                      tooltip: 'Actualiser ma position',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_uvIndex != null) ...[
                Row(
                  children: [
                    Text(_uvIndex!.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _uvColor(_uvIndex!))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_uvLabel(_uvIndex!),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _uvColor(_uvIndex!))),
                    ),
                  ],
                ),
                if (!canSynth) ...[
                  const SizedBox(height: 8),
                  _infoLine(Icons.info_outline,
                      'En dessous de UV 3, la synthèse de vitamine D est négligeable. Ce n\'est pas le bon moment — mais profite quand même du grand air.'),
                ],
              ] else ...[
                Text(_uvError ?? 'UV index inconnu.',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 10),
                // Saisie manuelle de secours
                Row(
                  children: [
                    const Text('Saisir manuellement : ',
                        style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: (_uvIndex ?? 5).clamp(0, 11).toDouble(),
                        min: 0,
                        max: 11,
                        divisions: 11,
                        activeColor: _kSun,
                        label: (_uvIndex ?? 5).toStringAsFixed(0),
                        onChanged: (v) => setState(() => _uvIndex = v),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Réglages d'exposition
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Ton type de peau : ',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(skin.label,
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _skinIndex = null),
                    child: const Text('Modifier'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 4),
              const Text('Surface de peau exposée',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < kExposureLevels.length; i++)
                    ChoiceChip(
                      label: Text(kExposureLevels[i].label),
                      selected: _exposureIndex == i,
                      onSelected: (_) => setState(() => _exposureIndex = i),
                      selectedColor: _kSun,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: _exposureIndex == i ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  const Text('Durée au soleil',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('$_minutes min',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900, color: _kSun)),
                ],
              ),
              Slider(
                value: _minutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                activeColor: _kSun,
                label: '$_minutes min',
                onChanged: (v) => setState(() => _minutes = v.round()),
              ),
              SwitchListTile(
                value: _usedSunscreen,
                onChanged: (v) => setState(() => _usedSunscreen = v),
                activeThumbColor: _kSun,
                contentPadding: EdgeInsets.zero,
                title: const Text('J\'avais de la crème solaire',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'La crème bloque 95 à 98 % de la synthèse de vitamine D.',
                    style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Estimation + validation
        if (canSynth && !_usedSunscreen) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSun.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kSun.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('≈ ${vitD.toStringAsFixed(1)} µg estimés',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: _kSun)),
                const SizedBox(height: 4),
                Text(
                  'pour $_minutes min, peau ${skin.label.split('—').last.trim().toLowerCase()}, ${kExposureLevels[_exposureIndex].label.toLowerCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _kSun,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: vitD > 0 ? _validateSession : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Valider mon exposition'),
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Bonnes conditions (pédagogie + garde-fous)
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Les bonnes conditions',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _condition(Icons.schedule,
                  'Les UVB nécessaires à la vitamine D ne sont présents qu\'au milieu de journée. Vise plutôt les bords de ce créneau (fin de matinée, milieu d\'après-midi) : quelques minutes suffisent. Entre 12h et 16h, le rayonnement est à son pic — bref et prudent, jamais une exposition prolongée.'),
              _condition(Icons.no_photography,
                  'Derrière une vitre (fenêtre, voiture), le verre bloque 100 % des UVB : aucune vitamine D produite.'),
              _condition(Icons.remove_red_eye,
                  'Les lunettes de soleil ne gênent PAS la synthèse : elle se fait par la peau, garde-les pour protéger tes yeux.'),
              _condition(Icons.calendar_month,
                  'Sous nos latitudes, la synthèse n\'est possible qu\'environ de mars à octobre. L\'hiver, mise sur l\'alimentation et éventuellement un complément.'),
              _condition(Icons.warning_amber,
                  'Ton corps ne produit qu\'une dose limitée de vitamine D, puis s\'arrête : rester plus longtemps n\'apporte rien de plus, mais accélère le vieillissement de la peau et augmente le risque de cancer cutané. L\'objectif est le strict nécessaire, pas le bronzage.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Estimation pédagogique fondée sur des modèles scientifiques. Ce n\'est pas une mesure médicale : seule une prise de sang évalue précisément ton taux de vitamine D.',
          style: TextStyle(fontSize: 11, color: Colors.black45),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Petits helpers UI ──────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: child,
      );

  Widget _infoLine(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: Colors.black45),
            const SizedBox(width: 7),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: Colors.black54)),
            ),
          ],
        ),
      );

  Widget _condition(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: _kSun),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.45, color: Colors.black87)),
            ),
          ],
        ),
      );

  Color _uvColor(double uv) {
    if (uv < 3) return const Color(0xFF43A047);
    if (uv < 6) return const Color(0xFFF9A825);
    if (uv < 8) return const Color(0xFFEF6C00);
    if (uv < 11) return const Color(0xFFC62828);
    return const Color(0xFF6A1B9A);
  }

  String _uvLabel(double uv) {
    if (uv < 3) return 'Faible — synthèse négligeable';
    if (uv < 6) return 'Modéré — synthèse possible';
    if (uv < 8) return 'Élevé — synthèse efficace, protège-toi';
    if (uv < 11) return 'Très élevé — quelques minutes suffisent';
    return 'Extrême — grande prudence';
  }
}