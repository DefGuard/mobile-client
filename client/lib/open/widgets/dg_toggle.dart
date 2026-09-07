import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';

class DgToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onTap;

  const DgToggle({super.key, required this.value, this.onTap});

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
          color: value ? Color(0xff34C759) : DgColor.bgWhite20,
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
                  color: DgColor.fgWhite100,
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
  return DgPreviewWrapper(child: DgToggle(value: false));
}

@Preview(name: 'Toggle On')
Widget previewNextToggleOn() {
  return DgPreviewWrapper(child: DgToggle(value: true));
}
