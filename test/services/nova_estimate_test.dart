// Score NOVA estimé (scripts/nova_classify.py, 31/10/2026) — repères tirés
// des exemples de la définition officielle (Monteiro et al., Public Health
// Nutrition 2019). Retour d'Alex : les flocons d'avoine étaient classés
// « ultra-transformés » (NOVA 4), comme le café, le thé ou le tofu nature.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/foods_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NOVA estimé : repères de la définition officielle', () async {
    final repo = FoodsRepository();
    await repo.loadFromAsset('assets/foods.csv');
    int nova(String startsWith) {
      final f = repo.items.firstWhere((f) => f.name.startsWith(startsWith),
          orElse: () => throw StateError('introuvable : $startsWith'));
      return f.novaScore!;
    }

    // 1 — brut ou peu transformé
    for (final n in [
      "Flocons d'avoine", 'Café, non instantané', 'Thé infusé', 'Tisane infusée', 'Tofu nature',
      'Yaourt ou lait fermenté, nature', 'Fromage blanc, nature, 0% MG', 'Pâtes sèches, standard, cuites',
      'Riz blanc, cuit', 'Lait demi-écrémé, UHT', 'Oeuf cru', "Jus d'orange, pur jus", 'Lentille verte, bouillie',
      'Poulet, filet sans peau cru', 'Banane, chair sans peau, crue', 'Amande, avec peau, sans sel ajouté',
    ]) {
      expect(nova(n), 1, reason: n);
    }
    // 2 — ingrédient culinaire
    for (final n in ["Huile d'olive vierge extra", 'Miel', "Sirop d'érable", 'Sucre blanc', 'Beurre à 80% MG minimum, doux']) {
      expect(nova(n), 2, reason: n);
    }
    // 3 — transformé
    for (final n in [
      'Emmental ou emmenthal', 'Pain blanc (par ex. : baguette', 'Jambon cuit, supérieur', 'Saumon fumé',
      'Thon, au naturel, appertisé', 'Bière blanche', 'Vin rouge', 'Chocolat noir 70 %',
    ]) {
      expect(nova(n), 3, reason: n);
    }
    // 4 — ultra-transformé
    for (final n in [
      'Pain de mie blanc, préemballé', 'Cola, sucré', 'Saucisse de Toulouse', 'Whisky', 'Gin',
      'Whey (protéine de lactosérum), poudre', 'Matière grasse tartinable', 'Nuggets ou croquette panée de poulet',
      'Céréales pour petit déjeuner au chocolat', 'Base de pizza',
    ]) {
      expect(nova(n), 4, reason: n);
    }
  });
}
