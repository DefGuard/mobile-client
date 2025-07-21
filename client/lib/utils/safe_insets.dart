import 'dart:math' as math;
import 'package:flutter/material.dart';

EdgeInsets safeInsetHorizontal(BuildContext context, double preferredPadding) {
  final safe = MediaQuery.of(context).padding;
  return EdgeInsets.only(
    left: math.max(safe.left, preferredPadding),
    right: math.max(safe.right, preferredPadding),
  );
}
