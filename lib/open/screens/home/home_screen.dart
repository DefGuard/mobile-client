// ignore_for_file: unused_element
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_client/data/db/database.dart';
import 'package:mobile_client/open/widgets/buttons/dg_button.dart';
import 'package:mobile_client/open/widgets/circular_progress.dart';
import 'package:mobile_client/open/widgets/icons/arrow_single.dart';
import 'package:mobile_client/open/widgets/icons/connection.dart';
import 'package:mobile_client/open/widgets/limited_text.dart';
import 'package:mobile_client/open/widgets/nav.dart';
import 'package:mobile_client/router/routes.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DgAppBar(title: "Home"),
      drawer: DgDrawer(),
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          onPressed: () {
            AddInstanceScreenRoute().go(context);
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
        child: Padding(
          padding: const EdgeInsets.all(DgSpacing.m),
          child: _InstancesList(),
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
            SliverToBoxAdapter(
              child: DgButton(
                variant: DgButtonVariant.secondary,
                size: DgButtonSize.big,
                text: "Delete all instances",
                width: double.infinity,
                onTap: () {
                  handleDeleteAll();
                },
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: DgSpacing.s)),
            SliverList.separated(
              itemCount: instances.length,
              separatorBuilder: (_, _) => SizedBox(height: DgSpacing.s),
              itemBuilder: (BuildContext context, int index) {
                final instance = instances[index];
                return _InstanceItem(instance: instance);
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

  const _InstanceItem({required this.instance});

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
            DgIconConnection(variant: DgIconConnectionVariant.disconnected),
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
