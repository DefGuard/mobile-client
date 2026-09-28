import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _plugin = MethodChannel('net.defguard.qr_plugin');

enum QrScannerError { permissionDenied, noCamera, cameraError }

class QrScannerException implements Exception {
  final QrScannerError code;
  final String? message;

  const QrScannerException(this.code, [this.message]);

  factory QrScannerException._fromNative(Object? code, String? message) =>
      QrScannerException(
        QrScannerError.values.asNameMap()[code] ?? QrScannerError.cameraError,
        message,
      );

  @override
  String toString() => message == null
      ? 'QrScannerException(${code.name})'
      : 'QrScannerException(${code.name}): $message';
}

Future<void> _invokeQuietly(
  MethodChannel channel,
  String method, [
  Object? arguments,
]) async {
  try {
    await channel.invokeMethod<void>(method, arguments);
  } catch (e) {
    if (e is! PlatformException && e is! MissingPluginException) rethrow;
  }
}

class QrScannerController {
  static int _nextId = 0;

  final int _id = _nextId++;
  late final MethodChannel _channel = MethodChannel(
    'net.defguard.qr_plugin/scanner_$_id',
  );
  bool _running = true;
  bool _attached = false;
  bool _inUse = false;

  bool get isRunning => _running;

  Future<void> start() => _setRunning(true);

  Future<void> stop() => _setRunning(false);

  Future<void> _setRunning(bool running) async {
    _running = running;
    if (_attached) await _invokeQuietly(_channel, running ? 'start' : 'stop');
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
  int? _textureId;
  Size? _size;
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    assert(!_controller._inUse, 'QrScannerController is bound to another view');
    _controller._inUse = true;
    _controller._channel.setMethodCallHandler(_handle);
    unawaited(_create());
  }

  @override
  void dispose() {
    _controller._attached = false;
    _controller._inUse = false;
    _controller._channel.setMethodCallHandler(null);
    unawaited(_invokeQuietly(_plugin, 'dispose', _controller._id));
    super.dispose();
  }

  Future<void> _create() async {
    final int? textureId;
    try {
      textureId = await _plugin.invokeMethod<int>('create', _controller._id);
    } catch (e) {
      if (e is! PlatformException && e is! MissingPluginException) rethrow;
      if (mounted) {
        widget.onError(
          e is PlatformException
              ? QrScannerException._fromNative(e.code, e.message)
              : QrScannerException(QrScannerError.cameraError, '$e'),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _textureId = textureId);
    _controller._attached = true;
    if (!_controller._running) await _controller.stop();
  }

  Future<void> _handle(MethodCall call) async {
    switch (call.method) {
      case 'code':
        if (_controller._running) widget.onCode(call.arguments as String);
      case 'size':
        final args = call.arguments as Map;
        setState(() {
          _size = Size(
            (args['width'] as num).toDouble(),
            (args['height'] as num).toDouble(),
          );
          _quarterTurns = args['quarterTurns'] as int;
        });
      case 'error':
        final args = call.arguments as Map;
        widget.onError(
          QrScannerException._fromNative(
            args['code'],
            args['message'] as String?,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textureId = _textureId;
    final size = _size;
    if (textureId == null || size == null) {
      return const ColoredBox(color: Color(0xFF000000));
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: RotatedBox(
          quarterTurns: _quarterTurns,
          child: SizedBox.fromSize(
            size: size,
            child: Texture(textureId: textureId),
          ),
        ),
      ),
    );
  }
}
