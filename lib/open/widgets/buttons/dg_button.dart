import 'package:flutter/material.dart';
import 'package:mobile_client/open/widgets/circular_progress.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

import '../icons/dg_icon.dart';

enum DgButtonVariant { primary, secondary }

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
    this.width,
    this.loading = false,
    this.icon,
    this.onTap,
  });

  factory DgButton({
    required text,
    Key? key,
    DgButtonVariant variant = DgButtonVariant.primary,
    DgIcon? icon,
    Color? color,
    Color? iconColor,
    double? spacing,
    double? width,
    TextStyle? textStyle,
    onTap,
    bool loading = false,
    bool disabled = false,
    DgButtonSize size = DgButtonSize.standard,
  }) {
    double height;
    BorderRadius borderRadius;
    Color backgroundColor;
    double spacingInner;
    TextStyle textStyleInner;
    Color textColor;
    Color iconColorInner;
    double padding;

    switch (size) {
      case DgButtonSize.big:
        height = 60;
        borderRadius = BorderRadius.all(Radius.circular(10));
        textStyleInner = DgText.buttonL;
        padding = 48;
        break;
      case DgButtonSize.standard:
        height = 40;
        borderRadius = BorderRadius.all(Radius.circular(10));
        textStyleInner = DgText.buttonS;
        padding = DgSpacing.xs;
        break;
      case DgButtonSize.small:
        height = 32;
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
      height: height,
      borderRadius: borderRadius,
      color: backgroundColor,
      spacing: spacingInner,
      textStyle: textStyleInner.copyWith(color: textColor),
      size: size,
      disabled: disabled,
      padding: padding,
      width: width,
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

  Text _getText() {
    return Text(text, style: textStyle);
  }

  List<Widget> _getRow() {
    if (loading) {
      double progressSize;
      Color iconColor;

      switch (size) {
        case DgButtonSize.big:
          progressSize = 32;
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

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !loading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: disabled ? 0.75 : 1.0,
      child: Material(
        color: color,
        borderRadius: borderRadius,
        child: Ink(
          height: height,
          width: width,
          decoration: _getBoxDecoration(),
          child: InkWell(
            onTap: isInteractive ? onTap : null,
            borderRadius: borderRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: padding),
              child: Row(
                spacing: spacing,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _getRow(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
