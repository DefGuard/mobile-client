import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/widgets/next/next_qr_scanner.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/utils/secure_storage.dart';

import '../../logging.dart';
import '../services/snackbar_service.dart';

enum QrScreenIntent { remoteMfa, addInstance }

class QrScreenData {
  final QrScreenIntent intent;
  final DefguardInstance? instance;

  const QrScreenData({required this.intent, this.instance});
}

class ScanQrScreen extends HookConsumerWidget {
  final QrScreenData screenData;

  const ScanQrScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final isLoading = useState(false);

    final description = screenData.intent == QrScreenIntent.remoteMfa
        ? "Open the desktop app, select this instance, connect using biometry, and scan the QR code."
        : "Scan QR Code to add instance\non your phone";

    return Scaffold(
      backgroundColor: Colors.black,
      body: NextQrScanner<Object>(
        description: description,
        loading: isLoading.value,
        onCancel: () => Navigator.of(context).pop(),
        validator: (raw) {
          try {
            final decodedString = jsonDecode(utf8.decode(base64Decode(raw)));
            switch (screenData.intent) {
              case QrScreenIntent.remoteMfa:
                return RemoteMfaQr.fromJson(decodedString);
              case QrScreenIntent.addInstance:
                return QrInstanceRegistration.fromJson(decodedString);
            }
          } catch (e) {
            talker.error("Failed to decode QR: $e");
            return null;
          }
        },
        onScan: (data, controller) async {
          isLoading.value = true;
          if (data is RemoteMfaQr) {
            final instance = screenData.instance!;
            if (instance.uuid != data.instanceId) {
              talker.error("Remote MFA failed! Instance mismatch");
              if (context.mounted) {
                SnackbarService.showError(
                  "Scanned QR belongs to an different instance.",
                );
              }
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
                talker.error("Failed biometric auth! Reason: $message");
                if (context.mounted) {
                  SnackbarService.showError(
                    "Biometric authentication failed! Reason: $message",
                  );
                }
                isLoading.value = false;
                await controller.resume();
                return;
              } on UserCanceledAuth {
                talker.error("User canceled biometric auth");
                isLoading.value = false;
                await controller.resume();
                return;
              }

              final signature = signChallenge(
                data.challenge,
                storage.privateKey,
              );
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
              SnackbarService.show("Desktop client authorized successfully.");

              if (context.mounted) {
                InstanceScreenRoute(id: instance.id.toString()).go(context);
              }
            } catch (e, st) {
              SnackbarService.showError(
                "Failed to authenticate desktop client.",
                error: e,
                stackTrace: st,
              );
              isLoading.value = false;
              await controller.resume();
            }
          } else if (data is QrInstanceRegistration) {
            final url = Uri.parse(data.url);
            final requestData = EnrollmentStartRequest(token: data.token);
            try {
              final registrationResponse = await proxyApi.startEnrollment(
                url,
                requestData,
              );
              final instanceId = registrationResponse.instance.id;
              final dbInstance = await db.managers.defguardInstances
                  .filter((row) => row.uuid.equals(instanceId))
                  .getSingleOrNull();

              if (dbInstance != null) {
                talker.error(
                  "Register Instance failed! Instance is already registered.",
                );
                SnackbarService.showError("Instance is already registered!");
                isLoading.value = false;
                await controller.resume();
                return;
              }

              final NameDeviceScreenData routeData = NameDeviceScreenData(
                proxyUrl: url,
                startResponse: registrationResponse,
              );

              if (context.mounted) {
                NameDeviceScreenRoute(routeData).go(context);
              }
            } catch (e, st) {
              if (context.mounted) {
                SnackbarService.showError(
                  "Something went wrong. Try again.",
                  logMessage: "Enrollment via QR start failed!",
                  error: e,
                  stackTrace: st,
                );
              }
              isLoading.value = false;
              await controller.resume();
            }
          }
        },
      ),
    );
  }
}
