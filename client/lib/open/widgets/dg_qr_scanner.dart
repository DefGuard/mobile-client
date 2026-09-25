import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_plugin/qr_plugin.dart';

import 'package:mobile/logging.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'dg_qr_overlay.dart';

const _duplicateWindow = Duration(milliseconds: 650);

T? decodeQrPayload<T>(String raw, T Function(Map<String, dynamic>) fromJson) {
  var step = 'base64';
  try {
    final bytes = base64Decode(raw);
    step = 'UTF-8';
    final text = utf8.decode(bytes);
    step = 'JSON';
    final json = jsonDecode(text);
    step = 'field';
    return fromJson(json as Map<String, dynamic>);
  } catch (e) {
    final reason = e is FormatException
        ? '${e.message}${e.offset != null ? ' at offset ${e.offset}' : ''}'
        : '$e';
    talker.warning(
      "Scanned QR is not a valid $T, $step decoding failed: $reason "
      "(payload length ${raw.length})",
    );
    return null;
  }
}

class DgScannerController {
  final QrScannerController _controller;
  final _rejected = <String>{};
  String? _lastValue;
  DateTime _lastSeenAt = DateTime(0);
  DateTime _cooldownUntil = DateTime(0);

  DgScannerController(this._controller);

  bool _isNewSighting(String value) {
    final now = DateTime.now();
    final repeated =
        value == _lastValue && now.difference(_lastSeenAt) < _duplicateWindow;
    _lastValue = value;
    _lastSeenAt = now;
    return !repeated &&
        now.isAfter(_cooldownUntil) &&
        !_rejected.contains(value);
  }

  Future<void> resume() async {
    _lastSeenAt = DateTime.now();
    _cooldownUntil = _lastSeenAt.add(toastDuration);
    if (!_controller.isRunning) {
      await _controller.start();
    }
  }

  Future<void> stop() async {
    if (_controller.isRunning) {
      await _controller.stop();
    }
  }
}

class DgQrScanner<T> extends HookWidget {
  final String description;
  final T? Function(String) validator;
  final void Function(T data, DgScannerController controller) onScan;
  final VoidCallback onCancel;
  final Widget Function(BuildContext, QrScannerException)? onError;
  final bool loading;

  const DgQrScanner({
    super.key,
    required this.description,
    required this.validator,
    required this.onScan,
    required this.onCancel,
    this.onError,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scannerController = useMemoized(QrScannerController.new);
    final nextController = useMemoized(
      () => DgScannerController(scannerController),
    );
    final permission = useFuture(useMemoized(Permission.camera.request));
    final error = useState<QrScannerException?>(null);

    void onCode(String rawValue) {
      if (!nextController._isNewSighting(rawValue)) return;
      try {
        final validated = validator(rawValue);
        if (validated == null) {
          nextController._rejected.add(rawValue);
          return;
        }
        // Explicitly stop scanning immediately to prevent double processing
        unawaited(nextController.stop());
        onScan(validated, nextController);
      } catch (e, st) {
        talker.error("Handling scanned QR failed", e, st);
      }
    }

    final granted = permission.data?.isGranted;

    useEffect(() {
      if (granted == false) {
        talker.warning(
          "Camera permission not granted: ${permission.data!.name}",
        );
      }
      return null;
    }, [granted]);
    final currentError = granted == false
        ? const QrScannerException(QrScannerException.permissionDenied)
        : error.value;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (currentError != null)
          _buildError(context, currentError)
        else if (granted == true)
          QrScannerView(
            controller: scannerController,
            onCode: onCode,
            onError: (e) {
              talker.error("QR scanner camera failed: $e");
              error.value = e;
            },
          )
        else
          const ColoredBox(color: Colors.black),
        DgQrOverlay(
          description: description,
          onCancel: onCancel,
          loading: loading,
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, QrScannerException error) {
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
                "Could not access camera: ${error.code}",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
