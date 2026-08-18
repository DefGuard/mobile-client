import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../theme/next/color.dart';
import 'icons/next_icon.dart';
import 'next_preview_wrapper.dart';

class NextIconButton extends StatelessWidget {
  final String icon;
  final NextIconDirection? direction;
  final VoidCallback? onTap;

  const NextIconButton({
    super.key,
    required this.icon,
    this.direction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(100);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: NextColor.bgWhite5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: NextIcon(
              icon,
              size: 20,
              color: NextColor.fgWhite100,
              direction: direction,
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Default', group: 'NextIconButton')
Widget previewNextIconButton() {
  return NextPreviewWrapper(
    child: NextIconButton(icon: 'arrow_small', onTap: () {}),
  );
}
