import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/loading_screen.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/utils/secure_storage.dart';
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
          spacing: DgSpacing.s,
          children: [
            Center(
              child: DgButton(
                text: "Register",
                variant: DgButtonVariant.primary,
                loading: isLoading.value,
                minWidth: 120,
                onTap: () async {
                  isLoading.value = true;
                  final msg = ScaffoldMessenger.of(context);
                  try {
                    final authSecret = await getBiometricInstanceStorage(
                      instance.secureStorageKey,
                    );
                    await proxyApi.registerMobileAuth(
                      Uri.parse(instance.proxyUrl),
                      authSecret.publicKey,
                      instance.pubKey,
                    );
                  } catch (e) {
                    msg.showSnackBar(
                      dgSnackBar(text: "Smth went wrong ! \n$e"),
                    );
                    talker.error("Failed mobile auth registration!", e);
                  } finally {
                    isLoading.value = false;
                  }
                  msg.showSnackBar(
                    dgSnackBar(
                      text:
                          "Mobile authorization configured for ${instance.name}",
                    ),
                  );
                  if (context.mounted) {
                    HomeScreenRoute().go(context);
                  }
                },
              ),
            ),
            Center(
              child: DgButton(
                text: "Skip",
                minWidth: 120,
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
