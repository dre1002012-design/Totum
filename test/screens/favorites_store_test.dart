// Régression (15/09/2026, retour utilisateur iOS/web) : un aliment ajouté
// aux favoris depuis la fiche détail n'apparaissait dans l'onglet "Favoris"
// qu'après avoir quitté/rouvert l'appli. Cause racine : _AddFoodPage est une
// route Navigator séparée de JournalScreenState, donc un setState() sur
// JournalScreenState ne la rebuild jamais — seul un abonnement direct au
// store (ChangeNotifier) garantit que tout écran affichant les favoris se
// met à jour, quel que soit l'endroit d'où vient le toggle.
//
// Ce test verrouille le contrat qui rend ce fix robuste : toggle()/load()
// DOIVENT notifier leurs listeners de façon synchrone et fiable, sans
// dépendre de Supabase (le store doit rester utilisable hors-ligne/déconnecté
// — voir le try/catch autour de _supabaseClient dans journal_screen.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totum_app/screens/journal_screen.dart' show FavoritesStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('toggle() ajoute/retire l\'id et notifie les listeners à chaque appel', () async {
    final store = FavoritesStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.toggle('ciqual:12345');
    expect(store.isFav('ciqual:12345'), isTrue);
    expect(notifications, 1,
        reason: 'un écran abonné (ex. _AddFoodPage) doit être averti dès '
            'l\'ajout, sans attendre la fin de la synchronisation Supabase');

    await store.toggle('ciqual:12345');
    expect(store.isFav('ciqual:12345'), isFalse);
    expect(notifications, 2,
        reason: 'le retrait d\'un favori doit aussi notifier');
  });

  test('plusieurs écrans abonnés au même store sont tous notifiés (le bug '
      'exact du 15/09/2026 : un seul écran recevait la mise à jour)', () async {
    final store = FavoritesStore();
    var journalScreenNotified = false;
    var addFoodPageNotified = false;
    store.addListener(() => journalScreenNotified = true);
    store.addListener(() => addFoodPageNotified = true);

    await store.toggle('usda:999');

    expect(journalScreenNotified, isTrue);
    expect(addFoodPageNotified, isTrue);
  });

  test('toggle() fonctionne sans compte connecté (pas de crash Supabase '
      'hors-ligne/déconnecté)', () async {
    final store = FavoritesStore();
    await store.toggle('recipe:totum_1');
    expect(store.isFav('recipe:totum_1'), isTrue);
  });
}
