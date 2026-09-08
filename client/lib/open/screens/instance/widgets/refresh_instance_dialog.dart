import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/utils/update_instance.dart';

class RefreshInstanceDialog extends HookConsumerWidget {
  final DefguardInstance instance;

  const RefreshInstanceDialog({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final toaster = ref.read(toastManagerProvider.notifier);
    final proxyUrlController = useTextEditingController(
      text: instance.proxyUrl,
    );
    final tokenController = useTextEditingController();
    final isLoading = useState(false);

    final submit = useCallback(() async {
      final url = proxyUrlController.text;
      final token = tokenController.text;
      final uri = Uri.parse(url);
      talker.debug("Submitting instance refresh form ($url | $token)");

      try {
        // this is only for dio to capture cookies required for network info call
        await proxyApi.startEnrollment(
          uri,
          EnrollmentStartRequest(token: token),
        );
        final networkInfo = await proxyApi.networkInfo(uri, instance.pubKey);
        talker.debug("Retrieved new instance information from proxy");
        talker.debug("Updating instance info in DB");
        final updateResult = await updateInstance(
          db: db,
          instance: instance,
          configs: networkInfo.configs,
          info: networkInfo.instance,
          token: networkInfo.token,
        );
        if (updateResult != null && updateResult.didChange) {
          final message = getInstanceUpdateMessage(instance.name, updateResult);
          toaster.show(
            message: "Instance ${instance.name} updated: $message",
          );
        } else {
          toaster.show(message: "Instance information refreshed");
        }
        talker.info("Instance information refreshed successfully");
      } catch (e) {
        toaster.showError(
          message: "Failed to refresh instance information",
          error: e,
        );
        rethrow;
      }
    }, [db, toaster, proxyUrlController, tokenController, isLoading]);

    return DgDialog(
      onClose: () => Navigator.of(context).pop(),
      children: [
        const DgDialogTitle("Refresh Instance"),
        const DgDialogDescription(
          "Enter your proxy URL and instance token to refresh the configuration.",
        ),
        DgTextFormField(
          controller: proxyUrlController,
          label: "Proxy URL",
          hintText: "https://...",
        ),
        const SizedBox(height: DgSpacing.md),
        DgTextFormField(
          controller: tokenController,
          label: "Instance Token",
          hintText: "Enter token",
        ),
        const SizedBox(height: DgSpacing.xl2),
        Row(
          spacing: DgSpacing.md,
          children: [
            Expanded(
              child: DgButton(
                text: "Cancel",
                style: DgButtonStyle.secondary,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: DgButton(
                text: "Refresh",
                style: DgButtonStyle.primary,
                loading: isLoading.value,
                onTap: () async {
                  isLoading.value = true;
                  try {
                    await submit();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                  } finally {
                    isLoading.value = false;
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
