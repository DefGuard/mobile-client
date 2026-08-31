import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_skip_dialog.dart';
import 'package:mobile/open/widgets/loading_screen.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:mobile/utils/secure_storage.dart';

class NextBiometrySetupScreen extends StatelessWidget {
  final int instanceId;

  const NextBiometrySetupScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
        child: SafeArea(child: _ScreenContent(instanceId: instanceId)),
      ),
    );
  }
}

final nextBiometryScreenDataProvider =
    StreamProvider.family<DefguardInstance, int>((ref, id) {
      final db = ref.read(databaseProvider);
      return db.managers.defguardInstances
          .filter((row) => row.id.equals(id))
          .watchSingle();
    });

class _ScreenContent extends HookConsumerWidget {
  final int instanceId;

  const _ScreenContent({required this.instanceId});

  Widget _getRiveAnimation(BiometricsState status) {
    String asset = "assets/next/rive/biometric_face.riv";
    if (!status.isSupported) {
      asset = "assets/next/rive/biometric_face.riv";
    } else if (status.enrolledOptions.isEmpty) {
      asset = "assets/next/rive/biometric_face.riv";
    } else {
      asset = "assets/next/rive/biometric_face.riv";
    }

    return Center(
      child: SizedBox(
        height: 100,
        width: 100,
        child: RiveAssetAnimation(asset),
      ),
    );
  }

  String _getTitle(BiometricsState status) {
    if (!status.isSupported) {
      return "Biometry Unsupported";
    }
    if (status.enrolledOptions.isEmpty) {
      return "Biometry Not Registered";
    }
    return "Enable Biometric Authentication";
  }

  String _getDescription(BiometricsState status) {
    if (!status.isSupported) {
      return "Biometry is not available on the system please add it and return to this screen or you can skip it.";
    }
    if (status.enrolledOptions.isEmpty) {
      return "Biometry is supported on your device, but no fingerprints or face data are registered. Please set them up in your system settings.";
    }
    return "Do you want to enable biometrics (FaceID/Touch ID) as a Multi-Factor Authentication (MFA) method when connecting to locations that require MFA?";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final instanceFuture = ref.watch(
      nextBiometryScreenDataProvider(instanceId),
    );
    final biometryStatus = ref.watch(biometricsCapabilityProvider);
    final isLoading = useState(false);

    final handleRegister = useCallback((
      DefguardInstance instance,
      BuildContext context,
    ) async {
      isLoading.value = true;
      try {
        final authSecret = await createBiometricStorage(
          instance.secureStorageKey,
          prompt: "Confirm to complete setup",
        );
        await proxyApi.registerMobileAuth(
          Uri.parse(instance.proxyUrl),
          authSecret.publicKey,
          instance.pubKey,
        );
        // update instance information
        var instanceDb = await db.managers.defguardInstances
            .filter((row) => row.id.equals(instanceId))
            .getSingle();
        instanceDb = instanceDb.copyWith(mfaKeysStored: true);
        await db.managers.defguardInstances.replace(instanceDb);
        isLoading.value = false;
        if (context.mounted) {
          BiometryFinishScreenRoute(id: instanceId.toString()).go(context);
          return;
        }
      } on PlatformException catch (e) {
        final message = getErrorMessageFromBiometricsException(e);
        talker.error("Register biometry failed: $message");
        if (context.mounted) {
          isLoading.value = false;
          BiometrySetupFailedScreenRoute(
            id: instanceId.toString(),
          ).push(context);
          return;
        }
      } catch (e) {
        talker.error("Failed mobile auth registration!", e);
        if (context.mounted) {
          isLoading.value = false;
          BiometrySetupFailedScreenRoute(
            id: instanceId.toString(),
          ).push(context);
          return;
        }
      } finally {
        isLoading.value = false;
      }
    }, []);

    return instanceFuture.when(
      loading: () => const LoadingView(),
      error: (err, _) {
        talker.error("Failed to get screen data", err);
        InstanceScreenRoute(id: instanceId.toString()).go(context);
        return const SizedBox();
      },
      data: (instance) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NextSpacing.xl,
          vertical: NextSpacing.xl,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 70),
                    _getRiveAnimation(biometryStatus),
                    SizedBox(height: 60),
                    Text(
                      _getTitle(biometryStatus),
                      style: NextText.h4.copyWith(color: NextColor.fgWhite100),
                      textAlign: .center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDescription(biometryStatus),
                      style: NextText.bodySm400.copyWith(
                        color: NextColor.fgWhite80,
                      ),
                      textAlign: .center,
                    ),
                    if (biometryStatus.isStrong) ...[
                      const SizedBox(height: NextSpacing.xl2),
                      Text(
                        "If you skip this step, you will need to use other MFA methods configured in your user profile (such as TOTP/Authenticator app or email codes).",
                        style: NextText.bodyXs400.copyWith(
                          color: NextColor.fgWhite60,
                        ),
                        textAlign: .center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: NextSpacing.xl),
            Column(
              spacing: NextSpacing.md,
              children: [
                if (biometryStatus.isStrong)
                  NextButton(
                    text: "Enable",
                    size: .big,
                    width: .infinity,
                    disabled: !biometryStatus.isStrong,
                    loading: isLoading.value,
                    style: NextButtonStyle.primary,
                    onTap: () => handleRegister(instance, context),
                  ),
                NextButton(
                  text: "Skip",
                  style: NextButtonStyle.secondary,
                  size: .big,
                  disabled: isLoading.value,
                  width: .infinity,
                  onTap: () {
                    showDialog(
                      context: context,
                      useSafeArea: false,
                      barrierColor: Colors.transparent,
                      builder: (context) => BiometrySkipDialog(
                        onSkip: () {
                          InstanceScreenRoute(
                            id: instanceId.toString(),
                          ).go(context);
                        },
                        onCancel: () => Navigator.of(context).pop(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
