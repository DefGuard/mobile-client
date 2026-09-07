import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/theme/spacing.dart';

const String _message =
    "There can be only one active connection at the same time. When connecting to the next location, previous location will be disconnected.";

/// Confirms swapping the active tunnel for another location.
///
/// Pops `true` to proceed and `false` to keep the current connection. Dismissing
/// it - the close button or a tap outside - counts as keeping the connection.
class ConnectionConflictDialog extends StatelessWidget {
  const ConnectionConflictDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DgDialog(
      onClose: () => Navigator.of(context).pop(false),
      children: [
        const DgDialogTitle("Change Active Connection"),
        const DgDialogDescription(_message),
        DgButton(
          text: "Proceed",
          style: DgButtonStyle.primary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: DgSpacing.md),
        DgButton(
          text: "Cancel",
          style: DgButtonStyle.secondary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
