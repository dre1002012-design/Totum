// lib/services/breath_stats.dart
//
// Compteur léger de séances de respiration (Priorité 43) — volontairement
// PAS une série/streak quotidienne : une vraie série demande une logique de
// fuseau horaire/jours manqués correcte, disproportionné pour un
// "nice-to-have", et un compteur de série cassé se voit immédiatement (pire
// qu'une absence de compteur). Juste un total hebdomadaire simple, remis à
// zéro automatiquement au changement de semaine.
import 'package:shared_preferences/shared_preferences.dart';

const String _kWeekStartKey = 'breath_week_start';
const String _kWeekCountKey = 'breath_week_count';
const String _kTotalCountKey = 'breath_total_count';

DateTime _mondayOf(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// À appeler uniquement à la fin NATURELLE d'une séance (pas en sortie
/// anticipée) — depuis `_RespirationScreenState._finish()` et
/// `_CyclicHyperventilationScreenState._finish()`.
Future<void> recordBreathSessionCompleted() async {
  final sp = await SharedPreferences.getInstance();
  final currentMonday = _iso(_mondayOf(DateTime.now()));
  final storedMonday = sp.getString(_kWeekStartKey);
  final weekCount = (storedMonday == currentMonday) ? (sp.getInt(_kWeekCountKey) ?? 0) : 0;
  await sp.setString(_kWeekStartKey, currentMonday);
  await sp.setInt(_kWeekCountKey, weekCount + 1);
  await sp.setInt(_kTotalCountKey, (sp.getInt(_kTotalCountKey) ?? 0) + 1);
}

/// Nombre de séances complétées depuis le lundi de la semaine en cours —
/// remis à 0 automatiquement dès qu'on lit après un changement de semaine
/// (pas besoin de job de reset séparé).
Future<int> loadBreathSessionsThisWeek() async {
  final sp = await SharedPreferences.getInstance();
  final currentMonday = _iso(_mondayOf(DateTime.now()));
  final storedMonday = sp.getString(_kWeekStartKey);
  if (storedMonday != currentMonday) return 0;
  return sp.getInt(_kWeekCountKey) ?? 0;
}
