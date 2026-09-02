import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

(double, double) safeInsetHorizontal(
  BuildContext context,
  double preferredPadding,
) {
  final safe = MediaQuery.of(context).padding;
  return (
    math.max(safe.left, preferredPadding),
    math.max(safe.right, preferredPadding),
  );
}
