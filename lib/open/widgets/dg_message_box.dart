import 'package:flutter/material.dart';
import 'package:mobile_client/open/widgets/icons/icon_info.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

enum DgMessageBoxVariant { info, infoOutlined, important, alert }

class DgMessageBox extends StatelessWidget {
  final double? width;
  final String text;
  final TextStyle textStyle;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final DgMessageBoxVariant variant;

  const DgMessageBox._({
    super.key,
    this.width,
    required this.text,
    required this.textStyle,
    required this.borderColor,
    required this.borderWidth,
    required this.backgroundColor,
    required this.variant,
  });

  factory DgMessageBox({
    Key? key,
    width,
    required text,
    DgMessageBoxVariant variant = DgMessageBoxVariant.info,
  }) {
    TextStyle textStyle;
    Color borderColor;
    Color backgroundColor;
    double borderWidth;

    switch (variant) {
      case DgMessageBoxVariant.info:
        textStyle = DgText.modal1.copyWith(color: DgColor.textBodySecondary);
        borderColor = DgColor.iconPrimary;
        borderWidth = 1;
        backgroundColor = DgColor.frameBg;
        break;
      case DgMessageBoxVariant.infoOutlined:
        textStyle = DgText.modal1.copyWith(color: DgColor.textBodySecondary);
        borderColor = Color.fromRGBO(0, 0, 0, 0);
        borderWidth = 0;
        backgroundColor = DgColor.infoModal;
      default:
        throw UnimplementedError(
          "Messagebox variant $variant is unimplemented !",
        );
    }
    return DgMessageBox._(
      key: key,
      width: width,
      text: text,
      borderColor: borderColor,
      textStyle: textStyle,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      variant: variant,
    );
  }

  Widget getIcon() {
    final DgIconInfoVariant iconVariant;
    switch (variant) {
      case DgMessageBoxVariant.info || DgMessageBoxVariant.infoOutlined:
        iconVariant = DgIconInfoVariant.info;
        break;
      case DgMessageBoxVariant.alert:
        iconVariant = DgIconInfoVariant.alert;
        break;
      case DgMessageBoxVariant.important:
        iconVariant = DgIconInfoVariant.important;
        break;
    }
    return DgIconInfo(variant: iconVariant, size: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: borderWidth > 0
            ? Border.fromBorderSide(
                BorderSide(width: borderWidth, color: borderColor),
              )
            : null,
        borderRadius: BorderRadius.circular(10),
        color: backgroundColor,
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.all(DgSpacing.xs),
        child: Row(
          spacing: DgSpacing.s,
          children: [
            Align(alignment: Alignment.center, child: getIcon()),
            Expanded(child: Text(text, style: textStyle)),
          ],
        ),
      ),
    );
  }
}
