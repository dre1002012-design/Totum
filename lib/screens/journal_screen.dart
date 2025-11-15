// lib/screens/journal_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile.dart'
    show NutritionTargets, Goals, computeAndSaveTargetsFromStoredProfile;
import '../services/foods_loader.dart' as foods_loader;
import 'account_screen.dart'; // ✅ nécessaire ici


// ────────────────────────────── Couleurs / helpers ───────────────────────────
const Color _kPctBrique = Color(0xFFD32F2F); // 0–50%
const Color _kPctOrange = Color(0xFFFF7A00); // 50–80%
const Color _kPctMiel   = Color(0xFFFFD54F); // 80–110%
const Color _kPctMenthe = Color(0xFF00C853); // >110%
const Color kTotumOrange = Color(0xFFFF7A00);

Color _barColor(double pct) {
  if (!pct.isFinite) return _kPctBrique;
  if (pct < 0.5) return _kPctBrique;
  if (pct < 0.8) return _kPctOrange;
  if (pct <= 1.1) return _kPctMiel;
  return _kPctMenthe;
}
Color _accent(BuildContext _) => kTotumOrange;

// ────────────────────────────── Normalisation recherche ──────────────────────
String _norm(String s) {
  var out = s.toLowerCase();
  final map = {
    'à':'a','â':'a','ä':'a','á':'a','ã':'a','å':'a',
    'ç':'c',
    'é':'e','è':'e','ê':'e','ë':'e',
    'î':'i','ï':'i','í':'i','ì':'i',
    'ô':'o','ö':'o','ò':'o','ó':'o','õ':'o',
    'û':'u','ù':'u','ü':'u','ú':'u',
    'ñ':'n',
    'œ':'oe','æ':'ae',
    '’':"'", 'ʼ':"'", 'ʹ':"'", '`':"'", '´':"'", '‘':"'", // apostrophes → '
    '“':'"', '”':'"',
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

// ───────────────────────────── Stats fréquence / récent ──────────────────────
class _FoodStats {
  Map<String, Map<String, num>> map = {};
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('food_stats');
    if (raw?.isNotEmpty == true) {
      try {
        map = Map<String, Map<String, num>>.from(
          (jsonDecode(raw!) as Map).map((k, v) => MapEntry(k.toString(), Map<String, num>.from(v)))
        );
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

// ───────────────────────────── Favoris ───────────────────────────────────────
class FavoritesStore {
  static const _key = 'fav_food_ids_v2';
  Set<String> _ids = <String>{};
  Set<String> get ids => _ids;
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw?.isNotEmpty == true) {
      try { _ids = (jsonDecode(raw!) as List).map((e) => e.toString()).toSet(); } catch (_) {}
    }
  }
  Future<void> toggle(String id) async {
    final sp = await SharedPreferences.getInstance();
    _ids.contains(id) ? _ids.remove(id) : _ids.add(id);
    await sp.setString(_key, jsonEncode(_ids.toList()));
  }
  bool isFav(String id) => _ids.contains(id);
}

// ───────────────────────────── Customs (aliments perso) ──────────────────────
class _CustomFood {
  final String id; // 'custom:<ts>'
  final String name;
  final double? kcal100, prot100, carb100, fat100, fiber100;
  final Map<String, double> micros100;
  _CustomFood({
    required this.id, required this.name,
    this.kcal100, this.prot100, this.carb100, this.fat100, this.fiber100,
    required this.micros100,
  });
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'kcal100': kcal100, 'prot100': prot100, 'carb100': carb100, 'fat100': fat100, 'fiber100': fiber100,
    'micros100': micros100,
  };
  static _CustomFood fromJson(Map<String, dynamic> j) => _CustomFood(
    id: j['id'], name: j['name'],
    kcal100: (j['kcal100'] as num?)?.toDouble(),
    prot100: (j['prot100'] as num?)?.toDouble(),
    carb100: (j['carb100'] as num?)?.toDouble(),
    fat100: (j['fat100'] as num?)?.toDouble(),
    fiber100: (j['fiber100'] as num?)?.toDouble(),
    micros100: Map<String, double>.from(
      (j['micros100'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
    ),
  );
  Map<String, double> macrosFor(double g) {
    final f = g / 100.0;
    return {
      'kcal': (kcal100 ?? 0) * f,
      'prot': (prot100 ?? 0) * f,
      'carb': (carb100 ?? 0) * f,
      'fat' : (fat100  ?? 0) * f,
      'fiber':(fiber100?? 0) * f,
    };
  }
}
class _CustomFoodsStore {
  static const _key = 'custom_foods_v1';
  List<_CustomFood> list = [];
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw?.isNotEmpty == true) {
      try { list = (jsonDecode(raw!) as List).map((e) => _CustomFood.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) {}
    }
  }
  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
  Future<void> add(_CustomFood f) async { list.add(f); await save(); }
  Future<void> remove(String id) async { list.removeWhere((e) => e.id == id); await save(); }
  Future<void> update(_CustomFood f) async { final i = list.indexWhere((e) => e.id == f.id); if (i >= 0) list[i] = f; await save(); }
}

// ───────────────────────────── Écran principal ───────────────────────────────
enum _SortMode { frequent, recent, az, za }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtl = TabController(length: 3, vsync: this);
  final TextEditingController _searchCtrl = TextEditingController();

  bool loading = false;
  final FavoritesStore _fav = FavoritesStore();
  final _CustomFoodsStore _customs = _CustomFoodsStore();
  final _FoodStats _stats = _FoodStats();

  Goals _goals = const Goals(kcal: 2200, prot: 120, carb: 302.5, fat: 85.6, fiber: 30);
  NutritionTargets? _targets;

  static List<dynamic>? _cacheAll; // cache mémoire
  List<dynamic> _all = <dynamic>[];
  String _query = '';
  _SortMode _sortMode = _SortMode.frequent;

  final Map<String, List<Map<String, dynamic>>> _journal = {
    'Petit-déjeuner': [], 'Déjeuner': [], 'Dîner': [], 'Collation': [],
  };
  double sumKcal = 0, sumProt = 0, sumCarb = 0, sumFat = 0, sumFib = 0;

  // ─────────── Journal persist ───────────
  String _journalKeyForToday() {
    final now = DateTime.now();
    return 'journal_${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  Future<void> _loadJournalForToday() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_journalKeyForToday());
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = (jsonDecode(raw) as Map<String, dynamic>);
      final Map<String, List<dynamic>> m = decoded.map((k, v) => MapEntry(k, (v as List)));
      setState(() {
        _journal.forEach((meal, _) {
          _journal[meal] = m[meal]?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        });
      });
      _recomputeTotals();
    } catch (_) {}
  }
  Future<void> _persistJournalForToday() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_journalKeyForToday(), jsonEncode({for (final meal in _journal.keys) meal: _journal[meal]}));
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
    setState(() { sumKcal = k; sumProt = p; sumCarb = c; sumFat = f; sumFib = fi; });
    SharedPreferences.getInstance().then((sp) {
      sp.setDouble('today_kcal', sumKcal);
      sp.setDouble('today_prot', sumProt);
      sp.setDouble('today_carb', sumCarb);
      sp.setDouble('today_fat',  sumFat);
      sp.setDouble('today_fiber',sumFib);
    });
    _persistJournalForToday();
  }
  Future<void> _saveDailySnapshot() async {
    final sp = await SharedPreferences.getInstance();
    const key = 'history_snapshots';
    final now = DateTime.now();
    final ymd = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    Map<String, dynamic> hist = {};
    final raw = sp.getString(key);
    if (raw?.isNotEmpty == true) { try { hist = jsonDecode(raw!); } catch (_) {} }
    hist[ymd] = {'kcal': sumKcal, 'prot': sumProt, 'carb': sumCarb, 'fat': sumFat, 'fiber': sumFib};
    await sp.setString(key, jsonEncode(hist));
  }

  // ─────────── Chargement repo + customs (avec cache) ───────────
  bool _isPersonal(dynamic it) {
    try { return ((it as dynamic).id as String?)?.startsWith('custom:') == true; }
    catch (_) { return false; }
  }

  Future<void> _ensureFoodsLoaded({bool force = false}) async {
    if (!force && _cacheAll != null) { setState(() => _all = _cacheAll!); return; }

    final repo = foods_loader.FoodsRepository.instance;
    try {
      if ((repo.items as List).isEmpty) {
        try { await (repo as dynamic).loadFromAsset('assets/foods.csv'); } catch (_) {}
        try { await (repo as dynamic).load(); } catch (_) {}
      }
    } catch (_) {}
    await _customs.load();

    final list = <dynamic>[]..addAll(repo.items)..addAll(_customs.list);
    _cacheAll = list; // ← met à jour le cache
    setState(() => _all = list);
  }

  // ─────────── Filtres + tri ───────────
  List<dynamic> _applyFilterSort(int tabIndex) {
    final q = _query.trim();
    Iterable<dynamic> base;
    switch (tabIndex) {
      case 1: base = _all.where((it){ try { return _fav.isFav(((it as dynamic).id as String)); } catch (_) { return false; } }); break;
      case 2: base = _all.where(_isPersonal); break;
      case 0:
      default: base = _all.where((it) => !_isPersonal(it)); break;
    }
    final arr = base.toList();

    arr.sort((a, b) {
      final an = (((a as dynamic).name) as String?) ?? '';
      final bn = (((b as dynamic).name) as String?) ?? '';
      switch (_sortMode) {
        case _SortMode.frequent:
          final s = _stats.count(((b as dynamic).id as String?) ?? '').compareTo(_stats.count(((a as dynamic).id as String?) ?? ''));
          if (s != 0) return s; break;
        case _SortMode.recent:
          final s = _stats.last(((b as dynamic).id as String?) ?? '').compareTo(_stats.last(((a as dynamic).id as String?) ?? ''));
          if (s != 0) return s; break;
        case _SortMode.az:
          final s = _norm(an).compareTo(_norm(bn)); if (s != 0) return s; break;
        case _SortMode.za:
          final s = _norm(bn).compareTo(_norm(an)); if (s != 0) return s; break;
      }
      if (q.isEmpty) return 0;
      final sqA = _scoreForQuery(an, q), sqB = _scoreForQuery(bn, q);
      return sqA.compareTo(sqB);
    });

    return q.isEmpty
        ? arr
        : arr.where((it) {
            final n = _norm((((it as dynamic).name) as String?) ?? '');
            return n.contains(_norm(q));
          }).toList();
  }

  // ─────────── Ajout au journal + stats ───────────
  Future<void> _addToJournal(String meal, dynamic it, double grams) async {
    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final f = grams / 100.0;
    final kcal = getD((it as dynamic).kcal100) * f,
           prot = getD((it).prot100) * f,
           carb = getD((it).carb100) * f,
           fat  = getD((it).fat100)  * f,
           fiber= getD((it).fiber100)* f;
    final name = (((it).name) as String?) ?? 'Aliment';
    final id   = (((it).id)   as String?) ?? 'custom:temp';
    _journal[meal]!.add({'id': id, 'name': name, 'grams': grams, 'kcal': kcal, 'prot': prot, 'carb': carb, 'fat': fat, 'fiber': fiber});
    await _stats.bump(id);
    _recomputeTotals();
    await _saveDailySnapshot();
  }

  @override
  void initState() {
    super.initState();
    _tabCtl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => loading = true);
      final t = await computeAndSaveTargetsFromStoredProfile();
      _targets = t; _goals = t.goals;
      await Future.wait([_fav.load(), _stats.load(), _ensureFoodsLoaded(force: true), _loadJournalForToday()]);
      setState(() => loading = false);
    });
  }
  @override
  void dispose() { _tabCtl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  // ───────────────────────────── Fiche Aliment (live + bouton figé) ─────────
  Future<void> _openFoodSheet(dynamic it) async {
    if (_targets == null) return;
    final T = _targets!;
    double grams = 100; String meal = 'Déjeuner';
    final qtyCtrl = TextEditingController(text: grams.toStringAsFixed(0));

    double getD(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    double micro(String key) { try { final map = (it as dynamic).micros100 as Map<String, dynamic>?; return getD(map?[key]); } catch (_) { return 0.0; } }
    Map<String, double> macros() {
      try {
        final m = ((it as dynamic).macrosFor(grams) as Map<String, dynamic>).map((k, v) => MapEntry(k, getD(v)));
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
    double ratio() => grams / 100.0; double asG(double x) => x * ratio(); double asMg(double x) => x * ratio(); double asUg(double x) => x * ratio();

    // EFA + watch + micro
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

    final retUg  = micro('Rétinol_µg_100g');
    final vdUg   = micro('Vitamine_D_µg_100g');
    final veMg   = micro('Vitamine_E_mg_100g');
    final vkUg   = micro('Vitamine_K1_µg_100g');
    final vcMg   = micro('Vitamine_C_mg_100g');
    final b1Mg   = micro('Vitamine_B1_mg_100g');
    final b2Mg   = micro('Vitamine_B2_mg_100g');
    final b3Mg   = micro('Vitamine_B3_mg_100g');
    final b5Mg   = micro('Vitamine_B5_mg_100g');
    final b6Mg   = micro('Vitamine_B6_mg_100g');
    final b9Ug   = micro('Vitamine_B9_µg_100g');
    final b12Ug  = micro('Vitamine_B12_µg_100g');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, useSafeArea: true, showDragHandle: true,
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
        ];
        List<_Metric> vitaminMetrics() => [
          _Metric('Vit A', asUg(retUg), T.vitA_Ug, 'µg', 0),
          _Metric('Vit D', asUg(vdUg),  T.vitD_Ug, 'µg', 0),
          _Metric('Vit E', asMg(veMg),  T.vitE_Mg, 'mg', 1),
          _Metric('Vit K', asUg(vkUg),  T.vitK_Ug, 'µg', 0),
          _Metric('Vit C', asMg(vcMg),  T.vitC_Mg, 'mg', 0),
          _Metric('B1',    asMg(b1Mg),  T.b1_Mg,   'mg', 1),
          _Metric('B2',    asMg(b2Mg),  T.b2_Mg,   'mg', 1),
          _Metric('B3',    asMg(b3Mg),  T.b3_Mg,   'mg', 1),
          _Metric('B5',    asMg(b5Mg),  T.b5_Mg,   'mg', 1),
          _Metric('B6',    asMg(b6Mg),  T.b6_Mg,   'mg', 1),
          _Metric('B9',    asUg(b9Ug),  T.b9_Ug,   'µg', 0),
          _Metric('B12',   asUg(b12Ug), T.b12_Ug,  'µg', 0),
        ];
        List<_Metric> mineralMetrics() => [
          _Metric('Calcium',   asMg(caMg), T.caMg, 'mg', 0),
          _Metric('Cuivre',    asMg(cuMg), T.cuMg, 'mg', 1),
          _Metric('Fer',       asMg(feMg), T.feMg, 'mg', 1),
          _Metric('Iode',      asUg(iUg),  T.iUg,  'µg', 0),
          _Metric('Magnésium', asMg(mgMg), T.mgMg, 'mg', 0),
          _Metric('Manganèse', asMg(mnMg), T.mnMg, 'mg', 1),
          _Metric('Phosphore', asMg(pMg),  T.pMg,  'mg', 0),
          _Metric('Potassium', asMg(kMg),  T.kMg,  'mg', 0),
          _Metric('Sélénium',  asUg(seUg), T.seUg, 'µg', 0),
          _Metric('Sodium',    asMg(naMg), T.naMg, 'mg', 0),
          _Metric('Zinc',      asMg(znMg), T.znMg, 'mg', 1),
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
                  // En-tête
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (it as dynamic).name ?? 'Aliment',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: _fav.isFav(((it as dynamic).id as String? ?? '')) ? 'Retirer des favoris' : 'Ajouter aux favoris',
                          icon: Icon(_fav.isFav(((it as dynamic).id as String? ?? '')) ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                          onPressed: () async {
                            final id = ((it as dynamic).id as String?) ?? '';
                            if (id.isNotEmpty) { await _fav.toggle(id); if (mounted) setState(() {}); setSheetState(() {}); }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Quantité + repas
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Quantité (g)',
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: onQtyChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: meal,
                            items: const [
                              DropdownMenuItem(value: 'Petit-déjeuner', child: Text('Petit-déjeuner')),
                              DropdownMenuItem(value: 'Déjeuner', child: Text('Déjeuner')),
                              DropdownMenuItem(value: 'Dîner', child: Text('Dîner')),
                              DropdownMenuItem(value: 'Collation', child: Text('Collation')),
                            ],
                            onChanged: (v) => meal = v ?? 'Déjeuner',
                            decoration: InputDecoration(
                              labelText: 'Repas',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [
                        _Section(title: '⚡ Macro-cibles', emoji: '', initiallyExpanded: true, metrics: macroMetrics()),
                        _Section(title: '🧠 Acides gras essentiels', emoji: '', metrics: efaMetrics()),
                        _Section(title: '🛑 À surveiller', emoji: '', metrics: watchMetrics()),
                        _Section(title: '🍋 Vitamines', emoji: '', metrics: vitaminMetrics()),
                        _Section(title: '🧱 Minéraux', emoji: '', metrics: mineralMetrics()),
                        _Section(title: 'ℹ️ Apport indicatif', emoji: '', metrics: indicativeMetrics()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Bouton figé
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent(context),
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () async {
                        await _addToJournal(meal, it, grams);
                        if (context.mounted) Navigator.pop(context);
                      },
                      label: const Text('Ajouter au journal'),
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

  // ──────────────────────────────── UI page ──────────────────────────────────
    @override
  Widget build(BuildContext context) {
    final tabs = const [ Tab(text: 'Commun'), Tab(text: 'Favoris'), Tab(text: 'Perso') ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon compte',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(controller: _tabCtl, tabs: tabs),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: SizedBox(
            height: 52, width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              style: FilledButton.styleFrom(backgroundColor: _accent(context), foregroundColor: Colors.black),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DayJournalView(
                    journal: _journal,
                    goals: _goals,
                    totals: DayTotals(kcal: sumKcal, prot: sumProt, carb: sumCarb, fat: sumFat, fiber: sumFib),
                    onRemoveAt: (meal, index) async {
                      _journal[meal]!.removeAt(index);
                      _recomputeTotals();
                      await _saveDailySnapshot();
                    },
                  ),
                ));
                setState(() {});
              },
              label: const Text('Voir le journal du jour'),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Recherche
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un aliment',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (s) { _query = s; setState(() {}); },
                  ),
                ),

                /// Curseur compact des filtres — aligné à droite (anti-overflow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CupertinoSlidingSegmentedControl<_SortMode>(
                          groupValue: _sortMode,
                          backgroundColor: Colors.black12.withOpacity(0.06),
                          thumbColor: _accent(context).withOpacity(0.18),
                          children: const <_SortMode, Widget>{
                            _SortMode.frequent: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text('Le + fréquent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            _SortMode.recent: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text('Le + récent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            _SortMode.az: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text('A → Z', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            _SortMode.za: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text('Z → A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          },
                          onValueChanged: (v) { if (v != null) setState(() => _sortMode = v); },
                        ),
                      ),
                    ),
                  ),
                ),

                // Listes 3 onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabCtl,
                    children: [
                      _FoodListView(
                        items: _applyFilterSort(0),
                        isFav: (id) => _fav.isFav(id),
                        onFavToggle: (id) async { await _fav.toggle(id); setState(() {}); },
                        onTap: _openFoodSheet,
                        showCreateButton: false,
                      ),
                      _FoodListView(
                        items: _applyFilterSort(1),
                        isFav: (id) => _fav.isFav(id),
                        onFavToggle: (id) async { await _fav.toggle(id); setState(() {}); },
                        onTap: _openFoodSheet,
                        showCreateButton: false,
                      ),
                      _FoodListView(
                        items: _applyFilterSort(2),
                        isFav: (id) => _fav.isFav(id),
                        onFavToggle: (id) async { await _fav.toggle(id); setState(() {}); },
                        onTap: _openFoodSheet,
                        showCreateButton: true,
                        onCreateCustom: () => _openCustomDialog(),
                        onEditCustom:   (item) => _openCustomDialog(editItem: item),
                        onDeleteCustom: (id) async { await _customs.remove(id); await _ensureFoodsLoaded(force: true); setState(() {}); },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ───────────────────────────── Ajout / édition aliment perso ───────────────
  Future<void> _openCustomDialog({dynamic editItem}) async {
    final isEdit = editItem != null && _isPersonal(editItem);
    final id = isEdit ? ((editItem as dynamic).id as String) : 'custom:${DateTime.now().millisecondsSinceEpoch}';
    final nameCtl = TextEditingController(text: isEdit ? ((editItem as dynamic).name as String? ?? '') : '');

    double? kcal = isEdit ? (editItem as dynamic).kcal100 as double? : null;
    double? prot = isEdit ? (editItem as dynamic).prot100 as double? : null;
    double? carb = isEdit ? (editItem as dynamic).carb100 as double? : null;
    double? fat  = isEdit ? (editItem as dynamic).fat100  as double? : null;
    double? fiber= isEdit ? (editItem as dynamic).fiber100 as double? : null;

    Map<String, double> micros = isEdit
        ? Map<String, double>.from(((editItem as dynamic).micros100 as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
        : {
            // macros dérivés (surveillance / EFA / sucres / sel)
            'AG_saturés_g_100g': 0,
            'Acide_oléique_W9_g_100g': 0, 'Acide_linoléique_W6_LA_g_100g': 0, 'Acide_alpha-linolénique_W3_ALA_g_100g': 0,
            'EPA_g_100g': 0, 'DHA_g_100g': 0,
            'Sucres_g_100g': 0, 'Sel_g_100g': 0,

            // Micronutriments (le bloc optionnel — vitamines + minéraux uniquement)
            'Calcium_mg_100g': 0, 'Cuivre_mg_100g': 0, 'Fer_mg_100g': 0, 'Iode_µg_100g': 0, 'Magnésium_mg_100g': 0,
            'Manganèse_mg_100g': 0, 'Phosphore_mg_100g': 0, 'Potassium_mg_100g': 0, 'Sélénium_µg_100g': 0,
            'Sodium_mg_100g': 0, 'Zinc_mg_100g': 0,
            'Rétinol_µg_100g': 0, 'Vitamine_D_µg_100g': 0, 'Vitamine_E_mg_100g': 0, 'Vitamine_K1_µg_100g': 0,
            'Vitamine_C_mg_100g': 0, 'Vitamine_B1_mg_100g': 0, 'Vitamine_B2_mg_100g': 0, 'Vitamine_B3_mg_100g': 0,
            'Vitamine_B5_mg_100g': 0, 'Vitamine_B6_mg_100g': 0, 'Vitamine_B9_µg_100g': 0, 'Vitamine_B12_µg_100g': 0,
          };

        double? parse(String s) => s.trim().isEmpty ? null : double.tryParse(s.replaceAll(',', '.'));

    Future<void> saveItem() async {
      final name = nameCtl.text.trim();
      if (name.isEmpty) return;

      // 1) On enregistre l’aliment perso dans ton store custom (logique existante)
      final item = _CustomFood(
        id: id,
        name: name,
        kcal100: kcal,
        prot100: prot,
        carb100: carb,
        fat100: fat,
        fiber100: fiber,
        micros100: micros,
      );
      if (isEdit) {
        await _customs.update(item);
      } else {
        await _customs.add(item);
      }

      // 2) On le pousse AUSSI dans FoodsRepository pour que l’onglet Bilan voie les micros
      final repo = foods_loader.FoodsRepository.instance;
      repo.addCustomFood(
        foods_loader.FoodItem(
          id: id,
          name: name,
          kcal100: kcal,
          prot100: prot,
          carb100: carb,
          fat100: fat,
          fiber100: fiber,
          micros100: micros,
        ),
      );
      await repo.saveCustomFoods(); // persistance des customs

      // 3) On rafraîchit la liste comme avant
      await _ensureFoodsLoaded(force: true);
      if (mounted) setState(() {});
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Modifier un aliment perso' : 'Ajouter un aliment perso'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Nom'), controller: nameCtl),

              const SizedBox(height: 12),
              // ——— Bloc "Macros + surveillances + EFA + sucres/sel" (tout en haut) ———
              _TwoFieldsRow(
                leftLabel: 'Énergie (kcal/100g)', leftInit: kcal?.toString() ?? '',
                rightLabel: 'Protéines (g/100g)', rightInit: prot?.toString() ?? '',
                onLeftChanged: (s) => kcal = parse(s),
                onRightChanged: (s) => prot = parse(s),
              ),
              const SizedBox(height: 8),
              _TwoFieldsRow(
                leftLabel: 'Glucides (g/100g)', leftInit: carb?.toString() ?? '',
                rightLabel: 'Lipides (g/100g)', rightInit: fat?.toString() ?? '',
                onLeftChanged: (s) => carb = parse(s),
                onRightChanged: (s) => fat  = parse(s),
              ),
              const SizedBox(height: 8),
              _TwoFieldsRow(
                leftLabel: 'Fibres (g/100g)', leftInit: fiber?.toString() ?? '',
                rightLabel: 'AG saturés (g/100g)', rightInit: micros['AG_saturés_g_100g']!.toString(),
                onLeftChanged: (s) => fiber = parse(s),
                onRightChanged:(s) => micros['AG_saturés_g_100g'] = parse(s) ?? 0,
              ),
              const SizedBox(height: 8),
              _TwoFieldsRow(
                leftLabel: 'Oméga 9 (g/100g)', leftInit: micros['Acide_oléique_W9_g_100g']!.toString(),
                rightLabel:'Oméga 6 (g/100g)', rightInit: micros['Acide_linoléique_W6_LA_g_100g']!.toString(),
                onLeftChanged:(s)=> micros['Acide_oléique_W9_g_100g']       = parse(s) ?? 0,
                onRightChanged:(s)=> micros['Acide_linoléique_W6_LA_g_100g'] = parse(s) ?? 0,
              ),
              const SizedBox(height: 8),
              _TwoFieldsRow(
                leftLabel: 'Oméga 3 ALA (g/100g)', leftInit: micros['Acide_alpha-linolénique_W3_ALA_g_100g']!.toString(),
                rightLabel:'EPA (g/100g)', rightInit: micros['EPA_g_100g']!.toString(),
                onLeftChanged:(s)=> micros['Acide_alpha-linolénique_W3_ALA_g_100g'] = parse(s) ?? 0,
                onRightChanged:(s)=> micros['EPA_g_100g']                          = parse(s) ?? 0,
              ),
              const SizedBox(height: 8),
              _TwoFieldsRow(
                leftLabel: 'DHA (g/100g)', leftInit: micros['DHA_g_100g']!.toString(),
                rightLabel:'Sucres (g/100g)', rightInit: micros['Sucres_g_100g']!.toString(),
                onLeftChanged:(s)=> micros['DHA_g_100g']     = parse(s) ?? 0,
                onRightChanged:(s)=> micros['Sucres_g_100g'] = parse(s) ?? 0,
              ),
              const SizedBox(height: 8),
              _TwoFieldsRow(
                leftLabel: 'Sel (g/100g)', leftInit: micros['Sel_g_100g']!.toString(),
                rightLabel:'', rightInit: '',
                onLeftChanged:(s)=> micros['Sel_g_100g'] = parse(s) ?? 0,
                onRightChanged:(_){},
              ),

              const SizedBox(height: 12),
              // ——— Bloc Micronutriments (optionnel) ——— (vitamines + minéraux UNIQUEMENT)
              ExpansionTile(
                title: const Text('Micronutriments (optionnel)'),
                children: [
                  _TwoFieldsRow(
                    leftLabel:'Calcium (mg/100g)', leftInit: micros['Calcium_mg_100g']!.toString(),
                    rightLabel:'Cuivre (mg/100g)',  rightInit: micros['Cuivre_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Calcium_mg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Cuivre_mg_100g']  = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Fer (mg/100g)', leftInit: micros['Fer_mg_100g']!.toString(),
                    rightLabel:'Iode (µg/100g)', rightInit: micros['Iode_µg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Fer_mg_100g']     = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Iode_µg_100g']   = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Magnésium (mg/100g)', leftInit: micros['Magnésium_mg_100g']!.toString(),
                    rightLabel:'Manganèse (mg/100g)', rightInit: micros['Manganèse_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Magnésium_mg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Manganèse_mg_100g']  = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Phosphore (mg/100g)', leftInit: micros['Phosphore_mg_100g']!.toString(),
                    rightLabel:'Potassium (mg/100g)', rightInit: micros['Potassium_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Phosphore_mg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Potassium_mg_100g'] = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Sélénium (µg/100g)', leftInit: micros['Sélénium_µg_100g']!.toString(),
                    rightLabel:'Sodium (mg/100g)',  rightInit: micros['Sodium_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Sélénium_µg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Sodium_mg_100g']   = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Zinc (mg/100g)', leftInit: micros['Zinc_mg_100g']!.toString(),
                    rightLabel:'Vitamine E (mg/100g)', rightInit: micros['Vitamine_E_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Zinc_mg_100g']        = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Vitamine_E_mg_100g'] = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Vit A (µg/100g)', leftInit: micros['Rétinol_µg_100g']!.toString(),
                    rightLabel:'Vit D (µg/100g)', rightInit: micros['Vitamine_D_µg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Rétinol_µg_100g']     = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Vitamine_D_µg_100g'] = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'Vit K1 (µg/100g)', leftInit: micros['Vitamine_K1_µg_100g']!.toString(),
                    rightLabel:'Vit C (mg/100g)',  rightInit: micros['Vitamine_C_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Vitamine_K1_µg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Vitamine_C_mg_100g']  = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'B1 (mg/100g)', leftInit: micros['Vitamine_B1_mg_100g']!.toString(),
                    rightLabel:'B2 (mg/100g)', rightInit: micros['Vitamine_B2_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Vitamine_B1_mg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Vitamine_B2_mg_100g'] = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'B3 (mg/100g)', leftInit: micros['Vitamine_B3_mg_100g']!.toString(),
                    rightLabel:'B5 (mg/100g)', rightInit: micros['Vitamine_B5_mg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Vitamine_B3_mg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Vitamine_B5_mg_100g'] = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'B6 (mg/100g)', leftInit: micros['Vitamine_B6_mg_100g']!.toString(),
                    rightLabel:'B9 (µg/100g)', rightInit: micros['Vitamine_B9_µg_100g']!.toString(),
                    onLeftChanged:(s)=> micros['Vitamine_B6_mg_100g'] = parse(s) ?? 0,
                    onRightChanged:(s)=> micros['Vitamine_B9_µg_100g'] = parse(s) ?? 0,
                  ),
                  const SizedBox(height:8),
                  _TwoFieldsRow(
                    leftLabel:'B12 (µg/100g)', leftInit: micros['Vitamine_B12_µg_100g']!.toString(),
                    rightLabel:'', rightInit:'',
                    onLeftChanged:(s)=> micros['Vitamine_B12_µg_100g'] = parse(s) ?? 0,
                    onRightChanged:(_){},
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await saveItem();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── JOURNAL DU JOUR ────────────────────────────────

class DayTotals {
  final double kcal, prot, carb, fat, fiber;
  const DayTotals({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
  });
}

/// Vue "Journal du jour"
class DayJournalView extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> journal;
  final Goals goals;
  final DayTotals totals;
  final Future<void> Function(String meal, int index) onRemoveAt;

  const DayJournalView({
    super.key,
    required this.journal,
    required this.goals,
    required this.totals,
    required this.onRemoveAt,
  });

  @override
  State<DayJournalView> createState() => _DayJournalViewState();
}

class _DayJournalViewState extends State<DayJournalView> {
  late Map<String, List<Map<String, dynamic>>> _journal;
  late DayTotals _totals;

  @override
  void initState() {
    super.initState();

    // On fait une petite copie locale pour pouvoir mettre à jour l’UI
    _journal = {
      'Petit-déjeuner':
          List<Map<String, dynamic>>.from(widget.journal['Petit-déjeuner'] ?? const []),
      'Déjeuner':
          List<Map<String, dynamic>>.from(widget.journal['Déjeuner'] ?? const []),
      'Dîner':
          List<Map<String, dynamic>>.from(widget.journal['Dîner'] ?? const []),
      'Collation':
          List<Map<String, dynamic>>.from(widget.journal['Collation'] ?? const []),
    };

    _totals = widget.totals;
  }

  void _recomputeTotals() {
    double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;

    for (final mealList in _journal.values) {
      for (final item in mealList) {
        kcal  += (item['kcal']  as num?)?.toDouble() ?? 0.0;
        prot  += (item['prot']  as num?)?.toDouble() ?? 0.0;
        carb  += (item['carb']  as num?)?.toDouble() ?? 0.0;
        fat   += (item['fat']   as num?)?.toDouble() ?? 0.0;
        fiber += (item['fiber'] as num?)?.toDouble() ?? 0.0;
      }
    }

    _totals = DayTotals(
      kcal: kcal,
      prot: prot,
      carb: carb,
      fat: fat,
      fiber: fiber,
    );
  }

  Future<void> _handleRemove(String meal, int index) async {
    // 1) on met à jour l’UI locale immédiatement
    setState(() {
      _journal[meal]!.removeAt(index);
      _recomputeTotals();
    });

    // 2) on prévient aussi l’écran parent pour qu’il garde les bons totaux
    await widget.onRemoveAt(meal, index);
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    final double gKcal = goals.kcal <= 0 ? 2000.0 : goals.kcal;

    return Scaffold(
      appBar: AppBar(title: const Text('Journal du jour')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // 🔸 Nouvelle vignette macros (copie du style Bilan)
            _DayMacroOverview(
              goals: goals,
              totals: _totals,
              gKcal: gKcal,
            ),
            const SizedBox(height: 16),

            // 🔸 Sections repas (on utilise _journal et _handleRemove)
            _MealSection(
              title: 'Petit-déjeuner',
              items: _journal['Petit-déjeuner']!,
              onRemove: (i) => _handleRemove('Petit-déjeuner', i),
            ),
            _MealSection(
              title: 'Déjeuner',
              items: _journal['Déjeuner']!,
              onRemove: (i) => _handleRemove('Déjeuner', i),
            ),
            _MealSection(
              title: 'Dîner',
              items: _journal['Dîner']!,
              onRemove: (i) => _handleRemove('Dîner', i),
            ),
            _MealSection(
              title: 'Collation',
              items: _journal['Collation']!,
              onRemove: (i) => _handleRemove('Collation', i),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Carte macros du jour :
/// copie du style _MacroOverview du Bilan
class _DayMacroOverview extends StatelessWidget {
  final Goals goals;
  final DayTotals totals;
  final double gKcal;

  const _DayMacroOverview({
    required this.goals,
    required this.totals,
    required this.gKcal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ÉNERGIE
    final targetKcal = gKcal > 0 ? gKcal : 2000.0;
    final pctKcal = targetKcal == 0
        ? 0.0
        : (totals.kcal / targetKcal).clamp(0.0, 2.0);
    final colorKcal = _barColor(pctKcal);

    final remainingKcal = targetKcal > 0
        ? (targetKcal - totals.kcal).clamp(0.0, double.infinity)
        : 0.0;

    // Pour le visuel côté droit : Protéines, Glucides, Lipides, Fibres
    final macros = <_MacroItem>[
      _MacroItem(
        label: 'Protéines',
        unit: 'g',
        value: totals.prot,
        target: goals.prot,
      ),
      _MacroItem(
        label: 'Glucides',
        unit: 'g',
        value: totals.carb,
        target: goals.carb,
      ),
      _MacroItem(
        label: 'Lipides',
        unit: 'g',
        value: totals.fat,
        target: goals.fat,
      ),
      _MacroItem(
        label: 'Fibres',
        unit: 'g',
        value: totals.fiber,
        target: goals.fiber,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // ───── COLONNE GAUCHE : DONUT ÉNERGIE ─────
          SizedBox(
            width: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Énergie',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pctKcal.clamp(0.02, 1.0),
                        strokeWidth: 9,
                        color: colorKcal,
                        backgroundColor: colorKcal.withOpacity(0.18),
                      ),
                      Text(
                        '${(pctKcal * 100).clamp(0, 200).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Objectif = ${targetKcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Consommé = ${totals.kcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Restant = ${remainingKcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ───── COLONNE DROITE : 4 MACROS AVEC PUCE + BARRE ─────
          Expanded(
            child: Column(
              children: macros.map((m) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _MacroBarRow(item: m),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem {
  final String label;
  final String unit;
  final double value;
  final double target;

  const _MacroItem({
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
  });
}

class _MacroBarRow extends StatelessWidget {
  final _MacroItem item;

  const _MacroBarRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final target = item.target;
    final pct = target == 0
        ? 0.0
        : (item.value / target).clamp(0.0, 2.0);
    final color = _barColor(pct);

    final pctText = (pct * 100).clamp(0, 200).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Nom du macro à gauche
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            // Petit badge % à droite
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Text(
                '$pctText%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct.clamp(0.02, 1.0),
            minHeight: 9,
            backgroundColor: color.withOpacity(0.18),
            color: color,
          ),
        ),
        const SizedBox(height: 2),

        // Texte "xx g / yy g"
        Text(
          '${item.value.toStringAsFixed(0)} ${item.unit} / '
          '${item.target.toStringAsFixed(0)} ${item.unit}',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Widgets utilitaires ───────────────────────────
class _FoodListView extends StatelessWidget {
  final List<dynamic> items;
  final bool Function(String id) isFav;
  final Future<void> Function(String id) onFavToggle;
  final void Function(dynamic it) onTap;

  final bool showCreateButton;
  final VoidCallback? onCreateCustom;
  final void Function(dynamic it)? onEditCustom;
  final Future<void> Function(String id)? onDeleteCustom;

  const _FoodListView({
    required this.items, required this.isFav, required this.onFavToggle, required this.onTap,
    required this.showCreateButton, this.onCreateCustom, this.onEditCustom, this.onDeleteCustom,
  });

  bool _isPersonal(dynamic it) {
    try { final id = (it as dynamic).id as String?; return id?.startsWith('custom:') == true; }
    catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showCreateButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                onPressed: onCreateCustom,
                label: const Text('Ajouter un aliment perso'),
              ),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucun résultat'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final name = (((it as dynamic).name) as String?) ?? 'Aliment';
                    final id = (((it as dynamic).id) as String?) ?? '';
                    final kcal100 = ((it as dynamic).kcal100 as num?)?.toDouble() ?? 0.0;
                    final fav = id.isNotEmpty ? isFav(id) : false;
                    final isCustom = _isPersonal(it);

                    return ListTile(
                      title: Text(name),
                      subtitle: Text('${kcal100.toStringAsFixed(0)} kcal / 100 g'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCustom && onEditCustom != null)
                            IconButton(tooltip: 'Modifier', icon: const Icon(Icons.edit_outlined), onPressed: () => onEditCustom!(it)),
                          if (isCustom && onDeleteCustom != null)
                            IconButton(tooltip: 'Supprimer', icon: const Icon(Icons.delete_outline), onPressed: () => onDeleteCustom!(id)),
                          IconButton(
                            tooltip: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                            icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                            onPressed: id.isNotEmpty ? () => onFavToggle(id) : null,
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => onTap(it),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Future<void> Function(int index) onRemove;

  const _MealSection({required this.title, required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _SectionCard(
          title: title,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Aucun aliment ajouté.', style: TextStyle(color: Colors.black54)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _SectionCard(
        title: title,
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _MealRow(item: items[i], onRemove: () => onRemove(i)),
              if (i != items.length - 1) const Divider(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  const _MealRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name  = (item['name']  ?? '') .toString();
    final grams = (item['grams'] ?? 0) .toDouble();
    final kcal  = (item['kcal']  ?? 0) .toDouble();
    final prot  = (item['prot']  ?? 0) .toDouble();
    final carb  = (item['carb']  ?? 0) .toDouble();
    final fat   = (item['fat']   ?? 0) .toDouble();
    final fiber = (item['fiber'] ?? 0) .toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '$grams g • ${kcal.toStringAsFixed(0)} kcal • '
              'P ${prot.toStringAsFixed(1)}g • G ${carb.toStringAsFixed(1)}g • L ${fat.toStringAsFixed(1)}g • F ${fiber.toStringAsFixed(1)}g',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ]),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline), tooltip: 'Supprimer'),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.restaurant, size: 18, color: Colors.black54),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ───────────── Sections repliables (avec % à droite) ─────────────
class _Metric {
  final String label; final double value; final double? target; final String unit; final int decimals;
  const _Metric(this.label, this.value, this.target, this.unit, this.decimals);
}
class _Section extends StatelessWidget {
  final String title; final String emoji; final List<_Metric> metrics; final bool initiallyExpanded;
  const _Section({required this.title, required this.emoji, required this.metrics, this.initiallyExpanded = false});
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        children: metrics.map((m) {
          final pct = (m.target == null || m.target == 0) ? null : (m.value / m.target!).clamp(0.0, 2.0).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (pct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _barColor(pct).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _barColor(pct).withOpacity(0.35)),
                    ),
                    child: Text('${(pct * 100).clamp(0, 200).toStringAsFixed(0)}%',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _barColor(pct), fontSize: 12)),
                  ),
              ]),
              const SizedBox(height: 6),
              if (pct != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.02, 1.0).toDouble(),
                    minHeight: 12,
                    backgroundColor: _barColor(pct).withOpacity(0.18),
                    color: _barColor(pct),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${m.value.toStringAsFixed(m.decimals)} ${m.unit} / ${m.target!.toStringAsFixed(m.decimals)} ${m.unit}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ] else
                Text('${m.value.toStringAsFixed(m.decimals)} ${m.unit}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ───────────── Champs utilitaires ─────────────
class _TwoFieldsRow extends StatelessWidget {
  final String leftLabel, rightLabel;
  final String leftInit, rightInit;
  final void Function(String) onLeftChanged, onRightChanged;
  const _TwoFieldsRow({
    required this.leftLabel, required this.rightLabel, required this.leftInit, required this.rightInit,
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
            controller: leftCtl, keyboardType: TextInputType.number,
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
            controller: rightCtl, keyboardType: TextInputType.number,
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
  const _LabeledField({required this.label, required this.controller, this.keyboardType, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}
