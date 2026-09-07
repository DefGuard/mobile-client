import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_dialog.dart';
import 'package:mobile/theme/next/spacing.dart';

const agreementPrefsKey = "DATA_GATHERING_AGREEMENT";

const noticeMessage =
    "This app connects your device to your organisation’s private Defguard instance. Defguard (the app developer) does not collect or store your data - only your organisation controls it. Diagnostic logs stay on your device only.";

class DataGatheringDialog extends StatelessWidget {
  const DataGatheringDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return NextDialog(
      onClose: () => Navigator.of(context).pop(false),
      children: [
        const NextDialogTitle("Data gathering"),
        const NextDialogDescription(noticeMessage),
        NextButton(
          text: "I Understand",
          style: NextButtonStyle.primary,
          size: NextButtonSize.big,
          width: double.infinity,
          onTap: () {
            Navigator.of(context).pop(true);
          },
        ),
        const SizedBox(height: NextSpacing.md),
        NextButton(
          text: "Decline",
          style: NextButtonStyle.secondary,
          size: NextButtonSize.big,
          width: double.infinity,
          onTap: () {
            Navigator.of(context).pop(false);
          },
        ),
      ],
    );
  }
}
