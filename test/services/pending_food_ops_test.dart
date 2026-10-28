import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/account_guard.dart';
import 'package:totum_app/services/pending_food_ops.dart';

void main() {
  const keys = [
    'settings_theme',
    'sb-yqcbawsszozouhlkxtsj-auth-token',
    'account_guard_last_user_id',
    PendingFoodOps.storageKey,
    'goals_kcal',
    'history_snapshots',
  ];

  group('localKeysToPurge (audit 27/10/2026, M1)', () {
    test('déconnexion : la file hors ligne et le dernier compte sont conservés', () {
      final purged = localKeysToPurge(keys, signingOut: true);
      expect(purged, containsAll(['goals_kcal', 'history_snapshots']));
      expect(purged, isNot(contains(PendingFoodOps.storageKey)));
      expect(purged, isNot(contains('account_guard_last_user_id')));
    });

    test('autre compte connecté : tout est purgé comme avant (file comprise)', () {
      final purged = localKeysToPurge(keys, signingOut: false);
      expect(purged, containsAll([
        PendingFoodOps.storageKey,
        'account_guard_last_user_id',
        'goals_kcal',
        'history_snapshots',
      ]));
    });

    test('réglages appareil et session Supabase jamais purgés', () {
      for (final signingOut in [true, false]) {
        final purged = localKeysToPurge(keys, signingOut: signingOut);
        expect(purged, isNot(contains('settings_theme')));
        expect(purged, isNot(contains('sb-yqcbawsszozouhlkxtsj-auth-token')));
      }
    });
  });

  group('PendingFoodOps.belongsTo', () {
    test('rejoue uniquement les opérations du compte courant', () {
      final op = {'type': 'insert', 'payload': {'user_id': 'a'}};
      expect(PendingFoodOps.belongsTo(op, 'a'), isTrue);
      expect(PendingFoodOps.belongsTo(op, 'b'), isFalse);
    });

    test('payload absent ou malformé : jamais rejoué', () {
      expect(PendingFoodOps.belongsTo({'type': 'insert'}, 'a'), isFalse);
      expect(PendingFoodOps.belongsTo({'payload': 'x'}, 'a'), isFalse);
    });
  });
}
