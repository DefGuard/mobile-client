import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';

class DgRadioIndicator extends StatelessWidget {
  final int? size;
  final bool value;

  const DgRadioIndicator({super.key, this.size, required this.value});

  @override
  Widget build(BuildContext context) {
    final double boxSize = (size ?? 20).toDouble();
    final double circleSize = boxSize - 4;
    const duration = Duration(milliseconds: 200);
    const curve = Curves.easeInOut;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Center(
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? DgColor.bgWhite100 : Colors.transparent,
            border: Border.all(
              color: value ? DgColor.bgWhite100 : DgColor.borderAction,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedScale(
              duration: duration,
              curve: curve,
              scale: value ? 1.0 : 0.0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DgColor.fgAction,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Off')
Widget previewNextRadioIndicatorOff() {
  return const DgPreviewWrapper(child: DgRadioIndicator(value: false));
}

@Preview(name: 'On')
Widget previewNextRadioIndicatorOn() {
  return const DgPreviewWrapper(child: DgRadioIndicator(value: true));
}

@Preview(name: 'Big Off')
Widget previewNextRadioIndicatorBigOff() {
  return const DgPreviewWrapper(
    child: DgRadioIndicator(value: false, size: 40),
  );
}

@Preview(name: 'Big On')
Widget previewNextRadioIndicatorBigOn() {
  return const DgPreviewWrapper(
    child: DgRadioIndicator(value: true, size: 40),
  );
}
