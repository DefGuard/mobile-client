import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/widgets/connection_conflict_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/delete_instance_dialog.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_menu.dart';
import 'package:mobile/open/widgets/icons/arrow_single.dart';
import 'package:mobile/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile/open/widgets/icons/connection.dart';
import 'package:mobile/open/widgets/icons/icon_rotation.dart';
import 'package:mobile/open/widgets/limited_text.dart';
import 'package:mobile/open/widgets/nav.dart';
import 'package:mobile/plugin.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/position.dart';

import '../../../data/db/enums.dart';
import '../../../logging.dart';

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
            return _ScreenContent(
              screenData: screenData,
              instance: screenData.instance,
            );
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
  final DefguardInstance instance;

  const _ScreenContent({required this.screenData, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: CustomScrollView(
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
              return _LocationItem(location: location, instance: instance);
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: DgSpacing.s,
                left: DgSpacing.l,
                right: DgSpacing.l,
              ),
              child: Container(
                constraints: BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return DeleteInstanceDialog(instance: instance);
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 0.5,
                            color: DgColor.textAlert,
                          ),
                        ),
                      ),
                      child: Text(
                        "Delete This Instance",
                        style: DgText.buttonXS.copyWith(
                          color: DgColor.textAlert,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationItem extends HookConsumerWidget {
  final Location location;
  final DefguardInstance instance;

  const _LocationItem({required this.location, required this.instance});

  bool checkConnected(PluginTunnelEventData? activeTunnel) {
    if (activeTunnel == null) return false;
    return activeTunnel.instanceId == instance.id &&
        activeTunnel.locationId == location.id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAnchorKey = useMemoized(() => GlobalKey());
    final menuController = useOverlayPortalController();
    final wireguardPlugin = ref.watch(wireguardPluginProvider);
    final activeTunnel = ref.watch(pluginActiveTunnelStateProvider);
    final isConnected = useState<bool>(checkConnected(activeTunnel));
    final isLoading = useState(false);
    final trafficLabel = useState<String?>(null);

    final dgMenuItems = useMemoized<List<DgMenuItem>>(() {
      return [
        DgMenuItem(text: "Select MFA Method", onTap: () {}),
        DgMenuItem(text: "Select Traffic Routing", onTap: () {}),
      ];
    }, []);

    // set connected flag
    useEffect(() {
      final connected = checkConnected(activeTunnel);
      isConnected.value = connected;
      if (connected && activeTunnel != null) {
        switch (activeTunnel.traffic) {
          case RoutingMethod.all:
            trafficLabel.value = "All Traffic";
            break;
          case RoutingMethod.predefined:
            trafficLabel.value = "Predefined Traffic";
            break;
        }
      } else {
        trafficLabel.value = null;
      }
      return null;
    }, [activeTunnel]);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: DgSpacing.m),
      child: GestureDetector(
        onLongPress: () {
          menuController.toggle();
        },
        child: OverlayPortal(
          controller: menuController,
          overlayChildBuilder: (BuildContext _) {
            final anchorGeometry = WidgetGeometry.fromKey(menuAnchorKey);
            return DgMenu(
              items: dgMenuItems,
              anchorGeometry: anchorGeometry,
              controller: menuController,
            );
          },
          child: Container(
            key: menuAnchorKey,
            constraints: BoxConstraints(minHeight: 64, maxHeight: 100),
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: DgSpacing.s),
            decoration: BoxDecoration(
              color: DgColor.navBg,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Row(
              spacing: 18,
              children: <Widget>[
                DgIconConnection(
                  variant: isConnected.value
                      ? DgIconConnectionVariant.connected
                      : DgIconConnectionVariant.disconnected,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LimitedText(text: location.name, style: DgText.sideBar),
                      if (trafficLabel.value != null)
                        LimitedText(
                          text: trafficLabel.value!,
                          style: DgText.buttonXS.copyWith(
                            color: DgColor.textBodySecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                DgButton(
                  size: DgButtonSize.small,
                  variant: DgButtonVariant.secondary,
                  iconColor: DgColor.textAlert,
                  icon: isConnected.value ? DgIconX().copyWith(size: 12) : null,
                  text: isConnected.value ? "Disconnect" : "Connect",
                  loading: isLoading.value,
                  onTap: () async {
                    if (isConnected.value) {
                      isLoading.value = true;
                      try {
                        await wireguardPlugin.closeTunnel();
                      } on PlatformException catch (e) {
                        talker.error(
                          "Closing tunnel for ${instance.name} - ${location.name} Failed ! Reason: ${e.message}",
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    } else {
                      if (activeTunnel != null) {
                        final bool? changeConnection = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return ConnectionConflictDialog();
                          },
                        );
                        if (changeConnection == null ||
                            changeConnection == false) {
                          return;
                        }
                      }
                      try {
                        isLoading.value = true;
                        final permissionsGranted = await wireguardPlugin
                            .requestPermissions();
                        if (permissionsGranted) {
                          if (context.mounted) {
                            await TunnelService.connect(
                              context: context,
                              instance: instance,
                              location: location,
                              payload: TunnelService.makePayload(
                                instance,
                                location,
                              ),
                              wireguardPlugin: wireguardPlugin,
                            );
                          }
                        }
                      } catch (e) {
                        talker.error(
                          "Failed to connect into ${instance.name}-${location.name} ! Reason: $e",
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
