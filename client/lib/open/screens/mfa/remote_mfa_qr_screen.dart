import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/next/next_qr_scanner.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/utils/secure_storage.dart';

import '../../../logging.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';

class RemoteMfaQrScreenData {
  final DefguardInstance instance;

  const RemoteMfaQrScreenData({required this.instance});
}

class RemoteMfaQrScreen extends HookConsumerWidget {
  final RemoteMfaQrScreenData screenData;

  const RemoteMfaQrScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final instance = screenData.instance;
    final toaster = ref.read(toastManagerProvider.notifier);

    const description =
        "Open the desktop app, select this instance, connect using biometry, and scan the QR code.";

    return Scaffold(
      backgroundColor: Colors.black,
      body: NextQrScanner<RemoteMfaQr>(
        description: description,
        loading: isLoading.value,
        onCancel: () => Navigator.of(context).pop(),
        validator: (raw) {
          try {
            final decodedString = jsonDecode(utf8.decode(base64Decode(raw)));
            return RemoteMfaQr.fromJson(decodedString);
          } catch (e) {
            talker.error("Failed to decode QR: $e");
            return null;
          }
        },
        onScan: (data, controller) async {
          isLoading.value = true;
          if (instance.uuid != data.instanceId) {
            toaster.showError(
              message: "Scanned QR belongs to an different instance.",
              logMessage: "Remote MFA failed! Instance mismatch",
            );
            isLoading.value = false;
            await controller.resume();
            return;
          }

          try {
            late SecureInstanceStorage storage;
            // Small delay to let camera close if needed or just for UX
            await Future.delayed(const Duration(milliseconds: 500));

            try {
              storage = await getBiometricInstanceStorage(
                instance.secureStorageKey,
              );
            } on PlatformException catch (e) {
              final message = getErrorMessageFromBiometricsException(e);
              toaster.showError(
                message: "Biometric authentication failed.",
                logMessage: "Failed biometric auth! Reason: $message",
                error: e,
              );
              isLoading.value = false;
              await controller.resume();
              return;
            } on UserCanceledAuth {
              talker.error("User canceled biometric auth");
              isLoading.value = false;
              await controller.resume();
              return;
            }

            final signature = signChallenge(data.challenge, storage.privateKey);
            final requestData = FinishMfaRequest(
              token: data.token,
              code: signature,
              authPubKey: storage.publicKey,
            );
            await proxyApi.finishRemoteMfa(
              Uri.parse(instance.proxyUrl),
              requestData,
            );
            talker.info(
              "Successfully authorized instance ${instance.logName}.",
            );
            toaster.show(message: "Desktop client authorized successfully.");

            if (context.mounted) {
              InstanceScreenRoute(id: instance.id.toString()).go(context);
            }
          } catch (e, st) {
            toaster.showError(
              message: "Failed to authenticate desktop client.",
              error: e,
              stackTrace: st,
            );
            isLoading.value = false;
            await controller.resume();
          }
        },
      ),
    );
  }
}
