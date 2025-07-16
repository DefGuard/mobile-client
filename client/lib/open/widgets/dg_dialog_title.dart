import 'package:flutter/material.dart';
import 'package:mobile/theme/text.dart';

class DgDialogTitle extends StatelessWidget {
  final String text;

  const DgDialogTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: DgText.sideBar, textAlign: TextAlign.center),
    );
  }
}
