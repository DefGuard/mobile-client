import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mobile/logging.dart';
import 'package:rive/rive.dart' as rive;

abstract final class RiveFileCache {
  static final Map<String, rive.File> _files = {};
  static final Map<String, Future<rive.File?>> _pending = {};

  static rive.File? get(String asset) => _files[asset];

  static Future<rive.File?> load(String asset) async {
    final cached = _files[asset];
    if (cached != null) return cached;
    return _pending[asset] ??= _decode(asset);
  }

  static Future<rive.File?> _decode(String asset) async {
    try {
      final file = await rive.File.asset(
        asset,
        riveFactory: rive.Factory.rive,
      );
      if (file == null) {
        talker.error("Rive asset $asset loaded as null");
      } else {
        _files[asset] = file;
      }
      return file;
    } catch (e, s) {
      talker.error("Failed to load Rive asset $asset", e, s);
      return null;
    } finally {
      _pending.remove(asset);
    }
  }
}

class RiveAssetAnimation extends StatefulWidget {
  final String asset;
  final rive.Fit fit;
  final Alignment alignment;
  final String? stateMachineName;

  const RiveAssetAnimation(
    this.asset, {
    super.key,
    this.fit = rive.Fit.contain,
    this.alignment = Alignment.center,
    this.stateMachineName,
  });

  @override
  State<RiveAssetAnimation> createState() => _RiveAssetAnimationState();
}

class _RiveAssetAnimationState extends State<RiveAssetAnimation> {
  rive.RiveWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant RiveAssetAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _attach();
    }
  }

  void _attach() {
    final cached = RiveFileCache.get(widget.asset);
    if (cached != null) {
      _replaceController(cached);
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final asset = widget.asset;
    final file = await RiveFileCache.load(asset);
    if (!mounted || file == null || asset != widget.asset) return;
    setState(() => _replaceController(file));
  }

  void _replaceController(rive.File file) {
    final stateMachineName = widget.stateMachineName;
    _controller?.dispose();
    _controller = rive.RiveWidgetController(
      file,
      stateMachineSelector: stateMachineName != null
          ? rive.StateMachineNamed(stateMachineName)
          : const rive.StateMachineDefault(),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return rive.RiveWidget(
      controller: controller,
      fit: widget.fit,
      alignment: widget.alignment,
    );
  }
}
