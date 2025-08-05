import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/circular_progress.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../icons/dg_icon.dart';

enum DgButtonVariant { primary, secondary, alert }

enum DgButtonSize { big, standard, small }

class DgButton extends StatelessWidget {
  final String text;
  final bool loading;
  final Widget? icon;
  final GestureTapCallback? onTap;
  final Color color;
  final BorderRadius borderRadius;
  final DgButtonVariant variant;
  final DgButtonSize size;
  final double height;
  final double? width;
  final double spacing;
  final TextStyle textStyle;
  final bool disabled;
  final double padding;
  final double? minWidth;

  const DgButton._({
    super.key,
    required this.text,
    required this.variant,
    required this.height,
    required this.borderRadius,
    required this.color,
    required this.spacing,
    required this.textStyle,
    required this.size,
    required this.disabled,
    required this.padding,
    this.minWidth,
    this.width,
    this.loading = false,
    this.icon,
    this.onTap,
  });

  factory DgButton({
    required String text,
    Key? key,
    DgButtonVariant variant = DgButtonVariant.secondary,
    DgIcon? icon,
    Color? color,
    Color? iconColor,
    double? spacing,
    double? width,
    double? height,
    TextStyle? textStyle,
    double? minWidth,
    onTap,
    bool loading = false,
    bool disabled = false,
    DgButtonSize size = DgButtonSize.standard,
  }) {
    double heightInner;
    BorderRadius borderRadius;
    Color backgroundColor;
    double spacingInner;
    TextStyle textStyleInner;
    Color textColor;
    Color iconColorInner;
    double padding;

    switch (size) {
      case DgButtonSize.big:
        heightInner = 60;
        borderRadius = BorderRadius.all(Radius.circular(10));
        textStyleInner = DgText.buttonL;
        padding = 48;
        break;
      case DgButtonSize.standard:
        heightInner = 40;
        borderRadius = BorderRadius.all(Radius.circular(10));
        textStyleInner = DgText.buttonS;
        padding = DgSpacing.xs;
        break;
      case DgButtonSize.small:
        heightInner = 32;
        borderRadius = BorderRadius.all(Radius.circular(8));
        textStyleInner = DgText.buttonXS;
        padding = DgSpacing.xs;
        break;
    }
    if (textStyle != null) {
      textStyleInner = textStyle;
    }
    switch (variant) {
      case DgButtonVariant.primary:
        if (color == null) {
          backgroundColor = DgColor.mainPrimary;
        } else {
          backgroundColor = color;
        }
        textColor = DgColor.textButtonSecondary;
        iconColorInner = DgColor.iconSecondary;
        break;
      case DgButtonVariant.secondary:
        if (color == null) {
          if (size == DgButtonSize.big) {
            backgroundColor = DgColor.button;
          } else {
            backgroundColor = DgColor.defaultModal;
          }
        } else {
          backgroundColor = color;
        }
        iconColorInner = DgColor.iconPrimary;
        textColor = DgColor.textButtonPrimary;
        break;
      case DgButtonVariant.alert:
        if (color == null) {
          backgroundColor = DgColor.alertPrimary;
        } else {
          backgroundColor = color;
        }
        iconColorInner = DgColor.iconSecondary;
        textColor = DgColor.textButtonSecondary;
        break;
    }
    if (spacing == null) {
      if (size == DgButtonSize.small) {
        spacingInner = 13;
      } else {
        spacingInner = DgSpacing.xs;
      }
    } else {
      spacingInner = spacing;
    }
    // Set text style
    return DgButton._(
      text: text,
      key: key,
      variant: variant,
      loading: loading,
      icon: icon?.copyWith(color: iconColor ?? iconColorInner),
      onTap: onTap,
      height: height ?? heightInner,
      borderRadius: borderRadius,
      color: backgroundColor,
      spacing: spacingInner,
      textStyle: textStyleInner.copyWith(color: textColor),
      size: size,
      disabled: disabled,
      padding: padding,
      width: width,
      minWidth: minWidth,
    );
  }

  BoxDecoration? _getBoxDecoration() {
    if (variant == DgButtonVariant.secondary) {
      return BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(width: 1, color: DgColor.borderPrimary),
      );
    }
    return null;
  }

  Widget _getText() {
    return Flexible(
      fit: FlexFit.loose,
      child: Text(text, style: textStyle, textAlign: TextAlign.center),
    );
  }

  List<Widget> _getRow() {
    if (loading) {
      double progressSize;
      Color iconColor;

      switch (size) {
        case DgButtonSize.big:
          progressSize = 22;
          break;
        case DgButtonSize.standard || DgButtonSize.small:
          progressSize = 18;
          break;
      }
      switch (variant) {
        case DgButtonVariant.primary:
          iconColor = DgColor.iconSecondary;
          break;
        case DgButtonVariant.secondary:
          iconColor = DgColor.iconPrimary;
          break;
        case DgButtonVariant.alert:
          iconColor = DgColor.iconSecondary;
          break;
      }
      return [
        DgCircularProgress(size: progressSize, color: iconColor),
        _getText(),
      ];
    }
    if (icon != null) {
      return [?icon, _getText()];
    }
    return [_getText()];
  }

  BoxConstraints? _getConstrains() {
    if (minWidth != null) {
      return BoxConstraints(minWidth: minWidth!, minHeight: height);
    }
    return BoxConstraints(minHeight: height);
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !loading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: disabled ? 0.75 : 1.0,
      child: Material(
        color: color,
        borderRadius: borderRadius,
        child: Container(
          constraints: _getConstrains(),
          width: width,
          child: Ink(
            decoration: _getBoxDecoration(),
            child: InkWell(
              onTap: isInteractive ? onTap : null,
              borderRadius: borderRadius,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: padding,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    spacing: spacing,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _getRow(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
