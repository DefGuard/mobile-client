import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/utils/safe_insets.dart';

EdgeInsetsGeometry screenPadding({
  required double top,
  required double bottom,
  required double horizontal,
  required BuildContext context,
}) {
  final safePaddings = MediaQuery.of(context).padding;
  final (left, right) = safeInsetHorizontal(context, horizontal);
  final safeBottom = math.max(bottom, safePaddings.bottom);
  return EdgeInsetsGeometry.only(
    top: top,
    left: left,
    right: right,
    bottom: safeBottom,
  );
}
