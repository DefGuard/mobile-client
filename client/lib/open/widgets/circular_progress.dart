import 'package:flutter/material.dart';
import 'package:mobile_client/theme/color.dart';

class DgCircularProgress extends StatelessWidget {
  final Color color;
  final double size;

  const DgCircularProgress({
    super.key,
    this.color = DgColor.mainPrimary,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
