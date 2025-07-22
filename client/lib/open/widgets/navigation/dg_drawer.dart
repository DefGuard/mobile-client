import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/riverpod/package_info/package_info.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

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

class _DrawerItemData {
  final String label;
  final GoRouteData route;

  const _DrawerItemData({required this.label, required this.route});
}

class DgDrawer extends HookConsumerWidget {
  const DgDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final RouteMatch lastMatch = router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch ? lastMatch.matches : router.routerDelegate.currentConfiguration;
    final String location = matchList.uri.toString();
    final year = DateTime.now().year;
    final version = ref
        .watch(packageInfoProvider)
        .maybeWhen(orElse: () => '', data: (info) => "v${info.version}");

    final items = useMemoized<List<_DrawerItemData>>(() {
      return [
        _DrawerItemData(label: "Instances", route: HomeScreenRoute()),
        _DrawerItemData(label: "Add Instance", route: AddInstanceScreenRoute()),
        _DrawerItemData(label: "Toaster test", route: ToastTestScreenRoute()),
        _DrawerItemData(
          label: "View Application Logs",
          route: TalkerScreenRoute(),
        ),
      ].where((item) => item.route.location != location).toList();
    }, [location]);

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
                      children: items
                          .map(
                            (data) => _MenuButton(
                              text: data.label,
                              route: data.route,
                            ),
                          )
                          .toList(),
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
                            Expanded(
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Copyright \u00a9 $year defguard",
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: DgText.copyright.copyWith(
                                        color: DgColor.textBodyPrimary,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Application version: $version",
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: DgText.copyright.copyWith(
                                        color: DgColor.textBodyPrimary,
                                      ),
                                    ),
                                  ),
                                ],
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
  final GoRouteData route;

  const _MenuButton({required this.text, required this.route});

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
      onPressed: () {
        Navigator.of(context).pop();
        route.push(context);
      },
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
