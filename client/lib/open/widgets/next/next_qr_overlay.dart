import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_circular_progress.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';

class NextQrOverlay extends StatefulWidget {
  final String description;
  final VoidCallback onCancel;
  final bool loading;

  const NextQrOverlay({
    super.key,
    required this.description,
    required this.onCancel,
    this.loading = false,
  });

  @override
  State<NextQrOverlay> createState() => _NextQrOverlayState();
}

class _NextQrOverlayState extends State<NextQrOverlay> {
  final GlobalKey _holeKey = GlobalKey();
  Rect? _holeRect;

  @override
  void initState() {
    super.initState();
    // Calculate initial hole position after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHole());
  }

  @override
  void didUpdateWidget(covariant NextQrOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if description or other properties change
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHole());
  }

  void _updateHole() {
    if (!mounted) return;
    final renderBox = _holeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final myBox = context.findRenderObject() as RenderBox?;
      if (myBox != null) {
        final localPosition = myBox.globalToLocal(position);
        final newRect = localPosition & renderBox.size;
        if (_holeRect != newRect) {
          setState(() {
            _holeRect = newRect;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the hole stays aligned during layout changes (e.g., rotation)
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHole());

    return Stack(
      children: [
        // Background with the dynamic hole clip
        if (_holeRect != null)
          Positioned.fill(
            child: ClipPath(
              clipper: _HoleClipper(hole: _holeRect!),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  color: const Color(0xFF020501).withValues(alpha: 0.8),
                ),
              ),
            ),
          )
        else
          // Fallback background while calculating the hole position
          Positioned.fill(
            child: Container(
              color: const Color(0xFF020501).withValues(alpha: 0.8),
            ),
          ),

        // Main UI Content
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 140),
                if (widget.loading)
                  const NextCircularProgress(size: 16)
                else
                  const NextIcon(
                    'assets/icons/qr',
                    size: 24,
                    color: NextColor.fgWhite100,
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.description,
                    style: NextText.bodySm400.copyWith(
                      color: NextColor.fgWhite80,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 80), // Dynamic spacing set to 80
                SizedBox(key: _holeKey, width: 292, height: 292),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: NextButton(
                    text: "Cancel",
                    style: NextButtonStyle.outlined,
                    size: NextButtonSize.primary,
                    onTap: widget.onCancel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final Rect hole;

  _HoleClipper({required this.hole});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(46)))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) =>
      hole != oldClipper.hole;
}

@Preview(name: 'Next QR Overlay')
Widget previewNextQrOverlay() {
  return NextPreviewWrapper(
    padding: EdgeInsets.zero,
    child: NextQrOverlay(
      description: "Scan QR Code to add instance\non your phone",
      onCancel: () {},
    ),
  );
}
