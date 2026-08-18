import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

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
  rive.File? _file;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  @override
  void didUpdateWidget(covariant RiveAssetAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _loadRiveFile();
    }
  }

  Future<void> _loadRiveFile() async {
    try {
      final file = await rive.File.asset(
        widget.asset,
        riveFactory: rive.Factory.rive,
      );

      if (!mounted) return;
      if (file == null) return;

      final stateMachineSelector = widget.stateMachineName != null
          ? rive.StateMachineNamed(widget.stateMachineName!)
          : const rive.StateMachineDefault();

      setState(() {
        _file?.dispose();
        _controller?.dispose();
        _file = file;
        _controller = rive.RiveWidgetController(
          file,
          stateMachineSelector: stateMachineSelector,
        );
      });
    } catch (e) {
      debugPrint('Error loading Rive file: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _file?.dispose();
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
