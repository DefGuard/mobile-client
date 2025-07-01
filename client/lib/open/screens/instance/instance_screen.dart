import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_client/data/db/database.dart';
import 'package:mobile_client/data/plugin/plugin.dart';
import 'package:mobile_client/main.dart';
import 'package:mobile_client/open/riverpod/plugin/plugin.dart';
import 'package:mobile_client/open/screens/instance/widgets/connect_dialog.dart';
import 'package:mobile_client/open/screens/instance/widgets/delete_instance_dialog.dart';
import 'package:mobile_client/open/widgets/buttons/dg_button.dart';
import 'package:mobile_client/open/widgets/icons/arrow_single.dart';
import 'package:mobile_client/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile_client/open/widgets/icons/connection.dart';
import 'package:mobile_client/open/widgets/icons/icon_rotation.dart';
import 'package:mobile_client/open/widgets/limited_text.dart';
import 'package:mobile_client/open/widgets/nav.dart';
import 'package:mobile_client/plugin.dart';
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

  bool getLocationConnected(
    PluginTunnelEventData? activeTunnel,
    int instanceId,
    int locationId,
  ) {
    if (activeTunnel != null) {
      return activeTunnel.instanceId == instanceId &&
          activeTunnel.locationId == locationId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTunnel = ref.watch(pluginActiveTunnelStateProvider);
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
            final isConnected = getLocationConnected(
              activeTunnel,
              instance.id,
              location.id,
            );
            return _LocationItem(
              location: location,
              instance: instance,
              isConnected: isConnected,
            );
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
                      style: DgText.buttonXS.copyWith(color: DgColor.textAlert),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationItem extends HookConsumerWidget {
  final Location location;
  final DefguardInstance instance;
  final bool isConnected;

  const _LocationItem({
    required this.location,
    required this.instance,
    required this.isConnected,
  });

  PluginConnectPayload makePayload() {
    return PluginConnectPayload(
      publicKey: location.pubKey,
      privateKey: instance.privKey,
      address: location.address,
      dns: location.dns,
      endpoint: location.endpoint,
      allowedIps: location.allowedIps,
      keepalive: location.keepAliveInterval,
      locationName: location.name,
      locationId: location.id,
      instanceId: instance.id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wireguardPlugin = ref.watch(wireguardPluginProvider);
    final isLoading = useState(false);

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
            DgIconConnection(
              variant: isConnected
                  ? DgIconConnectionVariant.connected
                  : DgIconConnectionVariant.disconnected,
            ),
            LimitedText(text: location.name, style: DgText.sideBar),
            Spacer(),
            DgButton(
              size: DgButtonSize.small,
              variant: DgButtonVariant.secondary,
              iconColor: DgColor.textAlert,
              icon: isConnected ? DgIconX().copyWith(size: 12) : null,
              text: isConnected ? "Disconnect" : "Connect",
              loading: isLoading.value,
              onTap: () async {
                if (isConnected) {
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
                  try {
                    isLoading.value = true;
                    final permissionsGranted = await wireguardPlugin
                        .requestPermissions();
                    if (permissionsGranted) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            final payload = makePayload();
                            return ConnectDialog(payload: payload);
                          },
                        );
                      }
                    }
                  } finally {
                    isLoading.value = false;
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
