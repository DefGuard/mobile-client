import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/open/widgets/next/next_radio_indicator.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

class NextMfaSelector extends StatelessWidget {
  final bool active;
  final MfaMethod factor;
  final VoidCallback? onTap;
  final bool disabled;

  const NextMfaSelector({
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
    if (disabled) return NextColor.fgDisabled;
    return active ? NextColor.fgWhite100 : NextColor.fgWhite80;
  }

  String get getLabel => factor.toUiString();

  Color get getLabelColor {
    if (disabled) return NextColor.fgDisabled;
    return active ? NextColor.fgWhite100 : NextColor.fgWhite80;
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
          color: active ? NextColor.bgWhite10 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NextColor.bgWhite10, width: 1),
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: duration,
          curve: curve,
          tween: ColorTween(end: contentColor),
          builder: (context, color, child) {
            final effectiveColor = color ?? contentColor;
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: NextSpacing.md,
              children: [
                NextIcon(getIcon, size: 20, color: effectiveColor),
                Expanded(
                  child: Text(
                    getLabel,
                    style: NextText.bodySm400.copyWith(color: effectiveColor),
                  ),
                ),
                NextRadioIndicator(value: active, size: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

@Preview(name: 'NextMfaSelector States', group: 'NextMfaSelector')
Widget previewNextMfaSelector() {
  return NextPreviewWrapper(
    child: Padding(
      padding: const EdgeInsets.all(NextSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: NextSpacing.md,
        children: [
          NextMfaSelector(active: true, factor: MfaMethod.totp, onTap: () {}),
          NextMfaSelector(active: false, factor: MfaMethod.totp, onTap: () {}),
          NextMfaSelector(active: false, factor: MfaMethod.email, onTap: () {}),
          NextMfaSelector(
            active: false,
            factor: MfaMethod.biometric,
            onTap: () {},
          ),
          NextMfaSelector(
            active: false,
            factor: MfaMethod.openid,
            onTap: () {},
          ),
          NextMfaSelector(
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
