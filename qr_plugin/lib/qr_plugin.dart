import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _viewType = 'net.defguard.qr_plugin/view';

class QrScannerException implements Exception {
  static const permissionDenied = 'permissionDenied';
  static const noCamera = 'noCamera';
  static const cameraError = 'cameraError';

  final String code;
  final String? message;

  const QrScannerException(this.code, [this.message]);

  @override
  String toString() => message == null
      ? 'QrScannerException($code)'
      : 'QrScannerException($code): $message';
}

class QrScannerController {
  static int _nextId = 0;

  final int _id = _nextId++;
  late final MethodChannel _channel = MethodChannel('${_viewType}_$_id');
  bool _running = true;
  bool _attached = false;

  bool get isRunning => _running;

  Future<void> start() => _setRunning(true);

  Future<void> stop() => _setRunning(false);

  Future<void> _setRunning(bool running) async {
    _running = running;
    if (_attached) {
      await _channel.invokeMethod(running ? 'start' : 'stop');
    }
  }
}

class QrScannerView extends StatefulWidget {
  final QrScannerController controller;
  final ValueChanged<String> onCode;
  final ValueChanged<QrScannerException> onError;

  const QrScannerView({
    super.key,
    required this.controller,
    required this.onCode,
    required this.onError,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  QrScannerController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller._channel.setMethodCallHandler(_handle);
  }

  @override
  void dispose() {
    _controller._attached = false;
    _controller._channel.setMethodCallHandler(null);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      unawaited(_controller._channel.invokeMethod('dispose'));
    }
    super.dispose();
  }

  Future<void> _handle(MethodCall call) async {
    switch (call.method) {
      case 'code':
        if (_controller._running) widget.onCode(call.arguments as String);
      case 'error':
        final args = call.arguments as Map;
        widget.onError(
          QrScannerException(
            args['code'] as String,
            args['message'] as String?,
          ),
        );
    }
  }

  void _onCreated(int _) {
    _controller._attached = true;
    if (!_controller._running) unawaited(_controller.stop());
  }

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidView(
        viewType: _viewType,
        creationParams: _controller._id,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: {Factory(EagerGestureRecognizer.new)},
        onPlatformViewCreated: _onCreated,
      ),
      TargetPlatform.iOS => UiKitView(
        viewType: _viewType,
        creationParams: _controller._id,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onCreated,
      ),
      _ => throw UnsupportedError('qr_plugin supports only Android and iOS'),
    };
  }
}
