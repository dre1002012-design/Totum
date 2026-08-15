// lib/services/app_settings.dart
//
// Réglages d'app persistés (écran Paramètres).
//
// Apparence verrouillée sur Clair pour l'instant : la charte graphique de
// l'app (TotumColors, ~600 usages) est actuellement figée en couleurs
// claires — un vrai mode sombre nécessite de la rendre adaptative au thème,
// un chantier à part entière, pas un correctif ponctuel. Proposer
// Système/Sombre avant que ce travail soit fait rendait l'app illisible
// (bug confirmé par Alex : barre de navigation du bas invisible en mode
// sombre système). `themeMode` reste un ValueNotifier (écouté par TotumApp
// dans main.dart) pour que la réintroduction du choix, une fois la charte
// réellement adaptative, n'ait qu'à changer sa valeur par défaut.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'units.dart';

class AppSettings {
  AppSettings._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

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

  static Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    final scale = sp.getDouble(_kTextScale);
    if (scale != null) textScale.value = scale;

    final lang = sp.getString(_kFoodNameLanguage);
    if (lang == 'fr' || lang == 'en') foodNameLanguage.value = lang!;

    final units = sp.getString(_kUnitSystem);
    if (units == 'imperial') unitSystem.value = UnitSystem.imperial;

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
  }
}
