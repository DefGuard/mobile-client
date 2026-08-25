import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';

class NextToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onTap;

  const NextToggle({super.key, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 250);
    const curve = Curves.easeOut;

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(!value) : null,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        width: 64,
        height: 28,
        decoration: BoxDecoration(
          color: value ? Color(0xff34C759) : NextColor.bgWhite20,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: duration,
              curve: curve,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 39,
                height: 24,
                decoration: BoxDecoration(
                  color: NextColor.fgWhite100,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Toggle Off')
Widget previewNextToggleOff() {
  return NextPreviewWrapper(child: NextToggle(value: false));
}

@Preview(name: 'Toggle On')
Widget previewNextToggleOn() {
  return NextPreviewWrapper(child: NextToggle(value: true));
}
