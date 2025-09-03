import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/theme/text.dart';

final noticeMessage =
    "This app connects your device to your organisation’s private Defguard instance. Defguard (the app developer) does not collect or store your data - only your organisation controls it. Diagnostic logs stay on your device only.";

class DataGatheringDialog extends HookConsumerWidget {
  const DataGatheringDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DgDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              "Data gathering",
              style: DgText.sideBar,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8),
          Text(
            noticeMessage,
            style: DgText.copyright,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
            child: DgButton(
              text: "I Understand",
              textStyle: DgText.buttonXS,
              size: DgButtonSize.standard,
              variant: DgButtonVariant.primary,
              width: double.infinity,
              onTap: () {
                Navigator.of(context).pop(true);
              },
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
            child: DgButton(
              text: "Decline",
              textStyle: DgText.buttonXS,
              size: DgButtonSize.standard,
              variant: DgButtonVariant.primary,
              width: double.infinity,
              onTap: () {
                Navigator.of(context).pop(false);
              },
            ),
          ),
        ],
      ),
    );
  }
}
