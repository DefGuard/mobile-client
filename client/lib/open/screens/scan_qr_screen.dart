import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/loading_screen.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/utils/secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/proxy/mfa.dart';
import '../../logging.dart';
import '../../theme/spacing.dart';
import '../widgets/buttons/dg_button.dart';

enum ScanQrScreenDataIntent { remoteMfa }

class ScanQrScreenData {
  final ScanQrScreenDataIntent intent;
  final DefguardInstance? instance;

  const ScanQrScreenData({required this.intent, this.instance});
}

class ScanQrScreen extends HookConsumerWidget {
  final ScanQrScreenData screenData;

  const ScanQrScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingForProxy = useState(false);
    final lifecycle = useAppLifecycleState();
    final scannerController = useMemoized(
      () => MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 250,
        formats: [BarcodeFormat.qrCode],
      ),
      [],
    );

    final handleRemoteMfaScan = useCallback((RemoteMfaQr data) async {
      final msg = ScaffoldMessenger.of(context);
      await scannerController.stop();
      waitingForProxy.value = true;
      try {
        if (screenData.instance!.uuid != data.instanceId) {
          talker.error("Remote MFA failed! Instance mismatch");
        }
        final secureStorage = await getBiometricInstanceStorage(
          screenData.instance!.secureStorageKey,
        );
        final signature = signChallenge(
          data.challenge,
          secureStorage.privateKey,
        );
        final requestData = FinishMfaRequest(
          token: data.token,
          code: signature,
          authPubKey: secureStorage.publicKey,
        );
        await proxyApi.finishRemoteMfa(
          Uri.parse(screenData.instance!.proxyUrl),
          requestData,
        );
        talker.info(
          "Successfully authorized instance ${screenData.instance!.logName}.",
        );
        msg.showSnackBar(
          dgSnackBar(text: "Desktop client authorized successfully."),
        );
      } catch (e) {
        talker.error(e);
        msg.showSnackBar(
          dgSnackBar(
            text: "Failed to authenticate desktop client.",
            textColor: DgColor.textAlert,
          ),
        );
      } finally {
        waitingForProxy.value = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }, [scannerController, context]);

    useEffect(() {
      print(lifecycle);
      if (lifecycle != null) {
        switch (lifecycle) {
          case AppLifecycleState.resumed:
            if (!scannerController.value.isRunning &&
                !scannerController.value.isStarting) {
              unawaited(scannerController.start());
            }
            break;
          case AppLifecycleState.inactive:
            if (scannerController.value.isRunning) {
              unawaited(scannerController.stop());
            }
            break;
          default:
        }
      }
      return null;
    }, [lifecycle]);

    useEffect(() {
      return () {
        scannerController.dispose();
      };
    }, []);

    if (waitingForProxy.value) return LoadingView();

    return Container(
      color: DgColor.frameBg,
      child: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: scannerController,
              onDetectError: (err, trace) {
                talker.error("Mobile scanner widget failed!", err, trace);
              },
              onDetect: (result) {
                final readResult = result.barcodes.first.rawValue;
                if (readResult != null) {
                  try {
                    final decodedString = jsonDecode(
                      utf8.decode(base64Decode(readResult)),
                    );
                    switch (screenData.intent) {
                      case ScanQrScreenDataIntent.remoteMfa:
                        final parsedData = RemoteMfaQr.fromJson(decodedString);
                        handleRemoteMfaScan(parsedData);
                        break;
                    }
                  } catch (e) {
                    debugPrint("Error $e");
                  }
                }
              },
            ),
            if (screenData.intent == ScanQrScreenDataIntent.remoteMfa)
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
                  onTap: () async {
                    await scannerController.stop();
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
