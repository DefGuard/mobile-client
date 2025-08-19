import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/widgets/connection_conflict_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/delete_instance_dialog.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_method_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/refresh_instance_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/routing_method_dialog.dart';
import 'package:mobile/open/screens/scan_qr_screen.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_menu.dart';
import 'package:mobile/open/widgets/dg_pill.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/icons/arrow_single.dart';
import 'package:mobile/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile/open/widgets/icons/connection.dart';
import 'package:mobile/open/widgets/icons/icon_rotation.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/plugin.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/position.dart';
import 'package:mobile/utils/update_instance.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../../data/db/enums.dart';
import '../../../logging.dart';

part 'instance_screen.g.dart';

class _ScreenData {
  final DefguardInstance instance;
  final int instancesCount;
  final List<Location> locations;

  const _ScreenData({
    required this.instance,
    required this.locations,
    required this.instancesCount,
  });
}

@riverpod
Stream<_ScreenData?> _screenData(Ref ref, String id) {
  final db = ref.read(databaseProvider);
  final parsedId = int.parse(id);
  final query = db.select(db.defguardInstances).join([
    drift.leftOuterJoin(
      db.locations,
      db.locations.instance.equalsExp(db.defguardInstances.id),
    ),
  ])..where(db.defguardInstances.id.equals(parsedId));
  final instanceDataStream = query.watch().map((rows) {
    if (rows.isEmpty) {
      return null;
    }

    final instance = rows.first.readTable(db.defguardInstances);
    final locations = rows
        .map((row) => row.readTableOrNull(db.locations))
        .whereType<Location>()
        .toList();

    return Tuple2(instance, locations);
  });
  final instancesCountStream = db.defguardInstances.count().watchSingle();
  return Rx.combineLatest2(instanceDataStream, instancesCountStream, (
    data,
    count,
  ) {
    if (data == null) return null;
    return _ScreenData(
      instance: data.item1,
      locations: data.item2,
      instancesCount: count,
    );
  });
}

class InstanceScreen extends HookConsumerWidget {
  final String id;

  const InstanceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenData = ref.watch(_screenDataProvider(id));

    return DgScaffold(
      title: "Locations",
      floatingActionButton: screenData.when(
        data: (screenData) {
          if (screenData != null) {
            return SizedBox(
              height: 60,
              width: 60,
              child: FloatingActionButton(
                onPressed: () {
                  final data = ScanQrScreenData(
                    intent: ScanQrScreenDataIntent.remoteMfa,
                    instance: screenData.instance,
                  );
                  QRScreenRoute(data).push(context);
                },
                backgroundColor: DgColor.mainPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SvgPicture.asset(
                  "assets/icons/icon-qr.svg",
                  width: 32,
                  height: 32,
                ),
              ),
            );
          }
          return null;
        },
        loading: () => null,
        error: (_, _) => null,
      ),
      child: Container(
        color: DgColor.frameBg,
        child: screenData.when(
          data: (screenData) {
            if (screenData == null) {
              talker.debug("Instance $id not found id DB, redirecting.");
              Future.microtask(() {
                if (context.mounted) {
                  HomeScreenRoute().go(context);
                }
              });
              return const SizedBox();
            }
            if (screenData.instance.enterpriseEnabled) {
              return _PullWrapper(
                screenData: screenData,
                child: _ScreenContent(screenData: screenData),
              );
            }
            return _ScreenContent(screenData: screenData);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) {
            talker.error("Instance route screen data returned error", err);
            HomeScreenRoute().go(context);
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _PullWrapper extends HookConsumerWidget {
  final Widget child;
  final _ScreenData screenData;

  const _PullWrapper({required this.screenData, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    return RefreshIndicator(
      color: DgColor.mainPrimary,
      onRefresh: () async {
        final msg = ScaffoldMessenger.of(context);
        try {
          final instance = screenData.instance;
          final (responseData, responseStatus) = await proxyApi
              .pollConfiguration(instance.proxyUrl, instance.poolingToken);
          if (responseData == null) {
            msg.showSnackBar(
              dgSnackBar(text: "Failed to get new information for instance."),
            );
            talker.error(
              "Failed to pull refresh instance data. Proxy response status: $responseStatus",
            );
            return;
          }
          await updateInstance(
            db: db,
            instance: instance,
            configs: responseData.configs,
            info: responseData.instance,
            token: responseData.token,
          );
          msg.showSnackBar(
            dgSnackBar(
              text: "Instance information updated",
              customDuration: Duration(seconds: 5),
            ),
          );
        } catch (e) {
          msg.showSnackBar(
            dgSnackBar(
              text: "Failed to get new information for instance.",
              customDuration: Duration(seconds: 5),
            ),
          );
          talker.error("Failed pull refresh instance data.", e);
        }
      },
      child: child,
    );
  }
}

class _ScreenContent extends HookConsumerWidget {
  final _ScreenData screenData;

  const _ScreenContent({required this.screenData});

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
                  if (screenData.instancesCount > 1)
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
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "${screenData.instance.name} instance locations:",
                      textAlign: TextAlign.center,
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
              return _LocationItem(
                key: Key(location.id.toString()),
                location: location,
                instance: screenData.instance,
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: DgSpacing.m)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: DgSpacing.xs + DgSpacing.m,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: DgSpacing.s,
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: DgColor.textAlert,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: DgSpacing.s,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return DeleteInstanceDialog(
                                      instance: screenData.instance,
                                    );
                                  },
                                );
                              },
                              child: Text(
                                "Delete This Instance",
                                style: DgText.buttonXS.copyWith(
                                  color: DgColor.textAlert,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(minHeight: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: DgColor.textBodySecondary,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => RefreshInstanceDialog(
                                instance: screenData.instance,
                              ),
                            );
                          },
                          child: Text(
                            "Refresh Configuration",
                            style: DgText.buttonXS.copyWith(
                              color: DgColor.textBodySecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: DgSpacing.m)),
        ],
      ),
    );
  }
}

class _LocationItem extends HookConsumerWidget {
  final Location location;
  final DefguardInstance instance;

  const _LocationItem({
    super.key,
    required this.location,
    required this.instance,
  });

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

    final mfaEnabled = TunnelService.checkMfaEnabled(location);

    final dgMenuItems = useMemoized<List<DgMenuItem>>(() {
      return [
        if (location.mfaEnabled == true ||
            location.locationMfaMode == LocationMfaMode.internal ||
            location.locationMfaMode == LocationMfaMode.external)
          DgMenuItem(
            text: "Select MFA Method",
            onTap: () {
              print(location.mfaMethod);
              showDialog(
                context: context,
                builder: (_) => MfaMethodDialog(
                  instance: instance,
                  location: location,
                  intention: MfaMethodDialogIntention.save,
                ),
              );
            },
          ),
        if (!instance.disableAllTraffic)
          DgMenuItem(
            text: "Select Traffic Routing",
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => RoutingMethodDialog(
                  location: location,
                  intention: RoutingMethodDialogIntention.save,
                ),
              );
            },
          ),
      ];
    }, [location, instance]);

    final disconnect = useCallback<Future<bool> Function()>(() async {
      try {
        await wireguardPlugin.closeTunnel();
        talker.debug("Location ${location.name}(${location.id}) disconnected");
        return true;
      } catch (e) {
        talker.error(
          "Failed to close tunnel for ${instance.name}(${instance.id}) - ${location.name}(${location.id}) ! Reason: $e",
        );
        return false;
      }
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
            constraints: BoxConstraints(minHeight: 64),
            padding: EdgeInsets.symmetric(
              vertical: 13.5,
              horizontal: DgSpacing.s,
            ),
            decoration: BoxDecoration(
              color: DgColor.navBg,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Row(
              children: <Widget>[
                DgIconConnection(
                  variant: isConnected.value
                      ? DgIconConnectionVariant.connected
                      : DgIconConnectionVariant.disconnected,
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location.name, style: DgText.sideBar),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: DgSpacing.xs,
                        children: [
                          if (mfaEnabled) DgPill(text: "MFA"),
                          if (trafficLabel.value != null)
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  trafficLabel.value!,
                                  textAlign: TextAlign.left,
                                  style: DgText.buttonXS.copyWith(
                                    color: DgColor.textBodySecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: DgSpacing.xxs + 1),
                DgButton(
                  size: DgButtonSize.small,
                  variant: DgButtonVariant.secondary,
                  iconColor: DgColor.textAlert,
                  icon: isConnected.value ? DgIconX().copyWith(size: 12) : null,
                  text: isConnected.value ? "Disconnect" : "Connect",
                  loading: isLoading.value,
                  onTap: () async {
                    final msg = ScaffoldMessenger.of(context);
                    print("Location traffic pref: ${location.trafficMethod}");
                    isLoading.value = true;
                    // check if there is active tunnel if so ask user if he want to change the active connection
                    if (activeTunnel != null) {
                      if (!isConnected.value) {
                        talker.debug("Connection change started");
                        // connection is on another location so ask if user want to change active to this one
                        final bool? changeConnection = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return ConnectionConflictDialog();
                          },
                        );
                        // user cancelled the operation
                        if (changeConnection == null ||
                            changeConnection == false) {
                          talker.debug("Connection change cancelled");
                          isLoading.value = false;
                          return;
                        } else {
                          if (!(await disconnect())) {
                            isLoading.value = false;
                            return;
                          }
                          talker.debug("Previous connection closed");
                        }
                      } else {
                        // active connection is the current location means disconnect
                        await disconnect();
                        isLoading.value = false;
                        return;
                      }
                    }
                    // connect
                    try {
                      final permissionsGranted = await wireguardPlugin
                          .requestPermissions();
                      if (permissionsGranted) {
                        if (context.mounted) {
                          await TunnelService.connect(
                            context: context,
                            instance: instance,
                            location: location,
                            wireguardPlugin: wireguardPlugin,
                          );
                          talker.debug(
                            "Location ${location.name} (${location.id}) connected",
                          );
                        }
                      }
                    } catch (e) {
                      talker.error(
                        "Failed to connect into ${instance.name}-${location.name} ! Reason: $e",
                      );
                      msg.showSnackBar(
                        dgSnackBar(
                          text: "Failed to connect.",
                          textColor: DgColor.textAlert,
                        ),
                      );
                    } finally {
                      isLoading.value = false;
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
