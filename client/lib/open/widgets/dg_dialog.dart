import 'package:flutter/material.dart';

import '../../theme/color.dart';
import '../../theme/spacing.dart';

class DgDialog extends StatelessWidget {
  final Widget child;

  const DgDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DgColor.defaultModal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: DgSpacing.s),
        child: child,
      ),
    );
  }
}
