import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/utils/secure_storage.dart';

import '../../logging.dart';
import '../services/snackbar_service.dart';

class TestStorageScreen extends HookConsumerWidget {
  const TestStorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    return DgScaffold(
      title: "Test Screen",
      child: DgSingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: DgButton(
                text: "Test it",
                minWidth: 100,
                onTap: () async {
                  try {
                    final instance = await db.managers.defguardInstances
                        .getSingle();
                    final storageData = await getBiometricInstanceStorage(
                      instance.secureStorageKey,
                    );
                    final message =
                        "Pub: ${storageData.publicKey}\n\nPrivate: ${storageData.privateKey}";
                    SnackbarService.show(
                      message,
                      duration: Duration(seconds: 2),
                    );
                    talker.debug(message);
                  } on PlatformException catch (e) {
                    final message = getErrorMessageFromBiometricsException(e);
                    talker.error(message);
                    SnackbarService.showError(message);
                  } on UserCanceledAuth {
                    SnackbarService.show(
                      "Canceled",
                      duration: Duration(seconds: 2),
                    );
                  } catch (e) {
                    debugPrint(e.toString());
                    talker.error(e.toString());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
