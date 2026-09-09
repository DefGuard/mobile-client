import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_method_row.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class MfaSettingsPane extends StatelessWidget {
  final List<MfaStep> steps;
  final List<MfaMethod?> working;
  final List<MfaMethod?> savedPlan;

  final bool biometricAvailable;
  final bool isSaving;
  final void Function(int step, MfaMethod method) onSelected;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const MfaSettingsPane({
    super.key,
    required this.steps,
    required this.working,
    required this.savedPlan,
    required this.biometricAvailable,
    required this.isSaving,
    required this.onSelected,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            spacing: DgSpacing.xl,
            children: [
              DgIconButton(
                icon: 'arrow_big',
                direction: DgIconDirection.left,
                onTap: onBack,
              ),
              Expanded(
                child: Text(
                  "MFA Settings",
                  style: DgText.bodyPrimary600.copyWith(
                    color: DgColor.fgWhite100,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 44, height: 44),
            ],
          ),
        ),
        const SizedBox(height: DgSpacing.xl2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: DgSpacing.xl2,
          children: [
            for (final (index, step) in steps.indexed)
              _StepSection(
                step: step,
                number: index + 1,
                selected: index < working.length ? working[index] : null,
                savedDefault: index < savedPlan.length
                    ? savedPlan[index]
                    : null,
                biometricAvailable: biometricAvailable,
                onSelected: (method) => onSelected(index, method),
              ),
          ],
        ),
        const SizedBox(height: DgSpacing.xl4),
        DgButton(
          text: "Save changes",
          size: DgButtonSize.big,
          style: DgButtonStyle.primary,
          loading: isSaving,
          onTap: onSave,
        ),
      ],
    );
  }
}

class _StepSection extends StatelessWidget {
  final MfaStep step;
  final int number;
  final MfaMethod? selected;
  final MfaMethod? savedDefault;
  final bool biometricAvailable;
  final ValueChanged<MfaMethod> onSelected;

  const _StepSection({
    required this.step,
    required this.number,
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
        Text(
          "Step $number",
          style: DgText.bodySm400.copyWith(color: DgColor.fgWhite60),
        ),
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
