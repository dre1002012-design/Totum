// lib/services/food_search.dart
//
// Moteur de recherche d'aliments partagé (Journal, recettes, repas perso).
//
// BUG CORRIGÉ (25/10/2026, retour d'Alex — "si on tape une phrase, ça ne
// trouve pas l'aliment ; il faut taper mot pour mot, avec la virgule au bon
// endroit") : l'ancienne recherche exigeait que la requête ENTIÈRE soit une
// sous-chaîne contiguë du nom (`nom.contains(requête)`). Or les noms CIQUAL
// sont rédigés "Catégorie, précision, cuisson" — "magret de canard" ne
// trouvait donc jamais "Canard, magret cru", ni "pâtes cuites" -> "Pâtes
// sèches, standard, cuites", ni "poulet rôti" -> "Poulet, rôti".
//
// Principe retenu (celui des moteurs de recherche des apps de référence —
// MyFitnessPal, Cronometer, MacroFactor — et de tout moteur plein texte) :
// 1. Normalisation : minuscules, accents retirés, toute ponctuation (virgule,
//    tiret, parenthèse, apostrophe...) devient un simple séparateur.
// 2. Découpage en mots, sans les mots vides ("de", "la", "aux"...), pluriels
//    ramenés au singulier ("pâtes" = "pâte", "noix" = "noix").
// 3. Correspondance mot à mot, dans N'IMPORTE QUEL ordre : chaque mot tapé
//    doit commencer un mot du nom (le dernier mot peut être en cours de
//    frappe). Une faute de frappe d'une lettre est tolérée sur les mots de
//    4 lettres ou plus ("poullet", "banane" tapé "bananne").
// 4. Phrase longue : si aucun aliment ne contient TOUS les mots, on accepte
//    ceux qui en contiennent tous sauf un (une phrase comme "pâtes complètes
//    cuites à l'eau" trouve encore "Pâtes alimentaires complètes, cuites").
// 5. Classement : nom qui commence par la requête > premier mot correspondant
//    > correspondances exactes > préfixes > fautes tolérées, puis noms courts
//    (aliments génériques) avant les variantes longues, puis favoris/aliments
//    déjà utilisés (bonus fourni par l'appelant).
//
// Performance : la normalisation d'un nom (la partie coûteuse) est calculée
// UNE seule fois par aliment et mise en cache (Expando, liée à la durée de
// vie de l'objet) — l'ancienne version renormalisait chaque nom à l'intérieur
// même des comparateurs de tri, soit des centaines de milliers d'appels à
// chaque frappe sur ~11 000 aliments (cause directe d'une partie de la
// latence ressentie sur la page "Ajouter un aliment").

import 'dart:math' as math;

const Map<String, String> _accentMap = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ô': 'o', 'ö': 'o', 'ò': 'o', 'ó': 'o', 'õ': 'o',
  'û': 'u', 'ù': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'ñ': 'n',
};

/// Mots qui ne portent aucune information pour retrouver un aliment.
/// Volontairement PAS dans la liste : "sans" ("sans sel ajouté", "sans
/// sucres" changent l'aliment), "cru"/"cuit", "nature", "light".
const Set<String> _stopWords = {
  // FR
  'de', 'du', 'des', 'd', 'la', 'le', 'les', 'l', 'un', 'une', 'au', 'aux',
  'a', 'en', 'et', 'ou', 'avec', 'pour', 'sur', 'par', 'type',
  // EN
  'of', 'the', 'and', 'with', 'in', 'or', 'an', 'for',
};

/// Minuscules + accents retirés + ponctuation -> espace + espaces fusionnés.
String foldForSearch(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  var lastWasSpace = true;
  for (final rune in lower.runes) {
    var ch = String.fromCharCode(rune);
    ch = _accentMap[ch] ?? ch;
    if (ch == 'œ') {
      ch = 'oe';
    } else if (ch == 'æ') {
      ch = 'ae';
    }
    final code = ch.codeUnitAt(0);
    final isAlnum = (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
    if (isAlnum || ch.length > 1) {
      buf.write(ch);
      lastWasSpace = false;
    } else if (!lastWasSpace) {
      buf.write(' ');
      lastWasSpace = true;
    }
  }
  return buf.toString().trim();
}

/// Pluriel français/anglais simple ramené au singulier — appliqué à
/// l'IDENTIQUE côté requête et côté nom, donc même un singulier "faux"
/// ("pois" -> "poi") reste cohérent des deux côtés.
String _stem(String t) {
  if (t.length > 3 && (t.endsWith('s') || t.endsWith('x')) && !t.endsWith('ss')) {
    return t.substring(0, t.length - 1);
  }
  return t;
}

List<String> searchTokens(String s) {
  final folded = foldForSearch(s);
  if (folded.isEmpty) return const [];
  final out = <String>[];
  for (final raw in folded.split(' ')) {
    if (raw.isEmpty || _stopWords.contains(raw)) continue;
    out.add(_stem(raw));
  }
  return out;
}

/// Clé de recherche pré-calculée d'un aliment.
class FoodSearchKey {
  /// Nom principal (celui qui est affiché), normalisé.
  final String primary;
  /// Mots du nom principal, dans l'ordre.
  final List<String> primaryTokens;
  /// Tous les mots indexés (nom principal + noms alternatifs : nom CIQUAL
  /// complet, traduction, marque...), sans doublon.
  final List<String> allTokens;
  FoodSearchKey(this.primary, this.primaryTokens, this.allTokens);

  factory FoodSearchKey.from(String primaryName, Iterable<String?> alternates) {
    final primaryTokens = searchTokens(primaryName);
    final all = <String>{...primaryTokens};
    for (final alt in alternates) {
      if (alt == null || alt.trim().isEmpty) continue;
      all.addAll(searchTokens(alt));
    }
    return FoodSearchKey(foldForSearch(primaryName), primaryTokens, all.toList());
  }
}

/// Requête analysée une fois pour toutes (et non à chaque aliment comparé).
class FoodSearchQuery {
  final String raw;
  final String folded;
  final List<String> tokens;
  FoodSearchQuery(this.raw)
      : folded = foldForSearch(raw),
        tokens = searchTokens(raw);
  bool get isEmpty => folded.isEmpty;
}

/// Distance d'édition (Damerau-Levenshtein restreinte) bornée à 1 : vrai si
/// [a] et [b] diffèrent d'au plus une lettre (ajout, retrait, substitution
/// ou inversion de 2 lettres voisines).
bool _withinOneEdit(String a, String b) {
  if (a == b) return true;
  final la = a.length, lb = b.length;
  if ((la - lb).abs() > 1) return false;
  if (la == lb) {
    var diff = -1;
    for (var i = 0; i < la; i++) {
      if (a.codeUnitAt(i) != b.codeUnitAt(i)) {
        if (diff >= 0) {
          // 2e différence : seule une inversion de lettres voisines passe.
          return diff == i - 1 &&
              a.codeUnitAt(i) == b.codeUnitAt(diff) &&
              a.codeUnitAt(diff) == b.codeUnitAt(i) &&
              a.substring(i + 1) == b.substring(i + 1);
        }
        diff = i;
      }
    }
    return true;
  }
  final s = la < lb ? a : b, l = la < lb ? b : a;
  var i = 0, j = 0, skipped = false;
  while (i < s.length && j < l.length) {
    if (s.codeUnitAt(i) == l.codeUnitAt(j)) {
      i++;
      j++;
    } else {
      if (skipped) return false;
      skipped = true;
      j++;
    }
  }
  return true;
}

/// Qualité de correspondance d'un mot tapé avec les mots d'un nom :
/// 3 = mot identique, 2 = début de mot, 1 = faute de frappe tolérée, 0 = rien.
int _tokenMatch(String q, List<String> tokens) {
  var best = 0;
  for (final t in tokens) {
    if (t == q) return 3;
    if (t.startsWith(q)) {
      best = 2;
      continue;
    }
    if (best < 1 && q.length >= 4) {
      // Faute tolérée sur le mot entier, ou sur le début du mot (mot en
      // cours de frappe : "bananne" vs "banane", "poulle" vs "poulet").
      final prefix = t.length > q.length ? t.substring(0, q.length) : t;
      if (_withinOneEdit(q, t) || _withinOneEdit(q, prefix)) best = 1;
    }
  }
  return best;
}

/// Score de pertinence (plus grand = plus pertinent), ou `null` si l'aliment
/// ne correspond pas. [allowOneMissing] : mode "phrase" (tous les mots sauf
/// un), utilisé seulement si le mode strict ne trouve rien.
double? scoreFoodMatch(FoodSearchKey key, FoodSearchQuery q, {bool allowOneMissing = false}) {
  if (q.isEmpty) return 0;
  if (q.tokens.isEmpty) {
    // Requête faite uniquement de mots vides ("de", "la") : repli sur une
    // simple sous-chaîne, pour ne jamais renvoyer "rien" sans raison.
    return key.primary.contains(q.folded) ? 1 : null;
  }
  var score = 0.0;
  var missing = 0;
  for (final t in q.tokens) {
    final m = _tokenMatch(t, key.allTokens);
    if (m == 0) {
      missing++;
      if (!allowOneMissing || missing > 1 || q.tokens.length < 3) return null;
      continue;
    }
    score += m * 10;
    // Le mot correspond au nom AFFICHÉ (pas seulement à un nom alternatif).
    if (_tokenMatch(t, key.primaryTokens) == m) score += 2;
  }
  if (missing > 0) score -= 25;

  // "Banane, crue" pour "banane", avant "Gâteau à la banane" — y compris
  // quand ce premier mot contient une faute ("bananne").
  if (key.primaryTokens.isNotEmpty) {
    final head = _tokenMatch(q.tokens.first, [key.primaryTokens.first]);
    if (head >= 2) {
      score += 15;
    } else if (head == 1) {
      score += 10;
    }
  }
  if (key.primary.startsWith(q.folded)) score += 25;
  if (key.primary == q.folded) score += 40;

  // Mots dans le même ordre que tapés : léger bonus.
  var lastIdx = -1;
  var inOrder = true;
  for (final t in q.tokens) {
    final idx = key.primaryTokens.indexWhere((p) => p.startsWith(t));
    if (idx < 0 || idx < lastIdx) {
      inOrder = false;
      break;
    }
    lastIdx = idx;
  }
  if (inOrder && q.tokens.length > 1) score += 5;

  // Noms courts (aliments génériques) avant les variantes très précises.
  score -= math.min(key.primaryTokens.length, 20) * 0.8;
  return score;
}

/// Recherche générique : renvoie [items] filtrés et triés par pertinence.
/// [keyOf] fournit la clé pré-calculée de chaque item (voir [FoodSearchIndex]).
/// [boost] (optionnel) ajoute un bonus personnel (favori, déjà utilisé...).
List<T> rankFoods<T>(
  Iterable<T> items,
  String query, {
  required FoodSearchKey Function(T) keyOf,
  double Function(T)? boost,
  int? limit,
}) {
  final q = FoodSearchQuery(query);
  if (q.isEmpty) return items.toList();

  List<MapEntry<T, double>> run(bool relaxed) {
    final out = <MapEntry<T, double>>[];
    for (final it in items) {
      final s = scoreFoodMatch(keyOf(it), q, allowOneMissing: relaxed);
      if (s == null) continue;
      out.add(MapEntry(it, s + (boost?.call(it) ?? 0)));
    }
    return out;
  }

  var scored = run(false);
  if (scored.isEmpty && q.tokens.length >= 3) scored = run(true);
  scored.sort((a, b) => b.value.compareTo(a.value));
  final ranked = scored.map((e) => e.key);
  return (limit != null ? ranked.take(limit) : ranked).toList();
}

/// Cache des clés de recherche, attaché à chaque objet aliment (libéré avec
/// lui). [namesOf] extrait (nom affiché, noms alternatifs) d'un objet.
class FoodSearchIndex {
  Expando<FoodSearchKey> _cache = Expando<FoodSearchKey>('foodSearchKey');
  final (String, List<String?>) Function(Object item) namesOf;
  FoodSearchIndex(this.namesOf);

  FoodSearchKey keyOf(Object item) {
    // Expando n'accepte pas les types valeur (String, num, bool, record) :
    // calcul direct, sans cache, pour ces cas (jamais utilisés pour les
    // aliments eux-mêmes, qui sont toujours des objets).
    if (item is String || item is num || item is bool || item is Record) {
      final (primary, alternates) = namesOf(item);
      return FoodSearchKey.from(primary, alternates);
    }
    final cached = _cache[item];
    if (cached != null) return cached;
    final (primary, alternates) = namesOf(item);
    final key = FoodSearchKey.from(primary, alternates);
    _cache[item] = key;
    return key;
  }

  /// À appeler si la langue d'affichage change (les noms affichés aussi).
  /// Expando n'a pas de clear() : on repart d'un cache neuf, les anciennes
  /// clés sont libérées avec le reste par le ramasse-miettes.
  void clear() => _cache = Expando<FoodSearchKey>('foodSearchKey');
}
