import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalState extends ChangeNotifier {
  // Totaux du jour (macros + fibre)
  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;

  // Micronutriments (clé = libellé CSV, valeur = total du jour)
  final Map<String, double> micros = {};

  // Appeler au démarrage de l’app (main.dart) et/ou à l’ouverture de Bilan
  Future<void> loadToday() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('today_totals');
    if (raw == null) return;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    kcal = (m['kcal'] ?? 0).toDouble();
    prot = (m['prot'] ?? 0).toDouble();
    carb = (m['carb'] ?? 0).toDouble();
    fat  = (m['fat']  ?? 0).toDouble();
    fiber= (m['fiber']?? 0).toDouble();
    micros
      ..clear()
      ..addAll((m['micros'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
      ) ?? {});
    notifyListeners();
  }

  Future<void> saveToday() async {
    final sp = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'kcal': kcal, 'prot': prot, 'carb': carb, 'fat': fat, 'fiber': fiber,
      'micros': micros,
    });
    await sp.setString('today_totals', payload);
  }

  // À appeler côté Journal lorsqu’un aliment est ajouté
  // m = macros calculées pour la quantité (kcal/prot/carb/fat/fiber)
  // mi = micros calculés pour la quantité (ex: {"Vitamine_C_mg_100g": 23.4, ...})
  Future<void> addEntry({
    required Map<String, double> m,
    required Map<String, double> mi,
  }) async {
    kcal += (m['kcal'] ?? 0);
    prot += (m['prot'] ?? 0);
    carb += (m['carb'] ?? 0);
    fat  += (m['fat']  ?? 0);
    fiber+= (m['fiber']?? 0);
    for (final e in mi.entries) {
      micros[e.key] = (micros[e.key] ?? 0) + (e.value);
    }
    await saveToday();
    notifyListeners();
  }

  // Remise à zéro (si tu proposes un bouton "Reset jour")
  Future<void> reset() async {
    kcal = prot = carb = fat = fiber = 0;
    micros.clear();
    await saveToday();
    notifyListeners();
  }
}
