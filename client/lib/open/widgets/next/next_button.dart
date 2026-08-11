import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/next_circular_progress.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

enum NextButtonSize { primary, big }

enum NextButtonStyle { primary, secondary, critical, outlined }

class NextButton extends StatelessWidget {
  final String text;
  final bool loading;
  final Widget? icon;
  final VoidCallback? onTap;
  final NextButtonStyle style;
  final NextButtonSize size;
  final bool disabled;
  final double? width;

  // Internal properties
  final Color backgroundColor;
  final TextStyle textStyle;
  final double height;
  final BorderRadius borderRadius;
  final double padding;
  final Border? border;
  final double spacing;

  const NextButton._({
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
  });

  factory NextButton({
    required String text,
    Key? key,
    NextButtonStyle style = NextButtonStyle.primary,
    NextButtonSize size = NextButtonSize.big,
    VoidCallback? onTap,
    bool loading = false,
    bool disabled = false,
    Widget? icon,
    double? width,
    double? height,
  }) {
    double heightInner;
    BorderRadius borderRadiusInner;
    Color backgroundColorInner;
    TextStyle textStyleInner;
    double paddingInner;
    Border? borderInner;
    double spacingInner = 8;

    // Size variants
    switch (size) {
      case NextButtonSize.big:
        heightInner = height ?? 44;
        borderRadiusInner = BorderRadius.circular(100);
        paddingInner = NextSpacing.lg;
        textStyleInner = NextText.buttonLabelBig;
        break;
      case NextButtonSize.primary:
        heightInner = height ?? 36;
        borderRadiusInner = BorderRadius.circular(8);
        paddingInner = NextSpacing.lg;
        textStyleInner = NextText.buttonLabelPrimary;
        break;
    }

    textStyleInner = textStyleInner.copyWith(color: NextColor.fgWhite100);

    // Style variants (minimal styling for now as requested)
    switch (style) {
      case NextButtonStyle.primary:
        backgroundColorInner = NextColor.bgWhite100;
        textStyleInner = textStyleInner.copyWith(color: NextColor.fgAction);
        break;
      case NextButtonStyle.secondary:
        backgroundColorInner = NextColor.bgWhite10;
        break;
      case NextButtonStyle.critical:
        backgroundColorInner = NextColor.bgCritical;
        break;
      case NextButtonStyle.outlined:
        backgroundColorInner = Colors.transparent;
        borderInner = Border.all(color: NextColor.bgWhite5, width: 1);
        break;
    }

    if (disabled || loading) {
      switch (style) {
        case NextButtonStyle.primary:
          backgroundColorInner = NextColor.bgWhite10;
          textStyleInner = textStyleInner.copyWith(color: NextColor.fgWhite40);
          break;
        case NextButtonStyle.secondary:
          backgroundColorInner = NextColor.bgWhite5;
          textStyleInner = textStyleInner.copyWith(color: NextColor.fgWhite40);
          break;
        case NextButtonStyle.critical:
          backgroundColorInner = NextColor.bgCriticalDisabled;
          textStyleInner = textStyleInner.copyWith(color: NextColor.fgWhite40);
        case NextButtonStyle.outlined:
          textStyleInner = textStyleInner.copyWith(color: NextColor.fgWhite40);
          borderInner = Border.all(color: NextColor.borderDisabled);
      }
    }

    return NextButton._(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !loading && !disabled;
    const duration = Duration(milliseconds: 160);
    const curve = Curves.easeOut;

    return AnimatedContainer(
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
          child: AnimatedPadding(
            duration: duration,
            curve: curve,
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 0),
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
      ),
    );
  }

  List<Widget> _getRow() {
    final List<Widget> children = [];

    if (loading) {
      children.add(NextCircularProgress(color: textStyle.color, size: 16));
      return children;
    } else if (icon != null) {
      children.add(icon!);
    }

    children.add(Flexible(child: Text(text, textAlign: TextAlign.center)));

    return children;
  }
}

@Preview(name: 'Normal', group: 'Big/Primary')
Widget previewBigPrimaryNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.primary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Primary')
Widget previewBigPrimaryLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.primary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Primary')
Widget previewBigPrimaryDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.primary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Big/Secondary')
Widget previewBigSecondaryNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.secondary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Secondary')
Widget previewBigSecondaryLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.secondary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Secondary')
Widget previewBigSecondaryDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.secondary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Big/Critical')
Widget previewBigCriticalNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.critical,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Critical')
Widget previewBigCriticalLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.critical,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Critical')
Widget previewBigCriticalDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.critical,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Big/Outlined')
Widget previewBigOutlinedNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.outlined,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Big/Outlined')
Widget previewBigOutlinedLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.outlined,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big/Outlined')
Widget previewBigOutlinedDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.big,
      style: NextButtonStyle.outlined,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Primary')
Widget previewPrimaryPrimaryNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.primary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Primary')
Widget previewPrimaryPrimaryLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.primary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Primary')
Widget previewPrimaryPrimaryDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.primary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Secondary')
Widget previewPrimarySecondaryNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.secondary,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Secondary')
Widget previewPrimarySecondaryLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.secondary,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Secondary')
Widget previewPrimarySecondaryDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.secondary,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Critical')
Widget previewPrimaryCriticalNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.critical,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Critical')
Widget previewPrimaryCriticalLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.critical,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Critical')
Widget previewPrimaryCriticalDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.critical,
      disabled: true,
    ),
  );
}

@Preview(name: 'Normal', group: 'Primary/Outlined')
Widget previewPrimaryOutlinedNormal() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.outlined,
      onTap: () {},
    ),
  );
}

@Preview(name: 'Loading', group: 'Primary/Outlined')
Widget previewPrimaryOutlinedLoading() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.outlined,
      loading: true,
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary/Outlined')
Widget previewPrimaryOutlinedDisabled() {
  return Center(
    child: NextButton(
      text: 'Button',
      size: NextButtonSize.primary,
      style: NextButtonStyle.outlined,
      disabled: true,
    ),
  );
}
