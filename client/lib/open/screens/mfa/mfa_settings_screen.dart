import 'package:drift/drift.dart' show Value;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/open/screens/instance/widgets/connect_dialog.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_mfa_selector.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

/// Edits a location's default method for each MFA step. Pops the saved plan so
/// the connect sheet, which holds a prebuilt widget and never sees the drift
/// row change, can pick it up.
class MfaSettingsScreen extends HookConsumerWidget {
  final Location location;
  final List<MfaMethod?> savedPlan;
  final bool biometricAvailable;

  const MfaSettingsScreen({
    super.key,
    required this.location,
    required this.savedPlan,
    required this.biometricAvailable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = effectiveMfaSteps(location);
    final toaster = ref.read(toastManagerProvider.notifier);
    final isSaving = useState(false);

    // The radio follows the working plan; the Default badge follows the plan as
    // it is stored right now.
    final working = useState<List<MfaMethod?>>(
      resolveMfaStepPlan(
        location.copyWith(mfaStepPlan: savedPlan),
        biometricAvailable: biometricAvailable,
      ),
    );

    Future<void> save() async {
      isSaving.value = true;
      final navigator = Navigator.of(context);
      final plan = working.value;
      try {
        await (ref
                .read(databaseProvider)
                .update(
                  ref.read(databaseProvider).locations,
                )
              ..where((t) => t.id.equals(location.id)))
            .write(
              LocationsCompanion(mfaStepPlan: Value(plan)),
            );
        if (navigator.mounted) navigator.pop(plan);
      } catch (e) {
        toaster.showError(
          message: "Failed to save the MFA settings.",
          logMessage: "Failed to write mfaStepPlan for location ${location.id}",
          error: e,
        );
        isSaving.value = false;
      }
    }

    return Container(
      decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DgAppBar(
          context: context,
          showLogo: false,
          title: "MFA Settings",
          actionLeft: DgIconButton(
            icon: 'arrow_small',
            direction: DgIconDirection.left,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: DgSpacing.xl),
                    itemCount: steps.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DgSpacing.xl2),
                    itemBuilder: (context, index) => _StepSection(
                      step: steps[index],
                      number: index + 1,
                      selected: working.value[index],
                      savedDefault: index < savedPlan.length
                          ? savedPlan[index]
                          : null,
                      biometricAvailable: biometricAvailable,
                      onSelected: (method) {
                        final next = [...working.value];
                        next[index] = method;
                        working.value = next;
                      },
                    ),
                  ),
                ),
                DgButton(
                  text: "Save changes",
                  size: DgButtonSize.big,
                  style: DgButtonStyle.primary,
                  loading: isSaving.value,
                  onTap: save,
                ),
              ],
            ),
          ),
        ),
      ),
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
          _row(
            entry,
            mfaMethodAvailability(
              entry,
              biometricAvailable: biometricAvailable,
            ),
          ),
      ],
    );
  }

  Widget _row(MfaStepMethod entry, MfaMethodAvailability availability) {
    final usable = availability == MfaMethodAvailability.usable;
    return DgMfaSelector(
      active: usable && entry.method == selected,
      factor: entry.method,
      label: entry.method == null ? entry.apiMethod.unsupportedLabel : null,
      disabled: !usable,
      isDefault: usable && entry.method == savedDefault,
      onTap: usable ? () => onSelected(entry.method!) : null,
      trailing: usable
          ? const DgMfaSelectorTrailing.radio()
          : DgMfaSelectorTrailing.note(availabilityNote(availability)),
    );
  }
}
