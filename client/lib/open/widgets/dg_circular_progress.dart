import 'package:material_ui/material_ui.dart';
import 'package:mobile/theme/color.dart';

class DgCircularProgress extends StatelessWidget {
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;

  const DgCircularProgress({
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
        valueColor: AlwaysStoppedAnimation(color ?? DgColor.fgWhite100),
        backgroundColor: backgroundColor ?? DgColor.fgWhite30,
      ),
    );
  }
}
