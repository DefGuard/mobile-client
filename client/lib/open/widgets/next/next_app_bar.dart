import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/next/images/dg_logo.dart';
import 'package:mobile/theme/next/spacing.dart';

import '../../../theme/next/color.dart';
import '../../../theme/next/text.dart';

class NextAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Widget? actionLeft;
  final List<Widget>? actionRight;
  final String? title;
  final String? subtitle;
  final bool? showLogo;

  const NextAppBar({
    super.key,
    this.height = 75, // 19 (top) + 44 (min height) + 12 (bottom)
    this.actionLeft,
    this.actionRight,
    this.title,
    this.subtitle,
    this.showLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: NextSpacing.xl,
            right: NextSpacing.xl,
            top: 19,
            bottom: 12,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: NextSpacing.xl,
              children: [
                actionLeft ?? const SizedBox(width: 44, height: 44),
                if (showLogo == true)
                  Expanded(
                    child: Align(
                      alignment: (actionRight?.length ?? 0) > 1
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: DgLogo(),
                    ),
                  )
                else if (title != null || subtitle != null)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: NextText.bodySm500.copyWith(
                              color: NextColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: NextText.bodyXs400.copyWith(
                              color: NextColor.fgWhite60,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (actionRight != null && actionRight!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: NextSpacing.md,
                    children: actionRight!,
                  )
                else
                  const SizedBox(width: 44, height: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
