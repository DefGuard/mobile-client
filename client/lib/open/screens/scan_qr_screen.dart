import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/screens/process_qr_screen.dart';
import 'package:mobile/open/widgets/next/next_qr_scanner.dart';
import 'package:mobile/router/routes.dart';

import '../../data/proxy/mfa.dart';
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
    final description = screenData.intent == QrScreenIntent.remoteMfa
        ? "Open the desktop app, select this instance, connect using biometry, and scan the QR code."
        : "Scan QR Code to add instance\non your phone";

    return Scaffold(
      backgroundColor: Colors.black,
      body: NextQrScanner<Object>(
        description: description,
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
          if (data is RemoteMfaQr) {
            final instance = screenData.instance!;
            if (instance.uuid != data.instanceId) {
              talker.error("Remote MFA failed! Instance mismatch");
              if (context.mounted) {
                SnackbarService.showError(
                  "Scanned QR belongs to an different instance.",
                );
              }
              await controller.resume();
              return;
            }
            if (context.mounted) {
              ProcessQrScreenRoute(
                ProcessQrScreenData(
                  intent: QrScreenIntent.remoteMfa,
                  remoteMfaQr: data,
                  instance: instance,
                ),
              ).go(context);
            }
          } else if (data is QrInstanceRegistration) {
            if (context.mounted) {
              ProcessQrScreenRoute(
                ProcessQrScreenData(
                  intent: screenData.intent,
                  registerInstanceData: data,
                ),
              ).go(context);
            }
          }
        },
      ),
    );
  }
}
