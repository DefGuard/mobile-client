import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_unavailable_dialog.dart';
import 'package:mobile/open/screens/mfa/mfa_settings_screen.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_mfa_selector.dart';
import 'package:mobile/open/widgets/dg_toggle.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

const String _multiStepDescription =
    "This location uses multi-step MFA verification. You can use the current "
    "settings or change the default verification methods for each step.";

class ConnectDialog extends HookConsumerWidget {
  final DefguardInstance instance;
  final Location location;
  final Future<ConnectResult> Function(
    RoutingMethod traffic,
    List<MfaMethod?> mfaPlan,
  )
  onConnect;

  const ConnectDialog({
    super.key,
    required this.instance,
    required this.location,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricsStatus = ref.watch(biometricsCapabilityProvider);
    final biometricAvailable =
        instance.mfaKeysStored && biometricsStatus.canOpenStorage;
    final steps = effectiveMfaSteps(location);

    final bool canChangeTraffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.none;
    final bool initialAllTraffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.forceAllTraffic ||
        (canChangeTraffic && location.trafficMethod == RoutingMethod.all);

    final allTraffic = useState(initialAllTraffic);
    final isLoading = useState(false);

    // Set by the MFA settings screen, which pops the plan it saved. The sheet
    // is handed a prebuilt widget, so it never sees the drift row change.
    final savedPlan = useState<List<MfaMethod?>>(location.mfaStepPlan);

    // The single-step picker's working choice, which is not a default until the
    // connect succeeds.
    final selection = useState<MfaMethod?>(null);

    final plan = useMemoized(
      () => resolveMfaStepPlan(
        location.copyWith(mfaStepPlan: savedPlan.value),
        oneOff: selection.value == null ? const [] : [selection.value],
        biometricAvailable: biometricAvailable,
      ),
      [location, savedPlan.value, selection.value, biometricAvailable],
    );

    final unpassable = plan.contains(null);
    final canEditDefaults =
        steps.length > 1 &&
        steps.any(
          (step) =>
              usableMfaMethods(
                step,
                biometricAvailable: biometricAvailable,
              ).length >
              1,
        );

    Future<void> openMfaSettings() async {
      final result = await Navigator.of(context).push<List<MfaMethod?>>(
        MaterialPageRoute(
          builder: (_) => MfaSettingsScreen(
            location: location,
            savedPlan: savedPlan.value,
            biometricAvailable: biometricAvailable,
          ),
        ),
      );
      if (result != null) savedPlan.value = result;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Connect ${location.name} location",
          style: DgText.bodyPrimary600.copyWith(color: DgColor.fgWhite100),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 16),
          child: Divider(height: 1, color: DgColor.bgWhite10),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canChangeTraffic
              ? () => allTraffic.value = !allTraffic.value
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  allTraffic.value ? "All traffic" : "Predefined traffic only",
                  style: DgText.bodySm400.copyWith(color: DgColor.fgWhite100),
                ),
                DgToggle(value: allTraffic.value),
              ],
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
              savedDefault: savedPlan.value.isEmpty
                  ? null
                  : savedPlan.value.first,
              biometricAvailable: biometricAvailable,
              onSelected: (method) => selection.value = method,
            ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: DgSpacing.xl2),
          child: Divider(height: 1, color: DgColor.bgWhite10),
        ),
        DgButton(
          text: "Connect VPN",
          size: DgButtonSize.big,
          style: DgButtonStyle.primary,
          loading: isLoading.value,
          onTap: unpassable
              ? () => showMfaUnavailableDialog(
                  context,
                  reason: unpassableStepReason(
                    location,
                    biometricAvailable: biometricAvailable,
                  ),
                  instanceId: instance.id,
                )
              : () async {
                  isLoading.value = true;
                  try {
                    final traffic = allTraffic.value
                        ? RoutingMethod.all
                        : RoutingMethod.predefined;

                    final result = await onConnect(traffic, plan);
                    if (context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  } finally {
                    isLoading.value = false;
                  }
                },
        ),
        if (canEditDefaults) ...[
          const SizedBox(height: DgSpacing.md),
          DgButton(
            text: "Change default MFA methods",
            size: DgButtonSize.big,
            style: DgButtonStyle.secondary,
            onTap: openMfaSettings,
          ),
        ],
      ],
    );
  }
}

/// The resolved plan for a multi-step flow. Read-only: methods change through
/// the MFA settings screen, not here.
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
          padding: const EdgeInsets.only(bottom: DgSpacing.sm),
          child: Text(
            _multiStepDescription,
            style: DgText.bodyXs400.copyWith(color: DgColor.fgWhite60),
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

/// One radio group, for a single-step location. Selecting a method here also
/// makes it that step's default, which is how it worked before multi-step.
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

String availabilityNote(MfaMethodAvailability availability) =>
    switch (availability) {
      MfaMethodAvailability.usable => "",
      MfaMethodAvailability.notConfigured => "Not configured",
      MfaMethodAvailability.biometryUnavailable => "Not set up",
      MfaMethodAvailability.unsupported => "Desktop only",
    };
