import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../logging.dart';
import 'next_qr_overlay.dart';

class NextScannerController {
  final MobileScannerController _controller;

  NextScannerController(this._controller);

  Future<void> resume() async {
    if (!_controller.value.isRunning) {
      await _controller.start();
    }
  }

  Future<void> stop() async {
    if (_controller.value.isRunning) {
      await _controller.stop();
    }
  }
}

class NextQrScanner<T> extends HookWidget {
  final String description;
  final T? Function(String) validator;
  final void Function(T data, NextScannerController controller) onScan;
  final VoidCallback onCancel;
  final Widget Function(BuildContext, MobileScannerException)? onError;

  const NextQrScanner({
    super.key,
    required this.description,
    required this.validator,
    required this.onScan,
    required this.onCancel,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final scannerController = useMemoized(
      () => MobileScannerController(
        facing: CameraFacing.back,
        autoStart: true,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 650,
        formats: [BarcodeFormat.qrCode],
        returnImage: false,
      ),
    );

    final nextController = useMemoized(
      () => NextScannerController(scannerController),
    );

    final lifecycle = useAppLifecycleState();

    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive) {
        unawaited(scannerController.stop());
      } else if (lifecycle == AppLifecycleState.resumed) {
        unawaited(scannerController.start());
      }
      return null;
    }, [lifecycle]);

    useEffect(() {
      return () {
        // Stop the scanner immediately on unmount to release camera
        unawaited(
          scannerController.stop().then((_) => scannerController.dispose()),
        );
      };
    }, []);

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: scannerController,
          onDetect: (capture) async {
            final barcode = capture.barcodes.firstOrNull;
            final rawValue = barcode?.rawValue;
            if (rawValue != null) {
              try {
                final validated = validator(rawValue);
                if (validated != null) {
                  // Explicitly stop scanning immediately to prevent double processing
                  await scannerController.stop();
                  onScan(validated, nextController);
                }
              } catch (e) {
                talker.error("QR validation failed: $e");
              }
            }
          },
          errorBuilder: (context, error) {
            talker.error("Camera error: ${error.errorCode}");
            if (onError != null) {
              return onError!(context, error);
            }
            return Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Could not access camera: ${error.errorCode}",
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        NextQrOverlay(description: description, onCancel: onCancel),
      ],
    );
  }
}
