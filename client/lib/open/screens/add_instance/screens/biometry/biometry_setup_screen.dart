import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_setup_banner.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/utils/screen_padding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../data/db/database.dart';
import '../../../../../logging.dart';
import '../../../../../router/routes.dart';
import '../../../../../theme/color.dart';
import '../../../../../theme/text.dart';
import '../../../../../utils/secure_storage.dart';
import '../../../../api.dart';
import '../../../../widgets/buttons/dg_button.dart';
import '../../../../widgets/loading_screen.dart';

part 'biometry_setup_screen.g.dart';

const String title = "Enable Biometric Authentication";

const String message1 = r"""
Do you want to enable biometrics as a Multi-Factor Authentication (MFA) method when connecting to locations that require MFA?

If you enable biometrics, by default, all locations requiring internal Defguard MFA will prompt you to authenticate using your device’s biometric method during connection.
""";

const String message2 =
    "\nIf you skip this step, you will need to use other MFA methods configured in your user profile (such as TOTP/Authenticator app or email codes).";

const String message3 =
    "Biometry is not available on the system please add it and return to this screen or you can skip it.";

class BiometrySetupScreen extends StatelessWidget {
  final int instanceId;

  const BiometrySetupScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(
      title: "Add Instance",
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
    final db = ref.read(databaseProvider);
    final instanceFuture = ref.watch(_screenDataProvider(instanceId));
    final isLoading = useState(false);
    final biometryEnabled = useState(false);
    final lifecycle = useAppLifecycleState();

    final handleRegister = useCallback((DefguardInstance instance) async {
      isLoading.value = true;
      try {
        final authSecret = await getBiometricInstanceStorage(
          instance.secureStorageKey,
          prompt: "Confirm to setup",
        );
        await proxyApi.registerMobileAuth(
          Uri.parse(instance.proxyUrl),
          authSecret.publicKey,
          instance.pubKey,
        );
        // update instance information
        final instanceDb = await db.managers.defguardInstances
            .filter((row) => row.id.equals(instanceId))
            .getSingle();
        await db.managers.defguardInstances.update(
          (_) => instanceDb.copyWith(mfaKeysStored: true),
        );
        isLoading.value = false;
        if (context.mounted) {
          BiometryFinishScreenRoute().go(context);
          return;
        }
      } catch (e) {
        talker.error("Failed mobile auth registration!", e);
        if (context.mounted) {
          isLoading.value = false;
          BiometrySetupFailedScreenRoute().push(context);
          return;
        }
      } finally {
        isLoading.value = false;
      }
    }, [context, isLoading, db]);

    final handleBiometryCheck = useCallback(() async {
      final status = await BiometricStorage().canAuthenticate();
      talker.debug(status);
      biometryEnabled.value = status == CanAuthenticateResponse.success;
    }, []);

    useEffect(() {
      handleBiometryCheck();
      return null;
    }, [lifecycle]);

    return instanceFuture.when(
      loading: () => LoadingView(),
      error: (err, _) {
        talker.error("Failed to get screen data", err);
        HomeScreenRoute().go(context);
        return const SizedBox();
      },
      data: (instance) => DgSingleChildScrollView(
        padding: screenPadding(
          top: DgSpacing.l,
          bottom: DgSpacing.m,
          horizontal: DgSpacing.s,
          context: context,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          spacing: DgSpacing.m,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: DgText.body1,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            BiometrySetupBanner(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: message1,
                    style: DgText.body2.copyWith(
                      color: DgColor.textBodySecondary,
                    ),
                  ),
                  TextSpan(
                    text: message2,
                    style: DgText.body2.copyWith(
                      color: DgColor.textBodySecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!biometryEnabled.value)
              Text(
                message3,
                style: DgText.body2.copyWith(color: DgColor.textAlert),
              ),
            Row(
              spacing: DgSpacing.m,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: DgButton(
                    text: "Skip",
                    size: DgButtonSize.big,
                    variant: DgButtonVariant.secondary,
                    disabled: isLoading.value,
                    onTap: () {
                      HomeScreenRoute().go(context);
                    },
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: DgButton(
                    text: "Yes",
                    disabled: !biometryEnabled.value,
                    loading: isLoading.value,
                    size: DgButtonSize.big,
                    variant: DgButtonVariant.primary,
                    onTap: () => handleRegister(instance),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
