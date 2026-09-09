import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/spacing.dart';

/// Explains why a location cannot be connected to from this app, and offers the
/// fix when there is one.
Future<void> showMfaUnavailableDialog(
  BuildContext context, {
  required MfaUnpassableReason? reason,
  required int instanceId,
}) => showDialog<void>(
  context: context,
  useSafeArea: false,
  barrierColor: Colors.transparent,
  builder: (_) => _MfaUnavailableDialog(reason: reason, instanceId: instanceId),
);

class _MfaUnavailableDialog extends StatelessWidget {
  final MfaUnpassableReason? reason;
  final int instanceId;

  const _MfaUnavailableDialog({required this.reason, required this.instanceId});

  @override
  Widget build(BuildContext context) {
    final setUpBiometry = reason == MfaUnpassableReason.setUpBiometry;

    return DgDialog(
      onClose: () => Navigator.of(context).pop(),
      children: [
        DgDialogTitle(
          setUpBiometry ? "Biometrics Required" : "Location Not Supported",
        ),
        DgDialogDescription(_description(reason)),
        if (setUpBiometry)
          DgButton(
            text: "Set up biometrics",
            style: DgButtonStyle.primary,
            size: DgButtonSize.big,
            width: double.infinity,
            onTap: () {
              Navigator.of(context).pop();
              BiometrySetupScreenRoute(id: instanceId.toString()).push(context);
            },
          ),
        if (setUpBiometry) const SizedBox(height: DgSpacing.md),
        DgButton(
          text: "Close",
          style: setUpBiometry
              ? DgButtonStyle.secondary
              : DgButtonStyle.primary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  String _description(MfaUnpassableReason? reason) => switch (reason) {
    MfaUnpassableReason.setUpBiometry =>
      "This location requires biometric verification, which is not set up on "
          "this device yet. Enable it to connect.",
    MfaUnpassableReason.notConfigured =>
      "This location requires a verification method you have not configured "
          "yet. Set it up in Defguard, then try again.",
    MfaUnpassableReason.desktopOnly || null =>
      "This location requires a verification method the mobile app cannot "
          "perform. Use the desktop client to connect.",
  };
}
