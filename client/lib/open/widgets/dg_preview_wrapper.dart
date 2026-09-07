import 'package:material_ui/material_ui.dart';
import 'package:mobile/theme/color.dart';

class DgPreviewWrapper extends StatelessWidget {
  static const double defaultMaxWidth = 500;

  final Widget child;

  /// Upper bound on the preview width; the child still shrink-wraps below it.
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  const DgPreviewWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          decoration: const BoxDecoration(gradient: DgColor.previewGradient),
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? defaultMaxWidth,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
