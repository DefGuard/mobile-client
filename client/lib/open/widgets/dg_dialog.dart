import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../theme/color.dart';
import '../../theme/spacing.dart';

class DgDialog extends StatelessWidget {
  final Widget child;

  const DgDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return Dialog(
      backgroundColor: DgColor.defaultModal,
      insetPadding: EdgeInsets.only(
        left: math.max(safePadding.left, DgSpacing.s),
        right: math.max(safePadding.right, DgSpacing.s),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: DgSpacing.s),
        child: child,
      ),
    );
  }
}
