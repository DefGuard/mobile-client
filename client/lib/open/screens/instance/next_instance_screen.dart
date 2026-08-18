import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_location_card.dart';
import 'package:mobile/open/widgets/next/next_menu.dart';
import 'package:mobile/plugin.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: NextAppBar(
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
            : NextIconButton(icon: "hamburger", onTap: () {}),
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
                  NextMenuItem(
                    icon: "disconnect_all",
                    text: "Disconnect all locations",
                    onTap: () {},
                  ),
                  NextMenuItem(
                    text: "Refresh configuration",
                    icon: "refresh",
                    onTap: () {
                      ref.invalidate(_nextScreenDataProvider(id));
                    },
                  ),
                  NextMenuItem(
                    icon: "delete",
                    text: "Delete Instance",
                    onTap: () {},
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
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.previewGradient),
        child: SafeArea(
          child: screenDataAsync.when(
            data: (data) {
              if (data == null) {
                talker.debug("Instance $id not found in DB, redirecting.");
                Future.microtask(() {
                  if (context.mounted) {
                    InstancesListScreenRoute().go(context);
                  }
                });
                return const Center(
                  child: CircularProgressIndicator(color: NextColor.fgWhite100),
                );
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
                  NextSpacing.xl,
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
                      style: NextText.bodyXs400.copyWith(
                        color: NextColor.fgWhite70,
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    NextLocationCard(
                      location: connectedLocation,
                      isConnected: true,
                      routingMethod: activeTunnel?.traffic,
                      onDisconnectTap: () async {
                        try {
                          await wireguardPlugin.closeTunnel();
                          talker.debug(
                            "Disconnected from ${connectedLocation.name}",
                          );
                        } catch (e) {
                          talker.error("Failed to disconnect", e);
                          SnackbarService.showError("Failed to disconnect");
                        }
                      },
                    ),
                    const SizedBox(height: NextSpacing.xl),
                  ],
                  if (otherLocations.isNotEmpty) ...[
                    Text(
                      "Offline",
                      style: NextText.bodyXs400.copyWith(
                        color: NextColor.fgWhite70,
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    ...otherLocations.map(
                      (location) => Padding(
                        padding: const EdgeInsets.only(bottom: NextSpacing.md),
                        child: NextLocationCard(
                          location: location,
                          isConnected: false,
                          onConnectTap: () async {
                            try {
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
                                  );
                                  talker.debug("Connected to ${location.name}");
                                }
                              }
                            } catch (e) {
                              talker.error("Failed to connect", e);
                              SnackbarService.showError("Failed to connect");
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              );
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
        ),
      ),
    );
  }
}
