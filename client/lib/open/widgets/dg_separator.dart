import 'package:flutter/material.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';

class DgSeparator extends StatelessWidget {
  const DgSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: DgSpacing.s),
      child: Container(
        width: double.infinity,
        height: 1,
        color: DgColor.borderSeparator2,
        child: null,
      ),
    );
  }
}
