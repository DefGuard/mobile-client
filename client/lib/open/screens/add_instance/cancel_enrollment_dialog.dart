import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/theme/spacing.dart';

const String _message =
    "Canceling now will end this enrollment. To add the instance later, you’ll need to start the enrollment again by scanning the QR code or entering the URL and token.";

/// Pops `true` to cancel the enrollment. Dismissing it counts as staying.
class CancelEnrollmentDialog extends StatelessWidget {
  const CancelEnrollmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DgDialog(
      onClose: () => Navigator.of(context).pop(false),
      children: [
        const DgDialogTitle("Cancel enrollment?"),
        const DgDialogDescription(_message),
        DgButton(
          identifier: "cancel_enrollment_confirm",
          text: "Cancel enrollment",
          style: DgButtonStyle.primary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: DgSpacing.md),
        DgButton(
          identifier: "cancel_enrollment_stay",
          text: "Continue enrollment",
          style: DgButtonStyle.secondary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
