import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanInstanceQrScreen extends HookConsumerWidget {
  const ScanInstanceQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final controller = useMemoized(
      () => StreamController<QrInstanceRegistration>.broadcast(),
    );
    final controllerRef = useRef(controller);

    final handleSuccessScan = useCallback((QrInstanceRegistration data) async {
      await scannerController.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          RegisterFromQrScreenRoute(data).push(context);
        }
      });
    }, [scannerController, context]);

    useEffect(() {
      final sub = controllerRef.value.stream.take(1).listen((data) {
        handleSuccessScan(data);
      });
      return () {
        sub.cancel();
      };
    }, [handleSuccessScan]);

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
        controllerRef.value.close();
        scannerController.dispose();
      };
    }, []);

    return DgScaffold(
      title: "Scan QR",
      child: Container(
        color: DgColor.frameBg,
        child: SafeArea(
          top: false,
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
                      final decodedString = utf8.decode(
                        base64Decode(readResult),
                      );
                      final data = QrInstanceRegistration.fromJson(
                        jsonDecode(decodedString),
                      );
                      controllerRef.value.add(data);
                    } catch (e) {
                      debugPrint("Error $e");
                    }
                  }
                },
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
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
