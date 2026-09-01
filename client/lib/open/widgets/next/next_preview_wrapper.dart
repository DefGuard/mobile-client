import 'package:flutter/material.dart';
import 'package:mobile/theme/next/color.dart';

class NextPreviewWrapper extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;

  const NextPreviewWrapper({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          decoration: const BoxDecoration(gradient: NextColor.previewGradient),
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width ?? 500,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
