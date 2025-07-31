import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/loading_screen.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../logging.dart';

part 'register_mobile_auth.g.dart';

class RegisterMobileAuthScreen extends StatelessWidget {
  final int instanceId;

  const RegisterMobileAuthScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(
      title: "Register device",
      child: _ScreenContent(instanceId: instanceId),
    );
  }
}

@riverpod
Stream<DefguardInstance> _screenData(Ref ref, int id) {
  final db = ref.read(databaseProvider);
  return db.managers.defguardInstances
      .filter((row) => row.id.equals(id))
      .watchSingle();
}

class _ScreenContent extends HookConsumerWidget {
  final int instanceId;

  const _ScreenContent({required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instanceFuture = ref.watch(_screenDataProvider(instanceId));
    final isLoading = useState(false);
    return instanceFuture.when(
      loading: () => LoadingView(),
      error: (err, _) {
        talker.error("Failed to get screen data", err);
        HomeScreenRoute().go(context);
        return const SizedBox();
      },
      data: (instance) => DgSingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: DgButton(
                text: "Register",
                loading: isLoading.value,
                onTap: () async {
                  isLoading.value = true;
                  try {} finally {
                    isLoading.value = false;
                  }
                },
              ),
            ),
            Center(
              child: DgButton(
                text: "Skip",
                onTap: () {
                  HomeScreenRoute().go(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
