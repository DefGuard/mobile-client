import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';

import 'package:mobile/theme/color.dart';
import 'icons/dg_icon.dart';
import 'dg_preview_wrapper.dart';

enum DgIconButtonSize { primary, small }

class DgIconButton extends StatelessWidget {
  final String icon;
  final DgIconDirection? direction;
  final VoidCallback? onTap;
  final DgIconButtonSize size;

  const DgIconButton({
    super.key,
    required this.icon,
    this.direction,
    this.onTap,
    this.size = DgIconButtonSize.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = size == DgIconButtonSize.small;
    final borderRadius = BorderRadius.circular(isSmall ? 8 : 100);

    return Container(
      width: isSmall ? 24 : null,
      height: isSmall ? 24 : null,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: DgColor.bgWhite5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 4 : 12),
            child: DgIcon(
              icon,
              size: isSmall ? 16 : 20,
              color: DgColor.fgWhite100,
              direction: direction,
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Default', group: 'DgIconButton')
Widget previewNextIconButton() {
  return DgPreviewWrapper(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DgIconButton(icon: 'arrow_small', onTap: () {}),
        const SizedBox(height: 8),
        DgIconButton(
          icon: 'arrow_small',
          size: DgIconButtonSize.small,
          onTap: () {},
        ),
      ],
    ),
  );
}
