import 'dart:ui' as ui show Image;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

const isDebug = false;

debug(String msg) {
  if (isDebug) {
    debugPrint("ReorderableGridView: $msg");
  }
}


Future<ui.Image?> takeScreenShot(State state) async {
  var renderObject = state.context.findRenderObject();
  if (renderObject is RenderRepaintBoundary) {
    RenderRepaintBoundary renderRepaintBoundary = renderObject;
    var devicePixelRatio = MediaQuery.of(state.context).devicePixelRatio;
    return renderRepaintBoundary.toImage(pixelRatio: devicePixelRatio);
  }
}