// lib/services/pending_food_ops.dart
//
// Priorité 66 (fiabilité hors ligne, suite de l'audit global) : jusqu'ici,
// un échec réseau sur un ajout/modif/suppression `food_entries` se
// contentait d'avertir l'utilisateur (SnackBar, voir journal_screen.dart
// `_notifySyncFailure`) sans jamais réessayer — la modification restait
// perdue côté serveur pour de bon. Cette file d'attente locale conserve
// chaque opération manquée et la rejoue automatiquement (au lancement de
// l'app et à chaque retour sur l'onglet Journal) jusqu'à ce qu'elle
// réussisse, sans jamais perdre le geste de l'utilisateur.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingFoodOps {
  PendingFoodOps._();
  static final PendingFoodOps instance = PendingFoodOps._();

  static const _key = 'pending_food_ops_v1';

  Future<List<Map<String, dynamic>>> _readQueue(SharedPreferences sp) async {
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(
      SharedPreferences sp, List<Map<String, dynamic>> queue) async {
    await sp.setString(_key, jsonEncode(queue));
  }

  /// Met en attente une opération ratée. Retourne l'identifiant de la file
  /// (à mémoriser localement sur l'entrée concernée pour pouvoir l'annuler
  /// via [cancel] si l'utilisateur la modifie/supprime avant qu'elle ait pu
  /// se synchroniser).
  Future<String> enqueue(String type, Map<String, dynamic> payload) async {
    final sp = await SharedPreferences.getInstance();
    final queue = await _readQueue(sp);
    final opId =
        '${DateTime.now().microsecondsSinceEpoch}_${queue.length}';
    queue.add({
      'id': opId,
      'type': type,
      'payload': payload,
      'queuedAt': DateTime.now().toIso8601String(),
    });
    // Garde-fou (même logique que l'historique des objectifs) : ne conserve
    // que les 300 dernières opérations en attente, pour ne jamais grossir
    // indéfiniment même si l'appareil reste hors ligne très longtemps.
    final trimmed =
        queue.length > 300 ? queue.sublist(queue.length - 300) : queue;
    await _writeQueue(sp, trimmed);
    return opId;
  }

  /// Annule une opération encore en attente (ex. l'utilisateur supprime ou
  /// modifie un aliment ajouté hors ligne avant qu'il ait pu se
  /// synchroniser) — évite qu'un ajout déjà annulé localement ne
  /// "ressuscite" côté serveur une fois la connexion revenue.
  Future<void> cancel(String opId) async {
    final sp = await SharedPreferences.getInstance();
    final queue = await _readQueue(sp);
    queue.removeWhere((e) => e['id'] == opId);
    await _writeQueue(sp, queue);
  }

  Future<int> pendingCount() async {
    final sp = await SharedPreferences.getInstance();
    return (await _readQueue(sp)).length;
  }

  /// Rejoue la file dans l'ordre où les opérations ont été mises en attente
  /// (important : un ajout suivi d'un "vider ce repas" doit rester rejoué
  /// dans cet ordre pour aboutir au bon résultat final). Chaque opération
  /// réussie est retirée ; celles qui échouent encore (toujours hors ligne)
  /// restent en attente pour le prochain appel. Retourne le nombre
  /// d'opérations effectivement synchronisées.
  Future<int> flush() async {
    final sp = await SharedPreferences.getInstance();
    final queue = await _readQueue(sp);
    if (queue.isEmpty) return 0;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0; // pas connecté : rien à tenter pour l'instant

    final remaining = <Map<String, dynamic>>[];
    var successCount = 0;

    for (final op in queue) {
      final type = op['type'] as String? ?? '';
      final payload =
          Map<String, dynamic>.from((op['payload'] as Map?) ?? {});
      try {
        switch (type) {
          case 'insert':
            await Supabase.instance.client
                .from('food_entries')
                .insert(payload);
            break;
          case 'delete_by_id':
            await Supabase.instance.client
                .from('food_entries')
                .delete()
                .eq('id', payload['entry_id'])
                .eq('user_id', payload['user_id']);
            break;
          case 'update_by_id':
            await Supabase.instance.client
                .from('food_entries')
                .update(Map<String, dynamic>.from(
                    (payload['fields'] as Map?) ?? {}))
                .eq('id', payload['entry_id'])
                .eq('user_id', payload['user_id']);
            break;
          case 'delete_by_criteria':
            await Supabase.instance.client
                .from('food_entries')
                .delete()
                .eq('user_id', payload['user_id'])
                .eq('entry_date', payload['entry_date'])
                .eq('meal_type', payload['meal_type']);
            break;
          default:
            // Type inconnu (version future ?) : on l'abandonne plutôt que
            // de rester bloqué dessus indéfiniment.
            break;
        }
        successCount++;
      } catch (_) {
        remaining.add(op); // probablement toujours hors ligne → on la garde
      }
    }

    await _writeQueue(sp, remaining);
    return successCount;
  }
}
