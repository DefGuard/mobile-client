import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/screens/instance/widgets/connection_conflict_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/delete_instance_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/next_connect_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/next_refresh_instance_dialog.dart';
import 'package:mobile/open/screens/mfa/remote_mfa_qr_screen.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_bottom_sheet.dart';
import 'package:mobile/open/widgets/next/next_drawer.dart';
import 'package:mobile/open/widgets/next/next_location_card.dart';
import 'package:mobile/open/widgets/next/next_menu.dart';
import 'package:mobile/plugin.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:mobile/utils/update_instance.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wireguard_plugin/wireguard_plugin.dart';

import '../../../logging.dart';
import '../../services/snackbar_service.dart';
import '../../widgets/next/next_icon_button.dart';

part 'next_instance_screen.g.dart';

class _ScreenData {
  final DefguardInstance instance;
  final List<Location> locations;

  const _ScreenData({required this.instance, required this.locations});
}

@riverpod
Stream<_ScreenData?> _nextScreenData(Ref ref, String id) {
  final db = ref.read(databaseProvider);
  final parsedId = int.tryParse(id);
  if (parsedId == null) return Stream.value(null);

  final query = db.select(db.defguardInstances).join([
    drift.leftOuterJoin(
      db.locations,
      db.locations.instance.equalsExp(db.defguardInstances.id),
    ),
  ])..where(db.defguardInstances.id.equals(parsedId));

  return query.watch().map((rows) {
    if (rows.isEmpty) {
      return null;
    }

    final instance = rows.first.readTable(db.defguardInstances);
    final locations = rows
        .map((row) => row.readTableOrNull(db.locations))
        .whereType<Location>()
        .toList();

    return _ScreenData(instance: instance, locations: locations);
  });
}

@riverpod
Stream<bool> isSingleInstance(Ref ref) {
  return ref.watch(databaseProvider).watchIsSingleInstance();
}

class NextInstanceScreen extends HookConsumerWidget {
  final String id;

  const NextInstanceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsController = useOverlayPortalController();
    final actionsLayerLink = useMemoized(() => LayerLink());
    final screenDataAsync = ref.watch(_nextScreenDataProvider(id));
    final activeTunnel = ref.watch(pluginActiveTunnelStateProvider);
    final wireguardPlugin = ref.watch(wireguardPluginProvider);
    final biometricStatus = ref.watch(biometricsCapabilityProvider);
    final isSingleAsync = ref.watch(isSingleInstanceProvider);
    final isDeleting = useState(false);

    final onRefresh = useCallback(() async {
      try {
        final instance = screenDataAsync.value?.instance;
        if (instance == null) return;
        final (responseData, responseStatus, _) = await proxyApi
            .pollConfiguration(instance.proxyUrl, instance.poolingToken);
        if (responseData == null) {
          SnackbarService.showError(
            "Failed to get new information for instance.",
          );
          talker.error(
            "Failed to pull refresh instance data. Proxy response status: $responseStatus",
          );
          return;
        }
        await updateInstance(
          db: ref.read(databaseProvider),
          instance: instance,
          configs: responseData.configs,
          info: responseData.instance,
          token: responseData.token,
        );
        SnackbarService.show("Instance information updated");
      } catch (e) {
        SnackbarService.showError(
          "Failed to get new information for instance.",
        );
        talker.error("Failed pull refresh instance data.", e);
      }
    }, [screenDataAsync.value, ref]);

    final onDeleteInstance = useCallback(() async {
      try {
        final instance = screenDataAsync.value?.instance;
        if (instance == null) return;

        isDeleting.value = true;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => DeleteInstanceDialog(instance: instance),
        );

        if (confirmed == true && context.mounted) {
          talker.info("Instance deleted, determining next route...");
          final db = ref.read(databaseProvider);
          final instances = await db.select(db.defguardInstances).get();

          if (!context.mounted) return;

          if (instances.isEmpty) {
            talker.info("No instances left, going to Add Instance.");
            const AddInstanceScreenRoute().go(context);
          } else if (instances.length == 1) {
            final nextId = instances.first.id.toString();
            talker.info("One instance left ($nextId), navigating...");
            InstanceScreenRoute(id: nextId).go(context);
          } else {
            talker.info("${instances.length} instances left, going to list.");
            const InstancesListScreenRoute().go(context);
          }
        } else {
          isDeleting.value = false;
        }
      } catch (e, st) {
        isDeleting.value = false;
        talker.error("Error during instance deletion routing", e, st);
        if (context.mounted) {
          const InstancesListScreenRoute().go(context);
        }
      }
    }, [screenDataAsync.value, context]);

    useEffect(() {
      final data = screenDataAsync.value;
      if (data == null &&
          !screenDataAsync.isLoading &&
          !isDeleting.value &&
          screenDataAsync.hasValue) {
        talker.debug("Instance $id not found in DB, redirecting.");
        Future.microtask(() async {
          if (!context.mounted) return;
          final db = ref.read(databaseProvider);
          final instances = await db.select(db.defguardInstances).get();
          if (!context.mounted) return;

          if (instances.isEmpty) {
            const AddInstanceScreenRoute().go(context);
          } else if (instances.length == 1) {
            InstanceScreenRoute(id: instances.first.id.toString()).go(context);
          } else {
            const InstancesListScreenRoute().go(context);
          }
        });
      }
      return null;
    }, [screenDataAsync.value, screenDataAsync.isLoading, isDeleting.value]);

    final instance = screenDataAsync.value?.instance;

    return Scaffold(
      drawer: const NextDrawer(),
      extendBodyBehindAppBar: true,
      appBar: _InstanceAppBar(
        id: id,
        screenDataAsync: screenDataAsync,
        activeTunnel: activeTunnel,
        wireguardPlugin: wireguardPlugin,
        isSingleAsync: isSingleAsync,
        actionsController: actionsController,
        actionsLayerLink: actionsLayerLink,
        onDeleteInstance: onDeleteInstance,
        topPadding: MediaQuery.paddingOf(context).top,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.previewGradient),
        child: SafeArea(
          child: Stack(
            children: [
              screenDataAsync.when(
                data: (data) {
                  if (data == null || isDeleting.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: NextColor.fgWhite100,
                      ),
                    );
                  }

                  Widget content = _LocationList(
                    data: data,
                    activeTunnel: activeTunnel,
                    wireguardPlugin: wireguardPlugin,
                    biometricStatus: biometricStatus,
                  );

                  if (data.instance.enterpriseEnabled) {
                    content = RefreshIndicator(
                      color: NextColor.bgWhite100,
                      backgroundColor: NextColor.bgDarkBlue80,
                      onRefresh: onRefresh,
                      child: content,
                    );
                  }

                  return content;
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: NextColor.fgWhite100),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    "Error: $err",
                    style: const TextStyle(color: NextColor.fgWhite100),
                  ),
                ),
              ),
              if (instance != null &&
                  !isDeleting.value &&
                  instance.mfaKeysStored &&
                  biometricStatus.canOpenStorage)
                Positioned(
                  right: NextSpacing.xl,
                  bottom: _QrScanButton.bottomPadding,
                  child: _QrScanButton(
                    onTap: () => RemoteMfaQrScreenRoute(
                      RemoteMfaQrScreenData(instance: instance),
                    ).push(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String id;
  final AsyncValue<_ScreenData?> screenDataAsync;
  final PluginTunnelEventData? activeTunnel;
  final WireguardPlugin wireguardPlugin;
  final AsyncValue<bool> isSingleAsync;
  final OverlayPortalController actionsController;
  final LayerLink actionsLayerLink;
  final VoidCallback onDeleteInstance;
  final double topPadding;

  const _InstanceAppBar({
    required this.id,
    required this.screenDataAsync,
    required this.activeTunnel,
    required this.wireguardPlugin,
    required this.isSingleAsync,
    required this.actionsController,
    required this.actionsLayerLink,
    required this.onDeleteInstance,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return NextAppBar(
      context: context,
      showLogo: isSingleAsync.value == true,
      title: isSingleAsync.value == false
          ? screenDataAsync.maybeWhen(
              data: (data) => data?.instance.name ?? "Instance",
              orElse: () => "...",
            )
          : null,
      subtitle: isSingleAsync.value == false ? "Instance" : null,
      actionLeft: isSingleAsync.value == false
          ? NextIconButton(
              icon: "arrow_big",
              direction: NextIconDirection.left,
              onTap: () => const InstancesListScreenRoute().go(context),
            )
          : Builder(
              builder: (context) => NextIconButton(
                icon: "hamburger",
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      actionRight: [
        if (isSingleAsync.value == true)
          NextIconButton(
            icon: "plus",
            onTap: () {
              const AddInstanceScreenRoute().push(context);
            },
          ),
        OverlayPortal(
          controller: actionsController,
          overlayChildBuilder: (context) {
            return NextMenu(
              items: [
                if (activeTunnel != null)
                  NextMenuItem(
                    icon: "disconnect_all",
                    text: "Disconnect all locations",
                    onTap: () async {
                      try {
                        await wireguardPlugin.closeTunnel();
                        talker.debug("Disconnected all locations");
                      } catch (e) {
                        talker.error("Failed to disconnect all", e);
                        SnackbarService.showError("Failed to disconnect all");
                      }
                    },
                  ),
                NextMenuItem(
                  text: "Refresh configuration",
                  icon: "refresh",
                  onTap: () {
                    final instance = screenDataAsync.value?.instance;
                    if (instance == null) return;
                    showDialog(
                      context: context,
                      builder: (context) =>
                          NextRefreshInstanceDialog(instance: instance),
                    );
                  },
                ),
                NextMenuItem(
                  icon: "delete",
                  text: "Delete Instance",
                  onTap: onDeleteInstance,
                ),
              ],
              controller: actionsController,
              link: actionsLayerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
            );
          },
          child: CompositedTransformTarget(
            link: actionsLayerLink,
            child: NextIconButton(
              icon: "menu",
              onTap: actionsController.toggle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(NextAppBar.baseHeight + topPadding);
}

class _LocationList extends HookConsumerWidget {
  final _ScreenData data;
  final PluginTunnelEventData? activeTunnel;
  final WireguardPlugin wireguardPlugin;
  final BiometricsState biometricStatus;

  const _LocationList({
    required this.data,
    required this.activeTunnel,
    required this.wireguardPlugin,
    required this.biometricStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingLocationId = useState<int?>(null);

    Future<void> onDisconnect(Location location) async {
      try {
        await wireguardPlugin.closeTunnel();
        talker.debug("Disconnected from ${location.name}");
      } catch (e) {
        talker.error("Failed to disconnect", e);
        SnackbarService.showError("Failed to disconnect");
      }
    }

    Future<void> onConnect(BuildContext context, Location location) async {
      loadingLocationId.value = location.id;
      try {
        if (activeTunnel != null) {
          final bool? changeConnection = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return const ConnectionConflictDialog();
            },
          );

          if (changeConnection != true) {
            loadingLocationId.value = null;
            return;
          }

          await wireguardPlugin.closeTunnel();
        }

        if (context.mounted) {
          await showNextBottomSheet(
            context: context,
            child: NextConnectDialog(
              instance: data.instance,
              location: location,
              onConnect: (traffic, mfa) async {
                final permissionsGranted = await wireguardPlugin
                    .requestPermissions();
                if (permissionsGranted) {
                  if (context.mounted) {
                    await TunnelService.connect(
                      context: context,
                      instance: data.instance,
                      location: location,
                      wireguardPlugin: wireguardPlugin,
                      biometricsStatus: biometricStatus,
                      db: ref.read(databaseProvider),
                      trafficMethod: traffic,
                      mfaMethod: mfa,
                    );
                  }
                }
              },
            ),
          );
          talker.debug("Connected to ${location.name}");
        }
      } catch (e) {
        talker.error("Failed to connect", e);
        SnackbarService.showError("Failed to connect");
      } finally {
        loadingLocationId.value = null;
      }
    }

    final locations = data.locations;
    final connectedLocation = locations.firstWhereOrNull(
      (l) =>
          activeTunnel?.instanceId == data.instance.id &&
          activeTunnel?.locationId == l.id,
    );
    final otherLocations = locations
        .where((l) => l != connectedLocation)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NextSpacing.xl,
        NextSpacing.sm,
        NextSpacing.xl,
        _QrScanButton.reservedScrollSpace,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: NextSpacing.xl),
          child: Text(
            "Locations",
            style: NextText.h4.copyWith(color: NextColor.fgWhite100),
          ),
        ),
        if (connectedLocation != null) ...[
          Text(
            "Connected",
            style: NextText.bodyXs400.copyWith(color: NextColor.fgWhite70),
          ),
          const SizedBox(height: NextSpacing.md),
          NextLocationCard(
            location: connectedLocation,
            isConnected: true,
            routingMethod: activeTunnel?.traffic,
            // gated so a stored preference never renders an MFA chip on a
            // location whose MFA has since been disabled server-side
            mfaMethod: TunnelService.checkMfaEnabled(connectedLocation)
                ? connectedLocation.mfaMethod
                : null,
            onDisconnectTap: () => onDisconnect(connectedLocation),
          ),
          const SizedBox(height: NextSpacing.xl),
        ],
        if (otherLocations.isNotEmpty) ...[
          Text(
            "Offline",
            style: NextText.bodyXs400.copyWith(color: NextColor.fgWhite70),
          ),
          const SizedBox(height: NextSpacing.md),
          ...otherLocations.map(
            (location) => Padding(
              padding: const EdgeInsets.only(bottom: NextSpacing.md),
              child: NextLocationCard(
                location: location,
                isConnected: false,
                loading: loadingLocationId.value == location.id,
                mfaMethod: TunnelService.checkMfaEnabled(location)
                    ? location.mfaMethod
                    : null,
                onConnectTap: () => onConnect(context, location),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QrScanButton extends StatelessWidget {
  static const double size = 52;

  static const double bottomPadding = 6;

  static const double reservedScrollSpace =
      size + bottomPadding + NextSpacing.md;

  final VoidCallback onTap;

  const _QrScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: NextColor.fgWhite100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(child: NextIcon("qr", color: NextColor.fgAction)),
        ),
      ),
    );
  }
}
