import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/dg_circular_progress.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

enum DgButtonSize { primary, big }

enum DgButtonStyle { primary, secondary, critical, outlined }

class DgButton extends StatelessWidget {
  final String text;
  final bool loading;
  final Widget? icon;
  final VoidCallback? onTap;
  final DgButtonStyle style;
  final DgButtonSize size;
  final bool disabled;
  final double? width;
  final String? identifier;

  final Color backgroundColor;
  final TextStyle textStyle;
  final double height;
  final BorderRadius borderRadius;
  final double padding;
  final Border? border;
  final double spacing;

  const DgButton._({
    super.key,
    required this.text,
    required this.style,
    required this.size,
    required this.backgroundColor,
    required this.textStyle,
    required this.height,
    required this.borderRadius,
    required this.padding,
    required this.spacing,
    this.border,
    this.onTap,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.width,
    this.identifier,
  });

  factory DgButton({
    required String text,
    Key? key,
    DgButtonStyle style = DgButtonStyle.primary,
    DgButtonSize size = DgButtonSize.big,
    VoidCallback? onTap,
    bool loading = false,
    bool disabled = false,
    Widget? icon,
    double? width,
    double? height,
    String? identifier,
  }) {
    double heightInner;
    BorderRadius borderRadiusInner;
    Color backgroundColorInner;
    TextStyle textStyleInner;
    double paddingInner;
    Border? borderInner;
    double spacingInner = 8;

    switch (size) {
      case DgButtonSize.big:
        heightInner = height ?? 44;
        borderRadiusInner = BorderRadius.circular(100);
        paddingInner = DgSpacing.lg;
        textStyleInner = DgText.buttonLabelBig;
        break;
      case DgButtonSize.primary:
        heightInner = height ?? 36;
        borderRadiusInner = BorderRadius.circular(8);
        paddingInner = DgSpacing.lg;
        textStyleInner = DgText.buttonLabelPrimary;
        break;
    }

    textStyleInner = textStyleInner.copyWith(color: DgColor.fgWhite100);

    switch (style) {
      case DgButtonStyle.primary:
        backgroundColorInner = DgColor.bgWhite100;
        textStyleInner = textStyleInner.copyWith(color: DgColor.fgAction);
        break;
      case DgButtonStyle.secondary:
        backgroundColorInner = DgColor.bgWhite10;
        break;
      case DgButtonStyle.critical:
        backgroundColorInner = DgColor.bgCritical;
        break;
      case DgButtonStyle.outlined:
        backgroundColorInner = Colors.transparent;
        borderInner = Border.all(color: DgColor.bgWhite5, width: 1);
        break;
    }

    if (disabled || loading) {
      switch (style) {
        case DgButtonStyle.primary:
          backgroundColorInner = DgColor.bgWhite10;
          textStyleInner = textStyleInner.copyWith(color: DgColor.fgWhite40);
          break;
        case DgButtonStyle.secondary:
          backgroundColorInner = DgColor.bgWhite5;
          textStyleInner = textStyleInner.copyWith(color: DgColor.fgWhite40);
          break;
        case DgButtonStyle.critical:
          backgroundColorInner = DgColor.bgCriticalDisabled;
          textStyleInner = textStyleInner.copyWith(color: DgColor.fgWhite40);
        case DgButtonStyle.outlined:
          textStyleInner = textStyleInner.copyWith(color: DgColor.fgWhite40);
          borderInner = Border.all(color: DgColor.borderDisabled);
      }
    }

    return DgButton._(
      key: key,
      text: text,
      style: style,
      size: size,
      backgroundColor: backgroundColorInner,
      textStyle: textStyleInner,
      height: height ?? heightInner,
      borderRadius: borderRadiusInner,
      padding: paddingInner,
      spacing: spacingInner,
      border: borderInner,
      onTap: onTap,
      loading: loading,
      disabled: disabled,
      icon: icon,
      width: width,
      identifier: identifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !loading && !disabled;
    const duration = Duration(milliseconds: 160);
    const curve = Curves.easeOut;

    final button = AnimatedContainer(
      duration: duration,
      curve: curve,
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onTap : null,
          borderRadius: borderRadius,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: duration,
                curve: curve,
                opacity: loading ? 0.0 : 1.0,
                child: AnimatedPadding(
                  duration: duration,
                  curve: curve,
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: 0,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: curve,
                    style: textStyle,
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
              if (loading) DgCircularProgress(color: textStyle.color, size: 16),
            ],
          ),
        ),
      ),
    );

    if (identifier == null) {
      return button;
    }

    return Semantics(identifier: identifier, child: button);
  }

  List<Widget> _getRow() {
    final List<Widget> children = [];

    if (icon != null) {
      children.add(icon!);
    }

    children.add(Flexible(child: Text(text, textAlign: TextAlign.center)));

    return children;
  }
}

@Preview(name: 'Normal', group: 'Big/Primary')
Widget previewBigPrimaryNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.primary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Primary')
Widget previewBigPrimaryLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.primary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Primary')
Widget previewBigPrimaryDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.primary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Big/Secondary')
Widget previewBigSecondaryNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.secondary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Secondary')
Widget previewBigSecondaryLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.secondary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Secondary')
Widget previewBigSecondaryDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.secondary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Big/Critical')
Widget previewBigCriticalNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.critical,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Critical')
Widget previewBigCriticalLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.critical,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Critical')
Widget previewBigCriticalDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.critical,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Big/Outlined')
Widget previewBigOutlinedNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.outlined,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Outlined')
Widget previewBigOutlinedLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.outlined,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Outlined')
Widget previewBigOutlinedDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.big,
      style: DgButtonStyle.outlined,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Primary')
Widget previewPrimaryPrimaryNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.primary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Primary')
Widget previewPrimaryPrimaryLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.primary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Primary')
Widget previewPrimaryPrimaryDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.primary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Secondary')
Widget previewPrimarySecondaryNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.secondary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Secondary')
Widget previewPrimarySecondaryLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.secondary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Secondary')
Widget previewPrimarySecondaryDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.secondary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Critical')
Widget previewPrimaryCriticalNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.critical,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Critical')
Widget previewPrimaryCriticalLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.critical,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Critical')
Widget previewPrimaryCriticalDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.critical,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Outlined')
Widget previewPrimaryOutlinedNormal() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.outlined,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Outlined')
Widget previewPrimaryOutlinedLoading() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.outlined,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Outlined')
Widget previewPrimaryOutlinedDisabled() {
  return DgPreviewWrapper(
    child: DgButton(
      text: 'Button',
      size: DgButtonSize.primary,
      style: DgButtonStyle.outlined,
      disabled: true,
    ),
  );
}
