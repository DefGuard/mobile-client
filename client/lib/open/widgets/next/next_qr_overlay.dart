import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';

class NextQrOverlay extends StatelessWidget {
  final String description;
  final VoidCallback onCancel;

  const NextQrOverlay({
    super.key,
    required this.description,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeArea = MediaQuery.of(context).padding;

        final textPainter = TextPainter(
          text: TextSpan(text: description, style: NextText.bodySm400),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: constraints.maxWidth - 80);

        final holeTop = safeArea.top + 140 + 24 + 16 + textPainter.height + 74;
        final holeRect = Rect.fromLTWH(
          (constraints.maxWidth - 292) / 2,
          holeTop,
          292,
          292,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _HoleClipper(hole: holeRect),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    color: const Color(0xFF020501).withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 140),
                    const NextIcon(
                      'assets/icons/qr',
                      size: 24,
                      color: NextColor.fgWhite100,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        description,
                        style: NextText.bodySm400.copyWith(
                          color: NextColor.fgWhite80,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 74),
                    const SizedBox(width: 292, height: 292),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: NextButton(
                        text: "Cancel",
                        style: NextButtonStyle.outlined,
                        size: NextButtonSize.primary,
                        onTap: onCancel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
