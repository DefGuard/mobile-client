import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';

/// Explains why a location cannot be connected to from this app.
Future<void> showMfaUnavailableDialog(
  BuildContext context, {
  required MfaUnpassableReason? reason,
  required bool biometryRegistered,
}) => showDialog<void>(
  context: context,
  useSafeArea: false,
  barrierColor: Colors.transparent,
  builder: (_) => _MfaUnavailableDialog(
    reason: reason,
    biometryRegistered: biometryRegistered,
  ),
);

class _MfaUnavailableDialog extends StatelessWidget {
  final MfaUnpassableReason? reason;
  final bool biometryRegistered;

  const _MfaUnavailableDialog({
    required this.reason,
    required this.biometryRegistered,
  });

  @override
  Widget build(BuildContext context) {
    return DgDialog(
      onClose: () => Navigator.of(context).pop(),
      children: [
        DgDialogTitle(switch (reason) {
          .setUpBiometry => "Biometrics Required",
          .registerSecurityKey => "Security Key Required",
          _ => "Location Not Supported",
        }),
        DgDialogDescription(_description(reason)),
        DgButton(
          text: "Close",
          style: DgButtonStyle.primary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  String _description(MfaUnpassableReason? reason) => switch (reason) {
    MfaUnpassableReason.setUpBiometry when biometryRegistered =>
      "This location requires biometric verification, but biometrics are not "
          "available on this device right now. Check your system biometric "
          "settings, then try again.",
    MfaUnpassableReason.setUpBiometry =>
      "This location requires biometric verification, which can only be "
          "enabled while adding an instance. Add this instance again and "
          "enable biometrics during setup.",
    MfaUnpassableReason.registerSecurityKey =>
      "This location requires a hardware security key. Register a certified "
          "key from the Defguard desktop client, then try again.",
    MfaUnpassableReason.notConfigured =>
      "This location requires a verification method you have not configured "
          "yet. Set it up in Defguard, then try again.",
    MfaUnpassableReason.desktopOnly || null =>
      "This location requires a verification method the mobile app cannot "
          "perform. Use the desktop client to connect.",
  };
}
