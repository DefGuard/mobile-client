import 'package:material_ui/material_ui.dart';
import 'package:mobile/theme/next/color.dart';

class NextCircularProgress extends StatelessWidget {
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;

  const NextCircularProgress({
    super.key,
    this.color,
    this.backgroundColor,
    this.size = 20,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(color ?? NextColor.fgWhite100),
        backgroundColor: backgroundColor ?? NextColor.fgWhite30,
      ),
    );
  }
}
