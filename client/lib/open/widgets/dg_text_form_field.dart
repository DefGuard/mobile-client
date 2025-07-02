import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

class DgTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool required;
  final int maxLines;
  final FormFieldValidator? validator;
  final bool disabled;
  final bool readOnly;

  const DgTextFormField({
    super.key,
    required this.controller,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.maxLines = 1,
    this.disabled = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: disabled ? 0.75 : 1,
      duration: Duration(milliseconds: 200),
      child: TextFormField(
        enabled: !disabled,
        readOnly: readOnly,
        textAlignVertical: TextAlignVertical.center,
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: DgColor.frameBg,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DgColor.alertPrimary, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DgColor.mainPrimary, width: 1),
          ),
          hintText: hintText,
          contentPadding: EdgeInsetsGeometry.directional(
            bottom: 14,
            top: 14,
            start: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DgColor.borderPrimary, width: 1),
          ),
          hintStyle: DgText.input.copyWith(color: DgColor.textBodyTertiary),
          suffixIcon: Align(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: DgIconAsterisk(size: 12),
          ),
        ),
        style: DgText.input.copyWith(color: DgColor.textBodyPrimary),
        maxLines: maxLines,
        textAlign: TextAlign.left,
        validator: validator,
      ),
    );
  }
}
