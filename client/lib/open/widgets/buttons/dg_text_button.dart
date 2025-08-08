import 'package:flutter/material.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class DgTextButton extends StatelessWidget {
  final Function() onTap;
  final String text;
  final TextStyle textStyle;

  const DgTextButton._({
    required this.onTap,
    required this.text,
    required this.textStyle,
  });

  factory DgTextButton({
    required Function() onTap,
    required String text,
    TextStyle? textStyle,
  }) {
    final TextStyle textStyleInner;
    if (textStyle != null) {
      textStyleInner = textStyle;
    } else {
      textStyleInner = DgText.buttonXS;
    }

    return DgTextButton._(text: text, onTap: onTap, textStyle: textStyleInner);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: DgSpacing.xs),
        child: Material(
          color: Colors.transparent,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(decoration: TextDecoration.underline, decorationColor: textStyle.color),
          ),
        ),
      ),
    );
  }
}
