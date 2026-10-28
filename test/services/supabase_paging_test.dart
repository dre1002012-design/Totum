import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/supabase_paging.dart';

/// Source simulée qui se comporte comme PostgREST : `.range(from, to)`
/// inclusif sur une liste déjà triée, plafonnée à [serverCap] lignes.
Future<List<dynamic>> Function(int, int) fakeSource(
  int total, {
  int serverCap = 1000,
  List<int>? calls,
  int? failOnCall,
}) {
  final rows = List.generate(total, (i) => {'id': i});
  var n = 0;
  return (from, to) async {
    n++;
    calls?.add(from);
    if (failOnCall != null && n == failOnCall) {
      throw Exception('réseau coupé');
    }
    if (from >= rows.length) return [];
    final end = [to + 1, rows.length, from + serverCap].reduce((a, b) => a < b ? a : b);
    return rows.sublist(from, end);
  };
}

void main() {
  for (final total in [0, 1, 999, 1000, 1001, 2500]) {
    test('lit exactement $total lignes, sans doublon ni trou', () async {
      final got = await fetchAllPages(fakeSource(total));
      expect(got.length, total);
      expect(got.map((r) => r['id']).toList(), List.generate(total, (i) => i));
    });
  }

  test('nombre de requêtes minimal (2500 lignes → 3 pages)', () async {
    final calls = <int>[];
    await fetchAllPages(fakeSource(2500, calls: calls));
    expect(calls, [0, 1000, 2000]);
  });

  test('moins d\'une page → une seule requête (comportement inchangé)', () async {
    final calls = <int>[];
    await fetchAllPages(fakeSource(42, calls: calls));
    expect(calls, [0]);
  });

  test('une erreur en cours de pagination est propagée, jamais un résultat partiel', () async {
    expect(
      () => fetchAllPages(fakeSource(2500, failOnCall: 2)),
      throwsA(isA<Exception>()),
    );
  });

  test('garde-fou maxPages', () async {
    final got = await fetchAllPages(fakeSource(10000), pageSize: 100, maxPages: 3);
    expect(got.length, 300);
  });
}
