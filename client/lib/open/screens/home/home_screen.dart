// ignore_for_file: unused_element
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/widgets/circular_progress.dart';
import 'package:mobile/open/widgets/icons/arrow_single.dart';
import 'package:mobile/open/widgets/icons/connection.dart';
import 'package:mobile/open/widgets/limited_text.dart';
import 'package:mobile/open/widgets/nav.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DgAppBar(title: "Instances"),
      drawer: DgDrawer(),
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
      body: Container(
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
      messenger.showSnackBar(SnackBar(content: const Text('Instance removed')));
    }

    Future<void> handleDeleteAll() async {
      final messenger = ScaffoldMessenger.of(context);
      await db.managers.defguardInstances.delete();
      messenger.showSnackBar(
        SnackBar(content: const Text("All instances removed")),
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
    return InkWell(
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
    );
  }
}
