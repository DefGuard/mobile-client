import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_method_row.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_mfa_selector.dart';
import 'package:mobile/open/widgets/dg_toggle.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

const String _multiStepDescription =
    "This location uses multi-step MFA verification. You can use the current "
    "settings or change the default verification methods for each step.";

class ConnectPane extends StatelessWidget {
  final String locationName;
  final List<MfaStep> steps;
  final List<MfaMethod?> plan;

  final List<MfaMethod?> savedPlan;
  final bool biometricAvailable;
  final bool allTraffic;
  final bool canChangeTraffic;
  final bool isLoading;
  final bool canEditDefaults;
  final VoidCallback onToggleTraffic;
  final ValueChanged<MfaMethod> onMethodSelected;
  final VoidCallback onConnectTap;
  final VoidCallback onOpenMfaSettings;

  const ConnectPane({
    super.key,
    required this.locationName,
    required this.steps,
    required this.plan,
    required this.savedPlan,
    required this.biometricAvailable,
    required this.allTraffic,
    required this.canChangeTraffic,
    required this.isLoading,
    required this.canEditDefaults,
    required this.onToggleTraffic,
    required this.onMethodSelected,
    required this.onConnectTap,
    required this.onOpenMfaSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Connect $locationName location",
          style: DgText.bodyPrimary600.copyWith(color: DgColor.fgWhite100),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 16),
          child: Divider(height: 1, color: DgColor.bgWhite10),
        ),
        Semantics(
          identifier: allTraffic
              ? "traffic_mode_all"
              : "traffic_mode_predefined",
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canChangeTraffic ? onToggleTraffic : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    allTraffic ? "All traffic" : "Predefined traffic only",
                    style: DgText.bodySm400.copyWith(color: DgColor.fgWhite100),
                  ),
                  DgToggle(value: allTraffic),
                ],
              ),
            ),
          ),
        ),
        if (steps.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: DgColor.bgWhite10, height: 1),
          ),
          Text(
            "Multi-Factor Authentication",
            style: DgText.bodySm400.copyWith(color: DgColor.fgWhite60),
          ),
          const SizedBox(height: DgSpacing.md),
          if (steps.length > 1)
            _StepSummary(steps: steps, plan: plan)
          else
            _MethodPicker(
              step: steps.single,
              selected: plan.single,
              savedDefault: savedPlan.isEmpty ? null : savedPlan.first,
              biometricAvailable: biometricAvailable,
              onSelected: onMethodSelected,
            ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: DgSpacing.xl2),
          child: Divider(height: 1, color: DgColor.bgWhite10),
        ),
        DgButton(
          identifier: "connect_vpn_submit",
          text: "Connect VPN",
          size: DgButtonSize.big,
          style: DgButtonStyle.primary,
          loading: isLoading,
          onTap: onConnectTap,
        ),
        if (canEditDefaults) ...[
          const SizedBox(height: DgSpacing.md),
          DgButton(
            text: "Change default MFA methods",
            size: DgButtonSize.big,
            style: DgButtonStyle.secondary,
            onTap: onOpenMfaSettings,
          ),
        ],
      ],
    );
  }
}

class _StepSummary extends StatelessWidget {
  final List<MfaStep> steps;
  final List<MfaMethod?> plan;

  const _StepSummary({required this.steps, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: DgSpacing.md,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            _multiStepDescription,
            style: DgText.bodyXs400.copyWith(color: DgColor.fgWhite80),
          ),
        ),
        for (final (index, step) in steps.indexed)
          DgMfaSelector(
            active: false,
            factor: plan[index],
            label: plan[index] == null ? _unusableLabel(step) : null,
            disabled: plan[index] == null,
            trailing: DgMfaSelectorTrailing.step(index + 1),
          ),
      ],
    );
  }

  String _unusableLabel(MfaStep step) {
    final entries = pickableMfaMethods(step);
    if (entries.isEmpty) return "No method available";
    return entries.first.method?.toUiString() ??
        entries.first.apiMethod.unsupportedLabel;
  }
}

class _MethodPicker extends StatelessWidget {
  final MfaStep step;
  final MfaMethod? selected;
  final MfaMethod? savedDefault;
  final bool biometricAvailable;
  final ValueChanged<MfaMethod> onSelected;

  const _MethodPicker({
    required this.step,
    required this.selected,
    required this.savedDefault,
    required this.biometricAvailable,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: DgSpacing.md,
      children: [
        for (final entry in pickableMfaMethods(step))
          mfaMethodRow(
            entry: entry,
            biometricAvailable: biometricAvailable,
            selected: selected,
            savedDefault: savedDefault,
            onSelected: onSelected,
          ),
      ],
    );
  }
}
