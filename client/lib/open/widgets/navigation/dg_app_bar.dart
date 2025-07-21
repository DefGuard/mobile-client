import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../theme/color.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text.dart';

class DgAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  static final double _height = 44 + (DgSpacing.s * 2);

  const DgAppBar({super.key, required this.title});

  @override
  Size get preferredSize => Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Container(
          color: DgColor.navBg,
          padding: EdgeInsetsGeometry.all(DgSpacing.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/nav-logo.svg',
                width: 40,
                height: 44,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: DgText.body1.copyWith(
                      color: DgColor.textBodyPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/nav-hamburger.svg',
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
