// lib/services/widget_image_renderer.dart
//
// Rendu d'un widget en image À LA TAILLE EXACTE voulue, sans l'afficher à
// l'écran (pipeline de rendu dédié, indépendant de la page visible).
// Utilisé pour exporter les visuels Instagram d'un repas en 1080 px de
// large quelle que soit la taille de l'écran du téléphone, et quel que soit
// le visuel affiché dans l'aperçu (un PageView ne construit que la page
// visible : impossible d'y capturer les 5 visuels d'un carrousel).
//
// Contrainte : le widget doit être "prêt à peindre" de façon synchrone —
// pas d'Image.network/asset (chargement asynchrone) : les photos sont
// passées déjà décodées (ui.Image + RawImage).

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<ui.Image> renderWidgetToImage(
  Widget widget, {
  required Size logicalSize,
  required double pixelRatio,
  required ui.FlutterView view,
}) async {
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(alignment: Alignment.topLeft, child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(logicalSize),
      physicalConstraints: BoxConstraints.tight(logicalSize),
      devicePixelRatio: 1.0,
    ),
  );
  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();

  final buildOwner = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: SizedBox.fromSize(size: logicalSize, child: widget),
  ).attachToRenderTree(buildOwner);
  // Arbre hors écran à usage unique (visuels sans état) : libéré avec ses
  // objets par le ramasse-miettes, aucun démontage manuel nécessaire.
  buildOwner.buildScope(root);
  buildOwner.finalizeTree();
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();
  return boundary.toImage(pixelRatio: pixelRatio);
}

Future<Uint8List> imageToPng(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
