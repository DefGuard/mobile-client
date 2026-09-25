import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _viewType = 'net.defguard.qr_plugin/view';

enum QrScannerError { permissionDenied, noCamera, cameraError }

class QrScannerException implements Exception {
  final QrScannerError code;
  final String? message;

  const QrScannerException(this.code, [this.message]);

  factory QrScannerException._fromNative(Map<Object?, Object?> args) =>
      QrScannerException(
        QrScannerError.values.asNameMap()[args['code']] ??
            QrScannerError.cameraError,
        args['message'] as String?,
      );

  @override
  String toString() => message == null
      ? 'QrScannerException(${code.name})'
      : 'QrScannerException(${code.name}): $message';
}

class QrScannerController {
  static int _nextId = 0;

  final int _id = _nextId++;
  late final MethodChannel _channel = MethodChannel('${_viewType}_$_id');
  bool _running = true;
  bool _attached = false;
  bool _inUse = false;

  bool get isRunning => _running;

  Future<void> start() => _setRunning(true);

  Future<void> stop() => _setRunning(false);

  Future<void> _setRunning(bool running) async {
    _running = running;
    if (_attached) await _invoke(running ? 'start' : 'stop');
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (e) {
      if (e is! PlatformException && e is! MissingPluginException) rethrow;
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
    assert(!_controller._inUse, 'QrScannerController is bound to another view');
    _controller._inUse = true;
    _controller._channel.setMethodCallHandler(_handle);
  }

  @override
  void dispose() {
    _controller._attached = false;
    _controller._inUse = false;
    _controller._channel.setMethodCallHandler(null);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      unawaited(_controller._invoke('dispose'));
    }
    super.dispose();
  }

  Future<void> _handle(MethodCall call) async {
    switch (call.method) {
      case 'code':
        if (_controller._running) widget.onCode(call.arguments as String);
      case 'error':
        widget.onError(QrScannerException._fromNative(call.arguments as Map));
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
