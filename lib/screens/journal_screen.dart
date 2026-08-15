// lib/screens/journal_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile.dart'
    show NutritionTargets, Goals, computeAndSaveTargetsFromStoredProfile;
import '../services/foods_loader.dart' as foods_loader;
import '../services/app_settings.dart';
import 'account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'barcode_scan_screen.dart';
import 'bilan_screen.dart' show showGlucidesBreakdown;
import '../theme/totum_style.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../services/nutrient_labels.dart';

SupabaseClient get _supabaseClient => Supabase.instance.client;

const Color kTotumOrange = TotumColors.accent;

/// Couleur de progression — délègue à la rampe partagée [TotumProgress]
/// (charte graphique). Remplace l'ancienne logique "feu tricolore"
/// (rouge/orange/miel/vert par seuil), qui introduisait 4 teintes hors
/// accent unique. Le dépassement d'objectif reste signalé séparément, en
/// texte, via [TotumColors.negative] (voir _DayMacroOverview/_MacroBarRow)
/// — jamais en recolorant la barre elle-même.
Color _barColor(double pct) {
  if (!pct.isFinite) return TotumProgress.stop100;
  return TotumProgress.forFraction(pct.clamp(0.0, 1.0));
}
Color _accent(BuildContext _) => kTotumOrange;

String _norm(String s) {
  var out = s.toLowerCase();
  final map = {
    'à':'a','â':'a','ä':'a','á':'a','ã':'a','å':'a','ç':'c',
    'é':'e','è':'e','ê':'e','ë':'e','î':'i','ï':'i','í':'i','ì':'i',
    'ô':'o','ö':'o','ò':'o','ó':'o','õ':'o','û':'u','ù':'u','ü':'u','ú':'u',
    'ñ':'n','œ':'oe','æ':'ae',
    '\u2018':"'",'\u02bc':"'",'\u02b9':"'","` ":"'",'\u00b4':"'",'\u2019':"'",
    '\u201c':'"','\u201d':'"',
  };
  map.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}

int _scoreForQuery(String name, String q) {
  final n = _norm(name), query = _norm(q);
  if (query.isEmpty) return 0;
  if (n.startsWith(query)) return -100;
  if (n.contains(' $query')) return -60;
  if (n.contains(query)) return -30;
  return n.length;
}

class _FoodStats {
  Map<String, Map<String, num>> map = {};
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('food_stats');
    if (raw?.isNotEmpty == true) {
      try {
        map = Map<String, Map<String, num>>.from(
          (jsonDecode(raw!) as Map).map((k, v) =>
              MapEntry(k.toString(), Map<String, num>.from(v))));
      } catch (_) {}
    }
  }
  Future<void> bump(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final m = map[id] ?? {'count': 0, 'last': 0};
    m['count'] = (m['count'] ?? 0) + 1;
    m['last']  = now;
    map[id] = m;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('food_stats', jsonEncode(map));
  }
  int count(String id) => (map[id]?['count'] ?? 0).toInt();
  int last(String id)  => (map[id]?['last']  ?? 0).toInt();
}

class FavoritesStore {
  static const _key = 'fav_food_ids_v2';
  final Set<String> _ids = <String>{};
  Set<String> get ids => _ids;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw?.isNotEmpty == true) {
      try {
        _ids.addAll(
            (jsonDecode(raw!) as List).map((e) => e.toString()).toSet());
      } catch (_) {}
    }
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        final List<dynamic> rows = await _supabaseClient
            .from('favorite_foods').select('food_id').eq('user_id', user.id);
        if (rows.isNotEmpty) {
          _ids.addAll(rows
              .map((r) => (r['food_id'] ?? '').toString())
              .where((id) => id.isNotEmpty));
          await sp.setString(_key, jsonEncode(_ids.toList()));
        }
      }
    } catch (e) { debugPrint('Erreur load favoris: $e'); }
  }

  Future<void> toggle(String id) async {
    final sp = await SharedPreferences.getInstance();
    final isRemove = _ids.contains(id);
    if (isRemove) { _ids.remove(id); } else { _ids.add(id); }
    await sp.setString(_key, jsonEncode(_ids.toList()));
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        if (isRemove) {
          await _supabaseClient.from('favorite_foods').delete()
              .eq('user_id', user.id).eq('food_id', id);
        } else {
          await _supabaseClient.from('favorite_foods')
              .upsert({'user_id': user.id, 'food_id': id});
        }
      }
    } catch (e) { debugPrint('Erreur toggle favoris: $e'); }
  }

  bool isFav(String id) => _ids.contains(id);
}

class _RecipeIngredient {
  final String foodId;
  final String foodName;
  final double grams;
  _RecipeIngredient({
    required this.foodId,
    required this.foodName,
    required this.grams,
  });
  Map<String, dynamic> toJson() =>
      {'foodId': foodId, 'foodName': foodName, 'grams': grams};
  static _RecipeIngredient fromJson(Map<String, dynamic> j) =>
      _RecipeIngredient(
        foodId: (j['foodId'] ?? '').toString(),
        foodName: (j['foodName'] ?? '').toString(),
        grams: (j['grams'] as num?)?.toDouble() ?? 0,
      );
}

class _Recipe {
  final String id;
  String name;
  String description;
  List<_RecipeIngredient> ingredients;
  double totalWeightG;
  double? kcal100, prot100, carb100, fat100, fiber100;
  Map<String, double> micros100;
  // Traçabilité : recette importée depuis la bibliothèque TOTUM (vs créée
  // de zéro par l'utilisateur). Champ explicite, mais toujours ré-déductible
  // depuis l'id ("recipe:totum_xxx" = bibliothèque) pour rester robuste même
  // sur d'anciennes recettes sauvegardées avant l'ajout de ce champ.
  final bool fromLibrary;

  _Recipe({
    required this.id,
    required this.name,
    this.description = '',
    required this.ingredients,
    required this.totalWeightG,
    this.kcal100,
    this.prot100,
    this.carb100,
    this.fat100,
    this.fiber100,
    required this.micros100,
    bool? fromLibrary,
  }) : fromLibrary = fromLibrary ?? id.startsWith('recipe:totum_');

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'total_weight_g': totalWeightG,
    'kcal100': kcal100, 'prot100': prot100, 'carb100': carb100,
    'fat100': fat100, 'fiber100': fiber100, 'micros100': micros100,
    'from_library': fromLibrary,
  };

  static _Recipe fromJson(Map<String, dynamic> j) => _Recipe(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    ingredients: ((j['ingredients'] as List?) ?? [])
        .map((e) => _RecipeIngredient.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList(),
    totalWeightG: (j['total_weight_g'] as num?)?.toDouble() ?? 100,
    kcal100: (j['kcal100'] as num?)?.toDouble(),
    prot100: (j['prot100'] as num?)?.toDouble(),
    carb100: (j['carb100'] as num?)?.toDouble(),
    fat100: (j['fat100'] as num?)?.toDouble(),
    fiber100: (j['fiber100'] as num?)?.toDouble(),
    micros100: Map<String, double>.from(
      ((j['micros100'] as Map?) ?? {}).map((k, v) =>
          MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0))),
    fromLibrary: j['from_library'] as bool?,
  );

  foods_loader.FoodItem toFoodItem() => foods_loader.FoodItem(
    id: id, name: name,
    kcal100: kcal100, prot100: prot100, carb100: carb100,
    fat100: fat100, fiber100: fiber100, micros100: micros100,
  );

  Map<String, double> macrosFor(double g) {
    final f = g / 100.0;
    return {
      'kcal': (kcal100 ?? 0) * f, 'prot': (prot100 ?? 0) * f,
      'carb': (carb100 ?? 0) * f, 'fat' : (fat100  ?? 0) * f,
      'fiber':(fiber100?? 0) * f,
    };
  }
}

class _RecipesStore {
  static const _key = 'recipes_v1';
  List<_Recipe> list = [];
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    List<_Recipe> localList = [];
    if (raw?.isNotEmpty == true) {
      try {
        localList = (jsonDecode(raw!) as List)
            .map((e) => _Recipe.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    list = localList;
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final List<dynamic> rows = await _client
          .from('recipes').select().eq('user_id', user.id);
      final remoteList = rows
          .map((r) => _Recipe.fromJson(Map<String, dynamic>.from(r)))
          .toList();
      // Fusion, jamais d'écrasement : une recette ajoutée localement mais
      // pas encore (ou jamais) synchronisée côté Supabase ne doit jamais
      // disparaître de "Mes recettes" au rechargement suivant.
      final remoteIds = remoteList.map((r) => r.id).toSet();
      final localOnly =
          localList.where((r) => !remoteIds.contains(r.id)).toList();
      list = [...remoteList, ...localOnly];
      await _saveLocal();
      for (final r in localOnly) {
        try {
          await _client.from('recipes').upsert({
            'user_id': user.id, 'id': r.id, 'name': r.name,
            'description': r.description,
            'ingredients': r.ingredients.map((e) => e.toJson()).toList(),
            'total_weight_g': r.totalWeightG,
            'kcal100': r.kcal100, 'prot100': r.prot100, 'carb100': r.carb100,
            'fat100': r.fat100, 'fiber100': r.fiber100, 'micros100': r.micros100,
          });
        } catch (_) {}
      }
    } catch (e) { debugPrint('Erreur load recipes Supabase: $e'); }
  }

  Future<void> _saveLocal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> save(_Recipe r) async {
    final i = list.indexWhere((e) => e.id == r.id);
    if (i >= 0) { list[i] = r; } else { list.add(r); }
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('recipes').upsert({
          'user_id': user.id, 'id': r.id, 'name': r.name,
          'description': r.description,
          'ingredients': r.ingredients.map((e) => e.toJson()).toList(),
          'total_weight_g': r.totalWeightG,
          'kcal100': r.kcal100, 'prot100': r.prot100, 'carb100': r.carb100,
          'fat100': r.fat100, 'fiber100': r.fiber100, 'micros100': r.micros100,
        });
      }
    } catch (e) { debugPrint('Erreur save recipe Supabase: $e'); }
  }

  Future<void> remove(String id) async {
    list.removeWhere((e) => e.id == id);
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('recipes').delete()
            .eq('user_id', user.id).eq('id', id);
      }
    } catch (e) { debugPrint('Erreur delete recipe Supabase: $e'); }
  }
}

/// Un repas perso : un "instantané" figé du contenu d'un repas (chaque
/// aliment avec ses grammes et macros déjà calculées), pas un aliment
/// paramétrable par portion comme une recette — on rejoue le repas tel
/// quel, comme le fait déjà "Copier ce repas" vers un autre jour.
class _CustomMeal {
  final String id;
  String name;
  String description;
  List<Map<String, dynamic>> items; // {id, name, grams, kcal, prot, carb, fat, fiber}
  _CustomMeal({
    required this.id,
    required this.name,
    this.description = '',
    required this.items,
  });

  double get totalKcal =>
      items.fold(0.0, (s, it) => s + ((it['kcal'] as num?)?.toDouble() ?? 0.0));
  double get totalProt =>
      items.fold(0.0, (s, it) => s + ((it['prot'] as num?)?.toDouble() ?? 0.0));
  double get totalCarb =>
      items.fold(0.0, (s, it) => s + ((it['carb'] as num?)?.toDouble() ?? 0.0));
  double get totalFat =>
      items.fold(0.0, (s, it) => s + ((it['fat'] as num?)?.toDouble() ?? 0.0));
  double get totalFiber =>
      items.fold(0.0, (s, it) => s + ((it['fiber'] as num?)?.toDouble() ?? 0.0));

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description, 'items': items};

  static _CustomMeal fromJson(Map<String, dynamic> j) => _CustomMeal(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        items: ((j['items'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

class _CustomMealsStore {
  static const _key = 'custom_meals_v1';
  List<_CustomMeal> list = [];
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    List<_CustomMeal> localList = [];
    if (raw?.isNotEmpty == true) {
      try {
        localList = (jsonDecode(raw!) as List)
            .map((e) => _CustomMeal.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    list = localList;
    // Synchronisation Supabase optionnelle (table `custom_meals`, mêmes
    // colonnes que `recipes` en plus simple : id/name/items). Si la table
    // n'existe pas encore côté projet, l'appel échoue silencieusement et le
    // repas perso reste utilisable en local uniquement — même filet de
    // sécurité que les autres stores perso de cet écran.
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final List<dynamic> rows = await _client
          .from('custom_meals').select().eq('user_id', user.id);
      final remoteList = rows
          .map((r) => _CustomMeal.fromJson(Map<String, dynamic>.from(r)))
          .toList();
      final remoteIds = remoteList.map((r) => r.id).toSet();
      final localOnly = localList.where((r) => !remoteIds.contains(r.id)).toList();
      list = [...remoteList, ...localOnly];
      await _saveLocal();
      for (final m in localOnly) {
        try {
          await _client.from('custom_meals').upsert(_toSupaJson(m, user.id));
        } catch (_) {}
      }
    } catch (e) { debugPrint('Erreur load custom_meals Supabase (table absente ?): $e'); }
  }

  Future<void> _saveLocal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Map<String, dynamic> _toSupaJson(_CustomMeal m, String userId) => {
    'user_id': userId, 'id': m.id, 'name': m.name,
    'description': m.description, 'items': m.items,
  };

  Future<void> add(_CustomMeal m) async {
    list.add(m);
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('custom_meals').upsert(_toSupaJson(m, user.id));
      }
    } catch (e) { debugPrint('Erreur add custom_meal Supabase: $e'); }
  }

  /// Renommage/description/composition modifiés depuis l'éditeur — même
  /// pattern que `_CustomFoodsStore.update` (aliments perso).
  Future<void> update(_CustomMeal m) async {
    final i = list.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      list[i] = m;
    } else {
      list.add(m);
    }
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('custom_meals').upsert(_toSupaJson(m, user.id));
      }
    } catch (e) { debugPrint('Erreur update custom_meal Supabase: $e'); }
  }

  Future<void> remove(String id) async {
    list.removeWhere((e) => e.id == id);
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('custom_meals').delete()
            .eq('user_id', user.id).eq('id', id);
      }
    } catch (e) { debugPrint('Erreur delete custom_meal Supabase: $e'); }
  }
}

// ── Accesseurs unifiés photo/pictogramme/NOVA (Priorité 25) ─────────────────
// `FoodItem` (base CIQUAL + aliments scannés en mémoire) et `_CustomFood`
// (aliments perso/scannés persistés) ne partagent pas de classe commune —
// ces fonctions évitent de dupliquer la logique `is` à chaque endroit qui
// affiche un aliment (liste de résultats, fiche détail).
String? _photoOf(dynamic it) {
  if (it is foods_loader.FoodItem) return it.imageUrl;
  if (it is _CustomFood) return it.imageUrl;
  return null;
}

int? _novaOf(dynamic it) {
  if (it is foods_loader.FoodItem) return it.novaScore;
  if (it is _CustomFood) return it.novaScore;
  return null;
}

bool _novaEstimeOf(dynamic it) {
  if (it is foods_loader.FoodItem) return it.novaEstime;
  if (it is _CustomFood) return it.novaEstime;
  return false;
}

String? _pictogramOf(dynamic it) => it is foods_loader.FoodItem ? it.pictogramme : null;

String? _nomGeneriqueOf(dynamic it) => it is foods_loader.FoodItem ? it.nomGenerique : null;

/// Nom d'affichage le plus pertinent (Priorité 39, langue Priorité 48) :
/// selon la langue choisie dans Réglages → Langue des aliments, préfère la
/// traduction française (`nameFr`, aliments USDA) ou anglaise (`nameEn`,
/// aliments CIQUAL) quand elle existe, sinon le nom générique CIQUAL déjà en
/// place, sinon le nom brut fourni en repli — jamais de traduction inventée.
/// Un seul point d'entrée pour ne pas dupliquer cette logique à chaque écran
/// de recherche.
String displayNameOf(dynamic it, String fallback) {
  if (it is foods_loader.FoodItem) {
    if (AppSettings.language.value == 'en') {
      final en = it.nameEn;
      if (en != null && en.trim().isNotEmpty) return en;
      return fallback;
    }
    final fr = it.nameFr;
    if (fr != null && fr.trim().isNotEmpty) return fr;
    final generic = it.nomGenerique;
    if (generic != null && generic.trim().isNotEmpty) return generic;
  }
  return fallback;
}

/// Traduit les unités de portion USDA les plus courantes (Priorité 50,
/// retour d'Alex 14/08/2026 : "cup"/"serving"/"tablespoon" restent en
/// anglais même une fois la langue des aliments réglée sur français). Le
/// jeu de données (`usda_portions.csv`) comporte ~1900 libellés très
/// hétérogènes (dimensions, noms de produits commerciaux...) — traduction
/// volontairement CIBLÉE sur les mots-unités les plus fréquents plutôt
/// qu'une tentative exhaustive risquée de mal traduire un nom de produit ;
/// tout le reste du libellé (nombres, fractions, parenthèses, noms propres)
/// n'est jamais touché.
String frenchPortionLabel(String label) {
  if (AppSettings.language.value != 'fr') return label;
  const words = <String, String>{
    'tablespoons': 'cuil. à soupe', 'tablespoon': 'cuil. à soupe', 'tbsp': 'cuil. à soupe',
    'teaspoons': 'cuil. à café', 'teaspoon': 'cuil. à café', 'tsp': 'cuil. à café',
    'cups': 'tasses', 'cup': 'tasse',
    'servings': 'portions', 'serving': 'portion',
    'slices': 'tranches', 'slice': 'tranche',
    'pieces': 'morceaux', 'piece': 'morceau',
    'containers': 'pots', 'container': 'pot',
    'packages': 'paquets', 'package': 'paquet',
    'bunches': 'bottes', 'bunch': 'botte',
    'cookies': 'biscuits', 'cookie': 'biscuit',
    'fillets': 'filets', 'fillet': 'filet',
    'orders': 'portions', 'order': 'portion',
    'each': 'unité',
    // Priorité 53 (14/08/2026, retour d'Alex — "tout est toujours en
    // anglais") : élargi au-delà du 1er lot de mots-unités (cup/serving/
    // tablespoon) à d'autres unités et descripteurs de taille très
    // fréquents dans usda_portions.csv, même principe : jamais les
    // dimensions en pouces ni les noms de produits commerciaux.
    'fl oz': 'oz liq.', 'fluid ounces': 'oz liq.', 'fluid ounce': 'oz liq.',
    'ounces': 'onces', 'ounce': 'once', 'oz': 'once',
    'pounds': 'livres', 'pound': 'livre', 'lb': 'livre', 'lbs': 'livres',
    'quarts': 'litres', 'quart': 'litre',
    'gallons': 'gallons', 'gallon': 'gallon',
    'pints': 'pintes', 'pint': 'pinte',
    'cans': 'boîtes', 'can': 'boîte',
    'bottles': 'bouteilles', 'bottle': 'bouteille',
    'bags': 'sachets', 'bag': 'sachet',
    'boxes': 'boîtes', 'box': 'boîte',
    'jars': 'pots', 'jar': 'pot',
    'sticks': 'bâtonnets', 'stick': 'bâtonnet',
    'wedges': 'quartiers', 'wedge': 'quartier',
    'halves': 'moitiés', 'half': 'moitié',
    'wholes': 'entiers', 'whole': 'entier',
    'cubes': 'cubes', 'cube': 'cube',
    'links': 'saucisses', 'link': 'saucisse',
    'spears': 'pointes', 'spear': 'pointe',
    'small': 'petit', 'medium': 'moyen', 'large': 'grand',
    'scoops': 'mesures', 'scoop': 'mesure',
    'bar': 'barre', 'bars': 'barres',
    'sheets': 'feuilles', 'sheet': 'feuille',
  };
  var out = label;
  for (final entry in words.entries) {
    out = out.replaceAllMapped(
      RegExp('(?<![a-zA-Z])${RegExp.escape(entry.key)}(?![a-zA-Z])', caseSensitive: false),
      (m) => entry.value,
    );
  }
  return out;
}

// Retour d'Alex (11/08/2026) : les aliments ajoutés depuis la base USDA
// (favoris, récents/fréquents...) doivent se distinguer visuellement de la
// base CIQUAL — l'id "usda:<fdcId>" est déjà posé par UsdaService.getFoodItem.
bool _isUsdaFood(dynamic it) {
  try {
    return ((it as dynamic).id as String?)?.startsWith('usda:') == true;
  } catch (_) {
    return false;
  }
}

/// Priorité 40 (retour d'Alex) : bascule "Base de données" à sélection
/// multiple (CIQUAL/USDA indépendamment activables) — sert à exclure CIQUAL
/// de l'onglet Commun quand seul USDA est coché.
bool _isCiqualFood(dynamic it) {
  try {
    return ((it as dynamic).id as String?)?.startsWith('ciqual:') == true;
  } catch (_) {
    return false;
  }
}

/// 'Petit-déjeuner'/'Déjeuner'/'Dîner'/'Collation' servent d'IDENTIFIANT
/// INTERNE STABLE dans tout ce fichier (clé de `_journal`, comparaisons,
/// callbacks) — jamais traduits à la source. Ne traduit que pour l'AFFICHAGE.
String _mealTypeLabel(String key, AppLocalizations l10n) => switch (key) {
      'Petit-déjeuner' => l10n.consCatBreakfast,
      'Déjeuner' => l10n.consCatLunch,
      'Dîner' => l10n.consCatDinner,
      'Collation' => l10n.consCatSnack,
      _ => key,
    };

/// Petit badge texte discret (ex. "USDA", "Perso", "Recette") — partagé
/// entre les différentes listes de recherche, jamais un pavé qui polluerait
/// la lecture de la ligne (retour d'Alex : "la plus discrète possible").
Widget _foodTag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _CustomFood {
  final String id;
  final String name;
  final double? kcal100, prot100, carb100, fat100, fiber100;
  final Map<String, double> micros100;
  // Photo produit + score NOVA officiel (scan Open Food Facts, Priorité 25).
  // Volontairement PAS envoyés à Supabase (_toSupaJson) : la table
  // `custom_foods` n'a pas ces colonnes, les y ajouter casserait l'upsert
  // pour tous les champs d'un coup. Persistance locale uniquement pour
  // l'instant (voir docs/TODO.md) — survit aux redémarrages sur CET appareil
  // grâce à la fusion dans _CustomFoodsStore.load(), mais ne se synchronise
  // pas encore entre appareils.
  final String? imageUrl;
  final int? novaScore;
  final bool novaEstime;
  _CustomFood({
    required this.id, required this.name,
    this.kcal100, this.prot100, this.carb100, this.fat100, this.fiber100,
    required this.micros100,
    this.imageUrl, this.novaScore, this.novaEstime = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'kcal100': kcal100, 'prot100': prot100,
    'carb100': carb100, 'fat100': fat100, 'fiber100': fiber100,
    'micros100': micros100,
    'imageUrl': imageUrl, 'novaScore': novaScore, 'novaEstime': novaEstime,
  };
  static _CustomFood fromJson(Map<String, dynamic> j) => _CustomFood(
    id: j['id'], name: j['name'],
    kcal100: (j['kcal100'] as num?)?.toDouble(),
    prot100: (j['prot100'] as num?)?.toDouble(),
    carb100: (j['carb100'] as num?)?.toDouble(),
    fat100: (j['fat100'] as num?)?.toDouble(),
    fiber100: (j['fiber100'] as num?)?.toDouble(),
    micros100: Map<String, double>.from(
      (j['micros100'] as Map).map((k, v) =>
          MapEntry(k.toString(), (v as num).toDouble()))),
    imageUrl: j['imageUrl'] as String?,
    novaScore: (j['novaScore'] as num?)?.toInt(),
    novaEstime: j['novaEstime'] as bool? ?? false,
  );
  Map<String, double> macrosFor(double g) {
    final f = g / 100.0;
    return {
      'kcal': (kcal100 ?? 0) * f, 'prot': (prot100 ?? 0) * f,
      'carb': (carb100 ?? 0) * f, 'fat': (fat100 ?? 0) * f,
      'fiber': (fiber100 ?? 0) * f,
    };
  }
}

class _CustomFoodsStore {
  static const _key = 'custom_foods_v1';
  List<_CustomFood> list = [];
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw?.isNotEmpty == true) {
      try {
        list = (jsonDecode(raw!) as List)
            .map((e) => _CustomFood.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      // Repli local pour photo/NOVA (retour d'Alex, 11/08/2026 : la photo
      // disparaissait après une réinstallation complète) : tant que la
      // migration Supabase (colonnes image_url/nova_score/nova_estime sur
      // `custom_foods`) n'a pas été appliquée par Alex, `m['image_url']` etc.
      // valent simplement null (colonne absente = pas d'erreur côté
      // PostgREST sur un `select()` sans liste explicite), et on retombe sur
      // la valeur locale — même filet de sécurité qu'avant. Une fois la
      // migration appliquée, la valeur distante prime (elle survit, elle,
      // à une réinstallation).
      final localById = {for (final f in list) f.id: f};
      final List<dynamic> rows = await _client
          .from('custom_foods').select().eq('user_id', user.id);
      if (rows.isNotEmpty) {
        list = rows.map((r) {
          final m = Map<String, dynamic>.from(r);
          final id = (m['id'] ?? '').toString();
          final local = localById[id];
          return _CustomFood(
            id: id,
            name: (m['name'] ?? '').toString(),
            kcal100: (m['kcal100'] as num?)?.toDouble(),
            prot100: (m['prot100'] as num?)?.toDouble(),
            carb100: (m['carb100'] as num?)?.toDouble(),
            fat100: (m['fat100'] as num?)?.toDouble(),
            fiber100: (m['fiber100'] as num?)?.toDouble(),
            micros100: Map<String, double>.from(
              (m['micros100'] as Map? ?? {}).map((k, v) =>
                  MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0))),
            imageUrl: (m['image_url'] as String?) ?? local?.imageUrl,
            novaScore: (m['nova_score'] as num?)?.toInt() ?? local?.novaScore,
            novaEstime: (m['nova_estime'] as bool?) ?? local?.novaEstime ?? false,
          );
        }).toList();
        await _saveLocal();
      }
    } catch (e) { debugPrint('Erreur load custom_foods Supabase: $e'); }
  }

  Future<void> _saveLocal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Map<String, dynamic> _toSupaJson(_CustomFood f, String userId, {bool withPhoto = true}) => {
    'user_id': userId, 'id': f.id, 'name': f.name,
    'kcal100': f.kcal100, 'prot100': f.prot100, 'carb100': f.carb100,
    'fat100': f.fat100, 'fiber100': f.fiber100, 'micros100': f.micros100,
    // Colonnes ajoutées par supabase/migrations/*_custom_foods_photo.sql —
    // tant qu'Alex n'a pas appliqué cette migration, un upsert qui les
    // inclut échoue en bloc (colonnes inconnues de PostgREST), pas seulement
    // sur ces 3 champs : `_upsertCustomFood` ci-dessous retente alors sans
    // elles, pour ne jamais perdre la synchro des macros en attendant.
    if (withPhoto) 'image_url': f.imageUrl,
    if (withPhoto) 'nova_score': f.novaScore,
    if (withPhoto) 'nova_estime': f.novaEstime,
  };

  Future<void> _upsertCustomFood(_CustomFood f, String userId) async {
    try {
      await _client.from('custom_foods').upsert(_toSupaJson(f, userId));
    } catch (e) {
      debugPrint('Erreur upsert custom (avec photo, migration pas encore appliquée ?): $e');
      await _client.from('custom_foods')
          .upsert(_toSupaJson(f, userId, withPhoto: false));
    }
  }

  Future<void> add(_CustomFood f) async {
    list.add(f);
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) await _upsertCustomFood(f, user.id);
    } catch (e) { debugPrint('Erreur add custom: $e'); }
  }

  Future<void> update(_CustomFood f) async {
    final i = list.indexWhere((e) => e.id == f.id);
    if (i >= 0) {
      list[i] = f;
      await _saveLocal();
      try {
        final user = _client.auth.currentUser;
        if (user != null) await _upsertCustomFood(f, user.id);
      } catch (e) { debugPrint('Erreur update custom: $e'); }
    }
  }

  Future<void> remove(String id) async {
    list.removeWhere((e) => e.id == id);
    await _saveLocal();
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('custom_foods').delete()
            .eq('user_id', user.id).eq('id', id);
      }
    } catch (e) { debugPrint('Erreur delete custom: $e'); }
  }
}

enum _SortMode { frequent, recent, az, za }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => JournalScreenState();
}

class JournalScreenState extends State<JournalScreen> {
  SupabaseClient get _client => Supabase.instance.client;

  bool loading = false;
  final FavoritesStore _fav = FavoritesStore();
  final _CustomFoodsStore _customs = _CustomFoodsStore();
  final _RecipesStore _recipes = _RecipesStore();
  final _CustomMealsStore _customMeals = _CustomMealsStore();
  final _FoodStats _stats = _FoodStats();

  Goals _goals = const Goals(
      kcal: 2200, prot: 120, carb: 302.5, fat: 85.6, fiber: 30);
  NutritionTargets? _targets;

  static List<dynamic>? _cacheAll;
  List<dynamic> _all = <dynamic>[];
  String _query = '';
  _SortMode _sortMode = _SortMode.frequent;
  // Pilote le rafraîchissement de la page d'ajout sans reconstruire l'onglet.
  /// Filtre de l'onglet Perso : 0 = Aliments perso, 1 = Recettes
  int _persoFilter = 0;
  /// Dans le sous-onglet Recettes : ne montrer que celles importées de la
  /// bibliothèque TOTUM (traçabilité demandée par Alex).
  bool _onlyLibraryRecipes = false;

  final Map<String, List<Map<String, dynamic>>> _journal = {
    'Petit-déjeuner': [], 'Déjeuner': [], 'Dîner': [], 'Collation': [],
  };
  double sumKcal = 0, sumProt = 0, sumCarb = 0, sumFat = 0, sumFib = 0;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _journalKeyForDate(DateTime d) => 'journal_${_ymd(d)}';
  String _journalKeyForToday() => _journalKeyForDate(DateTime.now());

  Future<void> _loadJournalForToday() async {
    await _loadJournalForDate(DateTime.now());
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadJournalForDate(
      DateTime date) async {
    final sp = await SharedPreferences.getInstance();
    Map<String, List<Map<String, dynamic>>> empty() => {
      'Petit-déjeuner': <Map<String, dynamic>>[],
      'Déjeuner': <Map<String, dynamic>>[],
      'Dîner': <Map<String, dynamic>>[],
      'Collation': <Map<String, dynamic>>[],
    };
    final result = empty();
    final user0 = _client.auth.currentUser;

    // Le cache local n'est utilisé QUE si l'utilisateur n'est pas connecté.
    // Connecté → Supabase est la seule source de vérité (évite que des
    // aliments supprimés réapparaissent depuis un cache périmé).
    if (user0 == null) {
      final raw = sp.getString(_journalKeyForDate(date));
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          for (final meal in result.keys) {
            result[meal] = (decoded[meal] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } catch (_) {}
      }
    }

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final ymd = _ymd(date);
        final List<dynamic> rows = await _client
            .from('food_entries').select()
            .eq('user_id', user.id).eq('entry_date', ymd)
            .order('created_at');
        // Utilisateur connecté → Supabase est la SOURCE DE VÉRITÉ.
        // Même si la liste est vide (tout supprimé), on l'applique :
        // on ne ressuscite jamais le cache local.
        final cloud = empty();
        for (final row in rows) {
          final r = row as Map<String, dynamic>;
          final mealType = (r['meal_type'] as String?) ?? 'Déjeuner';
          if (!cloud.containsKey(mealType)) continue;
          cloud[mealType]!.add({
            'id': r['food_id'] as String? ?? '',
            'name': r['food_name'] as String? ?? 'Aliment',
            'grams': (r['quantity_grams'] as num?)?.toDouble() ?? 0.0,
            'kcal': (r['energy_kcal'] as num?)?.toDouble() ?? 0.0,
            'prot': (r['protein_g'] as num?)?.toDouble() ?? 0.0,
            'carb': (r['carbs_g'] as num?)?.toDouble() ?? 0.0,
            'fat': (r['fat_g'] as num?)?.toDouble() ?? 0.0,
            'fiber': (r['fiber_g'] as num?)?.toDouble() ?? 0.0,
            'entry_id': r['id'],
          });
        }
        for (final meal in result.keys) {
          result[meal] = cloud[meal]!;
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement journal Supabase: $e');
      // En cas d'échec réseau alors qu'on est connecté, on retombe sur
      // le cache local pour ne pas afficher un journal vide à tort.
      if (user0 != null) {
        final raw = sp.getString(_journalKeyForDate(date));
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            for (final meal in result.keys) {
              result[meal] = (decoded[meal] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          } catch (_) {}
        }
      }
    }

    final isToday = _ymd(date) == _ymd(DateTime.now());
    if (isToday && mounted) {
      setState(() {
        for (final meal in _journal.keys) {
          _journal[meal] = result[meal]!;
        }
      });
      _recomputeTotals();
      await _saveDailySnapshot();
    }
    return result;
  }

  Future<void> _persistJournalForToday() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_journalKeyForToday(),
        jsonEncode({for (final m in _journal.keys) m: _journal[m]}));
  }

  void _recomputeTotals() {
    double k = 0, p = 0, c = 0, f = 0, fi = 0;
    for (final e in _journal.values.expand((x) => x)) {
      k  += (e['kcal']  as double);
      p  += (e['prot']  as double);
      c  += (e['carb']  as double);
      f  += (e['fat']   as double);
      fi += (e['fiber'] as double);
    }
    setState(() {
      sumKcal = k; sumProt = p; sumCarb = c; sumFat = f; sumFib = fi;
    });
    SharedPreferences.getInstance().then((sp) {
      sp.setDouble('today_kcal', sumKcal);
      sp.setDouble('today_prot', sumProt);
      sp.setDouble('today_carb', sumCarb);
      sp.setDouble('today_fat',  sumFat);
      sp.setDouble('today_fiber',sumFib);
    });
    _persistJournalForToday();
  }

  /// Sans argument : snapshot du jour courant à partir des totaux déjà en
  /// mémoire (`sumKcal` etc., comportement historique inchangé). Avec
  /// [date]/totaux explicites : permet aussi de snapshoter une date PASSÉE
  /// (voir `_addEntryToDate`) — nécessaire depuis que `CalibrationService.
  /// _kcalForDate()` lit cette clé `history_snapshots` (retour d'Alex,
  /// 13/08/2026 : la clé `journal_<date>` que ce service lisait avant
  /// n'était en réalité écrite QUE pour un ajout à une date passée, jamais
  /// pour le flux normal "ajouter à aujourd'hui" — donc la dépense
  /// énergétique adaptative ne voyait quasiment jamais les repas d'un
  /// utilisateur qui logue au jour le jour, contrairement à `history_
  /// snapshots`, déjà fiabilisée pour CE cas précis).
  Future<void> _saveDailySnapshot({
    DateTime? date,
    double? kcal, double? prot, double? carb, double? fat, double? fiber,
  }) async {
    final sp = await SharedPreferences.getInstance();
    const key = 'history_snapshots';
    final ymd = _ymd(date ?? DateTime.now());
    Map<String, dynamic> hist = {};
    final raw = sp.getString(key);
    if (raw?.isNotEmpty == true) {
      try { hist = jsonDecode(raw!); } catch (_) {}
    }
    hist[ymd] = {
      'kcal': kcal ?? sumKcal, 'prot': prot ?? sumProt, 'carb': carb ?? sumCarb,
      'fat': fat ?? sumFat, 'fiber': fiber ?? sumFib,
    };
    await sp.setString(key, jsonEncode(hist));
  }

  bool _isPersonal(dynamic it) {
    try {
      return ((it as dynamic).id as String?)?.startsWith('custom:') == true;
    } catch (_) { return false; }
  }

  bool _isRecipe(dynamic it) {
    try {
      return ((it as dynamic).id as String?)?.startsWith('recipe:') == true;
    } catch (_) { return false; }
  }

  Future<void> _ensureFoodsLoaded({bool force = false}) async {
    if (!force && _cacheAll != null) {
      setState(() => _all = _cacheAll!);
      return;
    }
    final repo = foods_loader.FoodsRepository.instance;
    try {
      if ((repo.items as List).isEmpty) {
        try { await (repo as dynamic).loadFromAsset('assets/foods.csv'); }
        catch (_) {}
        try { await (repo as dynamic).load(); } catch (_) {}
      }
    } catch (_) {}
    await _customs.load();
    await _recipes.load();
    await _customMeals.load();

    // Garantit que la base USDA (généraliste + marque/restaurant) est
    // chargée avant de construire `_all` — idempotent (repli immédiat si
    // déjà chargée), sécurité en plus de `repo.load()` ci-dessus qui la
    // charge déjà en parallèle de CIQUAL.
    try { await repo.loadUsdaFromAsset('assets/usda_foods.csv'); } catch (_) {}

    // On a besoin de la base des aliments pour recalculer les recettes.
    final baseFoods = <dynamic>[...repo.items, ..._customs.list]

      ;

    // Réparation : certaines recettes ont pu être sauvées à 0 kcal si la base
    // n'était pas chargée au moment de leur création. On les recalcule ici
    // à partir de leurs ingrédients, puis on persiste la correction.
    bool repaired = false;
    for (final r in _recipes.list) {
      final hasIngredients = r.ingredients.isNotEmpty;
      final noEnergy = (r.kcal100 ?? 0) <= 0;
      if (hasIngredients && noEnergy) {
        final fixed = _recomputeRecipeFromIngredients(r, baseFoods);
        if (fixed) repaired = true;
      }
    }
    if (repaired) {
      for (final r in _recipes.list) {
        await _recipes.save(r);
      }
    }

    // `_all` doit pouvoir résoudre N'IMPORTE QUEL aliment déjà logué/favori/
    // utilisé comme ingrédient, y compris venant de la base USDA (générale
    // ou Marque/Restaurant) — sans ça, un aliment USDA logué devenait
    // irrésolvable dans le journal (pictogramme, nom français, favoris,
    // tri fréquent/récent, agrégation micros du repas, sélecteur d'ingrédient
    // de recette : tout ça reposait uniquement sur `_all`). Retour d'Alex,
    // 12/08/2026. La visibilité PAR DÉFAUT de la base USDA dans l'onglet
    // "Commun" (recherche/parcours sans lien avec un aliment déjà connu)
    // reste filtrée séparément dans `_applyFilterSort` — cet ajout ici ne
    // change que ce qui est RÉSOLVABLE par id, pas ce qui s'affiche par
    // défaut.
    final list = <dynamic>[
      ...repo.items,
      ...repo.usdaItems,
      ...repo.brandItems,
      ..._customs.list,
      ..._recipes.list.map((r) => r.toFoodItem()),
    ];
    _cacheAll = list;
    setState(() => _all = list);
  }

  /// Recalcule les valeurs nutritionnelles d'une recette depuis ses ingrédients.
  /// Renvoie true si un recalcul a produit des valeurs non nulles.
  /// Retrouve un aliment dans la base en gérant les formats d'id hérités :
  /// id exact, code nu (-> ciqual:code), ou correspondance par nom normalisé.
  dynamic _findFoodFlexible(
      List<dynamic> baseFoods, String foodId, String foodName) {
    String idOf(dynamic f) => ((f as dynamic).id as String?) ?? '';
    // 1) Match exact
    for (final f in baseFoods) {
      if (idOf(f) == foodId) return f;
    }
    // 2) Code nu -> ciqual:code
    if (RegExp(r'^\d+$').hasMatch(foodId)) {
      final target = 'ciqual:$foodId';
      for (final f in baseFoods) {
        if (idOf(f) == target) return f;
      }
    }
    // Normalisation pour comparer les noms
    String norm(String x) => x
        .toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    // 3) Correspondance par nom
    final targetName = norm(foodName);
    if (targetName.isNotEmpty) {
      for (final f in baseFoods) {
        if (norm(((f as dynamic).name as String?) ?? '') == targetName) {
          return f;
        }
      }
    }
    // 4) L'ancien id était parfois le nom normalisé lui-même
    final normId = norm(foodId);
    if (normId.isNotEmpty) {
      for (final f in baseFoods) {
        if (norm(((f as dynamic).name as String?) ?? '') == normId) {
          return f;
        }
      }
    }
    return null;
  }

  bool _recomputeRecipeFromIngredients(_Recipe r, List<dynamic> baseFoods) {
    double totalKcal = 0, totalProt = 0, totalCarb = 0, totalFat = 0, totalFiber = 0;
    final Map<String, double> totalMicros = {};
    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    for (final ing in r.ingredients) {
      final food = _findFoodFlexible(baseFoods, ing.foodId, ing.foodName);
      if (food == null) {
        debugPrint('    ingredient introuvable: foodId=${ing.foodId} (${ing.foodName})');
        continue;
      }
      final f = ing.grams / 100.0;
      totalKcal  += getD((food as dynamic).kcal100) * f;
      totalProt  += getD((food).prot100) * f;
      totalCarb  += getD((food).carb100) * f;
      totalFat   += getD((food).fat100)  * f;
      totalFiber += getD((food).fiber100)* f;
      try {
        final micros = (food as dynamic).micros100 as Map<String, dynamic>?;
        micros?.forEach((key, val) {
          totalMicros[key] = (totalMicros[key] ?? 0) + getD(val) * f;
        });
      } catch (_) {}
    }

    if (totalKcal <= 0) return false; // ingrédients introuvables, on ne touche pas

    final ratio = r.totalWeightG > 0 ? 100.0 / r.totalWeightG : 1.0;
    r.kcal100  = totalKcal  * ratio;
    r.prot100  = totalProt  * ratio;
    r.carb100  = totalCarb  * ratio;
    r.fat100   = totalFat   * ratio;
    r.fiber100 = totalFiber * ratio;
    r.micros100 = Map<String, double>.fromEntries(
      totalMicros.entries.map((e) => MapEntry(e.key, e.value * ratio)));
    return true;
  }

  /// Un aliment USDA (générale/Marque/Restaurant) ne doit apparaître dans
  /// l'onglet "Commun" par défaut QUE s'il est déjà favori ou déjà logué au
  /// moins une fois — la découverte de nouveaux aliments USDA reste
  /// réservée à la bascule "Inclure la base USDA" du tiroir de filtre
  /// (mécanisme séparé, `_usdaMatches`). CIQUAL/perso/recettes sont
  /// toujours visibles (pas concernés par ce filtre). Retour d'Alex
  /// (12/08/2026) : un aliment USDA favori/fréquent doit rester visible
  /// dans "Commun" et "Favoris" quel que soit l'état de cette bascule.
  bool _visibleByDefaultInCommun(dynamic it) {
    if (!_isUsdaFood(it)) return true;
    final id = ((it as dynamic).id as String?) ?? '';
    return _fav.isFav(id) || _stats.count(id) > 0;
  }

  List<dynamic> _applyFilterSort(int tabIndex) {
    final q = _query.trim();
    Iterable<dynamic> base;
    switch (tabIndex) {
      case 1:
        base = _all.where((it) {
          try { return _fav.isFav(((it as dynamic).id as String)); }
          catch (_) { return false; }
        });
        break;
      case 2:
        base = _persoFilter == 0
            ? _all.where(_isPersonal)
            : _all.where(_isRecipe);
        if (_persoFilter == 1 && _onlyLibraryRecipes) {
          base = base.where((it) {
            final id = ((it as dynamic).id as String?) ?? '';
            return id.startsWith('recipe:totum_');
          });
        }
        break;
      case 0:
      default:
        // Affichage par défaut (pas de recherche) : uniquement la base
        // commune (+ aliments USDA déjà favoris/logués, voir
        // _visibleByDefaultInCommun ci-dessus), triée selon le mode choisi
        // (fréquent/récent/A→Z/Z→A), sans biais favoris. Dès qu'une
        // recherche est active, on cherche aussi parmi les aliments et
        // recettes perso — avant, "Commun" les excluait toujours, y
        // compris pendant une recherche par mot-clé. Le filtre USDA
        // s'applique aussi pendant la recherche : la découverte de
        // nouveaux aliments USDA passe par `_usdaMatches` (bascule dédiée),
        // pas par une frappe directe dans "Commun".
        base = q.isEmpty
            ? _all.where((it) =>
                !_isPersonal(it) && !_isRecipe(it) && _visibleByDefaultInCommun(it))
            : _all.where(_visibleByDefaultInCommun);
        break;
    }
    final arr = base.toList();
    arr.sort((a, b) {
      final an = (((a as dynamic).name) as String?) ?? '';
      final bn = (((b as dynamic).name) as String?) ?? '';
      // Recherche active : la pertinence prime, puis les favoris remontent
      // en premier parmi les résultats (dans Commun uniquement). Hors
      // recherche (affichage par défaut), aucun biais favoris — seul le
      // mode de tri choisi s'applique, comme demandé.
      if (q.isNotEmpty) {
        final s = _scoreForQuery(an, q).compareTo(_scoreForQuery(bn, q));
        if (s != 0) return s;
        if (tabIndex == 0) {
          bool favOf(dynamic x) {
            try { return _fav.isFav(((x as dynamic).id as String)); }
            catch (_) { return false; }
          }
          final fa = favOf(a), fb = favOf(b);
          if (fa != fb) return fa ? -1 : 1;
        }
      }
      switch (_sortMode) {
        case _SortMode.frequent:
          final s = _stats.count(((b as dynamic).id as String?) ?? '')
              .compareTo(_stats.count(((a as dynamic).id as String?) ?? ''));
          if (s != 0) return s;
          break;
        case _SortMode.recent:
          final s = _stats.last(((b as dynamic).id as String?) ?? '')
              .compareTo(_stats.last(((a as dynamic).id as String?) ?? ''));
          if (s != 0) return s;
          break;
        case _SortMode.az:
          final s = _norm(an).compareTo(_norm(bn));
          if (s != 0) return s;
          break;
        case _SortMode.za:
          final s = _norm(bn).compareTo(_norm(an));
          if (s != 0) return s;
          break;
      }
      if (q.isEmpty) return 0;
      return _scoreForQuery(an, q).compareTo(_scoreForQuery(bn, q));
    });
    return q.isEmpty
        ? arr
        : arr.where((it) {
            final n = _norm((((it as dynamic).name) as String?) ?? '');
            return n.contains(_norm(q));
          }).toList();
  }

  /// Retrouve un aliment/recette dans la liste globale par son id.
  dynamic _findFoodInAll(String foodId) {
    if (foodId.isEmpty) return null;
    for (final f in _all) {
      if (((f as dynamic).id as String?) == foodId) return f;
    }
    return null;
  }

  /// Snapshot des micronutriments pour [grams] g d'un item (aliment,
  /// perso ou recette). Retourne null si l'item est introuvable ou
  /// n'expose pas de micros — la lecture retombera alors sur le
  /// recalcul via la base (fallback).
  Map<String, double>? _microsSnapshot(dynamic it, double grams) {
    try {
      final map = (it as dynamic).micros100 as Map?;
      if (map == null || map.isEmpty || grams <= 0) return null;
      final f = grams / 100.0;
      final out = <String, double>{};
      map.forEach((k, v) {
        out[k.toString()] = ((v is num) ? v.toDouble() : 0.0) * f;
      });
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _addToJournal(String meal, dynamic it, double grams) async {
    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final f = grams / 100.0;
    final kcal  = getD(it.kcal100)  * f;
    final prot  = getD(it.prot100)  * f;
    final carb  = getD(it.carb100)  * f;
    final fat   = getD(it.fat100)   * f;
    final fiber = getD(it.fiber100) * f;
    final name = (it.name as String?) ?? 'Aliment';
    final id   = (it.id   as String?) ?? 'custom:temp';

    _journal[meal]!.add({
      'id': id, 'name': name, 'grams': grams,
      'kcal': kcal, 'prot': prot, 'carb': carb, 'fat': fat, 'fiber': fiber,
    });
    await _stats.bump(id);

    final micros = _microsSnapshot(it, grams);

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final ymd = _ymd(DateTime.now());
        final inserted = await _client.from('food_entries').insert({
          'user_id': user.id, 'entry_date': ymd, 'meal_type': meal,
          'food_id': id, 'food_name': name, 'quantity_grams': grams,
          'energy_kcal': kcal, 'protein_g': prot, 'carbs_g': carb,
          'fat_g': fat, 'fiber_g': fiber,
          'micros': micros,
        }).select('id').single();
        try {
          final entryId = inserted['id'];
          final list = _journal[meal];
          if (entryId != null && list != null && list.isNotEmpty) {
            list.last['entry_id'] = entryId;
          }
        } catch (_) {}
      }
    } catch (e) { debugPrint('Erreur ajout food_entries: $e'); }
    _recomputeTotals();
    await _saveDailySnapshot();
    // Rafraîchit la vue quotidienne pour que l'aliment ajouté apparaisse
    // immédiatement (sans avoir à changer de jour et revenir).
    _dayViewKey.currentState?.refreshCurrentDate();
  }

  /// Ajoute un aliment à un repas pour N'IMPORTE QUELLE date (passée incluse)
  Future<void> _addEntryToDate(
      String meal, dynamic it, double grams, DateTime date) async {
    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final f = grams / 100.0;
    final kcal  = getD(it.kcal100)  * f;
    final prot  = getD(it.prot100)  * f;
    final carb  = getD(it.carb100)  * f;
    final fat   = getD(it.fat100)   * f;
    final fiber = getD(it.fiber100) * f;
    final name = (it.name as String?) ?? 'Aliment';
    final id   = (it.id   as String?) ?? 'custom:temp';
    final ymd  = _ymd(date);

    final micros = _microsSnapshot(it, grams);

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('food_entries').insert({
          'user_id': user.id, 'entry_date': ymd, 'meal_type': meal,
          'food_id': id, 'food_name': name, 'quantity_grams': grams,
          'energy_kcal': kcal, 'protein_g': prot, 'carbs_g': carb,
          'fat_g': fat, 'fiber_g': fiber,
          'micros': micros,
        });
      }
    } catch (e) { debugPrint('Erreur ajout entrée date passée: $e'); }

    await _stats.bump(id);

    if (ymd == _ymd(DateTime.now())) {
      // Date = aujourd'hui → on garde le comportement existant
      _journal[meal]!.add({
        'id': id, 'name': name, 'grams': grams,
        'kcal': kcal, 'prot': prot, 'carb': carb, 'fat': fat, 'fiber': fiber,
      });
      _recomputeTotals();
      await _saveDailySnapshot();
    } else {
      // Date passée → on met aussi à jour le cache local hors-ligne
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_journalKeyForDate(date));
      Map<String, dynamic> decoded = {
        'Petit-déjeuner': [], 'Déjeuner': [], 'Dîner': [], 'Collation': [],
      };
      if (raw != null && raw.isNotEmpty) {
        try { decoded = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
      }
      final list = (decoded[meal] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      list.add({
        'id': id, 'name': name, 'grams': grams,
        'kcal': kcal, 'prot': prot, 'carb': carb, 'fat': fat, 'fiber': fiber,
      });
      decoded[meal] = list;
      await sp.setString(_journalKeyForDate(date), jsonEncode(decoded));

      // Recalcule les totaux de CETTE date (pas ceux, en mémoire, du jour
      // courant) et les snapshote — sans ça, la dépense énergétique
      // adaptative ne verrait jamais les repas ajoutés à une date passée
      // (voir le commentaire sur _saveDailySnapshot).
      double dKcal = 0, dProt = 0, dCarb = 0, dFat = 0, dFiber = 0;
      for (final mealList in decoded.values) {
        if (mealList is! List) continue;
        for (final e in mealList) {
          if (e is! Map) continue;
          dKcal  += (e['kcal']  as num?)?.toDouble() ?? 0.0;
          dProt  += (e['prot']  as num?)?.toDouble() ?? 0.0;
          dCarb  += (e['carb']  as num?)?.toDouble() ?? 0.0;
          dFat   += (e['fat']   as num?)?.toDouble() ?? 0.0;
          dFiber += (e['fiber'] as num?)?.toDouble() ?? 0.0;
        }
      }
      await _saveDailySnapshot(
        date: date, kcal: dKcal, prot: dProt, carb: dCarb, fat: dFat, fiber: dFiber,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => loading = true);
      final t = await computeAndSaveTargetsFromStoredProfile();
      _targets = t;
      _goals = t.goals;
      await Future.wait([
        _fav.load(), _stats.load(),
        _ensureFoodsLoaded(force: true),
        _loadJournalForToday(),
      ]);
      setState(() => loading = false);
    });
  }

  /// Recharge l'objectif/les cibles nutritionnelles — appelé par main.dart à
  /// chaque retour sur cet onglet. Les 4 onglets restent montés en
  /// permanence (IndexedStack, pour éviter le flash au changement d'onglet),
  /// donc `initState()` ne se relance plus jamais après le premier
  /// lancement : sans ce rafraîchissement explicite, un objectif modifié
  /// dans Tableau de bord ("Confirmer mes objectifs") ne se répercutait
  /// jamais dans le Journal tant que l'app n'était pas relancée — bug
  /// confirmé signalé par Alex. Ne recharge que les cibles (léger), pas la
  /// base d'aliments/favoris/stats déjà en mémoire.
  Future<void> refresh() async {
    if (!mounted) return;
    final t = await computeAndSaveTargetsFromStoredProfile();
    if (!mounted) return;
    setState(() {
      _targets = t;
      _goals = t.goals;
    });
  }

  Future<void> _openFoodSheet(dynamic it, {String? presetMeal}) async {
    if (_targets == null) return;
    final T = _targets!;
    double grams = 100;
    String meal = presetMeal ?? 'Déjeuner';
    final qtyCtrl = TextEditingController(text: '100');

    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    double micro(String key) {
      try {
        final map = (it as dynamic).micros100 as Map<String, dynamic>?;
        return getD(map?[key]);
      } catch (_) { return 0.0; }
    }

    Map<String, double> macros() {
      try {
        final m = ((it as dynamic).macrosFor(grams) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, getD(v)));
        return m;
      } catch (_) {
        final f = grams / 100.0;
        return {
          'kcal': getD((it as dynamic).kcal100) * f,
          'prot': getD((it).prot100) * f,
          'carb': getD((it).carb100) * f,
          'fat' : getD((it).fat100)  * f,
          'fiber':getD((it).fiber100)* f,
        };
      }
    }

    double ratio() => grams / 100.0;
    double asG(double x) => x * ratio();
    double asMg(double x) => x * ratio();
    double asUg(double x) => x * ratio();

    final oleicG = micro('Acide_oléique_W9_g_100g');
    final laG    = micro('Acide_linoléique_W6_LA_g_100g');
    final alaG   = micro('Acide_alpha-linolénique_W3_ALA_g_100g');
    final epaG   = micro('EPA_g_100g');
    final dhaG   = micro('DHA_g_100g');
    final satG   = micro('AG_saturés_g_100g');
    final cholMg = micro('Cholestérol_mg_100g');
    final sugarsG= micro('Sucres_g_100g');
    final saltG  = micro('Sel_g_100g');
    final caMg   = micro('Calcium_mg_100g');
    final cuMg   = micro('Cuivre_mg_100g');
    final feMg   = micro('Fer_mg_100g');
    final iUg    = micro('Iode_µg_100g');
    final mgMg   = micro('Magnésium_mg_100g');
    final mnMg   = micro('Manganèse_mg_100g');
    final pMg    = micro('Phosphore_mg_100g');
    final kMg    = micro('Potassium_mg_100g');
    final seUg   = micro('Sélénium_µg_100g');
    final naMg   = micro('Sodium_mg_100g');
    final znMg   = micro('Zinc_mg_100g');
    final retUg     = micro('Rétinol_µg_100g');
    final betaCarUg = micro('Beta-Carotène_µg_100g');
    final vdUg      = micro('Vitamine_D_µg_100g');
    final veMg   = micro('Vitamine_E_mg_100g');
    // K1 + K2 combinées : la vitamine K "totale" affichée partout ailleurs
    // dans l'app (Bilan, Conseils) additionne les deux formes — sinon un
    // aliment riche en K2 (oeuf, fromage affiné...) semble presque vide.
    final vkUg   = micro('Vitamine_K1_µg_100g') + micro('Vitamine_K2_µg_100g');
    final vcMg   = micro('Vitamine_C_mg_100g');
    final b1Mg   = micro('Vitamine_B1_mg_100g');
    final b2Mg   = micro('Vitamine_B2_mg_100g');
    final b3Mg   = micro('Vitamine_B3_mg_100g');
    final b5Mg   = micro('Vitamine_B5_mg_100g');
    final b6Mg   = micro('Vitamine_B6_mg_100g');
    final b9Ug   = micro('Vitamine_B9_µg_100g');
    final b12Ug  = micro('Vitamine_B12_µg_100g');

    // Description + composition de la recette (si l'aliment est une recette
    // perso) — la seule vue qui garde trace du dosage/des proportions
    // d'origine, sans quoi ils ne sont plus visibles une fois la recette
    // importée dans "Mes recettes" (seules les valeurs pour 100 g restent).
    String recipeDesc = '';
    List<_RecipeIngredient> recipeIngredients = const [];
    double recipeTotalWeight = 100;
    try {
      final fid = ((it as dynamic).id as String?) ?? '';
      if (fid.startsWith('recipe:')) {
        final r = _recipes.list.firstWhere(
          (x) => x.id == fid,
          orElse: () => _Recipe(
              id: '', name: '', ingredients: [],
              totalWeightG: 100, micros100: {}),
        );
        recipeDesc = r.description;
        recipeIngredients = r.ingredients;
        recipeTotalWeight = r.totalWeightG;
      }
    } catch (_) {}

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        List<_Metric> macroMetrics() => [
          _Metric('Énergie',   macros()['kcal'] ?? 0, T.goals.kcal, 'kcal', 0),
          _Metric('Protéines', macros()['prot'] ?? 0, T.goals.prot, 'g',    1),
          _Metric('Glucides',  macros()['carb'] ?? 0, T.goals.carb, 'g',    1),
          _Metric('Lipides',   macros()['fat']  ?? 0, T.goals.fat,  'g',    1),
          _Metric('Fibres',    macros()['fiber']?? 0, T.goals.fiber,'g',    1),
        ];
        List<_Metric> efaMetrics() => [
          _Metric('Oméga 9 (Oléique)', asG(oleicG), T.o9,  'g', 2),
          _Metric('Oméga 6 (LA)',      asG(laG),    T.o6,  'g', 2),
          _Metric('Oméga 3 (ALA)',     asG(alaG),   T.o3,  'g', 2),
          _Metric('EPA',               asG(epaG),   T.epa, 'g', 2),
          _Metric('DHA',               asG(dhaG),   T.dha, 'g', 2),
        ];
        List<_Metric> watchMetrics() => [
          _Metric('AG saturés', asG(satG),    T.sat,    'g', 2),
          _Metric('Sucres',     asG(sugarsG), T.sugars, 'g', 1),
          _Metric('Sel',        asG(saltG),   T.salt,   'g', 1),
          if (micro('Polyols_g_100g') * ratio() > 0.05)
            _Metric('Polyols', asG(micro('Polyols_g_100g')), null, 'g', 1),
          if (micro('Alcool_g_100g') * ratio() > 0.05)
            _Metric('Alcool', asG(micro('Alcool_g_100g')), null, 'g', 1),
        ];
        List<_Metric> vitaminMetrics() => [
          _Metric('Rétinol',   asUg(retUg),     T.vitAUg,       'µg', 0, ul: _kUlRetinolUg),
          _Metric('Bêta-car.', asUg(betaCarUg), T.vitBetacarUg, 'µg', 0),
          _Metric('Vit D', asUg(vdUg),  T.vitDUg, 'µg', 0),
          _Metric('Vit E', asMg(veMg),  T.vitEMg, 'mg', 1),
          _Metric('Vit K', asUg(vkUg),  T.vitKUg, 'µg', 0),
          _Metric('Vit C', asMg(vcMg),  T.vitCMg, 'mg', 0),
          _Metric('B1',    asMg(b1Mg),  T.b1Mg,   'mg', 1),
          _Metric('B2',    asMg(b2Mg),  T.b2Mg,   'mg', 1),
          _Metric('B3',    asMg(b3Mg),  T.b3Mg,   'mg', 1),
          _Metric('B5',    asMg(b5Mg),  T.b5Mg,   'mg', 1),
          _Metric('B6',    asMg(b6Mg),  T.b6Mg,   'mg', 1),
          _Metric('B9',    asUg(b9Ug),  T.b9Ug,   'µg', 0),
          _Metric('B12',   asUg(b12Ug), T.b12Ug,  'µg', 0),
        ];
        List<_Metric> mineralMetrics() => [
          _Metric('Calcium',   asMg(caMg), T.caMg, 'mg', 0),
          _Metric('Cuivre',    asMg(cuMg), T.cuMg, 'mg', 1),
          _Metric('Fer',       asMg(feMg), T.feMg, 'mg', 1, ul: _kUlFerMg),
          _Metric('Iode',      asUg(iUg),  T.iUg,  'µg', 0),
          _Metric('Magnésium', asMg(mgMg), T.mgMg, 'mg', 0),
          _Metric('Manganèse', asMg(mnMg), T.mnMg, 'mg', 1),
          _Metric('Phosphore', asMg(pMg),  T.pMg,  'mg', 0),
          _Metric('Potassium', asMg(kMg),  T.kMg,  'mg', 0),
          _Metric('Sélénium',  asUg(seUg), T.seUg, 'µg', 0, ul: _kUlSeleniumUg),
          _Metric('Sodium',    asMg(naMg), T.naMg, 'mg', 0),
          _Metric('Zinc',      asMg(znMg), T.znMg, 'mg', 1, ul: _kUlZincMg),
        ];
        List<_Metric> indicativeMetrics() => [
          _Metric('Cholestérol', asMg(cholMg), 1000.0, 'mg', 0),
        ];

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void onQtyChanged(String s) {
              final g = double.tryParse(s.replaceAll(',', '.'));
              if (g != null && g > 0) { grams = g; setSheetState(() {}); }
            }
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            // Bug corrigé (14/08/2026, retour d'Alex : "le
                            // nom est en français sur la ligne de recherche
                            // mais repasse en anglais une fois la fiche
                            // ouverte") : utilisait le nom brut au lieu de
                            // displayNameOf() (même fonction que partout
                            // ailleurs dans l'app), qui respecte la langue
                            // choisie dans Réglages → Langue des aliments.
                            displayNameOf(it, ((it as dynamic).name as String?) ?? ctx.l10n.jrnlGenericFoodFallback),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: _fav.isFav(
                                  ((it as dynamic).id as String? ?? ''))
                              ? ctx.l10n.jrnlRemoveFavorite
                              : ctx.l10n.jrnlAddFavorite,
                          icon: Icon(
                            _fav.isFav(((it as dynamic).id as String? ?? ''))
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _fav.isFav(((it as dynamic).id as String? ?? ''))
                                ? TotumColors.accent
                                : TotumColors.textMuted,
                          ),
                          onPressed: () async {
                            final id = ((it as dynamic).id as String?) ?? '';
                            if (id.isNotEmpty) {
                              await _fav.toggle(id);
                              if (mounted) setState(() {});
                              setSheetState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_photoOf(it) != null || _novaOf(it) != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                      child: Row(
                        children: [
                          if (_photoOf(it) != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _photoOf(it)!,
                                width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (_novaOf(it) != null) _NovaBadge(score: _novaOf(it)!, estime: _novaEstimeOf(it)),
                        ],
                      ),
                    ),
                  if (recipeDesc.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          recipeDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: TotumColors.textSecondary,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  // Composition d'origine (ingrédients + grammages) — le seul
                  // endroit où ce dosage reste consultable une fois la
                  // recette importée dans "Mes recettes".
                  if (recipeIngredients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          title: Text(
                            ctx.l10n.jrnlCompositionForGrams(
                                recipeTotalWeight.toStringAsFixed(0)),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          children: [
                            for (final ing in recipeIngredients)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(ing.foodName,
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                    Text('${ing.grams.toStringAsFixed(0)} g',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: TotumColors.textSecondary)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: ctx.l10n.jrnlQtyLabel,
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: onQtyChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: meal,
                            items: [
                              DropdownMenuItem(
                                  value: 'Petit-déjeuner',
                                  child: Text(ctx.l10n.consCatBreakfast)),
                              DropdownMenuItem(
                                  value: 'Déjeuner',
                                  child: Text(ctx.l10n.consCatLunch)),
                              DropdownMenuItem(
                                  value: 'Dîner', child: Text(ctx.l10n.consCatDinner)),
                              DropdownMenuItem(
                                  value: 'Collation',
                                  child: Text(ctx.l10n.consCatSnack)),
                            ],
                            onChanged: (v) => meal = v ?? 'Déjeuner',
                            decoration: InputDecoration(
                              labelText: ctx.l10n.jrnlMealDropdownLabel,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Portions courantes (Priorité 40, retour d'Alex : éviter
                  // la sous-estimation calorique de qui logue "100 g" par
                  // défaut pour, par exemple, un burger bien plus lourd) —
                  // uniquement pour les aliments USDA, seule base où ce
                  // poids de référence est mesuré (pas de données CIQUAL
                  // équivalentes fiables, donc rien n'est inventé côté
                  // CIQUAL). Repli silencieux : rien ne s'affiche pour un
                  // aliment sans portion connue.
                  Builder(builder: (_) {
                    final foodId = ((it as dynamic).id as String?) ?? '';
                    final portions = foods_loader.FoodsRepository.instance
                        .portionsFor(foodId);
                    if (portions.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final p in portions.take(4))
                            ActionChip(
                              label: Text(
                                  '${frenchPortionLabel(p.label)} · ${p.grams.toStringAsFixed(0)} g',
                                  style: const TextStyle(fontSize: 12)),
                              backgroundColor: TotumColors.accentSoft,
                              side: BorderSide.none,
                              onPressed: () {
                                qtyCtrl.text = p.grams.toStringAsFixed(0);
                                onQtyChanged(qtyCtrl.text);
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [
                        _Section(title: 'Macro-cibles', icon: Icons.bolt,
                            initiallyExpanded: true, metrics: macroMetrics()),
                        if (micro('Amidon_g_100g') +
                                micro('Fructose_g_100g') +
                                micro('Glucose_g_100g') +
                                micro('Saccharose_g_100g') >
                            0.1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: OutlinedButton.icon(
                              onPressed: () => showGlucidesBreakdown(
                                ctx,
                                (it as dynamic).micros100
                                    as Map<String, double>,
                                portionLabel: ctx.l10n.jrnlCompositionFor100g,
                              ),
                              icon: const Icon(Icons.donut_small,
                                  size: 18, color: TotumColors.accent),
                              label: Text(ctx.l10n.jrnlGlucidesDetailButton),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: TotumColors.accent,
                                side: const BorderSide(
                                    color: TotumColors.accent),
                                minimumSize: const Size.fromHeight(40),
                              ),
                            ),
                          ),
                        _Section(title: 'Acides gras essentiels',
                            icon: Icons.opacity, metrics: efaMetrics()),
                        _Section(title: 'À surveiller',
                            icon: Icons.visibility_outlined, metrics: watchMetrics()),
                        _Section(title: 'Vitamines',
                            icon: Icons.wb_sunny_outlined, metrics: vitaminMetrics()),
                        _Section(title: 'Minéraux',
                            icon: Icons.diamond_outlined, metrics: mineralMetrics()),
                        _Section(title: 'Apport indicatif',
                            icon: Icons.info_outline, metrics: indicativeMetrics()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent(context),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () async {
                        await _addToJournal(meal, it, grams);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      label: Text(ctx.l10n.jrnlAddToJournal),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// La page d'ajout d'aliment (recherche + Commun/Favoris/Perso).
  /// Ouverte via le bouton central « + » de la barre de navigation.
  Widget _buildSearchScaffold(BuildContext context) {
    return _AddFoodPage(parent: this);
  }

  /// L'onglet Journal affiche directement la vue quotidienne.
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _DayJournalView(
      key: _dayViewKey,
      initialDate: DateTime.now(),
      goals: _goals,
      loadJournalForDate: _loadJournalForDate,
      onRemoveEntry: _removeEntry,
      onEditEntry: _editEntry,
      onCopyMeal: _copyMealToDate,
      onSaveAsCustomMeal: _saveMealAsTemplate,
      onAddEntry: _addEntryToDate,
      onScanForMeal: _openBarcodeScannerForMeal,
      nutritionTargets: _targets,
      allFoods: _all,
      isFav: (id) => _fav.isFav(id),
      onToggleFav: (id) async {
        await _fav.toggle(id);
        if (mounted) setState(() {});
      },
      onClearMeal: _clearMeal,
      foodStats: _stats,
      customMeals: _customMeals.list,
      onAddCustomMeal: _addCustomMealToDate,
    );
  }

  /// Ouvre la page d'ajout d'aliment (appelée par le bouton central « + »).
  Future<void> openAddPage() async {
    if (_all.isEmpty) {
      await _ensureFoodsLoaded();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _buildSearchScaffold(context)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _removeEntry(String meal, int index,
      Map<String, dynamic> entry, DateTime date) async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final ymd = _ymd(date);
        var query = _client.from('food_entries').delete()
            .eq('user_id', user.id).eq('entry_date', ymd).eq('meal_type', meal);
        final dynamic entryId = entry['entry_id'];
        if (entryId != null) {
          query = query.eq('id', entryId);
        } else {
          // Sécurité : sans entry_id fiable, on ne supprime rien plutôt
          // que de risquer d'effacer la mauvaise ligne.
          debugPrint('Suppression annulée : entry_id manquant.');
          return;
        }
        await query;
      }
    } catch (e) { debugPrint('Erreur suppression Supabase: $e'); }

    if (_ymd(date) == _ymd(DateTime.now())) {
      // index == -1 : la ligne a déjà été retirée localement par l'appelant,
      // on se contente de persister l'état courant.
      final list = _journal[meal];
      if (index >= 0 && list != null && index < list.length) {
        list.removeAt(index);
      }
      _recomputeTotals();
      await _saveDailySnapshot();
    }
  }

  Future<void> _editEntry(Map<String, dynamic> entry, String oldMeal,
      String newMeal, double newGrams, DateTime date) async {
    final oldGrams = (entry['grams'] as num?)?.toDouble() ?? 100.0;
    final ratio = oldGrams > 0 ? newGrams / oldGrams : 1.0;
    final newKcal  = ((entry['kcal']  as num?)?.toDouble() ?? 0) * ratio;
    final newProt  = ((entry['prot']  as num?)?.toDouble() ?? 0) * ratio;
    final newCarb  = ((entry['carb']  as num?)?.toDouble() ?? 0) * ratio;
    final newFat   = ((entry['fat']   as num?)?.toDouble() ?? 0) * ratio;
    final newFiber = ((entry['fiber'] as num?)?.toDouble() ?? 0) * ratio;

    // Snapshot micros recalculé pour la nouvelle quantité
    final foodId = (entry['id'] ?? '').toString();
    Map<String, double>? newMicros =
        _microsSnapshot(_findFoodInAll(foodId), newGrams);

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final dynamic entryId = entry['entry_id'];
        if (entryId != null) {
          // Si l'aliment n'existe plus (ex: recette supprimée), on met à
          // l'échelle le snapshot déjà stocké en base pour le préserver.
          if (newMicros == null) {
            try {
              final row = await _client
                  .from('food_entries')
                  .select('micros')
                  .eq('id', entryId)
                  .single();
              final snap = row['micros'];
              if (snap is Map && snap.isNotEmpty) {
                newMicros = {};
                snap.forEach((k, v) {
                  newMicros![k.toString()] =
                      ((v is num) ? v.toDouble() : 0.0) * ratio;
                });
              }
            } catch (_) {}
          }
          await _client.from('food_entries').update({
            'meal_type': newMeal, 'quantity_grams': newGrams,
            'energy_kcal': newKcal, 'protein_g': newProt,
            'carbs_g': newCarb, 'fat_g': newFat, 'fiber_g': newFiber,
            'micros': newMicros,
          }).eq('id', entryId).eq('user_id', user.id);
        }
      }
    } catch (e) { debugPrint('Erreur modification Supabase: $e'); }

    if (_ymd(date) == _ymd(DateTime.now())) {
      final oldList = _journal[oldMeal];
      if (oldList != null) {
        final idx = oldList.indexWhere((e) => e['entry_id'] == entry['entry_id']);
        if (idx >= 0) oldList.removeAt(idx);
      }
      _journal[newMeal]!.add({
        ...entry,
        'meal_type': newMeal, 'grams': newGrams,
        'kcal': newKcal, 'prot': newProt, 'carb': newCarb,
        'fat': newFat, 'fiber': newFiber,
      });
      _recomputeTotals();
      await _saveDailySnapshot();
    }
  }

  Future<void> _copyMealToDate(List<Map<String, dynamic>> items,
      String sourceMeal, String targetMeal, DateTime targetDate) async {
    if (items.isEmpty) return;
    final ymd = _ymd(targetDate);
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        for (final item in items) {
          final fid = (item['id'] ?? '').toString();
          final g = (item['grams'] as num?)?.toDouble() ?? 0.0;
          final micros = _microsSnapshot(_findFoodInAll(fid), g);
          await _client.from('food_entries').insert({
            'user_id': user.id, 'entry_date': ymd, 'meal_type': targetMeal,
            'food_id': item['id'] ?? '',
            'food_name': item['name'] ?? 'Aliment',
            'quantity_grams': item['grams'] ?? 0,
            'energy_kcal': item['kcal'] ?? 0,
            'protein_g': item['prot'] ?? 0,
            'carbs_g': item['carb'] ?? 0,
            'fat_g': item['fat'] ?? 0,
            'fiber_g': item['fiber'] ?? 0,
            'micros': micros,
          });
        }
      }
    } catch (e) { debugPrint('Erreur copie repas Supabase: $e'); }

    if (ymd == _ymd(DateTime.now())) {
      for (final item in items) {
        _journal[targetMeal]!.add(Map<String, dynamic>.from(item)
          ..['meal_type'] = targetMeal);
      }
      _recomputeTotals();
      await _saveDailySnapshot();
    }
  }

  /// Enregistre le contenu d'un repas comme "repas perso" réutilisable —
  /// même contenu figé (aliments + grammes + macros) que ce que copie déjà
  /// `_copyMealToDate` vers un autre jour, juste stocké comme modèle au lieu
  /// d'être rejoué immédiatement.
  Future<void> _saveMealAsTemplate(
      String name, List<Map<String, dynamic>> items) async {
    if (items.isEmpty || name.trim().isEmpty) return;
    final meal = _CustomMeal(
      id: 'meal:${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      items: items.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
    await _customMeals.add(meal);
    if (mounted) setState(() {});
  }

  /// Ajoute le contenu d'un repas perso à un jour/repas donné — même
  /// mécanisme que "Copier ce repas" (le paramètre sourceMeal n'est en
  /// réalité pas utilisé par _copyMealToDate, uniquement les items).
  Future<void> _addCustomMealToDate(
      _CustomMeal meal, String targetMeal, DateTime targetDate) async {
    await _copyMealToDate(meal.items, '', targetMeal, targetDate);
  }

  Future<void> _clearMeal(String meal, DateTime date) async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('food_entries').delete()
            .eq('user_id', user.id)
            .eq('entry_date', _ymd(date))
            .eq('meal_type', meal);
      }
    } catch (e) { debugPrint('Erreur clear meal: $e'); }

    if (_ymd(date) == _ymd(DateTime.now())) {
      setState(() { _journal[meal] = []; });
      _recomputeTotals();
      await _saveDailySnapshot();
    }
  }

  /// Scanner lié à un repas précis : le produit scanné sera pré-affecté
  /// à ce repas dans la fiche produit.
  final GlobalKey<_DayJournalViewState> _dayViewKey =
      GlobalKey<_DayJournalViewState>();
  String? _scanTargetMeal;

  Future<void> _openBarcodeScannerForMeal(String meal) async {
    _scanTargetMeal = meal;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeScanScreen(
          onBarcode: (code) async { await _handleBarcode(code); },
        ),
      ),
    );
    // _scanTargetMeal est remis à null dans _handleBarcode après usage,
    // pour rester disponible pendant l'ouverture de la fiche produit.
  }

  Future<void> _openBarcodeScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeScanScreen(
          onBarcode: (code) async { await _handleBarcode(code); },
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: TextStyle(color: TotumColors.negative, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  List<String> _barcodeVariants(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final variants = <String>{digits};
    if (digits.length == 12) variants.add('0$digits');
    if (digits.length == 13 && digits.startsWith('0')) {
      variants.add(digits.substring(1));
    }
    if (digits.length > 13) variants.add(digits.substring(digits.length - 13));
    if (digits.length > 12) variants.add(digits.substring(digits.length - 12));
    return variants.toList();
  }

  Future<Map<String, dynamic>?> _fetchOFF(String code) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final uri = Uri.https('world.openfoodfacts.org', '/api/v0/product/$code.json');
        final resp = await http.get(uri).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          if ((json['status'] as int? ?? 0) == 1) return json;
        }
      } catch (_) {}
      if (attempt < 2) await Future.delayed(const Duration(milliseconds: 600));
    }
    return null;
  }

  Future<void> _handleBarcode(String rawBarcode) async {
      final l10n = context.l10n;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(ctx.l10n.jrnlSearchingProduct, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final variants = _barcodeVariants(rawBarcode);
        Map<String, dynamic>? data;
        String? usedCode;
        for (final code in variants) {
          data = await _fetchOFF(code);
          if (data != null) { usedCode = code; break; }
        }

        if (mounted && Navigator.canPop(context)) Navigator.pop(context);

        if (data == null) {
          _showErrorDialog(
            l10n.jrnlProductNotFoundTitle,
            l10n.jrnlProductNotFoundBody,
          );
          return;
        }

        final product = data['product'] as Map<String, dynamic>;
        final Map<String, dynamic> nutriments =
            (product['nutriments'] as Map?)?.cast<String, dynamic>() ?? {};

        // ── Helpers de conversion ─────────────────────────────────────────
        double toD(dynamic v) {
          if (v == null) return 0.0;
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
          return 0.0;
        }
        double? toDN(dynamic v) {
          if (v == null) return null;
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v.replaceAll(',', '.'));
          return null;
        }

        // ── Nom du produit ────────────────────────────────────────────────
        String name = (product['product_name'] ?? '').toString().trim();
        if (name.isEmpty) {
          name = (product['product_name_fr'] ??
                  product['product_name_en'] ??
                  l10n.jrnlScannedProductFallback).toString().trim();
        }
        if (name.isEmpty) name = l10n.jrnlScannedProductFallback;

        // ── Macros ────────────────────────────────────────────────────────
        final kcal100 = toDN(
          nutriments['energy-kcal_100g'] ??
          nutriments['energy-kcal'] ??
          nutriments['energy_100g'] ??
          (nutriments['energy-kj_100g'] != null
              ? toD(nutriments['energy-kj_100g']) / 4.184
              : null),
        );
        final prot100  = toDN(nutriments['proteins_100g']       ?? nutriments['proteins']);
        final carb100  = toDN(nutriments['carbohydrates_100g']   ?? nutriments['carbohydrates']);
        final fat100   = toDN(nutriments['fat_100g']             ?? nutriments['fat']);
        final fiber100 = toDN(nutriments['fiber_100g']           ?? nutriments['fiber']);

        // ── Micronutriments : initialisation à 0 ─────────────────────────
        final Map<String, double> micros = {
          'AG_saturés_g_100g': 0,
          'Acide_oléique_W9_g_100g': 0,
          'Acide_linoléique_W6_LA_g_100g': 0,
          'Acide_alpha-linolénique_W3_ALA_g_100g': 0,
          'EPA_g_100g': 0,
          'DHA_g_100g': 0,
          'Sucres_g_100g': 0,
          'Sel_g_100g': 0,
          'Cholestérol_mg_100g': 0,
          'Calcium_mg_100g': 0,
          'Cuivre_mg_100g': 0,
          'Fer_mg_100g': 0,
          'Iode_µg_100g': 0,
          'Magnésium_mg_100g': 0,
          'Manganèse_mg_100g': 0,
          'Phosphore_mg_100g': 0,
          'Potassium_mg_100g': 0,
          'Sélénium_µg_100g': 0,
          'Sodium_mg_100g': 0,
          'Zinc_mg_100g': 0,
          'Rétinol_µg_100g': 0,
          'Beta-Carotène_µg_100g': 0,
          'Vitamine_D_µg_100g': 0,
          'Vitamine_E_mg_100g': 0,
          'Vitamine_K1_µg_100g': 0,
          'Vitamine_K2_µg_100g': 0,
          'Vitamine_C_mg_100g': 0,
          'Vitamine_B1_mg_100g': 0,
          'Vitamine_B2_mg_100g': 0,
          'Vitamine_B3_mg_100g': 0,
          'Vitamine_B5_mg_100g': 0,
          'Vitamine_B6_mg_100g': 0,
          'Vitamine_B9_µg_100g': 0,
          'Vitamine_B12_µg_100g': 0,
        };

        // ── Fonction utilitaire : cherche la première clé non nulle ───────
        double offVal(List<String> keys) {
          for (final k in keys) {
            final v = nutriments[k];
            if (v != null) {
              final d = toD(v);
              if (d > 0) return d;
            }
          }
          return 0.0;
        }

        // ── Mapping exhaustif OFF → clés TOTUM ───────────────────────────
        micros['AG_saturés_g_100g'] = offVal([
          'saturated-fat_100g', 'saturated-fat', 'saturates_100g',
        ]);
        micros['Sucres_g_100g'] = offVal([
          'sugars_100g', 'sugars',
        ]);
        micros['Sel_g_100g'] = offVal([
          'salt_100g', 'salt',
        ]);
        micros['Sodium_mg_100g'] = offVal([
          'sodium_100g', 'sodium',
        ]);
        micros['Cholestérol_mg_100g'] = offVal([
          'cholesterol_100g', 'cholesterol',
        ]);

        // Acides gras
        micros['Acide_oléique_W9_g_100g'] = offVal([
          'oleic-acid_100g', 'oleic-acid', 'omega-9_100g', 'omega-9',
        ]);
        micros['Acide_linoléique_W6_LA_g_100g'] = offVal([
          'linoleic-acid_100g', 'linoleic-acid', 'omega-6_100g', 'omega-6',
        ]);
        micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = offVal([
          'alpha-linolenic-acid_100g', 'alpha-linolenic-acid',
          'omega-3_100g', 'omega-3',
        ]);
        micros['EPA_g_100g'] = offVal([
          'eicosapentaenoic-acid_100g', 'eicosapentaenoic-acid', 'epa_100g', 'epa',
        ]);
        micros['DHA_g_100g'] = offVal([
          'docosahexaenoic-acid_100g', 'docosahexaenoic-acid', 'dha_100g', 'dha',
        ]);

        // Minéraux
        micros['Calcium_mg_100g'] = offVal([
          'calcium_100g', 'calcium',
        ]);
        micros['Cuivre_mg_100g'] = offVal([
          'copper_100g', 'copper',
        ]);
        micros['Fer_mg_100g'] = offVal([
          'iron_100g', 'iron',
        ]);
        micros['Iode_µg_100g'] = offVal([
          'iodine_100g', 'iodine',
        ]);
        micros['Magnésium_mg_100g'] = offVal([
          'magnesium_100g', 'magnesium',
        ]);
        micros['Manganèse_mg_100g'] = offVal([
          'manganese_100g', 'manganese',
        ]);
        micros['Phosphore_mg_100g'] = offVal([
          'phosphorus_100g', 'phosphorus', 'phosphore_100g',
        ]);
        micros['Potassium_mg_100g'] = offVal([
          'potassium_100g', 'potassium',
        ]);
        micros['Sélénium_µg_100g'] = offVal([
          'selenium_100g', 'selenium',
        ]);
        micros['Zinc_mg_100g'] = offVal([
          'zinc_100g', 'zinc',
        ]);

        // Vitamines
        micros['Rétinol_µg_100g'] = offVal([
          'retinol_100g', 'retinol',
          'vitamin-a_100g', 'vitamin-a',
        ]);
        micros['Beta-Carotène_µg_100g'] = offVal([
          'beta-carotene_100g', 'beta-carotene',
          'carotene_100g', 'carotene',
        ]);
        micros['Vitamine_D_µg_100g'] = offVal([
          'vitamin-d_100g', 'vitamin-d',
          'vitamin-d3_100g', 'vitamin-d3',
        ]);
        micros['Vitamine_E_mg_100g'] = offVal([
          'vitamin-e_100g', 'vitamin-e',
        ]);
        micros['Vitamine_K1_µg_100g'] = offVal([
          'vitamin-k_100g', 'vitamin-k',
          'vitamin-k1_100g', 'vitamin-k1',
          'phylloquinone_100g',
        ]);
        micros['Vitamine_K2_µg_100g'] = offVal([
          'vitamin-k2_100g', 'vitamin-k2', 'menaquinone_100g',
        ]);
        micros['Vitamine_C_mg_100g'] = offVal([
          'vitamin-c_100g', 'vitamin-c',
          'ascorbic-acid_100g',
        ]);
        micros['Vitamine_B1_mg_100g'] = offVal([
          'vitamin-b1_100g', 'vitamin-b1',
          'thiamin_100g', 'thiamine_100g',
        ]);
        micros['Vitamine_B2_mg_100g'] = offVal([
          'vitamin-b2_100g', 'vitamin-b2',
          'riboflavin_100g',
        ]);
        micros['Vitamine_B3_mg_100g'] = offVal([
          'vitamin-b3_100g', 'vitamin-b3',
          'niacin_100g', 'niacin',
          'vitamin-pp_100g', 'vitamin-pp',
        ]);
        micros['Vitamine_B5_mg_100g'] = offVal([
          'vitamin-b5_100g', 'vitamin-b5',
          'pantothenic-acid_100g', 'pantothenic-acid',
        ]);
        micros['Vitamine_B6_mg_100g'] = offVal([
          'vitamin-b6_100g', 'vitamin-b6',
          'pyridoxine_100g',
        ]);
        micros['Vitamine_B9_µg_100g'] = offVal([
          'vitamin-b9_100g', 'vitamin-b9',
          'folates_100g', 'folates',
          'folic-acid_100g', 'folic-acid',
          'folate_100g', 'folate',
        ]);
        micros['Vitamine_B12_µg_100g'] = offVal([
          'vitamin-b12_100g', 'vitamin-b12',
          'cobalamin_100g',
        ]);
        
        // ── Conversion g → mg ou µg pour les minéraux/vitamines ──────────────
        double convertToMg(double val) => val < 1.0 ? val * 1000 : val;
        double convertToUg(double val) => val < 0.01 ? val * 1000000 : val < 1.0 ? val * 1000 : val;

        micros['Calcium_mg_100g']     = convertToMg(micros['Calcium_mg_100g']!);
        micros['Cuivre_mg_100g']      = convertToMg(micros['Cuivre_mg_100g']!);
        micros['Fer_mg_100g']         = convertToMg(micros['Fer_mg_100g']!);
        micros['Magnésium_mg_100g']   = convertToMg(micros['Magnésium_mg_100g']!);
        micros['Manganèse_mg_100g']   = convertToMg(micros['Manganèse_mg_100g']!);
        micros['Phosphore_mg_100g']   = convertToMg(micros['Phosphore_mg_100g']!);
        micros['Potassium_mg_100g']   = convertToMg(micros['Potassium_mg_100g']!);
        micros['Sodium_mg_100g']      = convertToMg(micros['Sodium_mg_100g']!);
        micros['Zinc_mg_100g']        = convertToMg(micros['Zinc_mg_100g']!);
        micros['Vitamine_E_mg_100g']  = convertToMg(micros['Vitamine_E_mg_100g']!);
        micros['Vitamine_C_mg_100g']  = convertToMg(micros['Vitamine_C_mg_100g']!);
        micros['Vitamine_B1_mg_100g'] = convertToMg(micros['Vitamine_B1_mg_100g']!);
        micros['Vitamine_B2_mg_100g'] = convertToMg(micros['Vitamine_B2_mg_100g']!);
        micros['Vitamine_B3_mg_100g'] = convertToMg(micros['Vitamine_B3_mg_100g']!);
        micros['Vitamine_B5_mg_100g'] = convertToMg(micros['Vitamine_B5_mg_100g']!);
        micros['Vitamine_B6_mg_100g'] = convertToMg(micros['Vitamine_B6_mg_100g']!);
        micros['Iode_µg_100g']        = convertToUg(micros['Iode_µg_100g']!);
        micros['Sélénium_µg_100g']    = convertToUg(micros['Sélénium_µg_100g']!);
        micros['Rétinol_µg_100g']         = convertToUg(micros['Rétinol_µg_100g']!);
        micros['Beta-Carotène_µg_100g']   = convertToUg(micros['Beta-Carotène_µg_100g']!);
        micros['Vitamine_D_µg_100g']      = convertToUg(micros['Vitamine_D_µg_100g']!);
        micros['Vitamine_K1_µg_100g'] = convertToUg(micros['Vitamine_K1_µg_100g']!);
        micros['Vitamine_B9_µg_100g'] = convertToUg(micros['Vitamine_B9_µg_100g']!);
        micros['Vitamine_B12_µg_100g']= convertToUg(micros['Vitamine_B12_µg_100g']!);

        // ── Score NOVA officiel + photo produit (Open Food Facts) ─────────
        // Contrairement au score NOVA estimé sur la base CIQUAL (aucune
        // donnée officielle disponible), OFF fournit directement le NOVA
        // pour les produits scannés — fiable à 100 %, jamais recalculé ici.
        final novaGroup = int.tryParse('${product['nova_group'] ?? product['nova_groups'] ?? ''}');
        String? imageUrl = (product['image_front_url'] ?? product['image_url'])?.toString();
        if (imageUrl != null && imageUrl.trim().isEmpty) imageUrl = null;

        // ── Construction du FoodItem ──────────────────────────────────────
        final item = foods_loader.FoodItem(
          id: 'off:$usedCode',
          name: name,
          kcal100: kcal100,
          prot100: prot100,
          carb100: carb100,
          fat100: fat100,
          fiber100: fiber100,
          micros100: micros,
          novaScore: novaGroup,
          novaEstime: false,
          imageUrl: imageUrl,
        );

        final customFood = _CustomFood(
          id: item.id, name: item.name,
          kcal100: item.kcal100, prot100: item.prot100,
          carb100: item.carb100, fat100: item.fat100,
          fiber100: item.fiber100, micros100: item.micros100,
          imageUrl: item.imageUrl, novaScore: item.novaScore,
          novaEstime: item.novaEstime,
        );

        // 1) On sauvegarde dans LES DEUX stores (local + Supabase) AVANT
        //    de recharger quoi que ce soit, pour que toutes les sources
        //    soient déjà cohérentes au moment du rechargement.
        final repo = foods_loader.FoodsRepository.instance;
        repo.addCustomFood(item);
        await repo.saveCustomFoods();
        await _customs.add(customFood);

        // 2) Ouverture de la fiche (utilise l'objet 'item' en mémoire,
        //    toujours correct peu importe l'état des caches)
        final targetMeal = _scanTargetMeal;
        _scanTargetMeal = null;
        await _openFoodSheet(item, presetMeal: targetMeal);
        // Rafraîchit la vue "jour" si elle est ouverte (le scan y ajoute).
        _dayViewKey.currentState?.refreshCurrentDate();

        // 3) Seulement maintenant on recharge les caches, une fois que
        //    les deux stores sont garantis synchronisés
        await _ensureFoodsLoaded(force: true);
        if (mounted) setState(() {});

      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        _showErrorDialog(l10n.jrnlTechnicalErrorTitle,
            l10n.jrnlScanErrorBody(e.toString()));
      }
    }

  /// Ouvre l'éditeur de repas perso (création ou modification) — même
  /// pattern que [_openRecipeEditor], en plus simple : un repas perso est
  /// une somme figée d'aliments, pas une recette normalisée pour 100g.
  Future<void> _openMealEditor({_CustomMeal? editMeal}) async {
    if (_all.isEmpty) {
      await _ensureFoodsLoaded();
      if (!mounted) return;
    }
    final isEdit = editMeal != null;
    final id = isEdit ? editMeal.id : 'meal:${DateTime.now().microsecondsSinceEpoch}';
    final nameCtl = TextEditingController(text: isEdit ? editMeal.name : '');
    final descCtl = TextEditingController(text: isEdit ? editMeal.description : '');
    final items = isEdit
        ? editMeal.items.map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MealEditorScreen(
        id: id, nameCtl: nameCtl, descCtl: descCtl, items: items,
        allFoods: _all, isEdit: isEdit,
        isFav: (fid) => _fav.isFav(fid),
        foodStats: _stats,
        onSave: (meal) async {
          if (isEdit) {
            await _customMeals.update(meal);
          } else {
            await _customMeals.add(meal);
          }
          if (mounted) setState(() {});
        },
      ),
    ));
  }

  /// Fiche détail d'un repas perso : composition, description, favori,
  /// et point d'entrée vers "Modifier"/"Ajouter au journal" — même besoin
  /// de visibilité qu'un aliment/une recette avant de l'ajouter.
  Future<void> _openMealDetailSheet(_CustomMeal meal) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final fav = _fav.isFav(meal.id);
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: TotumColors.page,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: TotumColors.outlineStrong, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(meal.name,
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
                      ),
                      IconButton(
                        tooltip: fav ? ctx.l10n.jrnlRemoveFavorite : ctx.l10n.jrnlAddFavorite,
                        icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                            color: fav ? TotumColors.accent : TotumColors.textMuted),
                        onPressed: () async {
                          await _fav.toggle(meal.id);
                          setSheet(() {});
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (meal.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(meal.description,
                        style: TextStyle(fontSize: 13, color: TotumColors.textSecondary, height: 1.4)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12, runSpacing: 4,
                    children: [
                      _NutriBadge('Énergie', '${meal.totalKcal.toStringAsFixed(0)} kcal'),
                      _NutriBadge('Protéines', '${meal.totalProt.toStringAsFixed(1)} g'),
                      _NutriBadge('Glucides', '${meal.totalCarb.toStringAsFixed(1)} g'),
                      _NutriBadge('Lipides', '${meal.totalFat.toStringAsFixed(1)} g'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(ctx.l10n.jrnlItemCountPlain(meal.items.length),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TotumColors.textSecondary)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      itemCount: meal.items.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: TotumColors.outline),
                      itemBuilder: (_, i) {
                        final it = meal.items[i];
                        final g = (it['grams'] as num?)?.toDouble() ?? 0.0;
                        final kc = (it['kcal'] as num?)?.toDouble() ?? 0.0;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text((it['name'] ?? '').toString(),
                              style: TextStyle(color: TotumColors.textPrimary)),
                          subtitle: Text('${g.toStringAsFixed(0)} g',
                              style: TextStyle(color: TotumColors.textSecondary)),
                          trailing: Text('${kc.toStringAsFixed(0)} kcal',
                              style: TextStyle(color: TotumColors.textSecondary)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openMealEditor(editMeal: meal);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(ctx.l10n.sunModifyButton),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: kTotumOrange, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _addMealTemplateDialog(meal);
                          },
                          icon: const Icon(Icons.add),
                          label: Text(ctx.l10n.jrnlAddToJournal),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Choix du jour/repas où ajouter un repas perso — même schéma que
  /// "Copier ce repas", plus simple (pas de choix de destination, la source
  /// est déjà un modèle enregistré).
  Future<void> _addMealTemplateDialog(_CustomMeal meal) async {
    String targetMeal = 'Petit-déjeuner';
    DateTime targetDate = DateTime.now();
    final dateCtrl = TextEditingController(
        text: '${targetDate.day.toString().padLeft(2, '0')}/'
            '${targetDate.month.toString().padLeft(2, '0')}/'
            '${targetDate.year}');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(ctx.l10n.jrnlAddQuoted(meal.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ctx.l10n.jrnlItemsAndKcal(meal.items.length, meal.totalKcal.toStringAsFixed(0)),
                  style: TextStyle(color: TotumColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: targetDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    setDlg(() {
                      targetDate = picked;
                      dateCtrl.text = '${picked.day.toString().padLeft(2, '0')}/'
                          '${picked.month.toString().padLeft(2, '0')}/'
                          '${picked.year}';
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: ctx.l10n.jrnlTowardDay,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(dateCtrl.text),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetMeal,
                decoration: InputDecoration(
                  labelText: ctx.l10n.jrnlTowardMeal,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem(value: 'Petit-déjeuner', child: Text(ctx.l10n.consCatBreakfast)),
                  DropdownMenuItem(value: 'Déjeuner', child: Text(ctx.l10n.consCatLunch)),
                  DropdownMenuItem(value: 'Dîner', child: Text(ctx.l10n.consCatDinner)),
                  DropdownMenuItem(value: 'Collation', child: Text(ctx.l10n.consCatSnack)),
                ],
                onChanged: (v) { if (v != null) setDlg(() => targetMeal = v); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.commonCancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kTotumOrange, foregroundColor: Colors.white),
              onPressed: () async {
                final l10n = ctx.l10n;
                Navigator.pop(ctx);
                await _addCustomMealToDate(meal, targetMeal, targetDate);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.jrnlAddedTo(meal.name, _mealTypeLabel(targetMeal, l10n))),
                  ));
                  Navigator.of(context).pop();
                }
              },
              child: Text(ctx.l10n.commonAdd),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecipeEditor({_Recipe? editRecipe}) async {
    if (_all.isEmpty) {
      await _ensureFoodsLoaded();
      if (!mounted) return;
    }
    final isEdit = editRecipe != null;
    final id = isEdit ? editRecipe.id : 'recipe:${DateTime.now().millisecondsSinceEpoch}';
    final nameCtl = TextEditingController(text: isEdit ? editRecipe.name : '');
    final descCtl = TextEditingController(text: isEdit ? editRecipe.description : '');
    final weightCtl = TextEditingController(
        text: isEdit ? editRecipe.totalWeightG.toStringAsFixed(0) : '100');
    final List<_RecipeIngredient> ingredients =
        isEdit ? List.from(editRecipe.ingredients) : [];

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _RecipeEditorScreen(
        id: id, nameCtl: nameCtl, descCtl: descCtl, weightCtl: weightCtl,
        ingredients: ingredients, allFoods: _all, isEdit: isEdit,
        isFav: (fid) => _fav.isFav(fid),
        foodStats: _stats,
        onSave: (recipe) async {
          await _recipes.save(recipe);
          await _ensureFoodsLoaded(force: true);
          if (mounted) setState(() {});
        },
      ),
    ));
  }

  Future<void> _openCustomDialog({dynamic editItem, dynamic prefillFrom}) async {
    final isEdit = editItem != null && _isPersonal(editItem);
    final hasPrefill = !isEdit && prefillFrom != null;
    final id = isEdit
        ? ((editItem as dynamic).id as String)
        : 'custom:${DateTime.now().millisecondsSinceEpoch}';
    final nameCtl = TextEditingController(
        text: isEdit
            ? ((editItem as dynamic).name as String? ?? '')
            : hasPrefill
                ? 'Copie de ${(prefillFrom as dynamic).name ?? ''}'
                : '');

    double? kcal = isEdit
        ? (editItem as dynamic).kcal100 as double?
        : hasPrefill ? (prefillFrom as dynamic).kcal100 as double? : null;
    double? prot = isEdit
        ? (editItem as dynamic).prot100 as double?
        : hasPrefill ? (prefillFrom as dynamic).prot100 as double? : null;
    double? carb = isEdit
        ? (editItem as dynamic).carb100 as double?
        : hasPrefill ? (prefillFrom as dynamic).carb100 as double? : null;
    double? fat  = isEdit
        ? (editItem as dynamic).fat100  as double?
        : hasPrefill ? (prefillFrom as dynamic).fat100 as double? : null;
    double? fiber= isEdit
        ? (editItem as dynamic).fiber100 as double?
        : hasPrefill ? (prefillFrom as dynamic).fiber100 as double? : null;

    late Map<String, double> micros;
    if (isEdit) {
      micros = Map<String, double>.from(
          ((editItem as dynamic).micros100 as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble())));
      micros.putIfAbsent('Beta-Carotène_µg_100g', () => 0.0);
    } else if (hasPrefill) {
      // Initialise toutes les clés à 0 pour éviter les null crashes
      micros = {
        'AG_saturés_g_100g': 0, 'Acide_oléique_W9_g_100g': 0,
        'Acide_linoléique_W6_LA_g_100g': 0,
        'Acide_alpha-linolénique_W3_ALA_g_100g': 0,
        'EPA_g_100g': 0, 'DHA_g_100g': 0,
        'Sucres_g_100g': 0, 'Sel_g_100g': 0,
        'Calcium_mg_100g': 0, 'Cuivre_mg_100g': 0, 'Fer_mg_100g': 0,
        'Iode_µg_100g': 0, 'Magnésium_mg_100g': 0,
        'Manganèse_mg_100g': 0, 'Phosphore_mg_100g': 0,
        'Potassium_mg_100g': 0, 'Sélénium_µg_100g': 0,
        'Sodium_mg_100g': 0, 'Zinc_mg_100g': 0,
        'Rétinol_µg_100g': 0, 'Beta-Carotène_µg_100g': 0, 'Vitamine_D_µg_100g': 0,
        'Vitamine_E_mg_100g': 0, 'Vitamine_K1_µg_100g': 0,
        'Vitamine_C_mg_100g': 0, 'Vitamine_B1_mg_100g': 0,
        'Vitamine_B2_mg_100g': 0, 'Vitamine_B3_mg_100g': 0,
        'Vitamine_B5_mg_100g': 0, 'Vitamine_B6_mg_100g': 0,
        'Vitamine_B9_µg_100g': 0, 'Vitamine_B12_µg_100g': 0,
      };
      // Superpose les vraies valeurs du prefill par-dessus les 0
      final prefillMicros = ((prefillFrom as dynamic).micros100 as Map? ?? {});
      prefillMicros.forEach((k, v) {
        micros[k.toString()] = (v as num?)?.toDouble() ?? 0.0;
      });
    } else {
      micros = {
            'AG_saturés_g_100g': 0,
            'Acide_oléique_W9_g_100g': 0,
            'Acide_linoléique_W6_LA_g_100g': 0,
            'Acide_alpha-linolénique_W3_ALA_g_100g': 0,
            'EPA_g_100g': 0, 'DHA_g_100g': 0,
            'Sucres_g_100g': 0, 'Sel_g_100g': 0,
            'Calcium_mg_100g': 0, 'Cuivre_mg_100g': 0, 'Fer_mg_100g': 0,
            'Iode_µg_100g': 0, 'Magnésium_mg_100g': 0,
            'Manganèse_mg_100g': 0, 'Phosphore_mg_100g': 0,
            'Potassium_mg_100g': 0, 'Sélénium_µg_100g': 0,
            'Sodium_mg_100g': 0, 'Zinc_mg_100g': 0,
            'Rétinol_µg_100g': 0, 'Vitamine_D_µg_100g': 0,
            'Vitamine_E_mg_100g': 0, 'Vitamine_K1_µg_100g': 0,
            'Vitamine_C_mg_100g': 0, 'Vitamine_B1_mg_100g': 0,
            'Vitamine_B2_mg_100g': 0, 'Vitamine_B3_mg_100g': 0,
            'Vitamine_B5_mg_100g': 0, 'Vitamine_B6_mg_100g': 0,
            'Vitamine_B9_µg_100g': 0, 'Vitamine_B12_µg_100g': 0,
          };
    }

    double? parse(String s) =>
        s.trim().isEmpty ? null : double.tryParse(s.replaceAll(',', '.'));

    Future<void> saveItem() async {
      final name = nameCtl.text.trim();
      if (name.isEmpty) return;
      final item = _CustomFood(
          id: id, name: name, kcal100: kcal, prot100: prot,
          carb100: carb, fat100: fat, fiber100: fiber, micros100: micros);
      if (isEdit) {
        await _customs.update(item);
      } else {
        await _customs.add(item);
      }
      final repo = foods_loader.FoodsRepository.instance;
      repo.addCustomFood(foods_loader.FoodItem(
          id: id, name: name, kcal100: kcal, prot100: prot,
          carb100: carb, fat100: fat, fiber100: fiber, micros100: micros));
      await repo.saveCustomFoods();
      await _ensureFoodsLoaded(force: true);
      if (mounted) setState(() {});
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        String fl(String key, String unit) => '${nutrientDisplayLabel(key, l10n)} ($unit)';
        return AlertDialog(
        title: Text(isEdit ? l10n.jrnlCustomFoodEditTitle : l10n.jrnlCustomFoodAddTitle),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(
                decoration: InputDecoration(labelText: l10n.commonNameField),
                controller: nameCtl),
            const SizedBox(height: 12),
            _TwoFieldsRow(
              leftLabel: fl('Énergie', 'kcal/100g'), leftInit: kcal?.toString() ?? '',
              rightLabel: fl('Protéines', 'g/100g'), rightInit: prot?.toString() ?? '',
              onLeftChanged: (s) => kcal = parse(s),
              onRightChanged: (s) => prot = parse(s),
            ),
            const SizedBox(height: 8),
            _TwoFieldsRow(
              leftLabel: fl('Glucides', 'g/100g'), leftInit: carb?.toString() ?? '',
              rightLabel: fl('Lipides', 'g/100g'), rightInit: fat?.toString() ?? '',
              onLeftChanged: (s) => carb = parse(s),
              onRightChanged: (s) => fat = parse(s),
            ),
            const SizedBox(height: 8),
            _TwoFieldsRow(
              leftLabel: fl('Fibres', 'g/100g'), leftInit: fiber?.toString() ?? '',
              rightLabel: fl('AG saturés', 'g/100g'),
              rightInit: micros['AG_saturés_g_100g']!.toString(),
              onLeftChanged: (s) => fiber = parse(s),
              onRightChanged: (s) => micros['AG_saturés_g_100g'] = parse(s) ?? 0,
            ),
            const SizedBox(height: 8),
            _TwoFieldsRow(
              leftLabel: fl('Oméga 9', 'g/100g'),
              leftInit: micros['Acide_oléique_W9_g_100g']!.toString(),
              rightLabel: fl('Oméga 6', 'g/100g'),
              rightInit: micros['Acide_linoléique_W6_LA_g_100g']!.toString(),
              onLeftChanged: (s) => micros['Acide_oléique_W9_g_100g'] = parse(s) ?? 0,
              onRightChanged: (s) => micros['Acide_linoléique_W6_LA_g_100g'] = parse(s) ?? 0,
            ),
            const SizedBox(height: 8),
            _TwoFieldsRow(
              leftLabel: fl('Oméga 3 (ALA)', 'g/100g'),
              leftInit: micros['Acide_alpha-linolénique_W3_ALA_g_100g']!.toString(),
              rightLabel: fl('EPA', 'g/100g'),
              rightInit: micros['EPA_g_100g']!.toString(),
              onLeftChanged: (s) => micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = parse(s) ?? 0,
              onRightChanged: (s) => micros['EPA_g_100g'] = parse(s) ?? 0,
            ),
            const SizedBox(height: 8),
            _TwoFieldsRow(
              leftLabel: fl('DHA', 'g/100g'),
              leftInit: micros['DHA_g_100g']!.toString(),
              rightLabel: fl('Sucres', 'g/100g'),
              rightInit: micros['Sucres_g_100g']!.toString(),
              onLeftChanged: (s) => micros['DHA_g_100g'] = parse(s) ?? 0,
              onRightChanged: (s) => micros['Sucres_g_100g'] = parse(s) ?? 0,
            ),
            const SizedBox(height: 8),
            _TwoFieldsRow(
              leftLabel: fl('Sel', 'g/100g'),
              leftInit: micros['Sel_g_100g']!.toString(),
              rightLabel: '', rightInit: '',
              onLeftChanged: (s) => micros['Sel_g_100g'] = parse(s) ?? 0,
              onRightChanged: (_) {},
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(l10n.jrnlMicronutrientsOptional),
              children: [
                _TwoFieldsRow(
                  leftLabel: fl('Calcium', 'mg/100g'),
                  leftInit: micros['Calcium_mg_100g']!.toString(),
                  rightLabel: fl('Cuivre', 'mg/100g'),
                  rightInit: micros['Cuivre_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Calcium_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Cuivre_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Fer', 'mg/100g'),
                  leftInit: micros['Fer_mg_100g']!.toString(),
                  rightLabel: fl('Iode', 'µg/100g'),
                  rightInit: micros['Iode_µg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Fer_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Iode_µg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Magnésium', 'mg/100g'),
                  leftInit: micros['Magnésium_mg_100g']!.toString(),
                  rightLabel: fl('Manganèse', 'mg/100g'),
                  rightInit: micros['Manganèse_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Magnésium_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Manganèse_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Phosphore', 'mg/100g'),
                  leftInit: micros['Phosphore_mg_100g']!.toString(),
                  rightLabel: fl('Potassium', 'mg/100g'),
                  rightInit: micros['Potassium_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Phosphore_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Potassium_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Sélénium', 'µg/100g'),
                  leftInit: micros['Sélénium_µg_100g']!.toString(),
                  rightLabel: fl('Sodium', 'mg/100g'),
                  rightInit: micros['Sodium_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Sélénium_µg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Sodium_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Zinc', 'mg/100g'),
                  leftInit: micros['Zinc_mg_100g']!.toString(),
                  rightLabel: fl('Vitamine E', 'mg/100g'),
                  rightInit: micros['Vitamine_E_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Zinc_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Vitamine_E_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Rétinol', 'µg/100g'),
                  leftInit: micros['Rétinol_µg_100g']!.toString(),
                  rightLabel: fl('Bêta-car.', 'µg/100g'),
                  rightInit: (micros['Beta-Carotène_µg_100g'] ?? 0).toString(),
                  onLeftChanged: (s) => micros['Rétinol_µg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Beta-Carotène_µg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: fl('Vit D', 'µg/100g'),
                  leftInit: micros['Vitamine_D_µg_100g']!.toString(),
                  rightLabel: 'Vit K1 (µg/100g)',
                  rightInit: micros['Vitamine_K1_µg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Vitamine_D_µg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Vitamine_K1_µg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: 'Vit C (mg/100g)',
                  leftInit: micros['Vitamine_C_mg_100g']!.toString(),
                  rightLabel: '', rightInit: '',
                  onLeftChanged: (s) => micros['Vitamine_C_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (_) {},
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: 'B1 (mg/100g)',
                  leftInit: micros['Vitamine_B1_mg_100g']!.toString(),
                  rightLabel: 'B2 (mg/100g)',
                  rightInit: micros['Vitamine_B2_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Vitamine_B1_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Vitamine_B2_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: 'B3 (mg/100g)',
                  leftInit: micros['Vitamine_B3_mg_100g']!.toString(),
                  rightLabel: 'B5 (mg/100g)',
                  rightInit: micros['Vitamine_B5_mg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Vitamine_B3_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Vitamine_B5_mg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: 'B6 (mg/100g)',
                  leftInit: micros['Vitamine_B6_mg_100g']!.toString(),
                  rightLabel: 'B9 (µg/100g)',
                  rightInit: micros['Vitamine_B9_µg_100g']!.toString(),
                  onLeftChanged: (s) => micros['Vitamine_B6_mg_100g'] = parse(s) ?? 0,
                  onRightChanged: (s) => micros['Vitamine_B9_µg_100g'] = parse(s) ?? 0,
                ),
                const SizedBox(height: 8),
                _TwoFieldsRow(
                  leftLabel: 'B12 (µg/100g)',
                  leftInit: micros['Vitamine_B12_µg_100g']!.toString(),
                  rightLabel: '', rightInit: '',
                  onLeftChanged: (s) => micros['Vitamine_B12_µg_100g'] = parse(s) ?? 0,
                  onRightChanged: (_) {},
                ),
              ],
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () async {
              await saveItem();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? l10n.commonSave : l10n.commonAdd),
          ),
        ],
      );
      },
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// MARQUES & RESTAURANTS — aliments de marque USDA (Priorité 39)
// Retour d'Alex (11/08/2026, 2e passe) : remplace l'ancien "cheat meal" à
// avertissement santé — deux familles filtrables PAR ENSEIGNE (pas de
// discours en dur), toujours issues des jeux Foundation/SR Legacy validés en
// laboratoire (jamais la base "Branded Foods" auto-déclarée). Le score NOVA
// est toujours affiché sur chaque ligne, laissé à l'appréciation de
// l'utilisateur plutôt qu'un texte d'avertissement.
// ══════════════════════════════════════════════════════════════════════════════
class _BrandOrRestaurantTab extends StatefulWidget {
  final String sourceType; // 'marque' ou 'restaurant'
  final Future<void> Function(foods_loader.FoodItem food) onFoodSelected;
  const _BrandOrRestaurantTab({required this.sourceType, required this.onFoodSelected});
  @override
  State<_BrandOrRestaurantTab> createState() => _BrandOrRestaurantTabState();
}

class _BrandOrRestaurantTabState extends State<_BrandOrRestaurantTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _queryCtrl = TextEditingController();
  bool _ready = false;
  String? _selected;

  @override
  bool get wantKeepAlive => true; // garde la sélection/recherche au changement d'onglet

  bool get _isRestaurant => widget.sourceType == 'restaurant';

  @override
  void initState() {
    super.initState();
    foods_loader.FoodsRepository.instance
        .loadUsdaFromAsset('assets/usda_foods.csv')
        .then((_) { if (mounted) setState(() => _ready = true); });
  }

  @override
  void dispose() { _queryCtrl.dispose(); super.dispose(); }

  void _select(String? v) {
    setState(() { _selected = v; _queryCtrl.clear(); });
  }

  String _kcalLabel(double? kcal100) =>
      kcal100 != null
          ? context.l10n.jrnlKcalPer100g(kcal100.toStringAsFixed(0))
          : context.l10n.jrnlCalorieValueUnknown;

  /// Fiche éducative (Priorité 40, retour d'Alex : "dans l'éducation et la
  /// prise de conscience") — chiffres sourcés, pas d'invention : la part de
  /// calories "plaisir" recommandée (5-15%) vient du comité américain des
  /// recommandations alimentaires (Dietary Guidelines Advisory Committee) ;
  /// le repas moyen en chaîne (~1200 kcal, ~2100 mg de sodium) vient d'une
  /// étude parue dans l'American Journal of Preventive Medicine sur les
  /// menus combo des grandes chaînes US. Recherche disponible : aucune étude
  /// ne fixe un chiffre unique et définitif (approche heuristique assumée
  /// dans la fiche, pas présentée comme une vérité absolue).
  ///
  /// Priorité 50 (13/08/2026, retour d'Alex) : n'est plus un bandeau fixe en
  /// tête d'onglet (prenait trop de place en permanence, même sans enseigne
  /// choisie) — accessible à la demande via le bouton "Informations" qui
  /// n'apparaît qu'une fois une enseigne sélectionnée (voir build()).
  /// Généralisée pour couvrir aussi "Marques" (contenu plus court, cette
  /// famille n'a pas le même enjeu nutritionnel que la restauration rapide).
  void _showSourceInfoSheet() {
    final l10n = context.l10n;
    Widget p(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text, style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.45)),
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _isRestaurant
              ? [
                  Text(l10n.jrnlRestaurantsInfoTitle,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  p(l10n.jrnlRestaurantsInfoP1),
                  p(l10n.jrnlRestaurantsInfoP2),
                  p(l10n.jrnlRestaurantsInfoP3),
                  p(l10n.jrnlRestaurantsInfoP4),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.jrnlUnderstood)),
                  ),
                ]
              : [
                  Text(l10n.jrnlAboutBrandTitle,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  p(l10n.jrnlAboutBrandBody),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.jrnlUnderstood)),
                  ),
                ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // requis par AutomaticKeepAliveClientMixin
    final repo = foods_loader.FoodsRepository.instance;
    final names = _isRestaurant ? repo.restaurantNames : repo.brandNames;
    final selected = _selected;
    return Column(
      children: [
        // Priorité 50 (13/08/2026, retour d'Alex) : plus de bandeau fixe —
        // la barre de recherche + la liste d'enseignes restent seules
        // visibles par défaut. Une fois une enseigne choisie, sa fiche
        // "Informations" (contenu ex-bandeau, voir _showSourceInfoSheet)
        // devient accessible à la demande à côté du chip de sélection.
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(_isRestaurant ? Icons.restaurant_outlined : Icons.storefront_outlined,
                          size: 16, color: TotumColors.accent),
                      label: Text(selected, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      onDeleted: () => _select(null),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      backgroundColor: TotumColors.accentSoft,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showSourceInfoSheet,
                  style: TextButton.styleFrom(foregroundColor: TotumColors.accent),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(context.l10n.jrnlInformationsButton, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              labelText: selected == null ? context.l10n.jrnlSearchBrand : context.l10n.jrnlSearchWithinBrand(selected),
              prefixIcon: const Icon(Icons.search),
              // Retour d'Alex (13/08/2026) : une croix pour vider le champ
              // d'un coup plutôt que d'effacer lettre par lettre.
              suffixIcon: _queryCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _queryCtrl.clear()),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (!_ready) const LinearProgressIndicator(color: TotumColors.accent),
        Expanded(
          child: selected == null
              ? _buildNameList(names)
              : _buildFoodList(repo.foodsForBrand(selected, query: _queryCtrl.text)),
        ),
      ],
    );
  }

  Widget _buildNameList(List<String> names) {
    final q = _queryCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? names
        : names.where((n) => n.toLowerCase().contains(q)).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(_ready ? context.l10n.jrnlNoChainFound : context.l10n.jrnlLoadingEllipsis,
            style: TextStyle(color: TotumColors.textSecondary)),
      );
    }
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: TotumColors.outline),
      itemBuilder: (ctx, i) {
        final name = filtered[i];
        return ListTile(
          leading: Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TotumColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_isRestaurant ? Icons.restaurant_outlined : Icons.storefront_outlined,
                color: TotumColors.accent, size: 18),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _select(name),
        );
      },
    );
  }

  Widget _buildFoodList(List<foods_loader.FoodItem> foods) {
    if (foods.isEmpty) {
      return Center(
        child: Text(context.l10n.jrnlNoResults, style: TextStyle(color: TotumColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: foods.length,
      itemBuilder: (ctx, i) {
        final food = foods[i];
        final pictogram = food.pictogramme;
        final displayName = displayNameOf(food, food.name);
        return ListTile(
          leading: Container(
            width: 38, height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TotumColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(pictogram ?? '🍽️', style: const TextStyle(fontSize: 19)),
          ),
          title: Text(displayName,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.25)),
          subtitle: Row(
            children: [
              Flexible(child: Text(_kcalLabel(food.kcal100),
                  style: TextStyle(fontSize: 12, color: TotumColors.textSecondary))),
              if (food.novaScore != null) ...[
                const SizedBox(width: 8),
                _NovaBadge(score: food.novaScore!, estime: food.novaEstime),
              ],
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          minVerticalPadding: 8,
          onTap: () => widget.onFoodSelected(food),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÉDITEUR DE RECETTE
// ══════════════════════════════════════════════════════════════════════════════
class _RecipeEditorScreen extends StatefulWidget {
  final String id;
  final TextEditingController nameCtl;
  final TextEditingController descCtl;
  final TextEditingController weightCtl;
  final List<_RecipeIngredient> ingredients;
  final List<dynamic> allFoods;
  final bool isEdit;
  final Future<void> Function(_Recipe recipe) onSave;
  final bool Function(String id)? isFav;
  final _FoodStats? foodStats;
  

  const _RecipeEditorScreen({
    required this.id, required this.nameCtl, required this.descCtl,
    required this.weightCtl, required this.ingredients,
    required this.allFoods, required this.isEdit, required this.onSave,
    this.isFav, this.foodStats,
  });

  @override
  State<_RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<_RecipeEditorScreen> {
  late List<_RecipeIngredient> _ingredients;
  final TextEditingController _ingSearchCtrl = TextEditingController();
  String _ingQuery = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.ingredients);
  }

  /// Retrouve un aliment dans la base en gérant les formats d'id hérités
  /// (id exact, code nu -> ciqual:code, ou correspondance par nom).
  dynamic _findIngredientFood(String foodId, String foodName) {
    String idOf(dynamic f) => ((f as dynamic).id as String?) ?? '';
    for (final f in widget.allFoods) {
      if (idOf(f) == foodId) return f;
    }
    if (RegExp(r'^\d+$').hasMatch(foodId)) {
      final target = 'ciqual:$foodId';
      for (final f in widget.allFoods) {
        if (idOf(f) == target) return f;
      }
    }
    String norm(String x) => x
        .toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final targetName = norm(foodName);
    if (targetName.isNotEmpty) {
      for (final f in widget.allFoods) {
        if (norm(((f as dynamic).name as String?) ?? '') == targetName) {
          return f;
        }
      }
    }
    final normId = norm(foodId);
    if (normId.isNotEmpty) {
      for (final f in widget.allFoods) {
        if (norm(((f as dynamic).name as String?) ?? '') == normId) {
          return f;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _computeNutrition() {
    double totalKcal = 0, totalProt = 0, totalCarb = 0, totalFat = 0, totalFiber = 0;
    final Map<String, double> totalMicros = {};
    final totalWeight =
        double.tryParse(widget.weightCtl.text.replaceAll(',', '.')) ?? 100.0;

    for (final ing in _ingredients) {
      final food = _findIngredientFood(ing.foodId, ing.foodName);
      if (food == null) continue;

      final f = ing.grams / 100.0;
      double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
      totalKcal  += getD((food as dynamic).kcal100) * f;
      totalProt  += getD((food).prot100) * f;
      totalCarb  += getD((food).carb100) * f;
      totalFat   += getD((food).fat100)  * f;
      totalFiber += getD((food).fiber100)* f;
      try {
        final micros = (food as dynamic).micros100 as Map<String, dynamic>?;
        micros?.forEach((key, val) {
          totalMicros[key] = (totalMicros[key] ?? 0) + getD(val) * f;
        });
      } catch (_) {}
    }

    final ratio = totalWeight > 0 ? 100.0 / totalWeight : 1.0;
    return {
      'kcal100': totalKcal * ratio, 'prot100': totalProt * ratio,
      'carb100': totalCarb * ratio, 'fat100': totalFat * ratio,
      'fiber100': totalFiber * ratio,
      'micros100': Map<String, double>.fromEntries(
        totalMicros.entries.map((e) => MapEntry(e.key, e.value * ratio)),
      ),
      'totalKcal': totalKcal, 'totalProt': totalProt,
      'totalCarb': totalCarb, 'totalFat': totalFat,
    };
  }

  List<dynamic> _filteredFoods() {
    final q = _ingQuery.trim();
    if (q.isEmpty) return [];
    final matches = widget.allFoods.where((it) {
      final n = _norm((((it as dynamic).name) as String?) ?? '');
      return n.contains(_norm(q));
    }).toList();

    matches.sort((a, b) {
      final aid = ((a as dynamic).id  as String?) ?? '';
      final bid = ((b as dynamic).id  as String?) ?? '';
      final an  = ((a as dynamic).name as String?) ?? '';
      final bn  = ((b as dynamic).name as String?) ?? '';

      // 1. Favoris en premier
      final aFav = widget.isFav?.call(aid) ?? false;
      final bFav = widget.isFav?.call(bid) ?? false;
      if (aFav != bFav) return aFav ? -1 : 1;

      // 2. Fréquence d'utilisation
      final aCount = widget.foodStats?.count(aid) ?? 0;
      final bCount = widget.foodStats?.count(bid) ?? 0;
      if (aCount != bCount) return bCount.compareTo(aCount);

      // 3. Récence
      final aLast = widget.foodStats?.last(aid) ?? 0;
      final bLast = widget.foodStats?.last(bid) ?? 0;
      if (aLast != bLast) return bLast.compareTo(aLast);

      // 4. Pertinence textuelle
      return _scoreForQuery(an, q).compareTo(_scoreForQuery(bn, q));
    });

    return matches.take(20).toList();
  }

  Future<void> _saveRecipe() async {
    final name = widget.nameCtl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jrnlRecipeNameRequired)));
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jrnlIngredientRequired)));
      return;
    }
    setState(() => _saving = true);
    final nutrition = _computeNutrition();
    final totalWeight =
        double.tryParse(widget.weightCtl.text.replaceAll(',', '.')) ?? 100.0;

    final recipe = _Recipe(
      id: widget.id, name: name,
      description: widget.descCtl.text.trim(),
      ingredients: _ingredients, totalWeightG: totalWeight,
      kcal100: (nutrition['kcal100'] as double?)?.isFinite == true ? nutrition['kcal100'] as double : 0,
      prot100: (nutrition['prot100'] as double?)?.isFinite == true ? nutrition['prot100'] as double : 0,
      carb100: (nutrition['carb100'] as double?)?.isFinite == true ? nutrition['carb100'] as double : 0,
      fat100:  (nutrition['fat100']  as double?)?.isFinite == true ? nutrition['fat100']  as double : 0,
      fiber100:(nutrition['fiber100']as double?)?.isFinite == true ? nutrition['fiber100']as double : 0,
      micros100: (nutrition['micros100'] as Map<String, double>?) ?? {},
    );

    await widget.onSave(recipe);
    setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nutrition = _computeNutrition();
    final suggestions = _filteredFoods();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? l10n.jrnlEditRecipeTitle : l10n.jrnlNewRecipeTitle),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _saveRecipe,
              child: Text(l10n.commonSave,
                  style: const TextStyle(color: kTotumOrange, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TextField(
            controller: widget.nameCtl,
            decoration: InputDecoration(
              labelText: l10n.jrnlRecipeNameField,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.descCtl,
            decoration: InputDecoration(
              labelText: l10n.jrnlDescOptionalField,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.weightCtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.jrnlRecipeTotalWeightField,
              helperText: l10n.jrnlMacrosCalculatedFor100g,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          if (_ingredients.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TotumColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TotumColors.accentBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.jrnlValuesPer100gRecipe,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12, runSpacing: 4,
                    children: [
                      _NutriBadge('Énergie', '${(nutrition['kcal100'] as double).toStringAsFixed(0)} kcal'),
                      _NutriBadge('Protéines', '${(nutrition['prot100'] as double).toStringAsFixed(1)} g'),
                      _NutriBadge('Glucides', '${(nutrition['carb100'] as double).toStringAsFixed(1)} g'),
                      _NutriBadge('Lipides', '${(nutrition['fat100'] as double).toStringAsFixed(1)} g'),
                      _NutriBadge('Fibres', '${(nutrition['fiber100'] as double).toStringAsFixed(1)} g'),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.jrnlIngredientsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text(l10n.jrnlItemCountPlain(_ingredients.length),
                  style: TextStyle(color: TotumColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _ingSearchCtrl,
            decoration: InputDecoration(
              labelText: l10n.jrnlSearchFoodToAdd,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _ingSearchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _ingSearchCtrl.clear();
                        _ingQuery = '';
                      }),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (s) => setState(() => _ingQuery = s),
          ),
          const SizedBox(height: 4),

          if (suggestions.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: TotumColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TotumColors.outline),
              ),
              child: Column(
                children: suggestions.map((food) {
                  final fname = displayNameOf(food, ((food as dynamic).name as String?) ?? l10n.jrnlGenericFoodFallback);
                  final fid = ((food).id as String?) ?? '';
                  final fkcal = ((food).kcal100 as num?)?.toDouble() ?? 0.0;
                  final isFavFood =
                      (widget.isFav != null && fid.isNotEmpty)
                          ? widget.isFav!(fid)
                          : false;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isFavFood ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isFavFood ? TotumColors.accent : TotumColors.textMuted,
                    ),
                    title: Text(fname, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(l10n.jrnlKcalSlash100g(fkcal.toStringAsFixed(0)),
                        style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.add_circle_outline, color: TotumColors.accent),
                    onTap: () {
                      final gCtrl = TextEditingController(text: '100');
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(fname, style: const TextStyle(fontSize: 15)),
                          content: TextField(
                            controller: gCtrl,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: ctx.l10n.jrnlQtyLabel,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(ctx.l10n.commonCancel)),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: TotumColors.accent,
                                  foregroundColor: Colors.white),
                              onPressed: () {
                                final g = double.tryParse(
                                    gCtrl.text.replaceAll(',', '.')) ?? 100.0;
                                setState(() {
                                  _ingredients.add(_RecipeIngredient(
                                      foodId: fid, foodName: fname, grams: g));
                                  _ingSearchCtrl.clear();
                                  _ingQuery = '';
                                });
                                Navigator.pop(ctx);
                              },
                              child: Text(ctx.l10n.commonAdd),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 12),

          if (_ingredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.jrnlNoIngredientAdded,
                  style: TextStyle(color: TotumColors.textSecondary)),
            )
          else
            ...List.generate(_ingredients.length, (i) {
              final ing = _ingredients[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Text(ing.foodName),
                  subtitle: Text('${ing.grams.toStringAsFixed(0)} g'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: TotumColors.accent),
                        tooltip: l10n.jrnlEditQuantityTooltip,
                        onPressed: () {
                          final gCtrl = TextEditingController(
                              text: ing.grams.toStringAsFixed(0));
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(ing.foodName,
                                  style: const TextStyle(fontSize: 15)),
                              content: TextField(
                                controller: gCtrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: ctx.l10n.jrnlQtyLabel,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(ctx.l10n.commonCancel)),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: kTotumOrange,
                                      foregroundColor: Colors.white),
                                  onPressed: () {
                                    final g = double.tryParse(
                                        gCtrl.text.replaceAll(',', '.')) ?? ing.grams;
                                    setState(() {
                                      _ingredients[i] = _RecipeIngredient(
                                          foodId: ing.foodId,
                                          foodName: ing.foodName,
                                          grams: g);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: TotumColors.textSecondary),
                        tooltip: l10n.jrnlRemoveTooltip,
                        onPressed: () => setState(() => _ingredients.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Éditeur de repas perso (création/édition) — même pattern que
/// [_RecipeEditorScreen], en plus simple : un repas perso est une somme
/// figée d'aliments (grammes + macros absolus déjà calculés), pas une
/// recette normalisée pour 100g. Recherche/ajout d'aliments réutilise le
/// même flux que l'éditeur de recette (favoris/fréquence en tête de liste).
class _MealEditorScreen extends StatefulWidget {
  final String id;
  final TextEditingController nameCtl;
  final TextEditingController descCtl;
  final List<Map<String, dynamic>> items;
  final List<dynamic> allFoods;
  final bool isEdit;
  final Future<void> Function(_CustomMeal meal) onSave;
  final bool Function(String id)? isFav;
  final _FoodStats? foodStats;

  const _MealEditorScreen({
    required this.id, required this.nameCtl, required this.descCtl,
    required this.items, required this.allFoods, required this.isEdit,
    required this.onSave, this.isFav, this.foodStats,
  });

  @override
  State<_MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends State<_MealEditorScreen> {
  late List<Map<String, dynamic>> _items;
  final TextEditingController _ingSearchCtrl = TextEditingController();
  String _ingQuery = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  double get _totalKcal =>
      _items.fold(0.0, (s, it) => s + ((it['kcal'] as num?)?.toDouble() ?? 0.0));
  double get _totalProt =>
      _items.fold(0.0, (s, it) => s + ((it['prot'] as num?)?.toDouble() ?? 0.0));
  double get _totalCarb =>
      _items.fold(0.0, (s, it) => s + ((it['carb'] as num?)?.toDouble() ?? 0.0));
  double get _totalFat =>
      _items.fold(0.0, (s, it) => s + ((it['fat'] as num?)?.toDouble() ?? 0.0));
  double get _totalFiber =>
      _items.fold(0.0, (s, it) => s + ((it['fiber'] as num?)?.toDouble() ?? 0.0));

  List<dynamic> _filteredFoods() {
    final q = _ingQuery.trim();
    if (q.isEmpty) return [];
    final matches = widget.allFoods.where((it) {
      final n = _norm((((it as dynamic).name) as String?) ?? '');
      return n.contains(_norm(q));
    }).toList();

    matches.sort((a, b) {
      final aid = ((a as dynamic).id as String?) ?? '';
      final bid = ((b as dynamic).id as String?) ?? '';
      final an = ((a as dynamic).name as String?) ?? '';
      final bn = ((b as dynamic).name as String?) ?? '';

      final aFav = widget.isFav?.call(aid) ?? false;
      final bFav = widget.isFav?.call(bid) ?? false;
      if (aFav != bFav) return aFav ? -1 : 1;

      final aCount = widget.foodStats?.count(aid) ?? 0;
      final bCount = widget.foodStats?.count(bid) ?? 0;
      if (aCount != bCount) return bCount.compareTo(aCount);

      final aLast = widget.foodStats?.last(aid) ?? 0;
      final bLast = widget.foodStats?.last(bid) ?? 0;
      if (aLast != bLast) return bLast.compareTo(aLast);

      return _scoreForQuery(an, q).compareTo(_scoreForQuery(bn, q));
    });

    return matches.take(20).toList();
  }

  Future<void> _saveMeal() async {
    final name = widget.nameCtl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jrnlMealNameRequired)));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jrnlFoodRequired)));
      return;
    }
    setState(() => _saving = true);
    final meal = _CustomMeal(
      id: widget.id, name: name,
      description: widget.descCtl.text.trim(),
      items: _items,
    );
    await widget.onSave(meal);
    setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestions = _filteredFoods();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? l10n.jrnlEditMealTitle : l10n.jrnlNewMealTitle),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _saveMeal,
              child: Text(l10n.commonSave,
                  style: const TextStyle(color: kTotumOrange, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TextField(
            controller: widget.nameCtl,
            decoration: InputDecoration(
              labelText: l10n.jrnlMealNameField,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.descCtl,
            decoration: InputDecoration(
              labelText: l10n.jrnlDescOptionalField,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          if (_items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TotumColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TotumColors.accentBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.jrnlMealTotalTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12, runSpacing: 4,
                    children: [
                      _NutriBadge('Énergie', '${_totalKcal.toStringAsFixed(0)} kcal'),
                      _NutriBadge('Protéines', '${_totalProt.toStringAsFixed(1)} g'),
                      _NutriBadge('Glucides', '${_totalCarb.toStringAsFixed(1)} g'),
                      _NutriBadge('Lipides', '${_totalFat.toStringAsFixed(1)} g'),
                      _NutriBadge('Fibres', '${_totalFiber.toStringAsFixed(1)} g'),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.jrnlFoodsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text(l10n.jrnlItemCountPlain(_items.length),
                  style: TextStyle(color: TotumColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _ingSearchCtrl,
            decoration: InputDecoration(
              labelText: l10n.jrnlSearchFoodToAdd,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _ingSearchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _ingSearchCtrl.clear();
                        _ingQuery = '';
                      }),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (s) => setState(() => _ingQuery = s),
          ),
          const SizedBox(height: 4),

          if (suggestions.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: TotumColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TotumColors.outline),
              ),
              child: Column(
                children: suggestions.map((food) {
                  final fname = displayNameOf(food, ((food as dynamic).name as String?) ?? l10n.jrnlGenericFoodFallback);
                  final fid = ((food).id as String?) ?? '';
                  final fkcal = ((food).kcal100 as num?)?.toDouble() ?? 0.0;
                  final isFavFood =
                      (widget.isFav != null && fid.isNotEmpty) ? widget.isFav!(fid) : false;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isFavFood ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isFavFood ? TotumColors.accent : TotumColors.textMuted,
                    ),
                    title: Text(fname, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(l10n.jrnlKcalSlash100g(fkcal.toStringAsFixed(0)),
                        style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.add_circle_outline, color: TotumColors.accent),
                    onTap: () {
                      final gCtrl = TextEditingController(text: '100');
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(fname, style: const TextStyle(fontSize: 15)),
                          content: TextField(
                            controller: gCtrl,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: ctx.l10n.jrnlQtyLabel,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.commonCancel)),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: TotumColors.accent, foregroundColor: Colors.white),
                              onPressed: () {
                                final g = double.tryParse(gCtrl.text.replaceAll(',', '.')) ?? 100.0;
                                double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
                                final f = g / 100.0;
                                setState(() {
                                  _items.add({
                                    'id': fid, 'name': fname, 'grams': g,
                                    'kcal': getD((food as dynamic).kcal100) * f,
                                    'prot': getD((food).prot100) * f,
                                    'carb': getD((food).carb100) * f,
                                    'fat': getD((food).fat100) * f,
                                    'fiber': getD((food).fiber100) * f,
                                  });
                                  _ingSearchCtrl.clear();
                                  _ingQuery = '';
                                });
                                Navigator.pop(ctx);
                              },
                              child: Text(ctx.l10n.commonAdd),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 12),

          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.jrnlNoFoodAdded, style: TextStyle(color: TotumColors.textSecondary)),
            )
          else
            ...List.generate(_items.length, (i) {
              final it = _items[i];
              final grams = (it['grams'] as num?)?.toDouble() ?? 0.0;
              final kcal = (it['kcal'] as num?)?.toDouble() ?? 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Text((it['name'] ?? '').toString()),
                  subtitle: Text(l10n.jrnlGramsAndKcal(grams.toStringAsFixed(0), kcal.toStringAsFixed(0))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: TotumColors.accent),
                        tooltip: l10n.jrnlEditQuantityTooltip,
                        onPressed: () {
                          final gCtrl = TextEditingController(text: grams.toStringAsFixed(0));
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text((it['name'] ?? '').toString(), style: const TextStyle(fontSize: 15)),
                              content: TextField(
                                controller: gCtrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: ctx.l10n.jrnlQtyLabel,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.commonCancel)),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: kTotumOrange, foregroundColor: Colors.white),
                                  onPressed: () {
                                    final newG = double.tryParse(gCtrl.text.replaceAll(',', '.')) ?? grams;
                                    setState(() {
                                      final oldG = grams;
                                      final ratio = oldG > 0 ? newG / oldG : 0.0;
                                      final updated = Map<String, dynamic>.from(_items[i]);
                                      updated['grams'] = newG;
                                      for (final k in ['kcal', 'prot', 'carb', 'fat', 'fiber']) {
                                        updated[k] = ((updated[k] as num?)?.toDouble() ?? 0.0) * ratio;
                                      }
                                      _items[i] = updated;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: TotumColors.textSecondary),
                        tooltip: l10n.jrnlRemoveTooltip,
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _NutriBadge extends StatelessWidget {
  final String label, value;
  const _NutriBadge(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nutrientDisplayLabel(label, context.l10n), style: TextStyle(fontSize: 11, color: TotumColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: TotumColors.textPrimary)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// JOURNAL DU JOUR
// ══════════════════════════════════════════════════════════════════════════════
class DayTotals {
  final double kcal, prot, carb, fat, fiber;
  const DayTotals({
    required this.kcal, required this.prot, required this.carb,
    required this.fat, required this.fiber,
  });
}

/// Page d'ajout d'aliment autonome, avec son PROPRE TabController local.
/// Elle réutilise les méthodes et données du parent (même fichier, donc
/// les membres privés restent accessibles), mais gère son affichage
/// — onglets, tri, recherche — toute seule : rapide, sans désynchronisation.
class _AddFoodPage extends StatefulWidget {
  final JournalScreenState parent;
  const _AddFoodPage({required this.parent});

  @override
  State<_AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<_AddFoodPage>
    with SingleTickerProviderStateMixin {
  // 5 onglets (Priorité 40, correction d'Alex) : Marques/Restaurant vivent
  // sur la MÊME barre que Commun/Favoris/Perso, pas dans un écran séparé
  // accessible par un lien caché dans le tiroir de filtre.
  late final TabController _tab = TabController(length: 5, vsync: this);
  final TextEditingController _searchCtrl = TextEditingController();

  // Refonte recherche (Priorité 38, retour d'Alex sur des captures d'écran
  // d'une appli concurrente) : ces 2 préférences remplacent l'ancien bouton
  // "recherche USDA" séparé (peu visible, retour d'Alex) — regroupées dans
  // un tiroir de filtre avec le tri déjà existant (_SortMode), pour gagner
  // en clarté et en espace écran. Persistées : un choix fait une fois reste.
  bool _includeUsda = false;
  bool _includeCiqual = true;
  bool _showCategoryTabs = true;
  // Priorité 40 (retour d'Alex, capture d'écran fournie) : bascule "Activer
  // l'ajout multiple" — sélection de plusieurs aliments d'un coup dans
  // l'onglet Commun, avec ajout groupé vers un repas choisi. Volontairement
  // scopé au seul onglet Commun (widget dédié _MultiSelectFoodList, ne
  // touche pas _FoodListView, partagé et déjà densément câblé sur 5
  // onglets — risque déjà identifié précédemment si modifié à la volée).
  bool _multiSelectEnabled = false;
  List<foods_loader.FoodItem> _usdaMatches = [];

  // Priorité 50 (13/08/2026, retour d'Alex) : repas présélectionné en tête
  // d'écran (remplace le titre statique "Ajouter un aliment") — tout
  // aliment tapé dans n'importe quel onglet est ajouté directement à CE
  // repas, sans repasser par le menu déroulant "Repas" de la fiche détail
  // (qui reste modifiable au cas par cas, voir _openFoodSheet).
  static const _mealOptions = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];
  static const _mealIcons = <String, IconData>{
    'Petit-déjeuner': Icons.free_breakfast_outlined,
    'Déjeuner': Icons.lunch_dining_outlined,
    'Dîner': Icons.dinner_dining_outlined,
    'Collation': Icons.cookie_outlined,
  };
  static String _defaultMealForNow() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Petit-déjeuner';
    if (h < 15) return 'Déjeuner';
    if (h < 21) return 'Dîner';
    return 'Collation';
  }
  late String _selectedMeal = _defaultMealForNow();

  // Priorité 50 (14/08/2026, retour d'Alex : "énormément de latence dans la
  // barre de recherche avant que mon texte apparaisse", surtout côté web) —
  // `_list(0)` trie jusqu'à ~3490 aliments CIQUAL à chaque frappe, et ce
  // calcul tournait sur CHAQUE lettre tapée (TextField.onChanged synchrone),
  // assez lourd pour retarder visiblement jusqu'au rendu du caractère saisi
  // lui-même. Le texte tapé s'affiche toujours instantanément (géré en
  // interne par `_searchCtrl`, indépendant de ceci) — seule la mise à jour
  // des RÉSULTATS est différée de 220ms après la dernière frappe.
  Timer? _searchDebounce;

  JournalScreenState get p => widget.parent;

  @override
  void initState() {
    super.initState();
    _tab.addListener(() => setState(() {}));
    // On s'aligne sur les valeurs courantes du parent.
    _searchCtrl.text = p._query;
    _loadFilterPrefs();
  }

  Future<void> _loadFilterPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final includeUsda = sp.getBool('addfood_include_usda') ?? false;
    final includeCiqual = sp.getBool('addfood_include_ciqual') ?? true;
    final showTabs = sp.getBool('addfood_show_tabs') ?? true;
    final multiSelect = sp.getBool('addfood_multi_select') ?? false;
    if (!mounted) return;
    setState(() {
      _includeUsda = includeUsda;
      // Garde-fou : jamais les deux bases désactivées en même temps (sinon
      // "Commun" n'a plus rien à montrer) — CIQUAL reprend la main si un
      // état incohérent a été persisté (ne devrait pas arriver vu les
      // garde-fous dans les setters, mais coûte rien à vérifier au chargement).
      _includeCiqual = includeCiqual || !includeUsda;
      _showCategoryTabs = showTabs;
      _multiSelectEnabled = multiSelect;
    });
    if (_includeUsda) _refreshUsdaMatches();
  }

  Future<void> _setIncludeUsda(bool v) async {
    // Bug corrigé (13/08/2026, retour d'Alex : "je sélectionne uniquement
    // USDA, ça ne marche pas") : l'ancien garde-fou refusait SILENCIEUSEMENT
    // le clic quand l'utilisateur décochait la 1re case alors que l'autre
    // base était encore inactive — la case ne bougeait pas, sans aucun
    // retour, et un "USDA uniquement" tenté dans le mauvais ordre de clic
    // finissait avec les deux bases actives sans que rien ne l'indique.
    // Remplacé par un bascule automatique de l'autre base : décocher USDA
    // alors que CIQUAL est déjà inactif réactive CIQUAL au lieu de bloquer
    // le tap — au moins une base reste toujours active, mais chaque clic
    // produit un effet visible.
    setState(() {
      _includeUsda = v;
      _usdaMatches = [];
      if (!v && !_includeCiqual) _includeCiqual = true;
    });
    if (_includeUsda) {
      await foods_loader.FoodsRepository.instance
          .loadUsdaFromAsset('assets/usda_foods.csv');
      _refreshUsdaMatches();
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('addfood_include_usda', _includeUsda);
    await sp.setBool('addfood_include_ciqual', _includeCiqual);
  }

  /// Priorité 40 (retour d'Alex, capture d'écran) : CIQUAL et USDA
  /// deviennent 2 bascules indépendantes ("Base de données"), CIQUAL activé
  /// par défaut — au lieu du seul "Inclure la base USDA" (CIQUAL toujours
  /// actif en dur). Filtre directement `_list(0)` (voir usage), sans
  /// toucher `_applyFilterSort` : la logique "USDA masqué par défaut sauf
  /// favori/fréquent" (Priorité 40, bug favoris/récents) reste inchangée,
  /// ce réglage ne fait qu'exclure CIQUAL en plus si décoché.
  Future<void> _setIncludeCiqual(bool v) async {
    // Même correctif que _setIncludeUsda ci-dessus : plus de blocage
    // silencieux, l'autre base se réactive automatiquement si besoin.
    setState(() {
      _includeCiqual = v;
      if (!v && !_includeUsda) _includeUsda = true;
    });
    if (_includeUsda) {
      await foods_loader.FoodsRepository.instance
          .loadUsdaFromAsset('assets/usda_foods.csv');
      _refreshUsdaMatches();
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('addfood_include_ciqual', _includeCiqual);
    await sp.setBool('addfood_include_usda', _includeUsda);
  }

  Future<void> _setMultiSelectEnabled(bool v) async {
    setState(() => _multiSelectEnabled = v);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('addfood_multi_select', v);
  }

  Future<void> _setShowCategoryTabs(bool v) async {
    setState(() {
      _showCategoryTabs = v;
      // Onglets masqués = plus aucun moyen de taper/swiper vers Favoris/
      // Perso (TabBar cachée + swipe désactivé, voir build()) — sans ce
      // recentrage, un utilisateur qui masque les onglets alors qu'il était
      // sur "Perso" resterait bloqué dessus sans pouvoir en sortir.
      if (!v) _tab.index = 0;
    });
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('addfood_show_tabs', v);
  }

  int _usdaSortCompare(foods_loader.FoodItem a, foods_loader.FoodItem b) {
    switch (p._sortMode) {
      case _SortMode.frequent:
        final s = p._stats.count(b.id).compareTo(p._stats.count(a.id));
        return s != 0 ? s : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortMode.recent:
        final s = p._stats.last(b.id).compareTo(p._stats.last(a.id));
        return s != 0 ? s : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortMode.az:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortMode.za:
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
    }
  }

  void _refreshUsdaMatches() {
    final q = p._query.trim();
    setState(() {
      if (!_includeUsda) {
        _usdaMatches = [];
      } else if (q.length >= 2) {
        // Bug corrigé (14/08/2026, retour d'Alex — "USDA uniquement" ne
        // montrait qu'une poignée d'aliments) : la limite de 20 avait un
        // sens quand USDA venait juste EN RENFORT de CIQUAL (éviter de
        // noyer les résultats CIQUAL) — mais en mode "USDA uniquement",
        // rien ne justifie de tronquer la recherche elle-même.
        _usdaMatches = foods_loader.FoodsRepository.instance
            .searchUsda(q, limit: _includeCiqual ? 20 : 100000);
      } else {
        // Bug corrigé (14/08/2026, retour d'Alex : "je sélectionne
        // uniquement USDA, je vois rien du tout") : sans recherche active,
        // aucun aliment USDA "général" n'apparaissait jamais (seuls les
        // favoris/déjà logués l'étaient, via _visibleByDefaultInCommun côté
        // JournalScreenState) — cocher la case ne changeait donc rien tant
        // que rien n'était tapé, indiscernable d'un filtre cassé.
        //
        // 2e bug corrigé le même jour : l'aperçu par défaut était plafonné
        // à 60 aliments et toujours trié A→Z en dur — en pratique, la very
        // grande quantité de "Alcoholic beverage, ..." (dizaines de
        // variantes USDA, alphabétiquement en tête) remplissait à elle
        // seule le plafond, laissant croire que le tri A→Z "s'arrêtait" et
        // ignorant le mode de tri réellement choisi dans le tiroir de
        // filtre. Plus de plafond, tri aligné sur `_sortMode` (comme le
        // reste de "Commun") — la liste ListView.builder en aval est déjà
        // paresseuse (construit seulement les lignes visibles), aucun coût
        // de rendu à afficher les ~7800 aliments USDA au complet.
        final all = List<foods_loader.FoodItem>.from(
            foods_loader.FoodsRepository.instance.usdaItems);
        all.sort(_usdaSortCompare);
        _usdaMatches = all;
      }
    });
  }

  /// Fiche d'info CIQUAL vs USDA (Priorité 39) : permet un choix éclairé
  /// plutôt qu'un interrupteur sans contexte — retour explicite d'Alex.
  Future<void> _showUsdaInfoSheet() async {
    final l10n = context.l10n;
    Widget row(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 3),
              Text(body, style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.4)),
            ],
          ),
        );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.jrnlCiqualVsUsdaTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            row(l10n.jrnlCiqualDefaultTitle, l10n.jrnlCiqualDefaultBody),
            row(l10n.jrnlUsdaReinforceTitle, l10n.jrnlUsdaReinforceBody),
            row(l10n.jrnlWhyBothTitle, l10n.jrnlWhyBothBody),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.jrnlUnderstood),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tiroir de filtre unique (Priorité 38) : regroupe le tri (déjà existant,
  /// simplement déplacé pour libérer de l'espace écran), le choix de base de
  /// données et l'affichage des onglets — un seul endroit pour tout ce qui
  /// concerne "comment la recherche se comporte", plutôt que des boutons
  /// séparés dispersés dans la barre d'app.
  Future<void> _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 18,
                  bottom: 18 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priorité 40 (retour d'Alex, capture d'écran fournie) :
                    // ordre et libellés alignés sur la référence — "Activer
                    // l'ajout multiple" et "Onglets de catégorie" en tête,
                    // puis Tri, puis Base de données.
                    Text(l10n.jrnlSearchOptionsTitle,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.jrnlMultiSelectToggleTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      subtitle: Text(
                        l10n.jrnlMultiSelectToggleDesc,
                        style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
                      ),
                      value: _multiSelectEnabled,
                      activeThumbColor: TotumColors.accent,
                      onChanged: (v) {
                        _setMultiSelectEnabled(v);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.jrnlCategoryTabsToggleTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      subtitle: Text(
                        l10n.jrnlCategoryTabsToggleDesc,
                        style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
                      ),
                      value: _showCategoryTabs,
                      activeThumbColor: TotumColors.accent,
                      onChanged: (v) {
                        _setShowCategoryTabs(v);
                        setSheetState(() {});
                      },
                    ),
                    const Divider(height: 28),
                    Text(l10n.jrnlSortByLabel, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        for (final entry in {
                          _SortMode.frequent: l10n.jrnlSortFrequent,
                          _SortMode.recent: l10n.jrnlSortRecent,
                          _SortMode.az: l10n.jrnlSortAZ,
                          _SortMode.za: l10n.jrnlSortZA,
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: p._sortMode == entry.key,
                            selectedColor: TotumColors.accentSoft,
                            labelStyle: TextStyle(
                              color: p._sortMode == entry.key ? TotumColors.accent : TotumColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() => p._sortMode = entry.key);
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    // Pendant une recherche active, la pertinence prime
                    // toujours sur le tri choisi (déjà le cas avant cette
                    // refonte) — le tri s'applique surtout à la liste par
                    // défaut (sans recherche) et aux égalités de pertinence.
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.jrnlSearchOverridesSortHint,
                        style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted),
                      ),
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Text(l10n.jrnlDatabaseLabel, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
                        const SizedBox(width: 4),
                        // Retour d'Alex (11/08/2026, Priorité 39) : une
                        // fiche d'info pour que le choix CIQUAL/USDA soit
                        // éclairé, pas juste des cases à cocher sans contexte.
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _showUsdaInfoSheet,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.info_outline, size: 15, color: TotumColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    // Priorité 40 (retour d'Alex, capture d'écran) : CIQUAL
                    // et USDA deviennent 2 cases indépendantes (au lieu d'un
                    // seul interrupteur "Inclure la base USDA" avec CIQUAL
                    // toujours actif en dur) — CIQUAL cochée par défaut, les
                    // deux activables en même temps. Garde-fou dans les
                    // setters : jamais les deux décochées ensemble.
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Text(l10n.jrnlCiqualDefaultCheckbox,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      value: _includeCiqual,
                      activeColor: TotumColors.accent,
                      onChanged: (v) {
                        _setIncludeCiqual(v ?? true);
                        setSheetState(() {});
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Text(l10n.jrnlUsdaReinforceCheckbox,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      value: _includeUsda,
                      activeColor: TotumColors.accent,
                      onChanged: (v) {
                        _setIncludeUsda(v ?? false);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Récupère la liste filtrée en s'assurant que le parent a les bons critères.
  List<dynamic> _list(int tab) => p._applyFilterSort(tab);

  /// Liste "Commun" combinant CIQUAL/perso/recettes (`_list(0)`, géré côté
  /// JournalScreenState) et la découverte USDA (`_usdaMatches`, géré ici —
  /// recherche live ou aperçu par défaut, voir _refreshUsdaMatches).
  ///
  /// Bug corrigé (14/08/2026, retour d'Alex : "si je sélectionne les deux,
  /// je ne vois pas l'USDA") : l'ancienne version concaténait bêtement
  /// [...CIQUAL, ...USDA] SANS re-trier par pertinence combinée — pendant
  /// une recherche avec beaucoup de résultats CIQUAL, les résultats USDA
  /// pourtant présents se retrouvaient rejetés tout en bas de la liste,
  /// indiscernables d'une absence totale. Un doublon était aussi possible
  /// (un aliment USDA déjà favori/logué pouvait apparaître à la fois via
  /// `_list(0)` et via `_usdaMatches`) — dédoublonné par id ici.
  List<dynamic> _commonItems() {
    final seenIds = <String>{};
    final merged = <dynamic>[];
    // Bug corrigé (14/08/2026, retour d'Alex : "en recherche USDA
    // uniquement, on voit encore des aliments perso/recettes/scannés qui
    // ne font pas partie de la base USDA") : l'exclusion ne visait que
    // CIQUAL (`_isCiqualFood`) — les aliments perso/recettes/scannés
    // (préfixes `custom:`/`recipe:`) ne sont ni CIQUAL ni USDA, donc
    // n'étaient jamais filtrés par ce test, quel que soit le réglage.
    // "USDA uniquement" est désormais réellement exclusif : ne garde QUE
    // les aliments `usda:`. Le mode normal (CIQUAL actif, seul ou avec
    // USDA) garde le comportement existant — les perso/recettes restent
    // volontairement surfacés pendant une recherche (voir _applyFilterSort).
    final usdaOnly = _includeUsda && !_includeCiqual;
    for (final it in [..._list(0), if (_includeUsda) ..._usdaMatches]) {
      final id = ((it as dynamic).id as String?) ?? '';
      if (id.isNotEmpty && !seenIds.add(id)) continue;
      if (usdaOnly) {
        if (!_isUsdaFood(it)) continue;
      } else if (!_includeCiqual && _isCiqualFood(it)) {
        continue;
      }
      merged.add(it);
    }
    final q = p._query.trim();
    if (q.isNotEmpty) {
      merged.sort((a, b) {
        final an = (((a as dynamic).name) as String?) ?? '';
        final bn = (((b as dynamic).name) as String?) ?? '';
        return _scoreForQuery(an, q).compareTo(_scoreForQuery(bn, q));
      });
    } else {
      // Bug corrigé (14/08/2026, retour d'Alex) : CIQUAL (déjà trié par
      // _list()) et USDA (déjà trié par _usdaSortCompare()) arrivaient ici
      // chacun DÉJÀ trié séparément puis simplement concaténés — avec les
      // deux bases actives, ça donnait 2 blocs alphabétiques distincts
      // (tout CIQUAL de A à Z, PUIS tout USDA de A à Z) au lieu d'un seul
      // tri global mélangeant les deux. Retrie l'ensemble fusionné avec le
      // même critère (`p._sortMode`) pour un vrai tri unique, cohérent que
      // CIQUAL et/ou USDA soient actifs.
      merged.sort((a, b) {
        final an = (((a as dynamic).name) as String?) ?? '';
        final bn = (((b as dynamic).name) as String?) ?? '';
        final aid = ((a as dynamic).id as String?) ?? '';
        final bid = ((b as dynamic).id as String?) ?? '';
        switch (p._sortMode) {
          case _SortMode.frequent:
            final s = p._stats.count(bid).compareTo(p._stats.count(aid));
            return s != 0 ? s : _norm(an).compareTo(_norm(bn));
          case _SortMode.recent:
            final s = p._stats.last(bid).compareTo(p._stats.last(aid));
            return s != 0 ? s : _norm(an).compareTo(_norm(bn));
          case _SortMode.az:
            return _norm(an).compareTo(_norm(bn));
          case _SortMode.za:
            return _norm(bn).compareTo(_norm(an));
        }
      });
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: PopupMenuButton<String>(
          initialValue: _selectedMeal,
          tooltip: l10n.jrnlChooseMeal,
          onSelected: (v) => setState(() => _selectedMeal = v),
          itemBuilder: (ctx) => [
            for (final m in _mealOptions)
              PopupMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(_mealIcons[m], size: 18, color: TotumColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(_mealTypeLabel(m, l10n)),
                  ],
                ),
              ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_mealIcons[_selectedMeal], size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(_mealTypeLabel(_selectedMeal, l10n),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: ScannerIcon(color: IconTheme.of(context).color ?? TotumColors.textSecondary),
            tooltip: context.l10n.jrnlScanProductTooltip,
            onPressed: p._openBarcodeScanner,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: context.l10n.jrnlMyAccountTooltip,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
        bottom: _showCategoryTabs
            ? TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: context.l10n.jrnlTabCommon),
                  Tab(text: context.l10n.jrnlTabFavorites),
                  Tab(text: context.l10n.jrnlTabPersonal),
                  Tab(text: context.l10n.jrnlTabBrands),
                  Tab(text: context.l10n.jrnlTabRestaurant),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Retour d'Alex (11/08/2026, captures d'écran d'une appli
          // concurrente) : recherche + filtre + scanner regroupés sur une
          // seule ligne — l'ancien bouton "recherche USDA" séparé (icône
          // 🔍🚫 peu explicite) disparaît, remplacé par le réglage "Inclure
          // USDA" du tiroir de filtre, plus visible et plus clair.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      // Bug corrigé (13/08/2026) : le libellé ne regardait
                      // que _includeUsda et affichait "CIQUAL + USDA" même
                      // quand CIQUAL était décochée — reflète maintenant les
                      // 2 bascules ("Base de données", tiroir de filtre).
                      labelText: _includeCiqual && _includeUsda
                          ? context.l10n.jrnlSearchBothDb
                          : _includeUsda
                              ? context.l10n.jrnlSearchUsdaOnly
                              : context.l10n.jrnlSearchCiqualOnly,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchDebounce?.cancel();
                                setState(() { _searchCtrl.clear(); p._query = ''; });
                                _refreshUsdaMatches();
                              },
                            ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (s) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 220), () {
                        if (!mounted) return;
                        setState(() => p._query = s);
                        _refreshUsdaMatches();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: TotumColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: TotumColors.accent),
                    tooltip: context.l10n.jrnlFiltersSortTooltip,
                    onPressed: _openFilterSheet,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              // Onglets masqués : plus de TabBar pour naviguer, donc plus de
              // swipe non plus (verrouillé sur "Commun", voir
              // _setShowCategoryTabs) — sans ça, un swipe accidentel
              // enverrait vers Favoris/Perso sans moyen visible d'en sortir.
              physics: _showCategoryTabs
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: [
                Builder(builder: (_) {
                  final commonItems = _commonItems();
                  return Column(
                    children: [
                      _matchingMealsSection(),
                      Expanded(
                        child: _multiSelectEnabled
                            ? _MultiSelectFoodList(
                                items: commonItems,
                                initialMeal: _selectedMeal,
                                onAddSelected: (items, meal) async {
                                  for (final it in items) {
                                    await p._addToJournal(meal, it, 100);
                                  }
                                },
                              )
                            : _FoodListView(
                                items: commonItems,
                                isFav: (id) => p._fav.isFav(id),
                                onFavToggle: (id) async { await p._fav.toggle(id); setState(() {}); },
                                onTap: (it) => p._openFoodSheet(it, presetMeal: _selectedMeal),
                                showCreateButton: false,
                                onDuplicate: (it) => p._openCustomDialog(prefillFrom: it),
                              ),
                      ),
                    ],
                  );
                }),
                _FoodListView(
                  items: _list(1),
                  isFav: (id) => p._fav.isFav(id),
                  onFavToggle: (id) async { await p._fav.toggle(id); setState(() {}); },
                  onTap: (it) => p._openFoodSheet(it, presetMeal: _selectedMeal),
                  showCreateButton: false,
                  onDuplicate: (it) => p._openCustomDialog(prefillFrom: it),
                ),
                _FoodListView(
                  items: _list(2),
                  isFav: (id) => p._fav.isFav(id),
                  onFavToggle: (id) async { await p._fav.toggle(id); setState(() {}); },
                  onTap: (it) => p._openFoodSheet(it, presetMeal: _selectedMeal),
                  showCreateButton: true,
                  persoFilter: p._persoFilter,
                  onPersoFilterChanged: (v) => setState(() => p._persoFilter = v),
                  persoCount: p._all.where(p._isPersonal).length,
                  recipeCount: p._all.where(p._isRecipe).length,
                  onlyLibraryRecipes: p._onlyLibraryRecipes,
                  onOnlyLibraryChanged: (v) => setState(() => p._onlyLibraryRecipes = v),
                  libraryRecipeCount: p._all.where((it) {
                    final id = ((it as dynamic).id as String?) ?? '';
                    return id.startsWith('recipe:totum_');
                  }).length,
                  onCreateCustom: () => p._openCustomDialog(),
                  onCreateRecipe: () => p._openRecipeEditor(),
                  onCreateMeal: () => p._openMealEditor(),
                  onEditCustom: (item) {
                    if (p._isRecipe(item)) {
                      final recipeId = ((item as dynamic).id as String?) ?? '';
                      final recipe = p._recipes.list.firstWhere(
                          (r) => r.id == recipeId,
                          orElse: () => _Recipe(
                              id: recipeId, name: '', ingredients: [],
                              totalWeightG: 100, micros100: {}));
                      p._openRecipeEditor(editRecipe: recipe);
                    } else {
                      p._openCustomDialog(editItem: item);
                    }
                  },
                  onDeleteCustom: (id) async {
                    if (id.startsWith('recipe:')) {
                      await p._recipes.remove(id);
                    } else {
                      await p._customs.remove(id);
                    }
                    await p._ensureFoodsLoaded(force: true);
                    setState(() {});
                  },
                  mealItems: p._customMeals.list,
                  onTapMeal: (meal) => p._addMealTemplateDialog(meal),
                  onOpenMealDetail: (meal) => p._openMealDetailSheet(meal),
                  onEditMeal: (meal) => p._openMealEditor(editMeal: meal),
                  onDeleteMeal: (id) async {
                    await p._customMeals.remove(id);
                    setState(() {});
                  },
                ),
                _BrandOrRestaurantTab(
                  sourceType: 'marque',
                  onFoodSelected: (food) => _addUsdaBrandFood(food),
                ),
                _BrandOrRestaurantTab(
                  sourceType: 'restaurant',
                  onFoodSelected: (food) => _addUsdaBrandFood(food),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Même flux que pour un aliment USDA "classique" du Commun (voir
  /// `onTap: (it) => p._openFoodSheet(it)` sur cet onglet) : l'id
  /// "usda:<fdc_id>" est déjà résolu par `findById` (favoris, journal,
  /// recettes...) sans registre "Perso" intermédiaire — voir confirmation
  /// Priorité 40. Pas de `_customs.add()` ici : ça créerait un doublon
  /// permanent (local + Supabase) juste en ouvrant la fiche pour consulter.
  Future<void> _addUsdaBrandFood(foods_loader.FoodItem food) async {
    await p._openFoodSheet(food, presetMeal: _selectedMeal);
  }

  /// Repas perso correspondant à la recherche en cours, affichés en tête de
  /// l'onglet Commun — avant, une recherche par mot-clé n'y faisait jamais
  /// remonter les repas perso (ni les aliments/recettes perso, corrigé côté
  /// _applyFilterSort).
  Widget _matchingMealsSection() {
    final q = p._query.trim();
    if (q.isEmpty) return const SizedBox.shrink();
    final matches = p._customMeals.list
        .where((m) => _norm(m.name).contains(_norm(q)))
        .toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.jrnlPersonalMealSegment, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TotumColors.textSecondary)),
          const SizedBox(height: 4),
          for (final meal in matches)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: TotumColors.accentSoft,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.bookmark, color: TotumColors.accent, size: 20),
                title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(context.l10n.jrnlItemsAndKcal(meal.items.length, meal.totalKcal.toStringAsFixed(0))),
                trailing: const Icon(Icons.add_circle_outline, color: TotumColors.accent),
                onTap: () => p._addMealTemplateDialog(meal),
              ),
            ),
          Divider(height: 16, color: TotumColors.outline),
        ],
      ),
    );
  }

}

class _DayJournalView extends StatefulWidget {
  final DateTime initialDate;
  final Goals goals;
  final Future<Map<String, List<Map<String, dynamic>>>> Function(DateTime)
      loadJournalForDate;
  final Future<void> Function(
      String meal, int index, Map<String, dynamic> entry, DateTime date)
      onRemoveEntry;
  final Future<void> Function(Map<String, dynamic> entry, String oldMeal,
      String newMeal, double newGrams, DateTime date) onEditEntry;
  final Future<void> Function(List<Map<String, dynamic>> items,
      String sourceMeal, String targetMeal, DateTime targetDate) onCopyMeal;
  final Future<void> Function(String name, List<Map<String, dynamic>> items)
      onSaveAsCustomMeal;
  final Future<void> Function(
      String meal, dynamic foodItem, double grams, DateTime date) onAddEntry;
  final NutritionTargets? nutritionTargets;
  final List<dynamic> allFoods;
  final bool Function(String id)? isFav;
  final Future<void> Function(String id)? onToggleFav;
  final Future<void> Function(String meal, DateTime date)? onClearMeal;
  final _FoodStats? foodStats;
  final Future<void> Function(String meal)? onScanForMeal;
  final List<_CustomMeal> customMeals;
  final Future<void> Function(_CustomMeal meal, String targetMeal, DateTime targetDate)?
      onAddCustomMeal;

  const _DayJournalView({
    super.key,
    required this.initialDate,
    required this.goals,
    required this.loadJournalForDate,
    required this.onRemoveEntry,
    required this.onEditEntry,
    required this.onCopyMeal,
    required this.onSaveAsCustomMeal,
    required this.onAddEntry,
    this.nutritionTargets,
    this.allFoods = const [],
    this.isFav,
    this.onToggleFav,
    this.onClearMeal,
    this.foodStats,
    this.onScanForMeal,
    this.customMeals = const [],
    this.onAddCustomMeal,
  });

  @override
  State<_DayJournalView> createState() => _DayJournalViewState();
}

class _DayJournalViewState extends State<_DayJournalView> {
  late DateTime _currentDate;
  Map<String, List<Map<String, dynamic>>> _journal = {
    'Petit-déjeuner': [], 'Déjeuner': [], 'Dîner': [], 'Collation': [],
  };
  DayTotals _totals =
      const DayTotals(kcal: 0, prot: 0, carb: 0, fat: 0, fiber: 0);
  bool _loadingDate = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _fetchDate(_currentDate);
  }
/// Rafraîchit la vue depuis l'extérieur (ex : après un scan).
  Future<void> refreshCurrentDate() =>
      _fetchDate(_currentDate, showSpinner: false);
  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get _isToday => _ymd(_currentDate) == _ymd(DateTime.now());

  Future<void> _fetchDate(DateTime date, {bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loadingDate = true);
    final data = await widget.loadJournalForDate(date);
    if (!mounted) return;
    setState(() { _journal = data; _loadingDate = false; });
    _recomputeTotals();
  }

  void _recomputeTotals() {
    double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
    for (final list in _journal.values) {
      for (final item in list) {
        kcal  += (item['kcal']  as num?)?.toDouble() ?? 0.0;
        prot  += (item['prot']  as num?)?.toDouble() ?? 0.0;
        carb  += (item['carb']  as num?)?.toDouble() ?? 0.0;
        fat   += (item['fat']   as num?)?.toDouble() ?? 0.0;
        fiber += (item['fiber'] as num?)?.toDouble() ?? 0.0;
      }
    }
    setState(() {
      _totals = DayTotals(kcal: kcal, prot: prot, carb: carb, fat: fat, fiber: fiber);
    });
  }

  void _goToPreviousDay() {
    final prev = _currentDate.subtract(const Duration(days: 1));
    setState(() => _currentDate = prev);
    _fetchDate(prev);
  }

  void _goToNextDay() {
    final next = _currentDate.add(const Duration(days: 1));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _currentDate = next);
    _fetchDate(next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _currentDate = picked);
      _fetchDate(picked);
    }
  }

  bool _isPersonalFood(dynamic it) {
    try {
      return ((it as dynamic).id as String?)?.startsWith('custom:') == true;
    } catch (_) { return false; }
  }

  bool _isRecipeFood(dynamic it) {
    try {
      return ((it as dynamic).id as String?)?.startsWith('recipe:') == true;
    } catch (_) { return false; }
  }


  /// Ouvre une recherche d'aliment puis l'ajoute au repas choisi,
  /// pour la date actuellement affichée (même si ce n'est pas aujourd'hui).
  /// 
  Future<void> _openAddFoodDialog(String meal) async {
    final searchCtrl = TextEditingController();
    String query = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final results = query.trim().isEmpty
              ? <dynamic>[]
              : (widget.allFoods.where((it) {
                  final n = _norm((((it as dynamic).name) as String? ?? ''));
                  final generic = _nomGeneriqueOf(it);
                  final q = _norm(query.trim());
                  return n.contains(q) || (generic != null && _norm(generic).contains(q));
                }).toList()
                ..sort((a, b) {
                  final aid = ((a as dynamic).id  as String?) ?? '';
                  final bid = ((b as dynamic).id  as String?) ?? '';
                  final an  = ((a as dynamic).name as String?) ?? '';
                  final bn  = ((b as dynamic).name as String?) ?? '';

                  // 1. Favoris en premier
                  final aFav = widget.isFav?.call(aid) ?? false;
                  final bFav = widget.isFav?.call(bid) ?? false;
                  if (aFav != bFav) return aFav ? -1 : 1;

                  // 2. Fréquence d'utilisation (plus utilisé = plus haut)
                  final aCount = widget.foodStats?.count(aid) ?? 0;
                  final bCount = widget.foodStats?.count(bid) ?? 0;
                  if (aCount != bCount) return bCount.compareTo(aCount);

                  // 3. Récence (utilisé plus récemment = plus haut)
                  final aLast = widget.foodStats?.last(aid) ?? 0;
                  final bLast = widget.foodStats?.last(bid) ?? 0;
                  if (aLast != bLast) return bLast.compareTo(aLast);

                  // 4. Pertinence textuelle (début du nom > milieu > contenu)
                  return _scoreForQuery(an, query.trim())
                      .compareTo(_scoreForQuery(bn, query.trim()));
                }))
                  .take(30)
                  .toList();

          // Repas perso correspondant à la recherche (retour d'Alex,
          // 12/08/2026) : un repas perso sauvegardé doit être trouvable et
          // ajoutable en un tap depuis cette même recherche, comme un
          // aliment classique — placés en tête, distincts visuellement
          // (voir branche `is _CustomMeal` dans l'itemBuilder ci-dessous).
          final matchingMeals = query.trim().isEmpty
              ? <_CustomMeal>[]
              : widget.customMeals
                  .where((m) => _norm(m.name).contains(_norm(query.trim())))
                  .toList();
          final combined = <dynamic>[...matchingMeals, ...results];

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      ctx.l10n.jrnlAddToMeal(_mealTypeLabel(meal, ctx.l10n)),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: ctx.l10n.jrnlSearchFood,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setSheetState(() {
                                  searchCtrl.clear();
                                  query = '';
                                }),
                              ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (s) => setSheetState(() => query = s),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: combined.isEmpty
                        ? Center(
                            child: Text(
                              query.trim().isEmpty
                                  ? ctx.l10n.jrnlTypeToSearchFood
                                  : ctx.l10n.jrnlNoResults,
                              style: TextStyle(color: TotumColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: combined.length,
                            itemBuilder: (_, i) {
                              final food = combined[i];
                              if (food is _CustomMeal) {
                                return ListTile(
                                  leading: Container(
                                    width: 38, height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: TotumColors.accentSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.dining_outlined,
                                        color: TotumColors.accent, size: 18),
                                  ),
                                  title: Text(food.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                      ctx.l10n.jrnlPersonalMealSummary(
                                          food.items.length, food.totalKcal.toStringAsFixed(0)),
                                      style: TextStyle(color: TotumColors.textSecondary, fontSize: 12)),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await widget.onAddCustomMeal?.call(food, meal, _currentDate);
                                    await _fetchDate(_currentDate, showSpinner: false);
                                  },
                                );
                              }
                              final fname =
                                  ((food as dynamic).name as String?) ??
                                      ctx.l10n.jrnlGenericFoodFallback;
                              final fkcal =
                                  ((food).kcal100 as num?)?.toDouble() ?? 0.0;
                              final fid = ((food).id as String?) ?? '';
                              final favStatus = (widget.isFav != null &&
                                      fid.isNotEmpty)
                                  ? widget.isFav!(fid)
                                  : false;
                              final isPerso = _isPersonalFood(food);
                              final isRecipe = _isRecipeFood(food);
                              final isUsda = _isUsdaFood(food);
                              // Pictogramme/photo + nom court (Priorité 26) : ce
                              // dialogue d'ajout rapide (bouton + par repas) avait
                              // sa propre liste, distincte de _FoodListView, et
                              // n'affichait ni l'un ni l'autre — retour d'Alex.
                              final photo = _photoOf(food);
                              final pictogram = _pictogramOf(food);
                              final displayName = displayNameOf(food, fname);
                              return ListTile(
                                leading: photo != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          photo, width: 38, height: 38, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 38, height: 38,
                                            decoration: BoxDecoration(
                                              color: TotumColors.accentSoft,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.image_not_supported_outlined,
                                                color: TotumColors.accent, size: 18),
                                          ),
                                        ),
                                      )
                                    : pictogram != null
                                        ? Container(
                                            width: 38, height: 38,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: TotumColors.accentSoft,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(pictogram, style: const TextStyle(fontSize: 19)),
                                          )
                                        // Retour d'Alex (11/08/2026) : distinguer visuellement
                                        // un aliment venant de la base USDA (pas de pictogramme
                                        // français dédié pour ceux-là) — et "je veux aucune
                                        // ligne où je n'ai pas d'icône présente sur le côté" :
                                        // "Perso" n'avait ici aucune icône dédiée (seulement le
                                        // badge texte du titre), et il n'y avait aucun repli
                                        // final avant ce correctif (juste `null`).
                                        : isPerso
                                            ? Container(
                                                width: 38, height: 38,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: TotumColors.accentSoft,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.person_outline,
                                                    color: TotumColors.accent, size: 18),
                                              )
                                            : isRecipe
                                            ? Container(
                                                width: 38, height: 38,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: TotumColors.accentSoft,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.menu_book_outlined,
                                                    color: TotumColors.accent, size: 18),
                                              )
                                            : isUsda
                                            ? Container(
                                                width: 38, height: 38,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: TotumColors.accentSoft,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.public,
                                                    color: TotumColors.accent, size: 18),
                                              )
                                            : Container(
                                                width: 38, height: 38,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: TotumColors.accentSoft,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.restaurant,
                                                    color: TotumColors.accent, size: 17),
                                              ),
                                // Priorité 50 (13/08/2026) : plafonné à 2 lignes
                                // (au lieu d'illimité) — même correctif que
                                // _FoodListView, hauteur de ligne prévisible.
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(displayName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14, height: 1.25)),
                                    ),
                                    if (isPerso) ...[
                                      const SizedBox(width: 6),
                                      _foodTag(ctx.l10n.jrnlTagPersonal, TotumColors.accent),
                                    ] else if (isRecipe) ...[
                                      const SizedBox(width: 6),
                                      _foodTag(ctx.l10n.jrnlTagRecipe, TotumColors.accent),
                                    ] else if (isUsda) ...[
                                      const SizedBox(width: 6),
                                      _foodTag('USDA', TotumColors.textSecondary),
                                    ],
                                  ],
                                ),
                                // Retour d'Alex (11/08/2026) : plus d'ancien nom en
                                // double en dessous — juste le nom et les kcal/100g.
                                subtitle: Text(ctx.l10n.jrnlKcalPer100g(fkcal.toStringAsFixed(0)),
                                    style: const TextStyle(fontSize: 12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                minVerticalPadding: 8,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        favStatus
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: favStatus
                                            ? TotumColors.accent
                                            : TotumColors.textMuted,
                                      ),
                                      tooltip: favStatus
                                          ? ctx.l10n.jrnlRemoveFavorite
                                          : ctx.l10n.jrnlAddFavorite,
                                      onPressed: (widget.onToggleFav != null &&
                                              fid.isNotEmpty)
                                          ? () async {
                                              await widget.onToggleFav!(fid);
                                              setSheetState(() {});
                                            }
                                          : null,
                                    ),
                                    const Icon(Icons.add_circle_outline,
                                        color: TotumColors.accent),
                                  ],
                                ),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  await _openQuantityDialog(meal, food);
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Demande la quantité puis enregistre l'aliment sur la date affichée
  Future<void> _openQuantityDialog(String meal, dynamic food) async {
    final qtyCtrl = TextEditingController(text: '100');
    final fname = displayNameOf(food, ((food as dynamic).name as String?) ?? context.l10n.jrnlGenericFoodFallback);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fname, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ctx.l10n.jrnlQtyLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: kTotumOrange, foregroundColor: Colors.white),
            onPressed: () async {
              final grams =
                  double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 100.0;
              Navigator.pop(ctx);
              await widget.onAddEntry(meal, food, grams, _currentDate);
              await _fetchDate(_currentDate, showSpinner: false);
            },
            child: Text(ctx.l10n.commonAdd),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      Map<String, dynamic> entry, String currentMeal) async {
    String newMeal = currentMeal;
    final currentGrams = (entry['grams'] as num?)?.toDouble() ?? 100.0;
    final qtyCtrl = TextEditingController(text: currentGrams.toStringAsFixed(0));
    final entryFoodId = (entry['id'] ?? '').toString();
    dynamic entryFood;
    try {
      entryFood = widget.allFoods
          .firstWhere((f) => ((f as dynamic).id as String?) == entryFoodId);
    } catch (_) { entryFood = null; }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(displayNameOf(entryFood, (entry['name'] ?? ctx.l10n.jrnlGenericFoodFallback).toString()),
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ctx.l10n.jrnlQtyLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: newMeal,
                decoration: InputDecoration(
                  labelText: ctx.l10n.jrnlMealDropdownLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem(value: 'Petit-déjeuner', child: Text(ctx.l10n.consCatBreakfast)),
                  DropdownMenuItem(value: 'Déjeuner', child: Text(ctx.l10n.consCatLunch)),
                  DropdownMenuItem(value: 'Dîner', child: Text(ctx.l10n.consCatDinner)),
                  DropdownMenuItem(value: 'Collation', child: Text(ctx.l10n.consCatSnack)),
                ],
                onChanged: (v) { if (v != null) setDlg(() => newMeal = v); },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.commonCancel)),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: kTotumOrange, foregroundColor: Colors.white),
              onPressed: () async {
                final newGrams = double.tryParse(
                    qtyCtrl.text.replaceAll(',', '.')) ?? currentGrams;
                Navigator.pop(ctx);
                await widget.onEditEntry(
                    entry, currentMeal, newMeal, newGrams, _currentDate);
                await _fetchDate(_currentDate, showSpinner: false);
              },
              child: Text(ctx.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCopyDialog(
      String sourceMeal, List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jrnlMealEmptyToCopy)));
      return;
    }
    String targetMeal = sourceMeal;
    DateTime targetDate = DateTime.now();
    bool saveAsTemplate = false;
    final dateCtrl = TextEditingController(
        text: '${targetDate.day.toString().padLeft(2, '0')}/'
            '${targetDate.month.toString().padLeft(2, '0')}/'
            '${targetDate.year}');
    final nameCtrl = TextEditingController(text: sourceMeal);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(ctx.l10n.jrnlCopyMealTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ctx.l10n.jrnlItemsFromMeal(items.length, _mealTypeLabel(sourceMeal, ctx.l10n)),
                  style: TextStyle(color: TotumColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, icon: const Icon(Icons.calendar_today, size: 16), label: Text(ctx.l10n.jrnlToDaySegment)),
                  ButtonSegment(value: true, icon: const Icon(Icons.bookmark_add_outlined, size: 16), label: Text(ctx.l10n.jrnlPersonalMealSegment)),
                ],
                selected: {saveAsTemplate},
                onSelectionChanged: (s) => setDlg(() => saveAsTemplate = s.first),
              ),
              const SizedBox(height: 14),
              if (!saveAsTemplate) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setDlg(() {
                        targetDate = picked;
                        dateCtrl.text =
                            '${picked.day.toString().padLeft(2, '0')}/'
                            '${picked.month.toString().padLeft(2, '0')}/'
                            '${picked.year}';
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: ctx.l10n.jrnlTowardDay,
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(dateCtrl.text),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: targetMeal,
                  decoration: InputDecoration(
                    labelText: ctx.l10n.jrnlTowardMeal,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Petit-déjeuner', child: Text(ctx.l10n.consCatBreakfast)),
                    DropdownMenuItem(value: 'Déjeuner', child: Text(ctx.l10n.consCatLunch)),
                    DropdownMenuItem(value: 'Dîner', child: Text(ctx.l10n.consCatDinner)),
                    DropdownMenuItem(value: 'Collation', child: Text(ctx.l10n.consCatSnack)),
                  ],
                  onChanged: (v) { if (v != null) setDlg(() => targetMeal = v); },
                ),
              ] else
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: ctx.l10n.jrnlPersonalMealNameField,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.commonCancel)),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: kTotumOrange, foregroundColor: Colors.white),
              onPressed: () async {
                final l10n = ctx.l10n;
                Navigator.pop(ctx);
                if (saveAsTemplate) {
                  await widget.onSaveAsCustomMeal(nameCtrl.text, items);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.jrnlSavedToPersonalMeals(nameCtrl.text.trim())),
                    ));
                  }
                } else {
                  await widget.onCopyMeal(items, sourceMeal, targetMeal, targetDate);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.jrnlItemsCopiedTo(items.length, _mealTypeLabel(targetMeal, l10n))),
                    ));
                  }
                }
              },
              child: Text(ctx.l10n.jrnlCopyButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRemove(String meal, int index) async {
    final list = _journal[meal];
    if (list == null || index < 0 || index >= list.length) return;
    final entry = Map<String, dynamic>.from(list[index]);
    // On retire d'abord localement, puis on demande la suppression distante
    // en se basant sur l'entry (entry_id), pas sur l'index qui a bougé.
    setState(() { list.removeAt(index); _recomputeTotals(); });
    await widget.onRemoveEntry(meal, -1, entry, _currentDate);
  }

  Future<void> _handleClearMeal(String meal) async {
    setState(() { _journal[meal] = []; });
    _recomputeTotals();
    await widget.onClearMeal?.call(meal, _currentDate);
  }

  // ── Fiche aliment depuis le journal ────────────────────────────────────────
  Future<void> _openEntrySheet(Map<String, dynamic> entry) async {
    final T = widget.nutritionTargets;
    if (T == null) return;

    final foodId = (entry['id'] ?? '').toString();
    dynamic food;
    try {
      food = widget.allFoods.firstWhere(
        (f) => ((f as dynamic).id as String?) == foodId,
      );
    } catch (_) {
      food = null;
    }

    // Aliment introuvable dans _all : affichage simplifié avec les macros du journal
    if (food == null) {
      final grams = (entry['grams'] as num?)?.toDouble() ?? 100.0;
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (entry['name'] ?? ctx.l10n.jrnlGenericFoodFallback).toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(ctx.l10n.jrnlQuantityGrams(grams.toString()),
                    style: TextStyle(color: TotumColors.textSecondary)),
                const SizedBox(height: 8),
                _simpleRow(nutrientDisplayLabel('Énergie', ctx.l10n),
                    '${((entry['kcal'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} kcal'),
                _simpleRow(nutrientDisplayLabel('Protéines', ctx.l10n),
                    '${((entry['prot'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} g'),
                _simpleRow(nutrientDisplayLabel('Glucides', ctx.l10n),
                    '${((entry['carb'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} g'),
                _simpleRow(nutrientDisplayLabel('Lipides', ctx.l10n),
                    '${((entry['fat'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} g'),
                _simpleRow(nutrientDisplayLabel('Fibres', ctx.l10n),
                    '${((entry['fiber'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} g'),
                const SizedBox(height: 8),
                Text(
                  ctx.l10n.jrnlDetailNotAvailable,
                  style: TextStyle(fontSize: 12, color: TotumColors.textMuted,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Aliment trouvé → fiche complète
    final grams = (entry['grams'] as num?)?.toDouble() ?? 100.0;
    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    double micro(String key) {
      try {
        final map = (food as dynamic).micros100 as Map<String, dynamic>?;
        return getD(map?[key]);
      } catch (_) { return 0.0; }
    }
    final f = grams / 100.0;
    Map<String, double> macros() => {
      'kcal': getD((food as dynamic).kcal100) * f,
      'prot': getD((food as dynamic).prot100) * f,
      'carb': getD((food as dynamic).carb100) * f,
      'fat':  getD((food as dynamic).fat100)  * f,
      'fiber':getD((food as dynamic).fiber100)* f,
    };
    double asG(double x)  => x * f;
    double asMg(double x) => x * f;
    double asUg(double x) => x * f;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayNameOf(food, (entry['name'] ?? 'Aliment').toString()),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('$grams g',
                      style: TextStyle(color: TotumColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _Section(
                    title: 'Macro-cibles', icon: Icons.bolt,
                    initiallyExpanded: true,
                    metrics: [
                      _Metric('Énergie',   macros()['kcal'] ?? 0, T.goals.kcal, 'kcal', 0),
                      _Metric('Protéines', macros()['prot'] ?? 0, T.goals.prot, 'g',    1),
                      _Metric('Glucides',  macros()['carb'] ?? 0, T.goals.carb, 'g',    1),
                      _Metric('Lipides',   macros()['fat']  ?? 0, T.goals.fat,  'g',    1),
                      _Metric('Fibres',    macros()['fiber']?? 0, T.goals.fiber,'g',    1),
                    ],
                  ),
                  _Section(
                    title: 'Acides gras essentiels', icon: Icons.opacity,
                    metrics: [
                      _Metric('Oméga 9', asG(micro('Acide_oléique_W9_g_100g')),      T.o9,  'g', 2),
                      _Metric('Oméga 6', asG(micro('Acide_linoléique_W6_LA_g_100g')), T.o6,  'g', 2),
                      _Metric('Oméga 3', asG(micro('Acide_alpha-linolénique_W3_ALA_g_100g')), T.o3, 'g', 2),
                      _Metric('EPA',     asG(micro('EPA_g_100g')),                    T.epa, 'g', 2),
                      _Metric('DHA',     asG(micro('DHA_g_100g')),                    T.dha, 'g', 2),
                    ],
                  ),
                  _Section(
                    title: 'À surveiller', icon: Icons.visibility_outlined,
                    metrics: [
                      _Metric('AG saturés', asG(micro('AG_saturés_g_100g')),   T.sat,    'g', 2),
                      _Metric('Sucres',     asG(micro('Sucres_g_100g')),        T.sugars, 'g', 1),
                      _Metric('Sel',        asG(micro('Sel_g_100g')),           T.salt,   'g', 1),
                    ],
                  ),
                  _Section(
                    title: 'Vitamines', icon: Icons.wb_sunny_outlined,
                    metrics: [
                      _Metric('Rétinol',   asUg(micro('Rétinol_µg_100g')),        T.vitAUg,       'µg', 0, ul: _kUlRetinolUg),
                      _Metric('Bêta-car.', asUg(micro('Beta-Carotène_µg_100g')), T.vitBetacarUg, 'µg', 0),
                      _Metric('Vit D',  asUg(micro('Vitamine_D_µg_100g')),  T.vitDUg, 'µg', 0),
                      _Metric('Vit E',  asMg(micro('Vitamine_E_mg_100g')),  T.vitEMg, 'mg', 1),
                      _Metric('Vit K',  asUg(micro('Vitamine_K1_µg_100g') + micro('Vitamine_K2_µg_100g')), T.vitKUg, 'µg', 0),
                      _Metric('Vit C',  asMg(micro('Vitamine_C_mg_100g')),  T.vitCMg, 'mg', 0),
                      _Metric('B1',     asMg(micro('Vitamine_B1_mg_100g')), T.b1Mg,   'mg', 1),
                      _Metric('B2',     asMg(micro('Vitamine_B2_mg_100g')), T.b2Mg,   'mg', 1),
                      _Metric('B3',     asMg(micro('Vitamine_B3_mg_100g')), T.b3Mg,   'mg', 1),
                      _Metric('B5',     asMg(micro('Vitamine_B5_mg_100g')), T.b5Mg,   'mg', 1),
                      _Metric('B6',     asMg(micro('Vitamine_B6_mg_100g')), T.b6Mg,   'mg', 1),
                      _Metric('B9',     asUg(micro('Vitamine_B9_µg_100g')), T.b9Ug,   'µg', 0),
                      _Metric('B12',    asUg(micro('Vitamine_B12_µg_100g')),T.b12Ug,  'µg', 0),
                    ],
                  ),
                  _Section(
                    title: 'Minéraux', icon: Icons.diamond_outlined,
                    metrics: [
                      _Metric('Calcium',   asMg(micro('Calcium_mg_100g')),   T.caMg, 'mg', 0),
                      _Metric('Cuivre',    asMg(micro('Cuivre_mg_100g')),    T.cuMg, 'mg', 1),
                      _Metric('Fer',       asMg(micro('Fer_mg_100g')),       T.feMg, 'mg', 1, ul: _kUlFerMg),
                      _Metric('Iode',      asUg(micro('Iode_µg_100g')),      T.iUg,  'µg', 0),
                      _Metric('Magnésium', asMg(micro('Magnésium_mg_100g')), T.mgMg, 'mg', 0),
                      _Metric('Manganèse', asMg(micro('Manganèse_mg_100g')), T.mnMg, 'mg', 1),
                      _Metric('Phosphore', asMg(micro('Phosphore_mg_100g')), T.pMg,  'mg', 0),
                      _Metric('Potassium', asMg(micro('Potassium_mg_100g')), T.kMg,  'mg', 0),
                      _Metric('Sélénium',  asUg(micro('Sélénium_µg_100g')),  T.seUg, 'µg', 0, ul: _kUlSeleniumUg),
                      _Metric('Sodium',    asMg(micro('Sodium_mg_100g')),    T.naMg, 'mg', 0),
                      _Metric('Zinc',      asMg(micro('Zinc_mg_100g')),      T.znMg, 'mg', 1, ul: _kUlZincMg),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper ligne simple pour la fiche basique
  Widget _simpleRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goals = widget.goals;
    final double gKcal = goals.kcal <= 0 ? 2000.0 : goals.kcal;
    final weekdays = [
      l10n.jrnlWeekdayMon, l10n.jrnlWeekdayTue, l10n.jrnlWeekdayWed, l10n.jrnlWeekdayThu,
      l10n.jrnlWeekdayFri, l10n.jrnlWeekdaySat, l10n.jrnlWeekdaySun,
    ];
    final months = [
      l10n.bilanMonthJan, l10n.bilanMonthFeb, l10n.bilanMonthMar, l10n.bilanMonthApr,
      l10n.bilanMonthMay, l10n.bilanMonthJun, l10n.bilanMonthJul, l10n.bilanMonthAug,
      l10n.bilanMonthSep, l10n.bilanMonthOct, l10n.bilanMonthNov, l10n.bilanMonthDec,
    ];
    final dateLabel = _isToday
        ? l10n.jrnlToday
        : '${weekdays[_currentDate.weekday - 1]} '
          '${_currentDate.day} '
          '${months[_currentDate.month - 1]} '
          '${_currentDate.year}';

    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TotumColors.textPrimary,
        title: Text(l10n.jrnlJournalTitle,
            style: TextStyle(fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
        // Priorité 50 (14/08/2026, retour d'Alex) : icône Compte &
        // Paramètres présente sur tous les autres onglets (Profil, écran
        // "Ajouter un aliment"...) — manquait sur l'onglet Journal lui-même.
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.jrnlAccountSettingsTooltip,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: TotumColors.textSecondary),
                  tooltip: l10n.jrnlPreviousDayTooltip,
                  onPressed: _goToPreviousDay,
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: TotumColors.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dateLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14.5, color: TotumColors.accent)),
                        const SizedBox(width: 6),
                        const Icon(Icons.calendar_today, size: 14, color: TotumColors.accent),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: l10n.jrnlNextDayTooltip,
                  onPressed: _isToday ? null : _goToNextDay,
                  color: _isToday ? TotumColors.textMuted : TotumColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loadingDate
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _DayMacroOverview(goals: goals, totals: _totals, gKcal: gKcal),
                  const SizedBox(height: 16),
                  for (final meal in ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'])
                    _MealSection(
                      title: meal,
                      items: _journal[meal] ?? [],
                      onRemove: (i) => _handleRemove(meal, i),
                      onEdit: (entry) => _showEditDialog(entry, meal),
                      onCopy: () => _showCopyDialog(meal, _journal[meal] ?? []),
                      onCopySelected: (selectedItems) =>
                          _showCopyDialog(meal, selectedItems),
                      onAddFood: () => _openAddFoodDialog(meal),
                      onScan: widget.onScanForMeal != null
                          ? () => widget.onScanForMeal!(meal)
                          : null,
                      onClearAll: () => _handleClearMeal(meal),
                      nutritionTargets: widget.nutritionTargets,
                      allFoods: widget.allFoods,
                      onTapItem: widget.nutritionTargets != null
                          ? (entry) => _openEntrySheet(entry)
                          : null,
                    ),
                  const SizedBox(height: 8),
                  _WaterBanner(date: _currentDate),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ══════════════════════════════════════════════════════════════════════════════

class _DayMacroOverview extends StatelessWidget {
  final Goals goals;
  final DayTotals totals;
  final double gKcal;
  const _DayMacroOverview({required this.goals, required this.totals, required this.gKcal});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targetKcal = gKcal > 0 ? gKcal : 2000.0;
    final pctKcal = targetKcal == 0
        ? 0.0
        : (totals.kcal / targetKcal).clamp(0.0, double.infinity);
    final colorKcal = TotumProgress.forFraction(pctKcal > 1 ? 1.0 : pctKcal);
    final remainingKcal = targetKcal > 0
        ? (targetKcal - totals.kcal).clamp(0.0, double.infinity)
        : 0.0;
    final macros = [
      _MacroItem(icon: Icons.egg_alt_outlined, label: 'Protéines', unit: 'g', value: totals.prot, target: goals.prot),
      _MacroItem(icon: Icons.grain, label: 'Glucides', unit: 'g', value: totals.carb, target: goals.carb),
      _MacroItem(icon: Icons.opacity, label: 'Lipides', unit: 'g', value: totals.fat, target: goals.fat),
      _MacroItem(icon: Icons.eco, label: 'Fibres', unit: 'g', value: totals.fiber, target: goals.fiber),
    ];
    return TotumCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 15, color: TotumColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(nutrientDisplayLabel('Énergie', l10n),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: TotumColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 94, height: 94,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pctKcal.clamp(0.02, 1.0),
                        strokeWidth: 9,
                        color: colorKcal,
                        backgroundColor: TotumColors.outlineStrong,
                      ),
                      Text(
                        '${(pctKcal * 100).clamp(0, 200).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18, color: TotumColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.jrnlTargetKcal(targetKcal.toStringAsFixed(0)),
                    style: TextStyle(fontSize: 11, color: TotumColors.textSecondary), textAlign: TextAlign.center),
                Text(l10n.jrnlConsumedKcal(totals.kcal.toStringAsFixed(0)),
                    style: TextStyle(fontSize: 11, color: TotumColors.textSecondary), textAlign: TextAlign.center),
                Text(l10n.jrnlRemainingKcal(remainingKcal.toStringAsFixed(0)),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TotumColors.textPrimary),
                    textAlign: TextAlign.center),
                Builder(builder: (_) {
                  final excessKcal = (totals.kcal - targetKcal).clamp(0.0, double.infinity);
                  if (targetKcal <= 0 || totals.kcal <= targetKcal) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 12, color: TotumColors.negative),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            l10n.jrnlExceededByKcal(excessKcal.toStringAsFixed(0)),
                            style: TextStyle(
                                fontSize: 10.5, color: TotumColors.negative, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: macros.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: _MacroBarRow(item: m),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem {
  final IconData icon;
  final String label, unit;
  final double value, target;
  const _MacroItem({required this.icon, required this.label, required this.unit,
      required this.value, required this.target});
}

class _MacroBarRow extends StatelessWidget {
  final _MacroItem item;
  const _MacroBarRow({required this.item});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = item.target == 0
        ? 0.0
        : (item.value / item.target).clamp(0.0, double.infinity);
    final color = TotumProgress.forFraction(pct > 1 ? 1.0 : pct);
    final remaining = (item.target - item.value).clamp(0.0, double.infinity);
    final excess    = (item.value - item.target).clamp(0.0, double.infinity);
    final overshot  = item.value > item.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(item.icon, size: 14, color: TotumColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(nutrientDisplayLabel(item.label, l10n),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: TotumColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct.clamp(0.02, 1.0),
            minHeight: 7,
            backgroundColor: TotumColors.page,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 10.5, color: TotumColors.textMuted),
            children: [
              TextSpan(text: '${item.value.toStringAsFixed(0)} / ${item.target.toStringAsFixed(0)} ${item.unit} · '),
              TextSpan(
                text: overshot
                    ? l10n.jrnlOverBy(excess.toStringAsFixed(0), item.unit)
                    : l10n.jrnlRemainingBy(remaining.toStringAsFixed(0), item.unit),
                style: TextStyle(
                  color: overshot ? TotumColors.negative : TotumColors.textMuted,
                  fontWeight: overshot ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealSection extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Future<void> Function(int) onRemove;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final VoidCallback onCopy;
  final Future<void> Function(List<Map<String, dynamic>>) onCopySelected;
  final Future<void> Function(Map<String, dynamic>)? onTapItem;
  final VoidCallback onAddFood;
  final VoidCallback? onScan;
  final Future<void> Function()? onClearAll;
  final NutritionTargets? nutritionTargets;
  final List<dynamic> allFoods;

  const _MealSection({
    required this.title,
    required this.items,
    required this.onRemove,
    required this.onEdit,
    required this.onCopy,
    required this.onCopySelected,
    required this.onAddFood,
    this.onScan,
    this.onTapItem,
    this.onClearAll,
    this.nutritionTargets,
    this.allFoods = const [],
  });

  @override
  State<_MealSection> createState() => _MealSectionState();
}

class _MealSectionState extends State<_MealSection> {
  bool _selectMode = false;
  final Set<int> _selected = {};
  bool _expanded = true; // bannière dépliée par défaut

  void _toggleSelectMode() {
    setState(() { _selectMode = !_selectMode; _selected.clear(); });
  }

  Future<void> _showMealDetailSheet(BuildContext context) async {
    final T = widget.nutritionTargets;
    if (T == null) return;

    double rKcal = 0, rProt = 0, rCarb = 0, rFat = 0, rFib = 0;
    final Map<String, double> rMicros = {};

    for (final entry in widget.items) {
      rKcal += (entry['kcal']  as num?)?.toDouble() ?? 0;
      rProt += (entry['prot']  as num?)?.toDouble() ?? 0;
      rCarb += (entry['carb']  as num?)?.toDouble() ?? 0;
      rFat  += (entry['fat']   as num?)?.toDouble() ?? 0;
      rFib  += (entry['fiber'] as num?)?.toDouble() ?? 0;

      final foodId = (entry['id'] ?? '').toString();
      final grams  = (entry['grams'] as num?)?.toDouble() ?? 0.0;
      if (foodId.isNotEmpty && grams > 0) {
        dynamic food;
        try {
          food = widget.allFoods.firstWhere(
              (f) => ((f as dynamic).id as String?) == foodId);
        } catch (_) { food = null; }
        if (food != null) {
          try {
            final micros = (food as dynamic).micros100 as Map<String, dynamic>?;
            micros?.forEach((key, val) {
              final v = (val is num) ? val.toDouble() : 0.0;
              rMicros[key] = (rMicros[key] ?? 0.0) + v * grams / 100.0;
            });
          } catch (_) {}
        }
      }
    }

    double mic(String key) => rMicros[key] ?? 0.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, size: 18, color: kTotumOrange),
                  const SizedBox(width: 8),
                  Text(widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.items.length} aliment${widget.items.length > 1 ? 's' : ''})',
                    style: TextStyle(fontSize: 13, color: TotumColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  _Section(title: 'Macro-cibles', icon: Icons.bolt, initiallyExpanded: true,
                    metrics: [
                      _Metric('Énergie',   rKcal, T.goals.kcal, 'kcal', 0),
                      _Metric('Protéines', rProt, T.goals.prot, 'g',    1),
                      _Metric('Glucides',  rCarb, T.goals.carb, 'g',    1),
                      _Metric('Lipides',   rFat,  T.goals.fat,  'g',    1),
                      _Metric('Fibres',    rFib,  T.goals.fiber,'g',    1),
                    ],
                  ),
                  _Section(title: 'Acides gras essentiels', icon: Icons.opacity,
                    metrics: [
                      _Metric('Oméga 9', mic('Acide_oléique_W9_g_100g'),               T.o9,  'g', 2),
                      _Metric('Oméga 6', mic('Acide_linoléique_W6_LA_g_100g'),         T.o6,  'g', 2),
                      _Metric('Oméga 3', mic('Acide_alpha-linolénique_W3_ALA_g_100g'), T.o3,  'g', 2),
                      _Metric('EPA',     mic('EPA_g_100g'),                             T.epa, 'g', 2),
                      _Metric('DHA',     mic('DHA_g_100g'),                             T.dha, 'g', 2),
                    ],
                  ),
                  _Section(title: 'À surveiller', icon: Icons.visibility_outlined,
                    metrics: [
                      _Metric('AG saturés', mic('AG_saturés_g_100g'), T.sat,    'g', 2),
                      _Metric('Sucres',     mic('Sucres_g_100g'),     T.sugars, 'g', 1),
                      _Metric('Sel',        mic('Sel_g_100g'),        T.salt,   'g', 1),
                    ],
                  ),
                  _Section(title: 'Vitamines', icon: Icons.wb_sunny_outlined,
                    metrics: [
                      _Metric('Rétinol',   mic('Rétinol_µg_100g'),        T.vitAUg,       'µg', 0, ul: _kUlRetinolUg),
                      _Metric('Bêta-car.', mic('Beta-Carotène_µg_100g'),  T.vitBetacarUg, 'µg', 0),
                      _Metric('Vit D', mic('Vitamine_D_µg_100g'),   T.vitDUg, 'µg', 0),
                      _Metric('Vit E', mic('Vitamine_E_mg_100g'),   T.vitEMg, 'mg', 1),
                      _Metric('Vit K', mic('Vitamine_K1_µg_100g') + mic('Vitamine_K2_µg_100g'),  T.vitKUg, 'µg', 0),
                      _Metric('Vit C', mic('Vitamine_C_mg_100g'),   T.vitCMg, 'mg', 0),
                      _Metric('B1',    mic('Vitamine_B1_mg_100g'),  T.b1Mg,   'mg', 1),
                      _Metric('B2',    mic('Vitamine_B2_mg_100g'),  T.b2Mg,   'mg', 1),
                      _Metric('B3',    mic('Vitamine_B3_mg_100g'),  T.b3Mg,   'mg', 1),
                      _Metric('B5',    mic('Vitamine_B5_mg_100g'),  T.b5Mg,   'mg', 1),
                      _Metric('B6',    mic('Vitamine_B6_mg_100g'),  T.b6Mg,   'mg', 1),
                      _Metric('B9',    mic('Vitamine_B9_µg_100g'),  T.b9Ug,   'µg', 0),
                      _Metric('B12',   mic('Vitamine_B12_µg_100g'), T.b12Ug,  'µg', 0),
                    ],
                  ),
                  _Section(title: 'Minéraux', icon: Icons.diamond_outlined,
                    metrics: [
                      _Metric('Calcium',   mic('Calcium_mg_100g'),   T.caMg, 'mg', 0),
                      _Metric('Cuivre',    mic('Cuivre_mg_100g'),    T.cuMg, 'mg', 1),
                      _Metric('Fer',       mic('Fer_mg_100g'),       T.feMg, 'mg', 1, ul: _kUlFerMg),
                      _Metric('Iode',      mic('Iode_µg_100g'),      T.iUg,  'µg', 0),
                      _Metric('Magnésium', mic('Magnésium_mg_100g'), T.mgMg, 'mg', 0),
                      _Metric('Manganèse', mic('Manganèse_mg_100g'), T.mnMg, 'mg', 1),
                      _Metric('Phosphore', mic('Phosphore_mg_100g'), T.pMg,  'mg', 0),
                      _Metric('Potassium', mic('Potassium_mg_100g'), T.kMg,  'mg', 0),
                      _Metric('Sélénium',  mic('Sélénium_µg_100g'),  T.seUg, 'µg', 0, ul: _kUlSeleniumUg),
                      _Metric('Sodium',    mic('Sodium_mg_100g'),    T.naMg, 'mg', 0),
                      _Metric('Zinc',      mic('Zinc_mg_100g'),      T.znMg, 'mg', 1, ul: _kUlZincMg),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TotumCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 22,
                    color: TotumColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: TotumColors.textPrimary),
                    ),
                  ),
                ),
                // Nombre d'aliments (discret) quand la bannière est repliée
                if (!_expanded && widget.items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: TotumColors.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.items.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TotumColors.accent),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                // ➕ Ajouter
                IconButton(
                  onPressed: widget.onAddFood,
                  icon: const Icon(Icons.add_circle, size: 24),
                  tooltip: context.l10n.jrnlAddFoodTooltip,
                  color: TotumColors.accent,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34),
                  visualDensity: VisualDensity.compact,
                ),
                // 📷 Scanner
                if (widget.onScan != null)
                  IconButton(
                    onPressed: widget.onScan,
                    icon: const ScannerIcon(size: 21, color: TotumColors.accent),
                    tooltip: l10n.jrnlScanProductTooltip,
                    color: TotumColors.accent,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34),
                    visualDensity: VisualDensity.compact,
                  ),
                // ⋮ Menu (sélection / copier / supprimer)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: TotumColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34),
                  tooltip: l10n.jrnlMoreOptionsTooltip,
                  onSelected: (value) async {
                    if (value == 'select') {
                      _toggleSelectMode();
                    } else if (value == 'copy') {
                      widget.onCopy();
                    } else if (value == 'clear') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(ctx.l10n.jrnlClearAllTitle),
                          content: Text(
                              ctx.l10n.jrnlClearAllBody(widget.items.length)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(ctx.l10n.commonCancel)),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: TotumColors.negative,
                                  foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(ctx.l10n.commonDelete),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await widget.onClearAll?.call();
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(
                            _selectMode
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 20,
                            color: TotumColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(_selectMode
                              ? l10n.jrnlExitSelection
                              : l10n.jrnlSelectFoods),
                        ],
                      ),
                    ),
                    if (widget.items.isNotEmpty)
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_outlined,
                                size: 20, color: TotumColors.textSecondary),
                            const SizedBox(width: 10),
                            Text(l10n.jrnlCopyMealTitle),
                          ],
                        ),
                      ),
                    if (widget.items.isNotEmpty)
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined,
                                size: 20, color: TotumColors.negative),
                            const SizedBox(width: 10),
                            Text(l10n.jrnlClearAllMenuItem),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_selectMode) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected.isEmpty
                          ? l10n.jrnlCheckFoodsToCopy
                          : l10n.jrnlFoodsSelectedCount(_selected.length),
                      style: TextStyle(
                          fontSize: 12,
                          color: _selected.isEmpty ? TotumColors.textSecondary : TotumColors.accent,
                          fontStyle: _selected.isEmpty ? FontStyle.italic : FontStyle.normal),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final selectedItems = _selected.map((i) => widget.items[i]).toList();
                        await widget.onCopySelected(selectedItems);
                        setState(() { _selectMode = false; _selected.clear(); });
                      },
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(l10n.jrnlCopySelection, style: const TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: TotumColors.accent),
                    ),
                ],
              ),
            ],
            // ── Contenu repliable (résumé macros + liste) ────────────────
            if (_expanded) ...[
            if (widget.items.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: TotumColors.page,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Builder(builder: (_) {
                        double rKcal = 0, rProt = 0, rCarb = 0, rFat = 0, rFib = 0;
                        for (final e in widget.items) {
                          rKcal += (e['kcal']  as num?)?.toDouble() ?? 0;
                          rProt += (e['prot']  as num?)?.toDouble() ?? 0;
                          rCarb += (e['carb']  as num?)?.toDouble() ?? 0;
                          rFat  += (e['fat']   as num?)?.toDouble() ?? 0;
                          rFib  += (e['fiber'] as num?)?.toDouble() ?? 0;
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MealMacroChip(Icons.bolt, rKcal.toStringAsFixed(0)),
                            _MealMacroChip(Icons.egg_alt_outlined, '${rProt.toStringAsFixed(0)}g'),
                            _MealMacroChip(Icons.grain, '${rCarb.toStringAsFixed(0)}g'),
                            _MealMacroChip(Icons.opacity, '${rFat.toStringAsFixed(0)}g'),
                            _MealMacroChip(Icons.eco, '${rFib.toStringAsFixed(0)}g'),
                          ],
                        );
                      }),
                    ),
                  ),
                  if (widget.nutritionTargets != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _showMealDetailSheet(context),
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: l10n.jrnlMealNutritionDetailsTooltip,
                      color: TotumColors.textMuted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
            if (widget.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                    children: [
                      for (int i = 0; i < widget.items.length; i++) ...[
                        _MealRow(
                          item: widget.items[i],
                          allFoods: widget.allFoods,
                          onRemove: () => widget.onRemove(i),
                          onEdit: () => widget.onEdit(widget.items[i]),
                          selectMode: _selectMode,
                          isSelected: _selected.contains(i),
                          onToggleSelect: () {
                            setState(() {
                              if (_selected.contains(i)) {
                                _selected.remove(i);
                              } else {
                                _selected.add(i);
                              }
                            });
                          },
                          onTapItem: widget.onTapItem != null
                              ? () => widget.onTapItem!(widget.items[i])
                              : null,
                        ),
                        if (i != widget.items.length - 1) Divider(height: 12, color: TotumColors.outline),
                      ],
                    ],
                  ),
                ],
            ], // fin du if (_expanded)
          ],
        ),
      ),
    );
  }
}

class _MealRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<dynamic> allFoods;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onTapItem;

  const _MealRow({
    required this.item,
    this.allFoods = const [],
    required this.onRemove,
    required this.onEdit,
    this.selectMode = false,
    this.isSelected = false,
    this.onToggleSelect,
    this.onTapItem,
  });

  @override
  State<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<_MealRow> {
  bool _pendingDelete = false;

  /// Retrouve l'objet aliment complet (CIQUAL/USDA/Marque/Restaurant/perso/
  /// recette — `allFoods` couvre désormais toutes ces sources) à partir du
  /// seul id stocké dans l'entrée de journal.
  dynamic _resolveFood(String id) {
    try {
      return widget.allFoods.firstWhere((f) => ((f as dynamic).id as String?) == id);
    } catch (_) {
      return null;
    }
  }

  /// Icône/photo de la ligne, résolue depuis `allFoods` (base CIQUAL +
  /// personnels + recettes + cache USDA, mêmes objets que `_FoodListView`) à
  /// partir du seul id stocké dans l'entrée de journal — retour d'Alex
  /// (11/08/2026) : "je veux aucune ligne où je n'ai pas d'icône présente
  /// sur le côté pour me repérer". Cette liste du journal du jour n'affichait
  /// jusqu'ici STRICTEMENT rien ici (juste le nom en texte), contrairement
  /// aux écrans de recherche qui ont déjà photo/pictogramme/badges.
  Widget _leadingIcon(String id, dynamic food) {
    final photo = _photoOf(food);
    final pictogram = _pictogramOf(food);
    final isCustom = id.startsWith('custom:');
    final isRec = id.startsWith('recipe:');
    final isUsda = id.startsWith('usda:');

    Widget box(Widget child) => Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TotumColors.accentSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        );

    if (photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          photo, width: 36, height: 36, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => box(const Icon(
              Icons.image_not_supported_outlined, color: TotumColors.accent, size: 17)),
        ),
      );
    }
    if (pictogram != null) {
      return box(Text(pictogram, style: const TextStyle(fontSize: 18)));
    }
    if (isRec) return box(const Icon(Icons.menu_book_outlined, color: TotumColors.accent, size: 18));
    if (isCustom) return box(const Icon(Icons.person_outline, color: TotumColors.accent, size: 18));
    if (isUsda) return box(const Icon(Icons.public, color: TotumColors.accent, size: 18));
    // Dernier repli : ne jamais laisser une ligne sans rien à côté du nom.
    return box(const Icon(Icons.restaurant, color: TotumColors.accent, size: 17));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final id    = (item['id']    ?? '').toString();
    final food  = _resolveFood(id);
    // Le nom stocké dans l'entrée est figé au moment de l'ajout (toujours
    // en anglais pour un aliment USDA à l'époque) — on préfère le nom
    // français live de l'aliment résolu quand c'est possible, y compris
    // pour une entrée déjà ancienne (retour d'Alex, 12/08/2026).
    final name  = displayNameOf(food, (item['name'] ?? '').toString());
    final grams = (item['grams'] ?? 0).toDouble();
    final kcal  = (item['kcal']  ?? 0).toDouble();
    final prot  = (item['prot']  ?? 0).toDouble();
    final carb  = (item['carb']  ?? 0).toDouble();
    final fat   = (item['fat']   ?? 0).toDouble();
    final fiber = (item['fiber'] ?? 0).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _pendingDelete
            ? TotumColors.negative.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: _pendingDelete
            ? Border.all(color: TotumColors.negative.withValues(alpha: 0.4))
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.selectMode)
            Checkbox(
              value: widget.isSelected,
              onChanged: (_) => widget.onToggleSelect?.call(),
              activeColor: TotumColors.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            const SizedBox(width: 4),
          _leadingIcon(id, food),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.selectMode ? widget.onToggleSelect : widget.onTapItem,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: TextStyle(fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
                      ),
                      if (widget.onTapItem != null && !widget.selectMode)
                        Icon(Icons.info_outline, size: 14, color: TotumColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$grams g • ${kcal.toStringAsFixed(0)} kcal • '
                    'P ${prot.toStringAsFixed(1)}g • G ${carb.toStringAsFixed(1)}g • '
                    'L ${fat.toStringAsFixed(1)}g • F ${fiber.toStringAsFixed(1)}g',
                    style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.selectMode) ...[
            if (!_pendingDelete)
              IconButton(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: context.l10n.sunModifyButton,
                color: TotumColors.accent,
              ),
            if (_pendingDelete) ...[
              TextButton(
                onPressed: () => setState(() => _pendingDelete = false),
                child: Text(context.l10n.commonCancel,
                    style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(Icons.delete_forever, color: TotumColors.negative),
                tooltip: context.l10n.jrnlConfirmDeleteTooltip,
              ),
            ] else
              IconButton(
                onPressed: () => setState(() => _pendingDelete = true),
                icon: Icon(Icons.delete_outline, color: TotumColors.textSecondary),
                tooltip: context.l10n.commonDelete,
              ),
          ],
        ],
      ),
    );
  }
}

/// Badge NOVA (indice de transformation des aliments, 1 = brut → 4 = ultra-
/// transformé). `estime: true` = estimation TOTUM déduite de la famille
/// CIQUAL (aucune donnée officielle disponible pour cette base) ; jamais
/// présentée avec la même autorité qu'un NOVA officiel Open Food Facts.
String _novaLabel(int score, AppLocalizations l10n) => switch (score) {
      1 => l10n.jrnlNova1Label,
      2 => l10n.jrnlNova2Label,
      3 => l10n.jrnlNova3Label,
      4 => l10n.jrnlNova4Label,
      _ => '',
    };
String _novaDesc(int score, AppLocalizations l10n) => switch (score) {
      1 => l10n.jrnlNova1Desc,
      2 => l10n.jrnlNova2Desc,
      3 => l10n.jrnlNova3Desc,
      4 => l10n.jrnlNova4Desc,
      _ => '',
    };
// Priorité 60 (mode sombre) : getter plutôt que Map const — positive/
// negative sont désormais adaptatifs au thème, un const figé au premier
// accès resterait bloqué sur la valeur du thème actif à ce moment-là.
Map<int, Color> get _kNovaColors => {
      1: TotumColors.positive,
      2: TotumColors.accent,
      3: const Color(0xFFE0932B),
      4: TotumColors.negative,
    };

/// Badge NOVA (indice de transformation des aliments, 1 = brut → 4 = ultra-
/// transformé). `estime: true` = estimation TOTUM déduite de la famille
/// CIQUAL (aucune donnée officielle disponible pour cette base) ; jamais
/// présentée avec la même autorité qu'un NOVA officiel Open Food Facts.
/// Cliquable : ouvre une fiche d'explication complète (pas juste un tooltip,
/// qui ne répond pas au tap sur mobile — retour d'Alex du 10/08/2026).
class _NovaBadge extends StatelessWidget {
  final int score;
  final bool estime;
  const _NovaBadge({required this.score, required this.estime});

  @override
  Widget build(BuildContext context) {
    final color = _kNovaColors[score] ?? TotumColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showNovaInfoSheet(context, score: score, estime: estime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NOVA $score', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12)),
            const SizedBox(width: 6),
            Text(_novaLabel(score, context.l10n), style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 13, color: color.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

void _showNovaInfoSheet(BuildContext context, {required int score, required bool estime}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ctx.l10n.jrnlNovaScoreTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                ctx.l10n.jrnlNovaScoreIntro,
                style: TextStyle(color: TotumColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_kNovaColors[score] ?? TotumColors.textMuted).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (_kNovaColors[score] ?? TotumColors.textMuted).withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: _kNovaColors[score]),
                    Expanded(
                      child: Text(
                        estime
                            ? ctx.l10n.jrnlNovaEstimated(score)
                            : ctx.l10n.jrnlNovaOfficial(score),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final g in [1, 2, 3, 4]) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (_kNovaColors[g] ?? TotumColors.textMuted).withValues(alpha: g == score ? 1 : 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('NOVA $g',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: g == score ? Colors.white : _kNovaColors[g])),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_novaLabel(g, ctx.l10n),
                              style: TextStyle(fontWeight: g == score ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(_novaDesc(g, ctx.l10n),
                              style: TextStyle(color: TotumColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (g != 4) const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              Text(
                ctx.l10n.jrnlNovaSource,
                style: TextStyle(color: TotumColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Liste "ajout multiple" (Priorité 40, retour d'Alex, capture d'écran
/// fournie) : coche plusieurs aliments d'un coup dans l'onglet Commun, puis
/// les ajoute tous vers un repas choisi en un seul geste. Widget dédié
/// séparé de `_FoodListView` (partagé sur 5 onglets, déjà densément câblé —
/// éviter d'y ajouter un mode sélection avait été explicitement identifié
/// comme risqué) : plus simple (pas de favoris/dupliquer/éditer inline ici),
/// scopé au seul onglet Commun.
class _MultiSelectFoodList extends StatefulWidget {
  final List<dynamic> items;
  final Future<void> Function(List<dynamic> items, String meal) onAddSelected;
  final String? initialMeal;
  const _MultiSelectFoodList({required this.items, required this.onAddSelected, this.initialMeal});

  @override
  State<_MultiSelectFoodList> createState() => _MultiSelectFoodListState();
}

class _MultiSelectFoodListState extends State<_MultiSelectFoodList> {
  final Set<String> _selected = {};
  late String _targetMeal = widget.initialMeal ?? 'Déjeuner';
  bool _adding = false;

  String _idOf(dynamic it) => ((it as dynamic).id as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedItems =
        widget.items.where((it) => _selected.contains(_idOf(it))).toList();

    return Column(
      children: [
        Expanded(
          child: widget.items.isEmpty
              ? Center(
                  child: Text(l10n.jrnlNoResults, style: TextStyle(color: TotumColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: TotumColors.outline),
                  itemBuilder: (_, i) {
                    final it = widget.items[i];
                    final id = _idOf(it);
                    final name = displayNameOf(it, ((it as dynamic).name as String?) ?? l10n.jrnlGenericFoodFallback);
                    final kcal = ((it as dynamic).kcal100 as num?)?.toDouble();
                    final pictogram = _pictogramOf(it);
                    final checked = _selected.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: id.isEmpty
                          ? null
                          : (v) => setState(() {
                              if (v == true) { _selected.add(id); } else { _selected.remove(id); }
                            }),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: TotumColors.accent,
                      secondary: Container(
                        width: 34, height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TotumColors.accentSoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(pictogram ?? '🍽️', style: const TextStyle(fontSize: 16)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: kcal != null
                          ? Text(l10n.jrnlKcalPer100g(kcal.toStringAsFixed(0)),
                              style: TextStyle(fontSize: 12, color: TotumColors.textSecondary))
                          : null,
                    );
                  },
                ),
        ),
        if (selectedItems.isNotEmpty)
          Material(
            color: TotumColors.page,
            elevation: 4,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _targetMeal,
                        isDense: true,
                        decoration: InputDecoration(
                          labelText: l10n.jrnlTowardMeal,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Petit-déjeuner', child: Text(l10n.consCatBreakfast)),
                          DropdownMenuItem(value: 'Déjeuner', child: Text(l10n.consCatLunch)),
                          DropdownMenuItem(value: 'Dîner', child: Text(l10n.consCatDinner)),
                          DropdownMenuItem(value: 'Collation', child: Text(l10n.consCatSnack)),
                        ],
                        onChanged: (v) => setState(() => _targetMeal = v ?? 'Déjeuner'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kTotumOrange, foregroundColor: Colors.white),
                      onPressed: _adding
                          ? null
                          : () async {
                              setState(() => _adding = true);
                              await widget.onAddSelected(selectedItems, _targetMeal);
                              if (!context.mounted) return;
                              setState(() { _selected.clear(); _adding = false; });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(l10n.jrnlItemsAddedTo(
                                    selectedItems.length, _mealTypeLabel(_targetMeal, l10n))),
                              ));
                            },
                      child: _adding
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.jrnlAddButtonCount(selectedItems.length)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FoodListView extends StatelessWidget {
  final List<dynamic> items;
  final bool Function(String id) isFav;
  final Future<void> Function(String id) onFavToggle;
  final void Function(dynamic it) onTap;
  final bool showCreateButton;
  final VoidCallback? onCreateCustom;
  final VoidCallback? onCreateRecipe;
  final void Function(dynamic it)? onEditCustom;
  final Future<void> Function(String id)? onDeleteCustom;
  final void Function(dynamic it)? onDuplicate;
  final int? persoFilter;
  final void Function(int)? onPersoFilterChanged;
  final int persoCount;
  final int recipeCount;
  // Sous-filtre du sous-onglet Recettes : ne montrer que celles importées
  // de la bibliothèque TOTUM (traçabilité).
  final bool onlyLibraryRecipes;
  final void Function(bool)? onOnlyLibraryChanged;
  final int libraryRecipeCount;
  // Repas perso (persoFilter == 2) : rendu à part, une meal-template n'a
  // pas de kcal/100g comme un aliment/une recette — c'est un contenu figé.
  final List<_CustomMeal> mealItems;
  final void Function(_CustomMeal meal)? onTapMeal;
  final void Function(_CustomMeal meal)? onOpenMealDetail;
  final void Function(_CustomMeal meal)? onEditMeal;
  final Future<void> Function(String id)? onDeleteMeal;
  final VoidCallback? onCreateMeal;

  const _FoodListView({
    required this.items, required this.isFav, required this.onFavToggle,
    required this.onTap, required this.showCreateButton,
    this.onCreateCustom, this.onCreateRecipe,
    this.onEditCustom, this.onDeleteCustom, this.onDuplicate,
    this.persoFilter, this.onPersoFilterChanged,
    this.persoCount = 0, this.recipeCount = 0,
    this.onlyLibraryRecipes = false, this.onOnlyLibraryChanged,
    this.libraryRecipeCount = 0,
    this.mealItems = const [], this.onTapMeal, this.onOpenMealDetail,
    this.onEditMeal, this.onDeleteMeal, this.onCreateMeal,
  });

  bool _isPersonal(dynamic it) {
    try { return ((it as dynamic).id as String?)?.startsWith('custom:') == true; }
    catch (_) { return false; }
  }

  bool _isRecipe(dynamic it) {
    try { return ((it as dynamic).id as String?)?.startsWith('recipe:') == true; }
    catch (_) { return false; }
  }

  /// Onglet Perso > Repas : un repas perso n'est pas un aliment (pas de
  /// kcal/100g, pas de saisie de grammes) — juste un nom, une description
  /// optionnelle et une composition figée (aliments + grammes). Mêmes
  /// options que les aliments/recettes perso : voir le détail (tap),
  /// modifier, ajouter aux favoris, supprimer — plus l'ajout rapide au
  /// journal via l'icône dédiée.
  Widget _buildMealsSection(BuildContext context) {
    if (mealItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_outline, size: 42, color: TotumColors.textMuted),
              const SizedBox(height: 10),
              Text(context.l10n.jrnlNoPersonalMealsYet, style: TextStyle(color: TotumColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                context.l10n.jrnlCreateFirstPersonalMealHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: TotumColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.separated(
        padding: showCreateButton ? const EdgeInsets.only(bottom: 88) : null,
        itemCount: mealItems.length,
        separatorBuilder: (_, __) => Divider(height: 8, color: TotumColors.outline),
        itemBuilder: (_, i) {
          final meal = mealItems[i];
          final fav = isFav(meal.id);
          return ListTile(
            leading: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.bookmark, color: TotumColors.accent, size: 20),
            ),
            title: Text(meal.name, style: TextStyle(color: TotumColors.textPrimary)),
            subtitle: Text(
                meal.description.trim().isNotEmpty
                    ? meal.description
                    : context.l10n.jrnlItemsAndKcal(meal.items.length, meal.totalKcal.toStringAsFixed(0)),
                maxLines: meal.description.trim().isNotEmpty ? 1 : null,
                overflow: meal.description.trim().isNotEmpty ? TextOverflow.ellipsis : null,
                style: TextStyle(color: TotumColors.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEditMeal != null)
                  IconButton(
                    tooltip: context.l10n.sunModifyButton,
                    icon: Icon(Icons.edit_outlined, color: TotumColors.textSecondary),
                    onPressed: () => onEditMeal!(meal),
                  ),
                if (onDeleteMeal != null)
                  IconButton(
                    tooltip: context.l10n.commonDelete,
                    icon: Icon(Icons.delete_outline, color: TotumColors.textSecondary),
                    onPressed: () => onDeleteMeal!(meal.id),
                  ),
                IconButton(
                  tooltip: fav ? context.l10n.jrnlRemoveFavorite : context.l10n.jrnlAddFavorite,
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? TotumColors.accent : TotumColors.textMuted),
                  onPressed: () => onFavToggle(meal.id),
                ),
                if (onTapMeal != null)
                  IconButton(
                    tooltip: context.l10n.jrnlAddToJournal,
                    icon: const Icon(Icons.add_circle_outline, color: TotumColors.accent),
                    onPressed: () => onTapMeal!(meal),
                  ),
              ],
            ),
            onTap: onOpenMealDetail != null ? () => onOpenMealDetail!(meal) : null,
          );
        },
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if (showCreateButton &&
                persoFilter != null &&
                onPersoFilterChanged != null)
              // ── Sélecteur compact : Aliments perso / Recettes ────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _PersoFilterCard(
                        icon: Icons.restaurant_menu,
                        label: 'Aliments perso',
                        count: persoCount,
                        selected: persoFilter == 0,
                        onTap: () => onPersoFilterChanged!(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PersoFilterCard(
                        icon: Icons.menu_book_outlined,
                        label: 'Recettes',
                        count: recipeCount,
                        selected: persoFilter == 1,
                        onTap: () => onPersoFilterChanged!(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PersoFilterCard(
                        icon: Icons.bookmark_outline,
                        label: 'Repas',
                        count: mealItems.length,
                        selected: persoFilter == 2,
                        onTap: () => onPersoFilterChanged!(2),
                      ),
                    ),
                  ],
                ),
              ),
            if (showCreateButton && persoFilter == 1 && onOnlyLibraryChanged != null)
              // ── Sous-filtre : retrouver facilement les recettes importées ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    avatar: Icon(Icons.verified,
                        size: 16,
                        color: onlyLibraryRecipes ? Colors.white : TotumColors.accent),
                    label: Text(context.l10n.jrnlLibraryChipLabel(libraryRecipeCount)),
                    selected: onlyLibraryRecipes,
                    onSelected: (v) => onOnlyLibraryChanged!(v),
                    selectedColor: TotumColors.accent,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: onlyLibraryRecipes ? Colors.white : TotumColors.textPrimary,
                    ),
                    backgroundColor: TotumColors.surface,
                    side: BorderSide(color: onlyLibraryRecipes ? Colors.transparent : TotumColors.outline),
                  ),
                ),
              ),
        if (persoFilter == 2)
          _buildMealsSection(context)
        else
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: persoFilter == null
                      ? Text(context.l10n.jrnlNoResults)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                persoFilter == 0
                                    ? Icons.restaurant_menu
                                    : Icons.menu_book_outlined,
                                size: 42,
                                color: TotumColors.textMuted),
                            const SizedBox(height: 10),
                            Text(
                              persoFilter == 0
                                  ? context.l10n.jrnlNoPersonalFoodYet
                                  : context.l10n.jrnlNoRecipeYet,
                              style: TextStyle(color: TotumColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              persoFilter == 0
                                  ? context.l10n.jrnlCreateFirstFoodHint
                                  : context.l10n.jrnlCreateFirstRecipeHint,
                              style: TextStyle(
                                  fontSize: 12, color: TotumColors.textMuted),
                            ),
                          ],
                        ),
                )
              : ListView.separated(
                  padding: showCreateButton
                      ? const EdgeInsets.only(bottom: 88)
                      : null,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: TotumColors.outline),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final name = (((it as dynamic).name) as String?) ?? 'Aliment';
                    final id = (((it as dynamic).id) as String?) ?? '';
                    final kcal100 = ((it as dynamic).kcal100 as num?)?.toDouble() ?? 0.0;
                    final fav = id.isNotEmpty ? isFav(id) : false;
                    final isCustom = _isPersonal(it);
                    final isRec = _isRecipe(it);
                    // Retour d'Alex (11/08/2026) : distinguer visuellement un
                    // aliment venant de la base USDA (favoris, récents/fréquents...).
                    final isUsda = _isUsdaFood(it);
                    // Traçabilité : une recette perso importée depuis la
                    // bibliothèque TOTUM garde son id d'origine ("recipe:totum_xxx") ;
                    // une recette créée de zéro a un id "recipe:<timestamp>".
                    final isFromLibrary = isRec && id.startsWith('recipe:totum_');
                    // Recherche rapide façon MacroFactor (Priorité 25) : pictogramme +
                    // nom court, le nom CIQUAL complet reste visible en sous-titre.
                    final pictogram = _pictogramOf(it);
                    final photo = _photoOf(it);
                    final displayName = displayNameOf(it, name);

                    return ListTile(
                      // La photo (aliment scanné) prime sur le pictogramme générique
                      // quand elle existe — même emplacement, même taille, comme demandé.
                      leading: photo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                photo, width: 38, height: 38, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: TotumColors.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.image_not_supported_outlined,
                                      color: TotumColors.accent, size: 18),
                                ),
                              ),
                            )
                          : pictogram != null
                          ? Container(
                              width: 38, height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: TotumColors.accentSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(pictogram, style: const TextStyle(fontSize: 19)),
                            )
                          : isRec
                          ? Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: TotumColors.accentSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Icon(
                                      isFromLibrary
                                          ? Icons.menu_book
                                          : Icons.menu_book_outlined,
                                      color: TotumColors.accent,
                                      size: 20,
                                    ),
                                  ),
                                  if (isFromLibrary)
                                    Positioned(
                                      right: -3,
                                      bottom: -3,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.verified,
                                          size: 13,
                                          color: TotumColors.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : isCustom
                              ? Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: TotumColors.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person_outline,
                                      color: TotumColors.accent, size: 20),
                                )
                              : isUsda
                                  ? Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: TotumColors.accentSoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.public,
                                          color: TotumColors.accent, size: 20),
                                    )
                                  // Retour d'Alex (11/08/2026) : "je veux aucune ligne où
                                  // je n'ai pas d'icône" — dernier repli au lieu de `null`.
                                  : Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: TotumColors.accentSoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.restaurant,
                                          color: TotumColors.accent, size: 18),
                                    ),
                      // Priorité 50 (13/08/2026, retour d'Alex avec capture
                      // d'écran d'une appli concurrente) : hauteur de ligne
                      // très irrégulière, surtout côté USDA (noms plus longs)
                      // — la troncature "jamais" décidée le 11/08/2026
                      // laissait le nom s'étendre sur un nombre de lignes
                      // illimité. Plafonné à 2 lignes avec points de
                      // suspension : reste lisible (comme la référence, qui
                      // passe elle aussi sur 2 lignes pour les noms longs)
                      // tout en gardant une hauteur de ligne prévisible.
                      // Retour d'Alex (11/08/2026, Priorité 39) : mention
                      // "USDA" discrète sur la ligne (en plus du globe déjà
                      // présent en tête) — un utilisateur ne devine pas
                      // forcément ce que représente une icône seule.
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14, color: TotumColors.textPrimary, fontWeight: FontWeight.w600, height: 1.25)),
                          ),
                          if (isUsda) ...[
                            const SizedBox(width: 6),
                            _foodTag('USDA', TotumColors.textSecondary),
                          ],
                        ],
                      ),
                      // Retour d'Alex (11/08/2026) : plus d'ancien nom affiché en
                      // double en dessous — le nom générique EST le nom officiel
                      // désormais (sauf graines) ; juste le nom et les kcal/100g.
                      subtitle: Text(
                          [
                            context.l10n.jrnlKcalPer100g(kcal100.toStringAsFixed(0)),
                            if (isFromLibrary) context.l10n.jrnlLibraryBadge,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      minVerticalPadding: 8,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((isCustom || isRec) && onEditCustom != null)
                            IconButton(
                              tooltip: context.l10n.sunModifyButton,
                              icon: Icon(Icons.edit_outlined, color: TotumColors.textSecondary),
                              onPressed: () => onEditCustom!(it),
                            ),
                          if ((isCustom || isRec) && onDeleteCustom != null)
                            IconButton(
                              tooltip: context.l10n.commonDelete,
                              icon: Icon(Icons.delete_outline, color: TotumColors.textSecondary),
                              onPressed: () => onDeleteCustom!(id),
                            ),
                          if (!isCustom && !isRec && onDuplicate != null)
                            IconButton(
                              tooltip: context.l10n.jrnlCopyAsPersonalFoodTooltip,
                              icon: const Icon(Icons.copy_outlined, size: 20),
                              color: TotumColors.textSecondary,
                              onPressed: () => onDuplicate!(it),
                            ),
                          IconButton(
                            tooltip: fav ? context.l10n.jrnlRemoveFavorite : context.l10n.jrnlAddFavorite,
                            icon: Icon(
                              fav ? Icons.favorite : Icons.favorite_border,
                              color: fav ? TotumColors.accent : TotumColors.textMuted,
                            ),
                            onPressed: id.isNotEmpty ? () => onFavToggle(id) : null,
                          ),
                          Icon(Icons.chevron_right, color: TotumColors.textMuted),
                        ],
                      ),
                      onTap: () => onTap(it),
                    );
                  },
                ),
        ),
          ],
        ),
        // ── Bouton de création flottant (contextuel) ──────────────────
        if (showCreateButton)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'perso_create_fab',
              backgroundColor: TotumColors.accent,
              foregroundColor: Colors.white,
              onPressed: switch (persoFilter ?? 0) {
                0 => onCreateCustom,
                2 => onCreateMeal,
                _ => onCreateRecipe,
              },
              icon: const Icon(Icons.add),
              label: Text(
                switch (persoFilter ?? 0) {
                  0 => 'Aliment perso',
                  2 => 'Repas perso',
                  _ => 'Recette',
                },
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

/// Limites supérieures de sécurité journalières (UL) — EFSA, adultes.
const double _kUlRetinolUg  = 3000.0; // Vitamine A préformée (rétinol)
const double _kUlFerMg      = 40.0;   // Fer (EFSA 2024)
const double _kUlZincMg     = 25.0;   // Zinc
const double _kUlSeleniumUg = 255.0;  // Sélénium (EFSA 2023)

class _Metric {
  final String label, unit;
  final double value;
  final double? target;
  final int decimals;
  final double? ul; // limite haute de sécurité (optionnelle)
  const _Metric(this.label, this.value, this.target, this.unit, this.decimals,
      {this.ul});
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Metric> metrics;
  final bool initiallyExpanded;
  const _Section({
    required this.title, required this.icon, required this.metrics,
    this.initiallyExpanded = false,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayTitle = switch (title) {
      'Macro-cibles' => l10n.bilanGroupMacroTargets,
      'Acides gras essentiels' => l10n.bilanPillarFattyAcidsFull,
      'À surveiller' => l10n.scorePillarWatch,
      'Vitamines' => l10n.scorePillarVitamins,
      'Minéraux' => l10n.scorePillarMinerals,
      'Apport indicatif' => l10n.bilanGroupIndicative,
      _ => title,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TotumCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            iconColor: TotumColors.textSecondary,
            collapsedIconColor: TotumColors.textSecondary,
            initiallyExpanded: initiallyExpanded,
            title: Row(
              children: [
                Icon(icon, size: 19, color: TotumColors.textSecondary),
                const SizedBox(width: 10),
                Text(displayTitle,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
              ],
            ),
            children: metrics.map((m) {
              final pct = (m.target == null || m.target == 0)
                  ? null
                  : (m.value / m.target!).clamp(0.0, double.infinity).toDouble();
              final overUl = m.ul != null && m.value > m.ul!;
              Color effColor(double p) => overUl ? TotumColors.negative : _barColor(p);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(nutrientDisplayLabel(m.label, l10n),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: TotumColors.textPrimary)),
                      ),
                      if (pct != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: effColor(pct).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: effColor(pct),
                                fontSize: 12),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    if (pct != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.02, 1.0).toDouble(),
                          minHeight: 12,
                          backgroundColor: effColor(pct).withValues(alpha: 0.18),
                          color: effColor(pct),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${m.value.toStringAsFixed(m.decimals)} ${m.unit} / '
                        '${m.target!.toStringAsFixed(m.decimals)} ${m.unit}',
                        style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
                      ),
                      if (overUl)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 13, color: TotumColors.negative),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  l10n.bilanExceedsSafetyLimit(
                                      m.ul!.toStringAsFixed(0), m.unit),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: TotumColors.negative,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else
                      Text(
                        '${m.value.toStringAsFixed(m.decimals)} ${m.unit}',
                        style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TwoFieldsRow extends StatelessWidget {
  final String leftLabel, rightLabel, leftInit, rightInit;
  final void Function(String) onLeftChanged, onRightChanged;
  const _TwoFieldsRow({
    required this.leftLabel, required this.rightLabel,
    required this.leftInit, required this.rightInit,
    required this.onLeftChanged, required this.onRightChanged,
  });
  @override
  Widget build(BuildContext context) {
    final leftCtl  = TextEditingController(text: leftInit);
    final rightCtl = TextEditingController(text: rightInit);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: leftCtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: leftLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: onLeftChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: rightCtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: rightLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: onRightChanged,
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  const _LabeledField({
    required this.label, required this.controller,
    this.keyboardType, this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}

class _MealMacroChip extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MealMacroChip(this.icon, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: TotumColors.accent),
        const SizedBox(width: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TotumColors.accent)),
      ],
    );
  }
}

class _PersoFilterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _PersoFilterCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? TotumColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? TotumColors.accent : TotumColors.outline,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17, color: selected ? TotumColors.accent : TotumColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? TotumColors.accent : TotumColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? TotumColors.accent : TotumColors.outlineStrong,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : TotumColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════
//  HYDRATATION — Bannière "Eau" avec verres visuels (façon Chronometer)
// ═══════════════════════════════════════════════════════════════════════

class _WaterBanner extends StatefulWidget {
  final DateTime date;
  const _WaterBanner({required this.date});

  @override
  State<_WaterBanner> createState() => _WaterBannerState();
}

class _WaterBannerState extends State<_WaterBanner> {
  static const int _defaultTargetMl = 2500; // objectif par défaut
  int _glassMl = 250; // taille d'un verre (personnalisable)

 int _totalMl = 0;
  int _foodWaterMl = 0; // eau apportée par les aliments du jour
  int _targetMl = _defaultTargetMl;
  int? _customTargetMl; // si l'utilisateur force un objectif manuel
  bool _loading = true;
  bool _expanded = true;

  SupabaseClient get _sb => Supabase.instance.client;

  /// Somme l'eau (colonne CIQUAL `Eau_g_100g`) des aliments du journal du jour.
  /// Repli sur le nom pour les boissons sans donnée (aliment perso ancien).
  Future<int> _computeFoodWater() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('journal_$_ymd');
      if (raw == null || raw.isEmpty) return 0;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final repo = foods_loader.FoodsRepository.instance;
      double totalMl = 0;
      for (final meal in decoded.keys) {
        final list = (decoded[meal] as List?) ?? [];
        for (final e in list) {
          final entry = Map<String, dynamic>.from(e as Map);
          final id = (entry['id'] ?? '').toString();
          final grams = (entry['grams'] as num?)?.toDouble() ?? 0.0;
          if (grams <= 0) continue;
          final food = repo.findById(id);
          if (food != null) {
            final w = food.microsFor(grams)['Eau_g_100g'] ?? 0.0;
            totalMl += w;
          }
        }
      }
      return totalMl.round();
    } catch (_) {
      return 0;
    }
  }

  String get _ymd =>
      '${widget.date.year.toString().padLeft(4, '0')}-'
      '${widget.date.month.toString().padLeft(2, '0')}-'
      '${widget.date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_WaterBanner old) {
    super.didUpdateWidget(old);
    if (old.date != widget.date) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Objectif d'hydratation basé sur le profil (poids × 30 + bonus activité),
    // sauf si l'utilisateur a fixé un objectif manuel.
    try {
      final sp = await SharedPreferences.getInstance();
      final custom = sp.getInt('water_target_manual');
      _glassMl = sp.getInt('water_glass_ml') ?? 250;
      if (custom != null && custom > 0) {
        _customTargetMl = custom;
        _targetMl = custom;
      } else {
        final weight = sp.getDouble('profile_weight') ?? 70.0;
        final act = sp.getInt('profile_activity') ?? 0;
        int bonus = switch (act.clamp(0, 4)) {
          1 => 300,
          2 => 600,
          3 || 4 => 900,
          _ => 0,
        };
        _targetMl = (weight * 30.0 + bonus).clamp(1000, 6000).toInt();
        _glassMl = sp.getInt('water_glass_ml') ?? 250;
      }
    } catch (_) {}

    // Réglages persistants (verre + objectif manuel) restaurés depuis Supabase
    try {
      final user = _sb.auth.currentUser;
      if (user != null) {
        final prof = await _sb
            .from('user_profile')
            .select('water_glass_ml, water_target_ml')
            .eq('user_id', user.id)
            .maybeSingle();
        final sp = await SharedPreferences.getInstance();
        final g = (prof?['water_glass_ml'] as num?)?.toInt();
        final t = (prof?['water_target_ml'] as num?)?.toInt();
        if (g != null && g > 0) {
          _glassMl = g;
          await sp.setInt('water_glass_ml', g);
        }
        if (t != null && t > 0) {
          _customTargetMl = t;
          _targetMl = t;
          await sp.setInt('water_target_manual', t);
        }
      }
    } catch (_) {}

    try {
      final user = _sb.auth.currentUser;
      if (user != null) {
        final row = await _sb
            .from('water_intake')
            .select('total_ml')
            .eq('user_id', user.id)
            .eq('intake_date', _ymd)
            .maybeSingle();
        if (mounted) {
          final fw = await _computeFoodWater();
          if (mounted) {
            setState(() {
              _totalMl = (row?['total_ml'] as int?) ?? 0;
              _foodWaterMl = fw;
              _loading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement eau: $e');
    }
    final fw = await _computeFoodWater();
    if (mounted) {
      setState(() {
      _foodWaterMl = fw;
      _loading = false;
    });
    }
  }

  Future<void> _save() async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) return;
      await _sb.from('water_intake').upsert({
        'user_id': user.id,
        'intake_date': _ymd,
        'total_ml': _totalMl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,intake_date');
    } catch (e) {
      debugPrint('Erreur sauvegarde eau: $e');
    }
  }

  Future<void> _saveWaterSettings() async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) return;
      await _sb.from('user_profile').upsert({
        'user_id': user.id,
        'water_glass_ml': _glassMl,
        'water_target_ml': _customTargetMl,
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Erreur sauvegarde réglages eau: $e');
    }
  }

  void _addGlass() {
    setState(() => _totalMl += _glassMl);
    _save();
  }

  void _removeGlass() {
    if (_totalMl <= 0) return;
    setState(() => _totalMl = (_totalMl - _glassMl).clamp(0, 999999));
    _save();
  }

  Future<void> _editManual() async {
    final ctrl = TextEditingController(text: _totalMl.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.jrnlEnterDrankQuantityTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.l10n.jrnlTotalDailyQuantityMl),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                suffixText: 'ml',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? _totalMl;
              Navigator.pop(ctx, v.clamp(0, 999999));
            },
            child: Text(ctx.l10n.jrnlValidateButton),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _totalMl = result);
      _save();
    }
  }

  Future<void> _editTarget() async {
    final ctrl = TextEditingController(text: _targetMl.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.jrnlHydrationTargetTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            suffixText: 'ml',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? _targetMl;
              Navigator.pop(ctx, v.clamp(500, 8000));
            },
            child: Text(ctx.l10n.jrnlValidateButton),
          ),
        ],
      ),
    );
    if (result != null) {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('water_target_manual', result);
      await _saveWaterSettings();
      setState(() {
        _targetMl = result;
        _customTargetMl = result;
      });
    }
  }

  Future<void> _editGlassSize() async {
    final ctrl = TextEditingController(text: _glassMl.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.jrnlGlassSizeMenuItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.l10n.jrnlWaterPerGlassMl),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                suffixText: 'ml',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? _glassMl;
              Navigator.pop(ctx, v.clamp(50, 2000));
            },
            child: Text(ctx.l10n.jrnlValidateButton),
          ),
        ],
      ),
    );
    if (result != null) {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('water_glass_ml', result);
      setState(() => _glassMl = result);
      await _saveWaterSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const waterColor = TotumColors.accent;
    final glassesFull = _totalMl ~/ _glassMl;
    final targetGlasses = (_targetMl / _glassMl).ceil();
    // nombre de verres à afficher : au moins l'objectif, plus si on dépasse
    final glassesToShow =
        (glassesFull > targetGlasses ? glassesFull : targetGlasses)
            .clamp(1, 40);
    final totalWater = _totalMl + _foodWaterMl;
    final pct =
        _targetMl > 0 ? (totalWater / _targetMl * 100).clamp(0, 999).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TotumCard(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête compact
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 22,
                    color: TotumColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.water_drop, size: 18, color: waterColor),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(l10n.jrnlWaterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15,
                            color: TotumColors.textPrimary)),
                  ),
                ),
                Text(
                  '$totalWater / $_targetMl ml',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: waterColor,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _addGlass,
                  icon: const Icon(Icons.add_circle, size: 24),
                  tooltip: l10n.jrnlAddGlassTooltip(_glassMl),
                  color: waterColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34),
                  visualDensity: VisualDensity.compact,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: TotumColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34),
                  tooltip: l10n.jrnlOptionsTooltip,
                  onSelected: (v) {
                    if (v == 'manual') _editManual();
                    if (v == 'target') _editTarget();
                    if (v == 'glass') _editGlassSize();
                    if (v == 'reset') {
                      setState(() => _totalMl = 0);
                      _save();
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'manual',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20, color: TotumColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(ctx.l10n.jrnlEnterQuantityMenuItem),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'target',
                      child: Row(children: [
                        Icon(Icons.flag, size: 20, color: TotumColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(ctx.l10n.jrnlEditTargetMenuItem),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'glass',
                      child: Row(children: [
                        Icon(Icons.local_drink, size: 20, color: TotumColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(ctx.l10n.jrnlGlassSizeMenuItem),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(children: [
                        Icon(Icons.refresh, size: 20, color: TotumColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(ctx.l10n.jrnlResetToZeroMenuItem),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            // Synthèse eau totale (cohérente avec le Bilan)
            if (_foodWaterMl > 0)
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 4),
                child: Text(
                  l10n.jrnlWaterBreakdown(_totalMl, _foodWaterMl, pct),
                  style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary),
                ),
              ),
            // Badge % quand replié
            if (!_expanded)
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 2),
                child: Text(l10n.jrnlPercentOfTarget(pct),
                    style: TextStyle(
                        fontSize: 12, color: TotumColors.textSecondary)),
              ),
            // Contenu déplié : les verres
            if (_expanded) ...[
              const SizedBox(height: 12),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < glassesToShow; i++)
                          GestureDetector(
                            onTap: () {
                              // tap sur un verre plein = retirer ; sur un vide = ajouter
                              if (i < glassesFull) {
                                _removeGlass();
                              } else {
                                _addGlass();
                              }
                            },
                            child: _GlassIcon(
                              filled: i < glassesFull,
                              color: waterColor,
                            ),
                          ),
                      ],
                    ),
              const SizedBox(height: 12),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _targetMl > 0
                      ? (_totalMl / _targetMl).clamp(0.0, 1.0)
                      : 0,
                  minHeight: 8,
                  backgroundColor: waterColor.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(waterColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (pct >= 100) ...[
                    const Icon(Icons.check_circle, size: 14, color: waterColor),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      pct >= 100
                          ? l10n.jrnlTargetReached(pct)
                          : l10n.jrnlPercentGlassesLeft(pct,
                              ((_targetMl - totalWater) / _glassMl).ceil().clamp(0, 99)),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: pct >= 100 ? FontWeight.w700 : FontWeight.normal,
                          color: pct >= 100 ? waterColor : TotumColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icône d'un verre d'eau (plein ou vide).
class _GlassIcon extends StatelessWidget {
  final bool filled;
  final Color color;
  const _GlassIcon({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 42,
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Icon(
        Icons.water_drop,
        size: 18,
        color: filled ? Colors.white : color.withValues(alpha: 0.4),
      ),
    );
  }
}