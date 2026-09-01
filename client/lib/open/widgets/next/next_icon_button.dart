import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';

import '../../../theme/next/color.dart';
import 'icons/next_icon.dart';
import 'next_preview_wrapper.dart';

enum NextIconButtonSize { primary, small }

class NextIconButton extends StatelessWidget {
  final String icon;
  final NextIconDirection? direction;
  final VoidCallback? onTap;
  final NextIconButtonSize size;

  const NextIconButton({
    super.key,
    required this.icon,
    this.direction,
    this.onTap,
    this.size = NextIconButtonSize.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = size == NextIconButtonSize.small;
    final borderRadius = BorderRadius.circular(isSmall ? 8 : 100);

    return Container(
      width: isSmall ? 24 : null,
      height: isSmall ? 24 : null,
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
            padding: EdgeInsets.all(isSmall ? 4 : 12),
            child: NextIcon(
              icon,
              size: isSmall ? 16 : 20,
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NextIconButton(icon: 'arrow_small', onTap: () {}),
        const SizedBox(height: 8),
        NextIconButton(
          icon: 'arrow_small',
          size: NextIconButtonSize.small,
          onTap: () {},
        ),
      ],
    ),
  );
}
