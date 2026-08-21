import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/riverpod/package_info/package_info.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:url_launcher/url_launcher.dart';

import 'icons/next_icon.dart';
import 'next_icon_button.dart';

const String _helpUrl = "https://docs.defguard.net/support";

sealed class _DrawerEntry {}

class _DrawerItemData extends _DrawerEntry {
  final String label;
  final String iconLeft;
  final String iconRight;
  final GoRouteData? route;
  final Function()? onPressed;

  _DrawerItemData({
    required this.label,
    required this.iconLeft,
    required this.iconRight,
    this.route,
    this.onPressed,
  });
}

class _DrawerDividerData extends _DrawerEntry {}

final allInstancesProvider = StreamProvider.autoDispose<List<DefguardInstance>>(
  (ref) {
    final db = ref.watch(databaseProvider);
    return db.select(db.defguardInstances).watch();
  },
);

class NextDrawer extends HookConsumerWidget {
  const NextDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(allInstancesProvider);
    final router = GoRouter.of(context);
    final RouteMatch lastMatch =
        router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : router.routerDelegate.currentConfiguration;
    final String location = matchList.uri.toString();

    final entries = useMemoized<List<_DrawerEntry>>(() {
      return [
        _DrawerItemData(
          label: "Application Logs",
          iconLeft: 'activity_notes',
          iconRight: 'arrow_small',
          route: TalkerScreenRoute(),
        ),
        _DrawerDividerData(),
        _DrawerItemData(
          label: "Help and Support",
          iconLeft: 'question',
          iconRight: 'open_in_new_window',
          onPressed: () async {
            final uri = Uri.parse(_helpUrl);
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {
              talker.error(e);
            }
          },
        ),
      ].where((entry) {
        if (entry is _DrawerItemData) {
          return entry.route == null ||
              (entry.route != null && entry.route!.location != location);
        }
        return true;
      }).toList();
    }, [location, instancesAsync]);

    return Container(
      decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  NextIconButton(
                    icon: 'close',
                    onTap: () {
                      Scaffold.of(context).closeDrawer();
                    },
                  ),
                ],
              ),
              const SizedBox(height: NextSpacing.xl4),
              ...entries.map((entry) {
                return switch (entry) {
                  _DrawerItemData data => DrawerItem(
                    label: data.label,
                    iconLeft: data.iconLeft,
                    iconRight: data.iconRight,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (data.onPressed != null) {
                        data.onPressed!();
                      }
                      if (data.route != null) {
                        data.route!.push(context);
                      }
                    },
                  ),
                  _DrawerDividerData() => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Container(height: 1, color: NextColor.bgWhite10),
                  ),
                };
              }),
              const Spacer(),
              const DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final String label;
  final String iconLeft;
  final String iconRight;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.label,
    required this.iconLeft,
    required this.iconRight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NextIcon(iconLeft, color: NextColor.fgWhite100, size: 20),
              const SizedBox(width: NextSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: NextText.bodySm400.copyWith(
                    color: NextColor.fgWhite100,
                  ),
                ),
              ),
              const SizedBox(width: NextSpacing.md),
              NextIcon(iconRight, color: NextColor.fgWhite50, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref
        .watch(packageInfoProvider)
        .maybeWhen(orElse: () => '', data: (info) => "v${info.version}");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset("assets/next/img/app_bar_logo.svg"),
        SizedBox(height: 14),
        Text(
          "Copyright \u00a9 2026 Defguard",
          style: NextText.bodyXs400.copyWith(color: NextColor.fgWhite50),
        ),
        SizedBox(height: 5),
        Text(
          "Application version: $version",
          style: NextText.bodyXs400.copyWith(color: NextColor.fgWhite50),
        ),
        // TODO: for task in 2.3
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 14),
        //   child: Container(height: 1, color: NextColor.bgWhite10),
        // ),
        // Text(
        //   "Defguard is made possible by other open-source software.",
        //   style: NextText.bodyXs400.copyWith(color: NextColor.fgWhite60),
        // ),
        // SizedBox(height: 5),
        // Row(
        //   children: [
        //     Text(
        //       "Learn more here",
        //       style: NextText.bodyXs400.copyWith(color: NextColor.fgWhite100),
        //     ),
        //     SizedBox(width: 4),
        //     NextIcon(
        //       "open_in_new_window",
        //       color: NextColor.fgWhite100,
        //       size: 16,
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
