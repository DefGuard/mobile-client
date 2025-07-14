import 'package:flutter/material.dart';

Offset? getRenderObjectPosition(RenderObject? renderObject) {
  if(renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero);
  }
  return null;
}

class WidgetGeometry {
  final Offset position;
  final Size size;

  const WidgetGeometry({
    required this.position,
    required this.size,
  });

  static WidgetGeometry fromKey(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if(renderObject is RenderBox && renderObject.hasSize) {
      final position = renderObject.localToGlobal(Offset.zero);
      final size = renderObject.size;
      return WidgetGeometry(position: position, size: size);
    }
    return WidgetGeometry(position: Offset.zero, size: Size.zero);
  }
}