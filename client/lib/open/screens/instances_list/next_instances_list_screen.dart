import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/open/widgets/next/next_instance_card.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'next_instances_list_screen.g.dart';

class _InstanceItemData {
  final DefguardInstance instance;
  final int locationsCount;
  final int connectedCount;

  _InstanceItemData({
    required this.instance,
    required this.locationsCount,
    required this.connectedCount,
  });
}

@riverpod
Stream<List<_InstanceItemData>> _nextInstancesListData(Ref ref) {
  final db = ref.watch(databaseProvider);
  final activeTunnel = ref.watch(pluginActiveTunnelStateProvider);

  final instancesStream = db.select(db.defguardInstances).watch();
  final locationsStream = db.select(db.locations).watch();

  return Rx.combineLatest2<
    List<DefguardInstance>,
    List<Location>,
    List<_InstanceItemData>
  >(instancesStream, locationsStream, (instances, locations) {
    return instances.map((instance) {
      final instanceLocations = locations
          .where((l) => l.instance == instance.id)
          .toList();
      final connectedCount = instanceLocations
          .where(
            (l) =>
                activeTunnel?.instanceId == instance.id &&
                activeTunnel?.locationId == l.id,
          )
          .length;

      return _InstanceItemData(
        instance: instance,
        locationsCount: instanceLocations.length,
        connectedCount: connectedCount,
      );
    }).toList();
  });
}

class NextInstancesListScreen extends HookConsumerWidget {
  const NextInstancesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(_nextInstancesListDataProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: NextAppBar(
        actionLeft: NextIconButton(icon: "hamburger", onTap: () {}),
        actionRight: [
          NextIconButton(
            icon: "plus",
            onTap: () => const AddInstanceScreenRoute().push(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.previewGradient),
        child: SafeArea(
          child: instancesAsync.when(
            data: (instances) {
              final connectedInstances = instances
                  .where((i) => i.connectedCount > 0)
                  .toList();
              final offlineInstances = instances
                  .where((i) => i.connectedCount == 0)
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
                      "Instances",
                      style: NextText.h4.copyWith(color: NextColor.fgWhite100),
                    ),
                  ),
                  if (connectedInstances.isNotEmpty) ...[
                    Text(
                      "Connected locations",
                      style: NextText.bodyXs400.copyWith(
                        color: NextColor.fgWhite70,
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    ...connectedInstances.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: NextSpacing.md),
                        child: NextInstanceCard(
                          locationsCount: data.locationsCount,
                          connectedCount: data.connectedCount,
                          name: data.instance.name,
                          onTap: () => InstanceScreenRoute(
                            id: data.instance.id.toString(),
                          ).go(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: NextSpacing.xl),
                  ],
                  if (offlineInstances.isNotEmpty) ...[
                    Text(
                      "No connected locations",
                      style: NextText.bodyXs400.copyWith(
                        color: NextColor.fgWhite70,
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    ...offlineInstances.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: NextSpacing.md),
                        child: NextInstanceCard(
                          locationsCount: data.locationsCount,
                          connectedCount: data.connectedCount,
                          name: data.instance.name,
                          onTap: () => InstanceScreenRoute(
                            id: data.instance.id.toString(),
                          ).go(context),
                        ),
                      ),
                    ),
                  ],
                  if (instances.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: NextSpacing.xl),
                      child: Center(
                        child: Text(
                          "No instances found",
                          style: NextText.bodyPrimary400.copyWith(
                            color: NextColor.fgWhite60,
                          ),
                        ),
                      ),
                    ),
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
