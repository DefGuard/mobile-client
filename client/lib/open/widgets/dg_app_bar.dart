import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/images/dg_logo.dart';
import 'package:mobile/theme/spacing.dart';

import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

class DgAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double baseHeight = 75;

  final double height;
  final Widget? actionLeft;
  final List<Widget>? actionRight;
  final String? title;
  final String? subtitle;
  final bool? showLogo;

  DgAppBar({
    super.key,
    BuildContext? context,
    double? height,
    this.actionLeft,
    this.actionRight,
    this.title,
    this.subtitle,
    this.showLogo,
  }) : height =
           (height ?? baseHeight) +
           (context != null ? MediaQuery.paddingOf(context).top : 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: DgSpacing.xl,
            right: DgSpacing.xl,
            top: 19,
            bottom: 12,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: DgSpacing.xl,
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
                            style: DgText.bodySm500.copyWith(
                              color: DgColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: DgText.bodyXs400.copyWith(
                              color: DgColor.fgWhite60,
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
                    spacing: DgSpacing.md,
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
