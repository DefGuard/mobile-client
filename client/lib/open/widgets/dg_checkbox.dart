import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/icons/icon_checkbox.dart';
import 'package:mobile/theme/spacing.dart';

import '../../theme/color.dart';
import '../../theme/text.dart';

class DgCheckbox extends StatelessWidget {
  final bool checked;
  final double iconSize;
  final String? text;
  final TextStyle? textStyle;
  final Function()? onTap;

  const DgCheckbox({
    super.key,
    required this.checked,
    this.text,
    this.onTap,
    this.textStyle,
    this.iconSize = 18,
  });

  DgIconCheckboxVariant _getIconVariant() {
    if (checked) {
      return DgIconCheckboxVariant.checked;
    }
    return DgIconCheckboxVariant.unchecked;
  }

  Widget _getBody() {
    final icon = DgIconCheckbox(size: iconSize, variant: _getIconVariant());
    TextStyle textStyleInner;
    if(textStyle == null) {
      textStyleInner = DgText.modal1.copyWith(color: DgColor.textBodySecondary);
    } else {
      textStyleInner = textStyle!;
    }
    if (text != null) {
      return Row(
        spacing: DgSpacing.xs,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          Text(text!, style: textStyleInner),
        ],
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: _getBody());
  }
}
