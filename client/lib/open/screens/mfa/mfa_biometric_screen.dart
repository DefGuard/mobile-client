import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_mfa_step_label.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/secure_storage.dart';

class MfaBiometricScreen extends HookConsumerWidget {
  final MfaStepHost host;
  final String secureStorageKey;

  const MfaBiometricScreen({
    super.key,
    required this.host,
    required this.secureStorageKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toaster = ref.read(toastManagerProvider.notifier);
    final isLoading = useState(false);
    final hasFailed = useState(false);

    final handleVerify = useCallback(() async {
      final challenge = host.controller.challenge;
      if (challenge == null) {
        host.reportFailure(
          message: "Verification failed. Please try again.",
          logMessage: "Biometric step opened without a challenge",
        );
        return;
      }

      isLoading.value = true;

      late SecureInstanceStorage storage;
      try {
        storage = await getBiometricInstanceStorage(
          secureStorageKey,
          prompt: "Confirm to connect",
        );
      } on UserCanceledAuth catch (e) {
        toaster.showError(
          message: "Biometric verification cancelled.",
          logMessage: "User canceled biometric MFA",
          error: e,
        );
        isLoading.value = false;
        hasFailed.value = true;
        return;
      } catch (e) {
        toaster.showError(
          message: "Biometric authentication failed.",
          logMessage:
              "Biometric MFA failed! Reason: ${getErrorMessageFromBiometricsException(e)}",
          error: e,
        );
        isLoading.value = false;
        hasFailed.value = true;
        return;
      }

      try {
        final signed = signChallenge(challenge, storage.privateKey);
        final progress = await host.controller.submit(code: signed);
        if (progress is MfaStepAwaiting) {
          throw StateError("biometric step returned an out-of-band outcome");
        }
        host.reportProgress(progress);
        return;
      } catch (e) {
        toaster.showError(
          message: "Verification failed. Please try again.",
          logMessage: "Biometric MFA challenge submit failed!",
          error: e,
        );
      }
      isLoading.value = false;
      hasFailed.value = true;
    }, [host, secureStorageKey]);

    return MfaStepScope(
      host: host,
      child: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: DgAppBar(
            context: context,
            showLogo: false,
            actionLeft: DgIconButton(
              icon: 'arrow_small',
              direction: DgIconDirection.left,
              onTap: host.abort,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 70),
                          const Center(
                            child: SizedBox(
                              height: 100,
                              width: 100,
                              child: RiveAssetAnimation(
                                "assets/next/rive/biometric_face.riv",
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          DgMfaStepLabel(host.controller.stepLabel),
                          Text(
                            "Biometric verification",
                            style: DgText.h4.copyWith(
                              color: DgColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Confirm your identity using Face ID to continue.",
                            style: DgText.bodySm400.copyWith(
                              color: DgColor.fgWhite80,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DgSpacing.xl),
                  DgButton(
                    identifier: "mfa_biometric_verify",
                    text: hasFailed.value ? "Retry" : "Verify now",
                    style: DgButtonStyle.primary,
                    size: DgButtonSize.big,
                    width: double.infinity,
                    loading: isLoading.value,
                    onTap: handleVerify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
