import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dialogs/dg_confirm_dialog.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

const String message =
    "There can be only one active connection at the same time. When connecting to the next location, previous location will be disconnected.";

class ConnectionConflictDialog extends StatelessWidget {
  const ConnectionConflictDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DgConfirmDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Text("Change Active Connection")),
          SizedBox(height: 8),
          Center(
            child: Text(
              message,
              style: DgText.copyright,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              spacing: DgSpacing.s,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DgButton(
                  text: "Cancel",
                  variant: DgButtonVariant.secondary,
                  size: DgButtonSize.standard,
                  onTap: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                DgButton(
                  text: "Proceed",
                  variant: DgButtonVariant.primary,
                  size: DgButtonSize.standard,
                  onTap: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
