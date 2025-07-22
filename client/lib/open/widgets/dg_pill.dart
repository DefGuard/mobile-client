import 'package:flutter/material.dart';
import 'package:mobile/theme/color.dart';

class DgPill extends StatelessWidget {
  final String text;

  const DgPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(5),
      color: DgColor.tagModal,
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: "Roboto",
            fontSize: 8,
            fontWeight: FontWeight.w400,
            color: DgColor.textBodyPrimary,
          ),
        ),
      ),
    );
  }
}
