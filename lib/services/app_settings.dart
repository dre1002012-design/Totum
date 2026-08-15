// lib/services/app_settings.dart
//
// Réglages d'app persistés (écran Paramètres).
//
// Priorité 60 (15/08/2026) : mode sombre réel. `TotumColors` (lib/theme/
// totum_style.dart) est désormais adaptative au thème — `themeMode` n'est
// plus verrouillé sur Clair, et `effectiveBrightness` résout "Système" vers
// la luminosité RÉELLE de l'OS (pas juste light/dark statique). Root cause
// du bug historique ("barre de navigation invisible en mode sombre
// système") : la barre custom utilisait des couleurs noires en dur pendant
// que le thème Material, lui, répondait déjà au mode sombre — corrigé dans
// main.dart (_navItem) en même temps que ce chantier.
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'units.dart';

class AppSettings {
  AppSettings._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  /// Luminosité RÉELLEMENT appliquée en ce moment — résout `ThemeMode.system`
  /// vers la luminosité actuelle de l'OS plutôt que de rester ambiguë.
  /// Source unique de vérité pour `TotumColors` (qui n'a pas de BuildContext
  /// disponible, étant une classe à champs statiques) et pour `TotumApp`
  /// (qui écoute ce ValueNotifier pour se reconstruire).
  static final ValueNotifier<Brightness> effectiveBrightness =
      ValueNotifier(Brightness.light);

  static void _recomputeEffectiveBrightness() {
    final mode = themeMode.value;
    final resolved = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => PlatformDispatcher.instance.platformBrightness,
    };
    if (effectiveBrightness.value != resolved) {
      effectiveBrightness.value = resolved;
    }
  }

  /// Multiplicateur de taille de police global (appliqué via
  /// MediaQuery.textScaler dans main.dart) — 0.85 / 1.0 / 1.15 / 1.3.
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);

  /// Langue préférée pour le NOM des aliments affiché dans les écrans de
  /// recherche/journal ('fr' ou 'en') — ne traduit PAS le reste de
  /// l'interface (boutons, libellés), voir displayNameOf() dans
  /// journal_screen.dart.
  static final ValueNotifier<String> foodNameLanguage = ValueNotifier('fr');

  /// Système d'unités pour le poids/la taille affichés — le stockage local
  /// et Supabase reste toujours en kg/cm (voir lib/services/units.dart).
  static final ValueNotifier<UnitSystem> unitSystem = ValueNotifier(UnitSystem.metric);

  static const _kTextScale = 'settings_text_scale';
  static const _kFoodNameLanguage = 'settings_food_name_language';
  static const _kUnitSystem = 'settings_unit_system';
  static const _kThemeMode = 'settings_theme_mode';

  static Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    final scale = sp.getDouble(_kTextScale);
    if (scale != null) textScale.value = scale;

    final lang = sp.getString(_kFoodNameLanguage);
    if (lang == 'fr' || lang == 'en') foodNameLanguage.value = lang!;

    final units = sp.getString(_kUnitSystem);
    if (units == 'imperial') unitSystem.value = UnitSystem.imperial;

    final theme = sp.getString(_kThemeMode);
    themeMode.value = switch (theme) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    _recomputeEffectiveBrightness();

    textScale.addListener(() async {
      final sp = await SharedPreferences.getInstance();
      await sp.setDouble(_kTextScale, textScale.value);
    });
    foodNameLanguage.addListener(() async {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kFoodNameLanguage, foodNameLanguage.value);
    });
    unitSystem.addListener(() async {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kUnitSystem, unitSystem.value == UnitSystem.imperial ? 'imperial' : 'metric');
    });
    themeMode.addListener(() async {
      _recomputeEffectiveBrightness();
      final sp = await SharedPreferences.getInstance();
      final value = switch (themeMode.value) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };
      await sp.setString(_kThemeMode, value);
    });
    // Réagit si l'OS bascule clair/sombre pendant que l'app tourne, tant
    // que themeMode == system (sinon _recomputeEffectiveBrightness()
    // n'a aucun effet, le mode choisi n'en dépend pas).
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      _recomputeEffectiveBrightness();
    };
  }
}
