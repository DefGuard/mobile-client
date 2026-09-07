import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_drawer.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_instance_card.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'instances_list_screen.g.dart';

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
Stream<List<_InstanceItemData>> _instancesListData(Ref ref) {
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

class InstancesListScreen extends HookConsumerWidget {
  const InstancesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(_instancesListDataProvider);

    return Scaffold(
      drawer: const DgDrawer(),
      extendBodyBehindAppBar: true,
      appBar: DgAppBar(
        context: context,
        actionLeft: Builder(
          builder: (context) => DgIconButton(
            icon: "hamburger",
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actionRight: [
          DgIconButton(
            icon: "plus",
            onTap: () => const AddInstanceScreenRoute().push(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: DgColor.previewGradient),
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
                  DgSpacing.xl,
                  DgSpacing.sm,
                  DgSpacing.xl,
                  DgSpacing.xl,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: DgSpacing.xl),
                    child: Text(
                      "Instances",
                      style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                    ),
                  ),
                  if (connectedInstances.isNotEmpty) ...[
                    Text(
                      "Connected locations",
                      style: DgText.bodyXs400.copyWith(
                        color: DgColor.fgWhite70,
                      ),
                    ),
                    const SizedBox(height: DgSpacing.md),
                    ...connectedInstances.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: DgSpacing.md),
                        child: DgInstanceCard(
                          locationsCount: data.locationsCount,
                          connectedCount: data.connectedCount,
                          name: data.instance.name,
                          onTap: () => InstanceScreenRoute(
                            id: data.instance.id.toString(),
                          ).go(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: DgSpacing.xl),
                  ],
                  if (offlineInstances.isNotEmpty) ...[
                    Text(
                      "No connected locations",
                      style: DgText.bodyXs400.copyWith(
                        color: DgColor.fgWhite70,
                      ),
                    ),
                    const SizedBox(height: DgSpacing.md),
                    ...offlineInstances.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: DgSpacing.md),
                        child: DgInstanceCard(
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
                      padding: const EdgeInsets.only(top: DgSpacing.xl),
                      child: Center(
                        child: Text(
                          "No instances found",
                          style: DgText.bodyPrimary400.copyWith(
                            color: DgColor.fgWhite60,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: DgColor.fgWhite100),
            ),
            error: (err, stack) => Center(
              child: Text(
                "Error: $err",
                style: const TextStyle(color: DgColor.fgWhite100),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
