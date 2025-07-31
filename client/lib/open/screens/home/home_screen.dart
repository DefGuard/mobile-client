// ignore_for_file: unused_element
import 'package:biometric_storage/biometric_storage.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/widgets/circular_progress.dart';
import 'package:mobile/open/widgets/dg_menu.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/icons/arrow_single.dart';
import 'package:mobile/open/widgets/icons/connection.dart';
import 'package:mobile/open/widgets/limited_text.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/position.dart';
import 'package:mobile/utils/secure_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(
      title: "Instances",
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          onPressed: () {
            AddInstanceScreenRoute().push(context);
          },
          backgroundColor: DgColor.mainPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SvgPicture.asset(
            "assets/icons/icon-plus.svg",
            width: 36,
            height: 36,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: Container(
        color: DgColor.frameBg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(DgSpacing.m),
            child: _InstancesList(),
          ),
        ),
      ),
    );
  }
}

final allInstancesProvider = StreamProvider.autoDispose<List<DefguardInstance>>(
  (ref) {
    final db = ref.watch(databaseProvider);
    return db.defguardInstances.all().watch();
  },
);

class _InstancesList extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final asyncInstances = ref.watch(allInstancesProvider);
    final activeTunnel = ref.watch(pluginActiveTunnelStateProvider);

    Future<void> handleDelete(int instanceId) async {
      final messenger = ScaffoldMessenger.of(context);
      await db.managers.defguardInstances
          .filter((f) => f.id(instanceId))
          .delete();
      messenger.showSnackBar(
        dgSnackBar(
          text: "Instance removed.",
          customDuration: Duration(seconds: 5),
        ),
      );
    }

    Future<void> handleDeleteAll() async {
      final messenger = ScaffoldMessenger.of(context);
      await db.managers.defguardInstances.delete();
      messenger.showSnackBar(
        dgSnackBar(
          text: "All instances removed",
          customDuration: Duration(seconds: 5),
        ),
      );
    }

    return asyncInstances.when(
      data: (instances) {
        if (instances.isEmpty) {
          return Center(child: Text("No instances found", style: DgText.body1));
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: DgSpacing.s)),
            SliverList.separated(
              itemCount: instances.length,
              separatorBuilder: (_, _) => SizedBox(height: DgSpacing.s),
              itemBuilder: (BuildContext context, int index) {
                final instance = instances[index];
                final bool isConnected;
                if (activeTunnel != null) {
                  isConnected = instance.id == activeTunnel.instanceId;
                } else {
                  isConnected = false;
                }
                return _InstanceItem(
                  instance: instance,
                  isConnected: isConnected,
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: DgCircularProgress()),
      error: (e, _) => Center(child: Text("Error $e")),
    );
  }
}

class _InstanceItem extends HookConsumerWidget {
  final DefguardInstance instance;
  final bool isConnected;

  const _InstanceItem({required this.instance, required this.isConnected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final menuAnchorKey = useMemoized(() => GlobalKey(), []);
    final menuController = useOverlayPortalController();
    final menuItems = useMemoized<List<DgMenuItem>>(() {
      return [
        DgMenuItem(
          text: "Register Biometry",
          onTap: () async {
            final msg = ScaffoldMessenger.of(context);
            final response = await BiometricStorage().canAuthenticate();
            if (response != CanAuthenticateResponse.success) {
              msg.showSnackBar(
                dgSnackBar(text: "Cannot use biometry on this device."),
              );
              return;
            }
            try {
              final instanceSecureData = await getBiometricInstanceStorage(
                instance,
              );
              if (!instance.mfaKeysStored) {
                final dbInstance = await db.managers.defguardInstances
                    .filter((row) => row.id.equals(instance.id))
                    .getSingle();
                await db.managers.defguardInstances.update(
                  (_) => dbInstance.copyWith(mfaKeysStored: true),
                );
              }
              msg.showSnackBar(
                dgSnackBar(
                  text: 'Private key: ${instanceSecureData.privateKey}',
                  onDismiss: () {
                    msg.hideCurrentSnackBar();
                  },
                ),
              );
            } catch (e) {
              talker.error(
                "Failed to save or retrieve instance data from secure storage",
                e,
              );
              msg.showSnackBar(
                dgSnackBar(text: e.toString(), textColor: DgColor.textAlert),
              );
            }
          },
        ),
      ];
    }, [instance, db, context]);

    return GestureDetector(
      onLongPress: () {
        menuController.show();
      },
      child: OverlayPortal(
        controller: menuController,
        overlayChildBuilder: (BuildContext _) {
          final anchor = WidgetGeometry.fromKey(menuAnchorKey);
          return DgMenu(
            items: menuItems,
            controller: menuController,
            anchorGeometry: anchor,
          );
        },
        child: InkWell(
          key: menuAnchorKey,
          onTap: () {
            InstanceScreenRoute(id: instance.id.toString()).go(context);
          },
          child: Container(
            constraints: BoxConstraints(minHeight: 64, maxHeight: 100),
            padding: EdgeInsetsDirectional.symmetric(
              vertical: 0,
              horizontal: DgSpacing.m,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: DgColor.navBg,
            ),
            child: Row(
              children: [
                DgIconConnection(
                  variant: isConnected
                      ? DgIconConnectionVariant.connected
                      : DgIconConnectionVariant.disconnected,
                ),
                SizedBox(width: 18),
                LimitedText(text: instance.name, style: DgText.sideBar),
                SizedBox(width: 10),
                Spacer(),
                DgIconArrowSingle(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
