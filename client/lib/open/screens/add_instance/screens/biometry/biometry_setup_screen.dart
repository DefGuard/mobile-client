import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_skip_dialog.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_circular_progress.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/secure_storage.dart';

class BiometrySetupScreen extends StatelessWidget {
  final int instanceId;

  const BiometrySetupScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: SafeArea(child: _ScreenContent(instanceId: instanceId)),
      ),
    );
  }
}

final biometryScreenDataProvider = StreamProvider.family<DefguardInstance, int>(
  (ref, id) {
    final db = ref.read(databaseProvider);
    return db.managers.defguardInstances
        .filter((row) => row.id.equals(id))
        .watchSingle();
  },
);

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
    // enrolled, but not class 3 / strong - the keystore cannot be biometry
    // bound, so registering would produce a key we could never open
    if (!status.isStrong) {
      return "Biometry Not Secure Enough";
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
    if (!status.isStrong) {
      return "Your device doesn't meet the required standards for the biometry MFA. Try to enable fingerprint auth and return to this screen, or use another MFA method.";
    }
    return "Do you want to enable biometrics (FaceID/Touch ID) as a Multi-Factor Authentication (MFA) method when connecting to locations that require MFA?";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final instanceFuture = ref.watch(
      biometryScreenDataProvider(instanceId),
    );
    final biometryStatus = ref.watch(biometricsCapabilityProvider);
    final isLoading = useState(false);

    final handleSkip = useCallback(() {
      ref
          .read(toastManagerProvider.notifier)
          .showSuccess(
            message: "Instance added successfully",
          );
      InstanceScreenRoute(
        id: instanceId.toString(),
      ).go(context);
    }, [instanceId]);

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
      loading: () => const Center(child: DgCircularProgress(size: 48)),
      error: (err, _) {
        talker.error("Failed to get screen data", err);
        InstanceScreenRoute(id: instanceId.toString()).go(context);
        return const SizedBox();
      },
      data: (instance) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DgSpacing.xl,
          vertical: DgSpacing.xl,
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
                      style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                      textAlign: .center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDescription(biometryStatus),
                      style: DgText.bodySm400.copyWith(
                        color: DgColor.fgWhite80,
                      ),
                      textAlign: .center,
                    ),
                    // shown in every state - skipping is always an option, so
                    // the consequence of skipping always has to be stated
                    const SizedBox(height: DgSpacing.xl2),
                    Text(
                      "If you skip this step, you will need to use other MFA methods configured in your user profile (such as TOTP/Authenticator app or email codes).",
                      style: DgText.bodyXs400.copyWith(
                        color: DgColor.fgWhite60,
                      ),
                      textAlign: .center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DgSpacing.xl),
            Column(
              spacing: DgSpacing.md,
              children: [
                if (biometryStatus.isSupported &&
                    (biometryStatus.isStrong ||
                        biometryStatus.enrolledOptions.isEmpty))
                  DgButton(
                    identifier: "enable_biometry",
                    text: "Enable",
                    size: .big,
                    width: .infinity,
                    loading: isLoading.value,
                    style: DgButtonStyle.primary,
                    disabled: biometryStatus.enrolledOptions.isEmpty,
                    onTap: () => handleRegister(instance, context),
                  ),
                DgButton(
                  text: "Skip",
                  style: DgButtonStyle.secondary,
                  size: .big,
                  disabled: isLoading.value,
                  width: .infinity,
                  onTap: () {
                    final cannotSetupBiometry =
                        !biometryStatus.isSupported ||
                        (biometryStatus.enrolledOptions.isNotEmpty &&
                            biometryStatus.isWeak);
                    if (cannotSetupBiometry) {
                      handleSkip();
                    } else {
                      showDialog(
                        context: context,
                        useSafeArea: false,
                        barrierColor: Colors.transparent,
                        builder: (context) => BiometrySkipDialog(
                          onSkip: handleSkip,
                          onCancel: () => Navigator.of(context).pop(),
                        ),
                      );
                    }
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
