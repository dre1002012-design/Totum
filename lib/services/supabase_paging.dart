// lib/services/supabase_paging.dart
//
// Audit 27/10/2026 (constat E3) : Supabase/PostgREST plafonne côté SERVEUR le
// nombre de lignes renvoyées par requête (réglage « Max rows », 1000 par
// défaut) — quel que soit le `.limit()` demandé par le client. Les
// `.limit(10000)` posés le 21/08/2026 ne levaient donc pas la limite : un
// utilisateur qui saisit aliment par aliment (17-31 lignes/jour) dépasse 1000
// lignes en 32-59 jours, et l'export du journal (tri croissant) perdait alors
// ses jours les PLUS RÉCENTS, le Bilan 90 j n'en voyait qu'une quarantaine.
//
// Seule correction indépendante du réglage serveur : lire par pages
// (`.range()`), jusqu'à obtenir une page incomplète. La requête passée DOIT
// avoir un ordre total (ex. `entry_date` PUIS `id`), sinon des lignes de
// même date peuvent être dupliquées ou sautées d'une page à l'autre.

/// Taille de page : égale au plafond serveur par défaut. Une page de moins
/// de [kSupabasePageSize] lignes signifie que tout a été lu.
const int kSupabasePageSize = 1000;

/// Lit toutes les lignes d'une requête par pages successives.
///
/// [fetchPage] reçoit les bornes INCLUSIVES `from`/`to` à passer à
/// `.range(from, to)`. Toute erreur d'une page est propagée telle quelle :
/// jamais un résultat partiel présenté comme complet. [maxPages] est un
/// garde-fou contre une boucle infinie (50 pages = 50 000 lignes, plusieurs
/// années de saisie très détaillée).
Future<List<Map<String, dynamic>>> fetchAllPages(
  Future<List<dynamic>> Function(int from, int to) fetchPage, {
  int pageSize = kSupabasePageSize,
  int maxPages = 50,
}) async {
  final all = <Map<String, dynamic>>[];
  for (var page = 0; page < maxPages; page++) {
    final from = page * pageSize;
    final rows = await fetchPage(from, from + pageSize - 1);
    for (final r in rows) {
      all.add(Map<String, dynamic>.from(r as Map));
    }
    if (rows.length < pageSize) break;
  }
  return all;
}
