import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/screens/process_qr_screen.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/proxy/mfa.dart';
import '../../logging.dart';
import '../../theme/spacing.dart';
import '../widgets/buttons/dg_button.dart';

enum QrScreenIntent { remoteMfa, addInstance }

class QrScreenData {
  final QrScreenIntent intent;
  final DefguardInstance? instance;

  const QrScreenData({required this.intent, this.instance});
}

class ScanQrScreen extends HookConsumerWidget {
  final QrScreenData screenData;

  const ScanQrScreen({super.key, required this.screenData});

  Future<void> handleRemoteMfaScan(
    RemoteMfaQr data,
    BuildContext context,
  ) async {
    final instance = screenData.instance!;
    if (instance.uuid != data.instanceId) {
      talker.error("Remote MFA failed! Instance mismatch");
      if (context.mounted) {
        final msg = ScaffoldMessenger.of(context);
        msg.showSnackBar(
          dgSnackBar(
            text: "Scanned QR belongs to an different instance.",
            customDuration: Duration(seconds: 10),
            onDismiss: () {
              msg.hideCurrentSnackBar();
            },
          ),
        );
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) {
      final screenData = ProcessQrScreenData(
        intent: QrScreenIntent.remoteMfa,
        remoteMfaQr: data,
        instance: instance,
      );
      ProcessQrScreenRoute(screenData).go(context);
    }
  }

  Future<void> handleDetect(
    BarcodeCapture capture,
    BuildContext context,
  ) async {
    final readResult = capture.barcodes.first.rawValue;
    if (readResult != null) {
      try {
        final decodedString = jsonDecode(utf8.decode(base64Decode(readResult)));
        switch (screenData.intent) {
          case QrScreenIntent.remoteMfa:
            final parsedData = RemoteMfaQr.fromJson(decodedString);
            await handleRemoteMfaScan(parsedData, context);
            break;
          case QrScreenIntent.addInstance:
            final parsedData = QrInstanceRegistration.fromJson(decodedString);
            await WidgetsBinding.instance.endOfFrame;
            if (context.mounted) {
              ProcessQrScreenRoute(
                ProcessQrScreenData(
                  intent: screenData.intent,
                  registerInstanceData: parsedData,
                ),
              ).go(context);
            }
            break;
        }
      } catch (e) {
        debugPrint("Barcode capture error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = useAppLifecycleState();

    final scannerController = useMemoized(
      () => MobileScannerController(
        facing: CameraFacing.back,
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 250,
        formats: [BarcodeFormat.qrCode],
      ),
      [],
    );

    useEffect(() {
      Future<void> handleLifecycle() async {
        if (lifecycle != null) {
          switch (lifecycle) {
            case AppLifecycleState.resumed:
              if (!scannerController.value.isRunning &&
                  !scannerController.value.isStarting) {
                await scannerController.start();
              }
              break;
            case AppLifecycleState.inactive:
              if (scannerController.value.isRunning) {
                await scannerController.stop();
              }
              break;
            default:
          }
        }
      }

      handleLifecycle();
      return null;
    }, [lifecycle]);

    useEffect(() {
      final sub = scannerController.barcodes.listen((capture) async {
        await scannerController.stop();
        if (context.mounted) {
          await handleDetect(capture, context);
        }
        await scannerController.start();
      });
      return () {
        unawaited(sub.cancel());
        unawaited(scannerController.dispose());
      };
    }, const []);

    return Container(
      color: DgColor.frameBg,
      child: SafeArea(
        child: Stack(
          children: [
            MobileScanner(controller: scannerController),
            if (screenData.intent == QrScreenIntent.remoteMfa)
              Positioned(
                top: DgSpacing.xs,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsetsGeometry.only(
                    left: DgSpacing.s,
                    right: DgSpacing.s,
                  ),
                  child: Material(
                    elevation: 5,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: DgMessageBox(
                      text:
                          "Please open the desktop app, select this instance, connect to a chosen location using Biometry authentication, and scan the QR code shown here.",
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: DgSpacing.s,
              left: 0,
              right: 0,
              child: Center(
                child: DgButton(
                  text: "Cancel",
                  minWidth: 100,
                  onTap: () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
