import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class DgMainCta extends StatelessWidget {
  final bool connected;
  final String text;
  final VoidCallback? onTap;

  const DgMainCta({
    super.key,
    required this.text,
    this.connected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    const curve = Curves.easeInOut;

    final backgroundColor = connected ? Colors.transparent : DgColor.bgWhite100;
    final border = connected
        ? Border.all(color: DgColor.borderDefault, width: 1)
        : null;
    final textStyle = (connected ? DgText.bodySm400 : DgText.bodySm600)
        .copyWith(color: connected ? DgColor.fgWhite100 : DgColor.fgAction);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      height: 36,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DgSpacing.lg),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: duration,
                curve: curve,
                style: textStyle,
                child: Text(text, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Not Connected')
Widget previewNotConnected() {
  return DgPreviewWrapper(
    child: DgMainCta(text: 'Connect', connected: false, onTap: () {}),
  );
}

@Preview(name: 'Connected')
Widget previewConnected() {
  return DgPreviewWrapper(
    child: DgMainCta(text: 'Connected', connected: true, onTap: () {}),
  );
}
