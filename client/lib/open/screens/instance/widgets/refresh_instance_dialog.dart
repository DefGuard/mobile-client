import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/open/widgets/dg_dialog_title.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/utils/update_instance.dart';

import '../../../../logging.dart';

class RefreshInstanceDialog extends HookConsumerWidget {
  final DefguardInstance instance;

  const RefreshInstanceDialog({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final proxyUrlController = useTextEditingController(
      text: instance.proxyUrl,
    );
    final tokenController = useTextEditingController();
    final isLoading = useState(false);

    final submit = useCallback(() async {
      final url = proxyUrlController.text;
      final token = tokenController.text;
      final uri = Uri.parse(url);
      talker.debug("Submitting instance refresh form");
      // this is only for dio to capture cookies required for network info call
      await proxyApi.startEnrollment(uri, EnrollmentStartRequest(token: token));
      final networkInfo = await proxyApi.networkInfo(uri, instance.pubKey);
      talker.debug("Retrieved new instance information from proxy");
      talker.debug("Updating instance info in DB");
      await updateInstance(
        db: db,
        instance: instance,
        configs: networkInfo.configs,
        info: networkInfo.instance,
      );
      talker.info("Instance information refreshed successfully");
    }, [db, proxyUrlController, tokenController, isLoading]);

    return DgDialog(
      child: Form(
        child: Column(
          children: [
            DgDialogTitle(text: "Refresh Instance"),
            DgTextFormField(controller: proxyUrlController, hintText: "Url"),
            DgTextFormField(
              controller: tokenController,
              hintText: "Instance Token",
            ),
            Row(
              children: [
                DgButton(
                  text: "Cancel",
                  size: DgButtonSize.standard,
                  variant: DgButtonVariant.secondary,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                DgButton(
                  text: "Submit",
                  size: DgButtonSize.standard,
                  variant: DgButtonVariant.primary,
                  loading: isLoading.value,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    isLoading.value = true;
                    try {
                      await submit();
                      navigator.pop();
                    } catch (e) {
                      talker.error("Failed to submit instance refresh form", e);
                    } finally {
                      isLoading.value = false;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
