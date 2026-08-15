// lib/theme/totum_style.dart
//
// ═══════════════════════════════════════════════════════════════════════
//  CHARTE GRAPHIQUE TOTUM — référence unique pour toute l'application.
// ═══════════════════════════════════════════════════════════════════════
//
// Principes (validés sur l'onglet Profil, à reconduire tels quels sur
// Journal / Bilan / Conseils) :
//
// 1. UN SEUL ACCENT DE MARQUE (l'orange), jamais une 2e couleur de section.
//    Le contraste vient des contours, des pictogrammes et des nuances de
//    CET accent — pas de nouvelles teintes ajoutées au fil des écrans.
//    Raison marketing : une identité de marque forte et reconnaissable
//    repose sur la répétition d'un signal visuel unique et constant (c'est
//    le principe derrière le rouge Coca-Cola ou le bleu Facebook) — multiplier
//    les couleurs par fonctionnalité dilue la reconnaissance de marque et
//    fatigue visuellement, l'inverse de "confiance + plaisir d'usage".
// 2. SURFACES NEUTRES (blanc/gris très clair), contours fins plutôt que
//    fonds colorés — lisible, reposant, jamais criard.
// 3. PICTOGRAMMES = icônes Material vectorielles monochromes uniquement,
//    JAMAIS d'emoji multicolore (un emoji embarque ses propres couleurs
//    fixes, indépendantes de la charte → casse la cohérence dès qu'il
//    apparaît à côté d'un composant qui respecte, lui, l'accent unique).
//    Couleur d'icône : textSecondary au repos, accent quand actif/sélectionné.
// 4. PROGRESSION (donuts, barres, curseurs) = une RAMPE de teintes du MÊME
//    accent (mélange avec du blanc), jamais un dégradé multi-teintes
//    (rouge→orange→vert). Voir [TotumProgress] ci-dessous : c'est LA seule
//    logique de remplissage progressif de toute l'app, réutilisée partout.
// 5. Exception délibérée et restreinte : [TotumColors.positive]/[negative]
//    (vert/rouge) — réservés UNIQUEMENT à la direction d'un delta chiffré
//    (poids qui monte/descend, écart calorique) : un axe sémantique différent
//    de la progression (pas "combien j'ai avancé", mais "dans quel sens").
//    Ne jamais les utiliser comme accent de section ou de catégorie.

import 'package:flutter/material.dart';
import '../services/app_settings.dart';

/// Priorité 60 (15/08/2026) : mode sombre réel — remplace le badge "arrive
/// bientôt" (voir account_screen.dart, AppearanceSettingsScreen). Chaque
/// champ de [TotumColors] passe de `static const` à `static get`, lu
/// dynamiquement selon [AppSettings.effectiveBrightness] (mis à jour par
/// AppSettings.load(), voir ce fichier — résout "Système" vers la
/// luminosité réelle de l'OS, pas une valeur figée).
///
/// Les 847 sites d'appel (`TotumColors.xxx`, dans tout `lib/`) restent
/// TOUS identiques en syntaxe — seule l'implémentation change ici. Seule
/// conséquence côté appelants : un getter n'est plus une expression
/// constante, donc tout widget qui embarquait `TotumColors.xxx` dans un
/// contexte `const` a dû perdre ce `const` (traité fichier par fichier,
/// piloté par les erreurs précises de `flutter analyze`).
bool get _isDark => AppSettings.effectiveBrightness.value == Brightness.dark;

class TotumColors {
  TotumColors._();

  /// Seule couleur d'accent de toute l'app — jamais une 2e couleur "de
  /// marque" à côté. Utilisée avec parcimonie : CTA principal, état actif/
  /// sélectionné, valeur la plus importante d'une carte. Identique en clair
  /// et en sombre (cohérence de marque — déjà un bon contraste sur les 2).
  static const accent = Color(0xFFFF7A00);

  // accent à ~12%/~25% en clair (fonds discrets/contours) — légèrement
  // remonté en sombre (0x33/0x59, ~20%/~35%), sinon trop discret sur un
  // fond sombre.
  static Color get accentSoft => _isDark ? const Color(0x33FF7A00) : const Color(0x1FFF7A00);
  static Color get accentBorder => _isDark ? const Color(0x59FF7A00) : const Color(0x40FF7A00);

  static Color get page => _isDark ? const Color(0xFF121214) : const Color(0xFFF6F6F4);
  static Color get surface => _isDark ? const Color(0xFF1C1D21) : Colors.white;
  // Contours : noir-transparent en clair, BLANC-transparent en sombre — du
  // noir sur fond sombre serait invisible (c'est exactement le bug corrigé
  // dans main.dart, _navItem, avec un Colors.black45 en dur).
  static Color get outline => _isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000);
  static Color get outlineStrong => _isDark ? const Color(0x38FFFFFF) : const Color(0x2E000000);

  // Blanc cassé (jamais blanc pur, évite l'éblouissement) → gris clairs
  // dégressifs en sombre — même hiérarchie de lisibilité qu'en clair,
  // inversée.
  static Color get textPrimary => _isDark ? const Color(0xFFF2F2F0) : const Color(0xFF16171B);
  static Color get textSecondary => _isDark ? const Color(0xFFB4B6BC) : const Color(0xFF6E7076);
  static Color get textMuted => _isDark ? const Color(0xFF7C7E85) : const Color(0xFFA7A9AE);

  // Usage sobre uniquement (delta positif/négatif) — jamais comme accent de
  // section ou de catégorie. Voir règle 5 en tête de fichier. Légèrement
  // éclaircis en sombre : un vert/rouge saturé devient terne sur fond noir.
  static Color get positive => _isDark ? const Color(0xFF3DB673) : const Color(0xFF1F9254);
  static Color get negative => _isDark ? const Color(0xFFF06B5C) : const Color(0xFFD84C3E);
}

/// Rampe de progression — LA seule logique de remplissage progressif de
/// toute l'app (donuts, barres, curseurs, jauges). 4 arrêts nommés (logique
/// "par quart" demandée) + une fonction continue pour les remplissages
/// animés — tous dérivés de l'UNIQUE accent de marque mélangé à du blanc,
/// jamais d'une nouvelle teinte. Un repère toujours visible même à 0%
/// (jamais blanc pur) : "pas commencé" doit rester visible comme un état,
/// pas disparaître.
class TotumProgress {
  TotumProgress._();

  // Rampe claire : mélange accent → blanc, inchangée (Priorité 60).
  static const _paleLight = Color(0xFFFFE7CC); // départ de rampe (~10% accent)
  static const _stop25Light = Color(0xFFFFCA8E);
  static const _stop50Light = Color(0xFFFFAD55);
  static const _stop75Light = Color(0xFFFF9022);

  // Rampe sombre : mélanger vers du BLANC comme en clair rendrait le "pas
  // commencé" quasi-blanc sur fond sombre (illisible/à contretemps) —
  // mélange vers la surface sombre à la place, paliers plus lumineux pour
  // rester visibles. Calculée (lerp), pas des valeurs hex inventées à la
  // main.
  static const _darkBase = Color(0xFF1C1D21); // = TotumColors.surface (sombre)
  static Color get _paleDark => Color.lerp(_darkBase, TotumColors.accent, 0.16)!;
  static Color get _stop25Dark => Color.lerp(_darkBase, TotumColors.accent, 0.38)!;
  static Color get _stop50Dark => Color.lerp(_darkBase, TotumColors.accent, 0.60)!;
  static Color get _stop75Dark => Color.lerp(_darkBase, TotumColors.accent, 0.82)!;

  static Color get stop25 => _isDark ? _stop25Dark : _stop25Light;
  static Color get stop50 => _isDark ? _stop50Dark : _stop50Light;
  static Color get stop75 => _isDark ? _stop75Dark : _stop75Light;
  static Color get stop100 => TotumColors.accent;

  /// Couleur pour une fraction 0.0–1.0 d'avancement — interpole dans la
  /// même famille de teintes que les 4 arrêts nommés ci-dessus.
  static Color forFraction(double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    final pale = _isDark ? _paleDark : _paleLight;
    if (f <= 1 / 3) return Color.lerp(pale, stop50, f / (1 / 3))!;
    if (f <= 2 / 3) return Color.lerp(stop50, stop75, (f - 1 / 3) / (1 / 3))!;
    return Color.lerp(stop75, stop100, (f - 2 / 3) / (1 / 3))!;
  }
}

class TotumRadius {
  TotumRadius._();
  static const card = 20.0;
  static const tile = 16.0;
  static const chip = 999.0;
}

/// Carte neutre à contour fin — le composant de base de tout l'onglet
/// (remplace les fonds dégradés colorés par section de la version
/// précédente). Le contraste vient du contour, pas de la couleur.
class TotumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool accentBorder;
  const TotumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accentBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: TotumColors.surface,
        borderRadius: BorderRadius.circular(TotumRadius.card),
        border: Border.all(
          color: accentBorder ? TotumColors.accentBorder : TotumColors.outline,
          width: accentBorder ? 1.6 : 1,
        ),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TotumRadius.card),
      child: card,
    );
  }
}

/// Indicateur à points — reflète la page courante d'un carrousel horizontal
/// (PageView). Composant partagé, même vocabulaire visuel partout.
class TotumDots extends StatelessWidget {
  final int count;
  final int index;
  const TotumDots({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? TotumColors.accent : TotumColors.outlineStrong,
            borderRadius: BorderRadius.circular(TotumRadius.chip),
          ),
        );
      }),
    );
  }
}

/// Vignette d'entrée "avec un +" — icône + libellé, et soit une invite à
/// renseigner (état vide), soit la valeur choisie affichée directement
/// (état rempli). Un seul composant pour toutes les entrées de l'onglet.
class TotumInputTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value; // null = état vide
  final VoidCallback onTap;
  const TotumInputTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  /// Hauteur FIXE, volontairement — 2 vignettes côte à côte doivent toujours
  /// être alignées à la même hauteur, quelle que soit la longueur de leur
  /// valeur (ex. "Mesures" a un texte plus long qu'"Objectif").
  static const double height = 124.0;

  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    return SizedBox(
      height: height,
      child: TotumCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        accentBorder: filled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: filled ? TotumColors.accent : TotumColors.textSecondary),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? TotumColors.accentSoft : TotumColors.page,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    filled ? Icons.check : Icons.add,
                    size: 14,
                    color: filled ? TotumColors.accent : TotumColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                filled ? value! : 'Ajouter',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: filled ? TotumColors.textPrimary : TotumColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icône scanner "viseur + code-barres" (Priorité 39, pictogramme fourni par
/// Alex — 4 coins de cadrage façon viseur de scan, avec les barres d'un
/// code-barres au centre) — remplace `Icons.qr_code_scanner` (icône Material
/// générique, plus proche d'un QR code que d'un scan de code-barres produit).
/// Dessinée en vecteur monochrome pour respecter la charte (voir en-tête de
/// ce fichier : jamais d'emoji multicolore, une seule couleur d'icône).
class ScannerIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const ScannerIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ScannerIconPainter(color: color ?? TotumColors.textSecondary),
    );
  }
}

class _ScannerIconPainter extends CustomPainter {
  final Color color;
  _ScannerIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.09;
    final corner = s * 0.24;
    final inset = stroke / 2;

    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    void bracket(Offset a, Offset b, Offset c) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, framePaint);
    }

    // 4 coins de cadrage (viseur de scan).
    bracket(Offset(inset, inset + corner), Offset(inset, inset), Offset(inset + corner, inset));
    bracket(Offset(s - inset - corner, inset), Offset(s - inset, inset), Offset(s - inset, inset + corner));
    bracket(Offset(inset, s - inset - corner), Offset(inset, s - inset), Offset(inset + corner, s - inset));
    bracket(Offset(s - inset - corner, s - inset), Offset(s - inset, s - inset), Offset(s - inset, s - inset - corner));

    // Barres du code-barres au centre, largeurs alternées.
    final barPaint = Paint()..color = color..style = PaintingStyle.fill;
    final barTop = s * 0.32;
    final barBottom = s * 0.68;
    final widths = [0.07, 0.04, 0.09, 0.04, 0.07];
    final gap = s * 0.045;
    final totalW = widths.fold<double>(0, (a, w) => a + w * s) + gap * (widths.length - 1);
    double x = (s - totalW) / 2;
    for (final wRatio in widths) {
      final w = wRatio * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x, barTop, x + w, barBottom),
          Radius.circular(w * 0.3),
        ),
        barPaint,
      );
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerIconPainter oldDelegate) => oldDelegate.color != color;
}
