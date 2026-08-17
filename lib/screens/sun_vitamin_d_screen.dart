import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../theme/totum_style.dart';

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

List<SkinType> skinTypesFor(AppLocalizations l10n) => [
      SkinType(0, l10n.sunSkinType1Label, l10n.sunSkinType1Desc, 6),
      SkinType(1, l10n.sunSkinType2Label, l10n.sunSkinType2Desc, 7),
      SkinType(2, l10n.sunSkinType3Label, l10n.sunSkinType3Desc, 9),
      SkinType(3, l10n.sunSkinType4Label, l10n.sunSkinType4Desc, 12),
      SkinType(4, l10n.sunSkinType5Label, l10n.sunSkinType5Desc, 16),
      SkinType(5, l10n.sunSkinType6Label, l10n.sunSkinType6Desc, 26),
    ];

/// Fraction de la surface corporelle exposée selon la tenue.
class ExposureLevel {
  final String label;
  final double bodyFraction; // part de peau exposée (0..1)
  final IconData icon;
  const ExposureLevel(this.label, this.bodyFraction, this.icon);
}

List<ExposureLevel> exposureLevelsFor(AppLocalizations l10n) => [
      ExposureLevel(l10n.sunExposureFaceHands, 0.10, Icons.face),
      ExposureLevel(l10n.sunExposureArmsFace, 0.25, Icons.front_hand),
      ExposureLevel(l10n.sunExposureArmsLegs, 0.40, Icons.accessibility_new),
      ExposureLevel(l10n.sunExposureSwimwear, 0.70, Icons.pool),
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
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() => _skinIndex = i);
  }

  // ── Récupération de l'UV index via Open-Meteo ──────────────────────────
  Future<void> _fetchUv() async {
    final l10n = context.l10n;
    setState(() {
      _loadingUv = true;
      _uvError = null;
    });
    try {
      // 1) Le service de localisation est-il activé sur l'appareil ?
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceOn) {
        setState(() {
          _uvError = l10n.sunLocationDisabled;
          _loadingUv = false;
        });
        return;
      }
      // 2) Permission (demande explicite, indispensable sur Android) — la
      // boîte de dialogue système peut rester ouverte longtemps si
      // l'utilisateur quitte l'écran pendant ce temps.
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _uvError = l10n.sunLocationDenied;
          _loadingUv = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      // 2) Appel Open-Meteo (UV index courant, gratuit, sans clé)
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${pos.latitude}&longitude=${pos.longitude}'
        '&current=uv_index',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final uv = (data['current']?['uv_index'] as num?)?.toDouble();
        setState(() {
          _uvIndex = uv;
          _loadingUv = false;
        });
      } else {
        setState(() {
          _uvError = l10n.sunUvFetchFailed;
          _loadingUv = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uvError = l10n.sunLocationUnavailable;
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

    final skin = skinTypesFor(context.l10n)[_skinIndex!];
    final exposure = exposureLevelsFor(context.l10n)[_exposureIndex];

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
    final l10n = context.l10n;
    final sp = await SharedPreferences.getInstance();
    final key = sunVitDKey(DateTime.now());
    final current = sp.getDouble(key) ?? 0.0;
    final total = (current + vitD).clamp(0.0, 100.0);
    await _saveSunVitD(DateTime.now(), total);
    await sp.setInt('sun_exposure_pref', _exposureIndex);
    if (!mounted) return;
    setState(() => _todaySunVitD = total);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sunValidateSnackbar(vitD.toStringAsFixed(1))),
          backgroundColor: TotumColors.positive,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetToday() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(sunVitDKey(DateTime.now()));
    await _saveSunVitD(DateTime.now(), 0.0);
    if (!mounted) return;
    setState(() => _todaySunVitD = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TotumColors.textPrimary,
        title: Text(context.l10n.sunScreenTitle,
            style: TextStyle(fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
      ),
      body: _skinIndex == null ? _buildSkinPicker() : _buildMain(),
    );
  }

  // ── Premier lancement : choix du type de peau ──────────────────────────
  Widget _buildSkinPicker() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [TotumColors.accent.withValues(alpha: 0.14), TotumColors.accent.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sunSkinPickerTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                l10n.sunSkinPickerSubtitle,
                style: TextStyle(fontSize: 13, height: 1.5, color: TotumColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final s in skinTypesFor(l10n)) ...[
          _skinCard(s),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _skinCard(SkinType s) {
    return TotumCard(
      onTap: () => _saveSkin(s.index),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _skinToneColor(s.index),
              shape: BoxShape.circle,
              border: Border.all(color: TotumColors.outline),
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
                    style: TextStyle(
                        fontSize: 12, height: 1.4, color: TotumColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: TotumColors.textMuted),
        ],
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
    final l10n = context.l10n;
    final skinTypes = skinTypesFor(l10n);
    final exposureLevels = exposureLevelsFor(l10n);
    final skin = skinTypes[_skinIndex!];
    final vitD = _estimateVitD();
    final canSynth = (_uvIndex ?? 0) >= 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Total du jour
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            // Même dégradé de héros que _CoachHeroCard/_todayAnalysisHero
            // (conseils_screen.dart) — un seul vocabulaire de "vignette
            // héroïque" dans toute l'app, jamais un dégradé propre à cet
            // écran.
            gradient: LinearGradient(
              colors: [TotumColors.accent, TotumProgress.stop75],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: TotumColors.accent.withValues(alpha: 0.3),
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
                    Text(
                      l10n.sunTodayEstimateLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (_todaySunVitD > 0)
                IconButton(
                  onPressed: _resetToday,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: l10n.sunResetTooltip,
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
                  const Icon(Icons.wb_twilight, color: TotumColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.sunUvCurrentTitle,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (_loadingUv)
                    const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      onPressed: _fetchUv,
                      icon: const Icon(Icons.my_location, size: 20),
                      tooltip: l10n.sunRefreshLocationTooltip,
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
                  _infoLine(Icons.info_outline, l10n.sunBelowUv3Info),
                ],
              ] else ...[
                Text(_uvError ?? l10n.sunUvUnknown,
                    style: TextStyle(fontSize: 13, color: TotumColors.textSecondary)),
                const SizedBox(height: 10),
                // Saisie manuelle de secours
                Row(
                  children: [
                    Text(l10n.sunManualUvLabel,
                        style: const TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: (_uvIndex ?? 5).clamp(0, 11).toDouble(),
                        min: 0,
                        max: 11,
                        divisions: 11,
                        activeColor: TotumColors.accent,
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
                  Text(l10n.sunYourSkinTypeLabel,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(skin.label,
                        style: TextStyle(fontSize: 13, color: TotumColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _skinIndex = null),
                    child: Text(l10n.sunModifyButton),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 4),
              Text(l10n.sunExposedSkinSurface,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < exposureLevels.length; i++)
                    ChoiceChip(
                      label: Text(exposureLevels[i].label),
                      selected: _exposureIndex == i,
                      onSelected: (_) => setState(() => _exposureIndex = i),
                      selectedColor: TotumColors.accent,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: _exposureIndex == i ? Colors.white : TotumColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: TotumColors.surface,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: TotumColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(l10n.sunSunDuration,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(l10n.sunMinutesShort(_minutes),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900, color: TotumColors.accent)),
                ],
              ),
              Slider(
                value: _minutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                activeColor: TotumColors.accent,
                label: l10n.sunMinutesShort(_minutes),
                onChanged: (v) => setState(() => _minutes = v.round()),
              ),
              SwitchListTile(
                value: _usedSunscreen,
                onChanged: (v) => setState(() => _usedSunscreen = v),
                activeThumbColor: TotumColors.accent,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.sunSunscreenSwitchTitle,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    l10n.sunSunscreenSwitchSubtitle,
                    style: const TextStyle(fontSize: 11.5)),
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
              color: TotumColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TotumColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(l10n.sunEstimatedAmount(vitD.toStringAsFixed(1)),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: TotumColors.accent)),
                const SizedBox(height: 4),
                Text(
                  l10n.sunEstimateDetail(_minutes,
                      skin.label.split('—').last.trim().toLowerCase(),
                      exposureLevels[_exposureIndex].label.toLowerCase()),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: TotumColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: vitD > 0 ? _validateSession : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.sunValidateButton),
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Bonnes conditions (pédagogie + garde-fous)
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sunGoodConditionsTitle,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _condition(Icons.schedule, l10n.sunCondition1),
              _condition(Icons.no_photography, l10n.sunCondition2),
              _condition(Icons.remove_red_eye, l10n.sunCondition3),
              _condition(Icons.calendar_month, l10n.sunCondition4),
              _condition(Icons.warning_amber, l10n.sunCondition5),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.sunDisclaimer,
          style: TextStyle(fontSize: 11, color: TotumColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Petits helpers UI ──────────────────────────────────────────────────
  Widget _card({required Widget child}) => TotumCard(child: child);

  Widget _infoLine(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: TotumColors.textMuted),
            const SizedBox(width: 7),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, height: 1.4, color: TotumColors.textSecondary)),
            ),
          ],
        ),
      );

  Widget _condition(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: TotumColors.accent),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12.5, height: 1.45, color: TotumColors.textPrimary)),
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
    final l10n = context.l10n;
    if (uv < 3) return l10n.sunUvLow;
    if (uv < 6) return l10n.sunUvModerate;
    if (uv < 8) return l10n.sunUvHigh;
    if (uv < 11) return l10n.sunUvVeryHigh;
    return l10n.sunUvExtreme;
  }
}