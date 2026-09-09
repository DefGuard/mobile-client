import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/open/widgets/dg_mfa_selector.dart';

String availabilityNote(MfaMethodAvailability availability) =>
    switch (availability) {
      MfaMethodAvailability.usable => "",
      MfaMethodAvailability.notConfigured => "Not configured",
      MfaMethodAvailability.biometryUnavailable => "Not set up",
      MfaMethodAvailability.unsupported => "Desktop only",
    };

Widget mfaMethodRow({
  required MfaStepMethod entry,
  required bool biometricAvailable,
  required MfaMethod? selected,
  required MfaMethod? savedDefault,
  required ValueChanged<MfaMethod> onSelected,
}) {
  final availability = mfaMethodAvailability(
    entry,
    biometricAvailable: biometricAvailable,
  );
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
