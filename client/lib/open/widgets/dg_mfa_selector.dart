import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/open/widgets/dg_radio_indicator.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class DgMfaSelector extends StatelessWidget {
  final bool active;
  final MfaMethod factor;
  final VoidCallback? onTap;
  final bool disabled;

  const DgMfaSelector({
    super.key,
    required this.active,
    required this.factor,
    this.onTap,
    this.disabled = false,
  });

  String get getIcon {
    switch (factor) {
      case MfaMethod.totp:
        return 'mobile_lock';
      case MfaMethod.email:
        return 'mail';
      case MfaMethod.biometric:
        return 'biometric';
      case MfaMethod.openid:
        return 'globe';
    }
  }

  Color get getIconColor {
    if (disabled) return DgColor.fgDisabled;
    return active ? DgColor.fgWhite100 : DgColor.fgWhite80;
  }

  String get getLabel => factor.toUiString();

  Color get getLabelColor {
    if (disabled) return DgColor.fgDisabled;
    return active ? DgColor.fgWhite100 : DgColor.fgWhite80;
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = getLabelColor;
    const duration = Duration(milliseconds: 200);
    const curve = Curves.easeOut;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        constraints: BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        decoration: BoxDecoration(
          color: active ? DgColor.bgWhite10 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DgColor.bgWhite10, width: 1),
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: duration,
          curve: curve,
          tween: ColorTween(end: contentColor),
          builder: (context, color, child) {
            final effectiveColor = color ?? contentColor;
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: DgSpacing.md,
              children: [
                DgIcon(getIcon, size: 20, color: effectiveColor),
                Expanded(
                  child: Text(
                    getLabel,
                    style: DgText.bodySm400.copyWith(color: effectiveColor),
                  ),
                ),
                DgRadioIndicator(value: active, size: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

@Preview(name: 'DgMfaSelector States', group: 'DgMfaSelector')
Widget previewNextMfaSelector() {
  return DgPreviewWrapper(
    child: Padding(
      padding: const EdgeInsets.all(DgSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: DgSpacing.md,
        children: [
          DgMfaSelector(active: true, factor: MfaMethod.totp, onTap: () {}),
          DgMfaSelector(active: false, factor: MfaMethod.totp, onTap: () {}),
          DgMfaSelector(active: false, factor: MfaMethod.email, onTap: () {}),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.biometric,
            onTap: () {},
          ),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.openid,
            onTap: () {},
          ),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.totp,
            disabled: true,
            onTap: () {},
          ),
        ],
      ),
    ),
  );
}
