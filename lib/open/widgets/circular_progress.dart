import 'package:flutter/material.dart';
import 'package:mobile_client/theme/color.dart';

class DgCircularProgress extends StatelessWidget {
  const DgCircularProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: 2,
      color: DgColor.mainPrimary,
    );
  }
}
