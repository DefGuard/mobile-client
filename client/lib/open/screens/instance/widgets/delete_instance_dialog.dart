import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_dialog.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/utils/secure_storage.dart';

import '../../../../theme/next/color.dart';

class DeleteInstanceDialog extends HookConsumerWidget {
  final DefguardInstance instance;

  const DeleteInstanceDialog({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String warningText =
        "Are you sure you want to delete this instance ${instance.name}. This action can’t be undone and you will be disconnected from all locations from this instance.";

    final db = ref.watch(databaseProvider);
    final toaster = ref.read(toastManagerProvider.notifier);

    Future<void> deleteInstance(BuildContext context) async {
      try {
        if (instance.mfaKeysStored) {
          await removeInstanceStorage(instance.secureStorageKey);
        }
        await db.managers.defguardInstances
            .filter((row) => row.id.equals(instance.id))
            .delete();
        if (context.mounted) {
          toaster.show(message: "Instance deleted");
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        talker.error(
          "Failed to delete instance ${instance.logName}! Reason: \n $e",
        );
      }
    }

    return NextDialog(
      onClose: () => Navigator.of(context).pop(),
      children: [
        NextIcon("dialog_warning", size: 40, color: NextColor.fgWhite100),
        const SizedBox(height: NextSpacing.xl2),
        const NextDialogTitle("Delete instance"),
        NextDialogDescription(warningText),
        NextButton(
          text: "Delete instance",
          style: NextButtonStyle.critical,
          size: NextButtonSize.big,
          width: double.infinity,
          onTap: () => deleteInstance(context),
        ),
        const SizedBox(height: NextSpacing.md),
        NextButton(
          text: "Cancel",
          style: NextButtonStyle.secondary,
          size: NextButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
