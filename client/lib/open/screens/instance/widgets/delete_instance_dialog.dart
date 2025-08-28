import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/secure_storage.dart';


class DeleteInstanceDialog extends HookConsumerWidget {
  final DefguardInstance instance;

  const DeleteInstanceDialog({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String warningText =
        "Are you sure you want to delete this ${instance.name} instance? This action is permanent and cannot be undone. All associated data and configurations will be lost.";

    final db = ref.watch(databaseProvider);

    Future<void> deleteInstance(BuildContext context) async {
      final messenger = ScaffoldMessenger.of(context);
      await removeInstanceStorage(instance.secureStorageKey);
      await db.managers.defguardInstances
          .filter((row) => row.id.equals(instance.id))
          .delete();
      if (context.mounted) {
        messenger.showSnackBar(dgSnackBar(text: "Instance deleted"));
        Navigator.of(context).pop();
      }
    }

    return DgDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              "Delete Instance",
              style: DgText.sideBar,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsetsGeometry.only(
              top: 0,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              children: [
                Text(
                  warningText,
                  style: DgText.copyright,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DgButton(
                      size: DgButtonSize.standard,
                      variant: DgButtonVariant.secondary,
                      text: "Cancel",
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: DgButton(
                        text: "Delete Instance",
                        size: DgButtonSize.standard,
                        variant: DgButtonVariant.alert,
                        icon: DgIconX(size: 18),
                        onTap: () {
                          deleteInstance(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
