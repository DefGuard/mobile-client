import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/open/widgets/dg_radio_indicator.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

/// What a factor row shows on its right edge.
sealed class DgMfaSelectorTrailing {
  const DgMfaSelectorTrailing();

  /// Selectable row, in a list where the user picks one.
  const factory DgMfaSelectorTrailing.radio() = DgMfaSelectorRadio;

  /// Row that states which step of a multi-step flow it belongs to.
  const factory DgMfaSelectorTrailing.step(int number) = DgMfaSelectorStep;

  /// Row that states why it cannot be used.
  const factory DgMfaSelectorTrailing.note(String text) = DgMfaSelectorNote;
}

class DgMfaSelectorRadio extends DgMfaSelectorTrailing {
  const DgMfaSelectorRadio();
}

class DgMfaSelectorStep extends DgMfaSelectorTrailing {
  final int number;

  const DgMfaSelectorStep(this.number);
}

class DgMfaSelectorNote extends DgMfaSelectorTrailing {
  final String text;

  const DgMfaSelectorNote(this.text);
}

class DgMfaSelector extends StatelessWidget {
  final bool active;

  /// Null for a factor this client cannot perform, which [label] then names.
  final MfaMethod? factor;
  final VoidCallback? onTap;
  final bool disabled;

  /// Names a factor with no [MfaMethod], and overrides the label otherwise.
  final String? label;

  /// Marks the row as the saved default for its step.
  final bool isDefault;

  final DgMfaSelectorTrailing trailing;

  const DgMfaSelector({
    super.key,
    required this.active,
    required this.factor,
    this.onTap,
    this.disabled = false,
    this.label,
    this.isDefault = false,
    this.trailing = const DgMfaSelectorTrailing.radio(),
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
      case null:
        return 'key';
    }
  }

  Color get getIconColor {
    if (disabled) return DgColor.fgDisabled;
    return active ? DgColor.fgWhite100 : DgColor.fgWhite80;
  }

  String get getLabel => label ?? factor?.toUiString() ?? 'Unsupported method';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              spacing: DgSpacing.md,
              children: [
                DgIcon(getIcon, size: 20, color: effectiveColor),
                Expanded(
                  child: Row(
                    spacing: DgSpacing.md,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          getLabel,
                          style: DgText.bodySm400.copyWith(
                            color: effectiveColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDefault) const _DefaultBadge(),
                    ],
                  ),
                ),
                _Trailing(trailing: trailing, active: active),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: DgColor.bgWhite10,
      ),
      child: Text(
        "Default",
        style: DgText.bodyXs500.copyWith(color: DgColor.fgWhite80),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  final DgMfaSelectorTrailing trailing;
  final bool active;

  const _Trailing({required this.trailing, required this.active});

  @override
  Widget build(BuildContext context) => switch (trailing) {
    DgMfaSelectorRadio() => DgRadioIndicator(value: active, size: 20),
    DgMfaSelectorStep(:final number) => Text(
      "Step $number",
      style: DgText.bodySm400.copyWith(color: DgColor.fgWhite60),
    ),
    DgMfaSelectorNote(:final text) => Text(
      text,
      style: DgText.bodyXs400.copyWith(color: DgColor.fgDisabled),
    ),
  };
}

@Preview(name: 'DgMfaSelector States', group: 'DgMfaSelector')
Widget previewDgMfaSelector() {
  return DgPreviewWrapper(
    child: Padding(
      padding: const EdgeInsets.all(DgSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: DgSpacing.md,
        children: [
          DgMfaSelector(
            active: true,
            factor: MfaMethod.totp,
            isDefault: true,
            onTap: () {},
          ),
          DgMfaSelector(active: false, factor: MfaMethod.totp, onTap: () {}),
          DgMfaSelector(active: false, factor: MfaMethod.email, onTap: () {}),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.biometric,
            onTap: () {},
          ),
          DgMfaSelector(active: false, factor: MfaMethod.openid, onTap: () {}),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.totp,
            disabled: true,
            trailing: const DgMfaSelectorTrailing.note("Not configured"),
          ),
          DgMfaSelector(
            active: false,
            factor: null,
            label: "Security key",
            disabled: true,
            trailing: const DgMfaSelectorTrailing.note("Desktop only"),
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'DgMfaSelector Steps', group: 'DgMfaSelector')
Widget previewDgMfaSelectorSteps() {
  return DgPreviewWrapper(
    child: Padding(
      padding: const EdgeInsets.all(DgSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: DgSpacing.md,
        children: const [
          DgMfaSelector(
            active: false,
            factor: MfaMethod.totp,
            trailing: DgMfaSelectorTrailing.step(1),
          ),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.biometric,
            trailing: DgMfaSelectorTrailing.step(2),
          ),
          DgMfaSelector(
            active: false,
            factor: MfaMethod.email,
            trailing: DgMfaSelectorTrailing.step(3),
          ),
        ],
      ),
    ),
  );
}
