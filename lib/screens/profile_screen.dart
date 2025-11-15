import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_screen.dart';

// ==== Palette moderne Totum ====
const kTotumOrange = Color(0xFFFF7A00);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum Sex { male, female }

enum Activity {
  sedentary,    // 1.20
  light,        // 1.375 (1–3 / semaine)
  moderate,     // 1.55  (3–5 / semaine)
  intense,      // 1.725 (6–7 / semaine)
  veryIntense,  // 1.90  (2× / jour)
}

enum Goal {
  loss,     // -15%
  maintain, // 0%
  gain,     // +10%
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Champs
  Sex _sex = Sex.male;
  Activity _activity = Activity.moderate;
  Goal _goal = Goal.maintain;
  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '175'); // cm
  final _weightCtrl = TextEditingController(text: '70');  // kg

  // Résultats affichés
  double _kcal = 0, _prot = 0, _carb = 0, _fat = 0, _fib = 30;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

  double _activityFactor(Activity a) {
    switch (a) {
      case Activity.sedentary:   return 1.20;
      case Activity.light:       return 1.375;
      case Activity.moderate:    return 1.55;
      case Activity.intense:     return 1.725;
      case Activity.veryIntense: return 1.90;
    }
  }

  /// Protéines (g/kg) selon activité – 1.0 / 1.2 / 1.6 / 2.0 / 2.5
  double _proteinPerKg(Activity a) {
    switch (a) {
      case Activity.sedentary:   return 1.0;
      case Activity.light:       return 1.2;
      case Activity.moderate:    return 1.6;
      case Activity.intense:     return 2.0;
      case Activity.veryIntense: return 2.5;
    }
  }

  double _goalMultiplier(Goal g) {
    switch (g) {
      case Goal.loss:     return 0.85; // -15%
      case Goal.maintain: return 1.00; // 0%
      case Goal.gain:     return 1.10; // +10%
    }
  }

  /// BMR Mifflin-St Jeor
  double _bmrMifflin({
    required Sex sex,
    required double kg,
    required double cm,
    required int age,
  }) {
    if (sex == Sex.male) {
      return (10 * kg) + (6.25 * cm) - (5 * age) + 5;
    } else {
      return (10 * kg) + (6.25 * cm) - (5 * age) - 161;
    }
  }

  Future<void> _computeAndSave() async {
  if (!_formKey.currentState!.validate()) return;

  final kg  = _num(_weightCtrl);
  final cm  = _num(_heightCtrl);
  final age = _num(_ageCtrl).round();

  // 1) BMR → TDEE → objectif
  final bmr  = _bmrMifflin(sex: _sex, kg: kg, cm: cm, age: age);
  final tdee = bmr * _activityFactor(_activity);
  final kcal = tdee * _goalMultiplier(_goal);

  // 2) Macro-cibles (prot en g/kg selon activité, lipides 35% kcal, glucides 55%, fibres fixes)
  final prot     = _proteinPerKg(_activity) * kg; // g
  final kcalFat  = kcal * 0.35;  // 35%
  final fat      = kcalFat / 9.0;
  final kcalCarb = kcal * 0.55;  // 55%
  final carb     = kcalCarb / 4.0;
  const fib      = 30.0;

  // 3) Sauvegarde
  final sp = await SharedPreferences.getInstance();

  // 3a) Profil
  await sp.setString('profile_sex', _sex == Sex.female ? 'female' : 'male');
  await sp.setInt('profile_activity', _activity.index);
  await sp.setInt('profile_goal', _goal.index);
  await sp.setDouble('profile_age', age.toDouble());
  await sp.setDouble('profile_height', cm.toDouble());
  await sp.setDouble('profile_weight', kg);

  // 3b) Cibles
  await sp.setDouble('goals_kcal', kcal);
  await sp.setDouble('goals_prot', prot);
  await sp.setDouble('goals_carb', carb);
  await sp.setDouble('goals_fat',  fat);
  await sp.setDouble('goals_fiber', fib);

  // 4) Affichage local
  setState(() {
    _kcal = kcal;
    _prot = prot;
    _carb = carb;
    _fat  = fat;
    _fib  = fib;
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil et objectifs sauvegardés ✅')),
    );
  }
}

  @override
void initState() {
  super.initState();
  _loadProfile();
}

Future<void> _loadProfile() async {
  final sp = await SharedPreferences.getInstance();

  // Profil (inchangé)
  final sexStr = sp.getString('profile_sex');
  final activityIndex = sp.getInt('profile_activity');
  final goalIndex = sp.getInt('profile_goal');
  final age = sp.getDouble('profile_age');
  final height = sp.getDouble('profile_height');
  final weight = sp.getDouble('profile_weight');

  // ✅ Objectifs (nouveau : relit les valeurs persistées)
  final goalsKcal  = sp.getDouble('goals_kcal');
  final goalsProt  = sp.getDouble('goals_prot');
  final goalsCarb  = sp.getDouble('goals_carb');
  final goalsFat   = sp.getDouble('goals_fat');
  final goalsFiber = sp.getDouble('goals_fiber');

  setState(() {
    // Profil (inchangé)
    _sex = (sexStr == 'female') ? Sex.female : Sex.male;
    if (activityIndex != null) _activity = Activity.values[activityIndex];
    if (goalIndex != null) _goal = Goal.values[goalIndex];
    if (age != null) _ageCtrl.text = age.toStringAsFixed(0);
    if (height != null) _heightCtrl.text = height.toStringAsFixed(0);
    if (weight != null) _weightCtrl.text = weight.toStringAsFixed(0);

    // ✅ Objectifs (chargés si disponibles, sinon on garde les valeurs actuelles)
    if (goalsKcal  != null) _kcal = goalsKcal;
    if (goalsProt  != null) _prot = goalsProt;
    if (goalsCarb  != null) _carb = goalsCarb;
    if (goalsFat   != null) _fat  = goalsFat;
    if (goalsFiber != null) _fib  = goalsFiber;
  });
}



    @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- LOGO centré, grand ---
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 96, // ajuste si tu veux plus grand/petit
                ),
              ),
            ),
            // ---------------------------

            // Sexe
            Text('Sexe', style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('Homme')),
                ButtonSegment(value: Sex.female, label: Text('Femme')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 16),

            // Age / Taille / Poids
            Row(
              children: [
                Expanded(child: _numField(label: 'Âge (ans)', controller: _ageCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _numField(label: 'Taille (cm)', controller: _heightCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _numField(label: 'Poids (kg)', controller: _weightCtrl)),
              ],
            ),
            const SizedBox(height: 16),

            // Activité
            Text('Activité physique', style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<Activity>(
              value: _activity,
              onChanged: (v) => setState(() => _activity = v!),
              items: const [
                DropdownMenuItem(value: Activity.sedentary, child: Text('Sédentaire')),
                DropdownMenuItem(value: Activity.light, child: Text('Léger 1–3/sem')),
                DropdownMenuItem(value: Activity.moderate, child: Text('Modéré 3–5/sem')),
                DropdownMenuItem(value: Activity.intense, child: Text('Soutenu 6–7/sem')),
                DropdownMenuItem(value: Activity.veryIntense, child: Text('Très intense 2×/jour')),
              ],
            ),
            const SizedBox(height: 16),

            // Objectif
            Text('Objectif', style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<Goal>(
              value: _goal,
              onChanged: (v) => setState(() => _goal = v!),
              items: const [
                DropdownMenuItem(value: Goal.loss, child: Text('Perte de poids')),
                DropdownMenuItem(value: Goal.maintain, child: Text('Maintien')),
                DropdownMenuItem(value: Goal.gain, child: Text('Prise de poids')),
              ],
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kTotumOrange,
                foregroundColor: Colors.black, // ✅ texte et icône en noir
              ),
              onPressed: () async {
                await _computeAndSave();

                // ✅ Sauvegarde les objectifs dans SharedPreferences
                final sp = await SharedPreferences.getInstance();
                await sp.setDouble('goals_kcal', _kcal);
                await sp.setDouble('goals_prot', _prot);
                await sp.setDouble('goals_carb', _carb);
                await sp.setDouble('goals_fat', _fat);
                await sp.setDouble('goals_fiber', _fib);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil enregistré et objectifs mis à jour.')),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Calculer & sauvegarder'),
            ),
            const SizedBox(height: 12),

            // Récap
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Objectifs journaliers', style: t.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _goalRow('Énergie', '${_kcal.toStringAsFixed(0)} kcal'),
                    _goalRow('Protéines', '${_prot.toStringAsFixed(0)} g'),
                    _goalRow('Glucides', '${_carb.toStringAsFixed(0)} g'),
                    _goalRow('Lipides', '${_fat.toStringAsFixed(0)} g'),
                    _goalRow('Fibres', '${_fib.toStringAsFixed(0)} g'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ici, un aperçu des cibles macros. Tous les résultats détaillés (acides gras essentiels, vitamines, minéraux, etc.) se calculent automatiquement dans l’onglet Bilan.',
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }


  Widget _numField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          (double.tryParse((v ?? '').replaceAll(',', '.')) == null)
              ? 'Nombre invalide'
              : null,
    );
  }

  Widget _goalRow(String k, String v) {
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
}
