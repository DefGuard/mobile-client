import 'package:flutter/material.dart';
import 'package:mobile/theme/color.dart';

import '../../../theme/spacing.dart';

class DgConfirmDialog extends StatelessWidget {
  final Widget child;

  const DgConfirmDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
      ),
      backgroundColor: DgColor.defaultModal,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 25,
          horizontal: DgSpacing.s,
        ),
        child: child,
      ),
    );
  }
}
