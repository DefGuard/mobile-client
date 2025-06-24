import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_client/data/db/database.dart';
import 'package:mobile_client/open/widgets/buttons/dg_button.dart';
import 'package:mobile_client/open/widgets/icons/arrow_single.dart';
import 'package:mobile_client/open/widgets/icons/connection.dart';
import 'package:mobile_client/open/widgets/icons/icon_rotation.dart';
import 'package:mobile_client/open/widgets/limited_text.dart';
import 'package:mobile_client/open/widgets/nav.dart';
import 'package:mobile_client/router/routes.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

class _ScreenData {
  final DefguardInstance instance;
  final List<Location> locations;

  const _ScreenData({required this.instance, required this.locations});
}

final _screenDataProvider = FutureProvider.family<_ScreenData?, String>((
  ref,
  id,
) async {
  final int parsedId = int.parse(id);
  final db = ref.watch(databaseProvider);
  final instanceWithRefs = await db.managers.defguardInstances
      .withReferences((prefetch) => prefetch(locationsRefs: true))
      .filter((row) => row.id(parsedId))
      .getSingleOrNull();
  if (instanceWithRefs == null) {
    return null;
  } else {
    final (instance, refs) = instanceWithRefs;
    final locations = await refs.locationsRefs.get();
    return _ScreenData(locations: locations, instance: instance);
  }
});

class InstanceScreen extends HookConsumerWidget {
  final String id;

  const InstanceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenData = ref.watch(_screenDataProvider(id));

    return Scaffold(
      appBar: DgAppBar(title: "Locations"),
      drawer: DgDrawer(),
      body: Container(
        color: DgColor.frameBg,
        child: screenData.when(
          data: (screenData) {
            if (screenData == null) {
              Future.microtask(() {
                if (context.mounted) {
                  HomeScreenRoute().go(context);
                }
              });
              return SizedBox();
            }
            return _ScreenContent(screenData: screenData);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) {
            HomeScreenRoute().go(context);
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _ScreenContent extends HookConsumerWidget {
  final _ScreenData screenData;

  const _ScreenContent({required this.screenData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: DgSpacing.m,
              horizontal: DgSpacing.m,
            ),
            child: Column(
              spacing: DgSpacing.m,
              children: [
                DgButton(
                  width: double.infinity,
                  variant: DgButtonVariant.secondary,
                  size: DgButtonSize.standard,
                  text: "Back to instances list",
                  icon: DgIconArrowSingle(
                    size: 18,
                    direction: DgIconDirection.left,
                  ),
                  onTap: () {
                    HomeScreenRoute().go(context);
                  },
                ),
                Center(
                  child: Text(
                    "${screenData.instance.name} instance locations:",
                    style: DgText.sideBar,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.separated(
          itemCount: screenData.locations.length,
          separatorBuilder: (_, _) => SizedBox(height: DgSpacing.s),
          itemBuilder: (BuildContext context, int index) {
            final location = screenData.locations[index];
            return _LocationItem(location: location);
          },
        ),
      ],
    );
  }
}

class _LocationItem extends HookConsumerWidget {
  final Location location;

  const _LocationItem({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: DgSpacing.m),
      child: Container(
        constraints: BoxConstraints(minHeight: 64, maxHeight: 100),
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: DgSpacing.s),
        decoration: BoxDecoration(
          color: DgColor.navBg,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Row(
          spacing: 18,
          children: <Widget>[
            DgIconConnection(variant: DgIconConnectionVariant.disconnected),
            LimitedText(text: location.name, style: DgText.sideBar),
            Spacer(),
            DgButton(
              size: DgButtonSize.small,
              variant: DgButtonVariant.secondary,
              text: "Connect",
            ),
          ],
        ),
      ),
    );
  }
}
