import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/riverpod/package_info/package_info.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

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
              Center(
                child: Text(
                  title,
                  style: DgText.body1.copyWith(color: DgColor.textBodyPrimary),
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

class _DrawerLogo extends StatelessWidget {
  const _DrawerLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/drawer-logo.svg',
      colorFilter: ColorFilter.mode(DgColor.textBodyPrimary, BlendMode.srcIn),
    );
  }
}

class DgDrawer extends HookConsumerWidget {
  const DgDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final version = ref
        .watch(packageInfoProvider)
        .maybeWhen(orElse: () => '', data: (info) => "v${info.version}");

    return Container(
      color: DgColor.navBg,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
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
                  Center(
                    child: Text(
                      "Menu",
                      style: DgText.body1.copyWith(
                        color: DgColor.textBodyPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Scaffold.of(context).closeDrawer();
                    },
                    icon: const _IconX(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(DgSpacing.m),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      spacing: DgSpacing.s,
                      children: [
                        _MenuButton(
                          text: "Instances",
                          onPressed: () {
                            HomeScreenRoute().push(context);
                          },
                        ),
                        _MenuButton(
                          text: "Add Instance",
                          onPressed: () {
                            AddInstanceScreenRoute().push(context);
                          },
                        ),
                        _MenuButton(
                          text: "Toaster test",
                          onPressed: () {
                            ToastTestScreenRoute().push(context);
                          },
                        ),
                        _MenuButton(
                          text: "View Application Logs",
                          onPressed: () {
                            TalkerScreenRoute().push(context);
                          },
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            width: 1,
                            color: DgColor.borderPrimary,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(DgSpacing.s),
                        child: Row(
                          spacing: DgSpacing.s,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _DrawerLogo(),
                            Text(
                              "Copyright \u00a9 $year defguard\nApplication version: $version",
                              style: DgText.copyright.copyWith(
                                color: DgColor.textBodyPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _MenuButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 43),
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.symmetric(
          vertical: DgSpacing.xs,
          horizontal: DgSpacing.s,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      onPressed: onPressed,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: DgText.sideBar.copyWith(color: DgColor.textBodyPrimary),
        ),
      ),
    );
  }
}

class _IconX extends StatelessWidget {
  const _IconX();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset("assets/icons/icon-x.svg", width: 40, height: 40);
  }
}
