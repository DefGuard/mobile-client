import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';

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
        await instance.removeSecrets();
        await db.managers.defguardInstances
            .filter((row) => row.id.equals(instance.id))
            .delete();
        if (context.mounted) {
          toaster.show(message: "Instance deleted");
          Navigator.of(context).pop(true);
        }
      } catch (e, st) {
        toaster.showError(
          message: "Failed to delete instance. Please try again.",
          logMessage: "Failed to delete instance ${instance.logName}!",
          error: e,
          stackTrace: st,
        );
      }
    }

    return DgDialog(
      onClose: () => Navigator.of(context).pop(),
      children: [
        DgIcon("dialog_warning", size: 40, color: DgColor.fgWhite100),
        const SizedBox(height: DgSpacing.xl2),
        const DgDialogTitle("Delete instance"),
        DgDialogDescription(warningText),
        DgButton(
          text: "Delete instance",
          style: DgButtonStyle.critical,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => deleteInstance(context),
        ),
        const SizedBox(height: DgSpacing.md),
        DgButton(
          text: "Cancel",
          style: DgButtonStyle.secondary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
