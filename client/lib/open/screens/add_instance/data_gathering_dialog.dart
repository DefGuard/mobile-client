import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/theme/spacing.dart';

const agreementPrefsKey = "DATA_GATHERING_AGREEMENT";

const noticeMessage =
    "This app connects your device to your organisation’s private Defguard instance. Defguard (the app developer) does not collect or store your data - only your organisation controls it. Diagnostic logs stay on your device only.";

class DataGatheringDialog extends StatelessWidget {
  const DataGatheringDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DgDialog(
      onClose: () => Navigator.of(context).pop(false),
      children: [
        const DgDialogTitle("Data gathering"),
        const DgDialogDescription(noticeMessage),
        DgButton(
          text: "I Understand",
          style: DgButtonStyle.primary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () {
            Navigator.of(context).pop(true);
          },
        ),
        const SizedBox(height: DgSpacing.md),
        DgButton(
          text: "Decline",
          style: DgButtonStyle.secondary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () {
            Navigator.of(context).pop(false);
          },
        ),
      ],
    );
  }
}
