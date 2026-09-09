// lib/widgets/word_safe_text.dart
//
// BUG CORRIGÉ (19/08/2026, retour d'Alex — persistant après une 1re
// tentative par comptage de caractères : "il y a toujours des mots coupés
// avec trois petits points") : `TextOverflow.ellipsis` tronque au niveau du
// CARACTÈRE, pas du mot — sur une liste (Journal, recherche d'aliments...),
// le dernier mot visible peut se retrouver coupé en plein milieu. Une 1re
// tentative avait pré-tronqué la CHAÎNE à un nombre de caractères fixe
// (~60) estimé "à peu près" pour 2 lignes — mais cette estimation ne
// correspond pas à la largeur RÉELLEMENT disponible (varie selon l'écran,
// la police, le padding de la ligne), donc l'ellipsis native de Flutter
// continuait à couper au milieu du mot dans les cas où l'estimation était
// trop généreuse.
//
// Ce widget mesure le texte RÉELLEMENT, avec la police et la largeur
// disponibles au moment du rendu (via `TextPainter`, le même moteur que
// Flutter utilise en interne pour la mise en page) et ne coupe jamais qu'à
// une frontière de mot — jamais une approximation.
import 'package:flutter/material.dart';

class WordSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  const WordSafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final displayText =
            _fitToWordBoundary(text, effectiveStyle, constraints.maxWidth, maxLines);
        return Text(
          displayText,
          style: style,
          maxLines: maxLines,
          textAlign: textAlign,
          // Filet de sécurité pour le seul cas résiduel où `_fitToWordBoundary`
          // n'a trouvé aucune frontière de mot exploitable (un mot unique
          // plus large que tout le conteneur, ex. une URL sans espace) —
          // dans TOUS les autres cas, `displayText` tient déjà exactement
          // dans `maxLines`, cet ellipsis ne se déclenche jamais.
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  /// Mesure `text` avec `style` sur une largeur `maxWidth` — s'il tient déjà
  /// dans `maxLines`, le retourne inchangé. Sinon, essaie des préfixes
  /// COMPLETS EN MOTS de plus en plus courts (jamais un mot coupé), chacun
  /// mesuré réellement via `TextPainter`, jusqu'à en trouver un qui tient.
  static String _fitToWordBoundary(String text, TextStyle style, double maxWidth, int maxLines) {
    if (!maxWidth.isFinite || maxWidth <= 0) return text;

    bool fits(String s) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      return !tp.didExceedMaxLines;
    }

    if (fits(text)) return text;

    final words = text.split(' ');
    for (int end = words.length - 1; end > 0; end--) {
      final candidate = '${words.sublist(0, end).join(' ')}…';
      if (fits(candidate)) return candidate;
    }
    // Même le premier mot seul ne tient pas (mot unique très long / conteneur
    // très étroit) — repli sur le texte brut, l'ellipsis natif de Text (voir
    // `overflow: TextOverflow.ellipsis` ci-dessus) prendra le relais, cas
    // limite où une coupure mi-mot est réellement inévitable.
    return text;
  }
}
