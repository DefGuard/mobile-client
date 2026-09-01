import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

class NextMainCta extends StatelessWidget {
  final bool connected;
  final String text;
  final VoidCallback? onTap;

  const NextMainCta({
    super.key,
    required this.text,
    this.connected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    const curve = Curves.easeInOut;

    final backgroundColor = connected
        ? Colors.transparent
        : NextColor.bgWhite100;
    final border = connected
        ? Border.all(color: NextColor.borderDefault, width: 1)
        : null;
    final textStyle = (connected ? NextText.bodySm400 : NextText.bodySm600)
        .copyWith(color: connected ? NextColor.fgWhite100 : NextColor.fgAction);

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
            padding: const EdgeInsets.symmetric(horizontal: NextSpacing.lg),
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
  return NextPreviewWrapper(
    child: NextMainCta(text: 'Connect', connected: false, onTap: () {}),
  );
}

@Preview(name: 'Connected')
Widget previewConnected() {
  return NextPreviewWrapper(
    child: NextMainCta(text: 'Connected', connected: true, onTap: () {}),
  );
}
