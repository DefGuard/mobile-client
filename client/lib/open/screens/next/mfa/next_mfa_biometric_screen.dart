import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:mobile/utils/secure_storage.dart';

class NextMfaBiometricScreenData {
  final String proxyUrl;
  final String token;
  final String challenge;
  final String secureStorageKey;

  const NextMfaBiometricScreenData({
    required this.proxyUrl,
    required this.token,
    required this.challenge,
    required this.secureStorageKey,
  });
}

class NextMfaBiometricScreen extends HookConsumerWidget {
  final NextMfaBiometricScreenData screenData;

  const NextMfaBiometricScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toaster = ref.read(toastManagerProvider.notifier);
    final isLoading = useState(false);
    final hasFailed = useState(false);

    final handleVerify = useCallback(() async {
      final navigator = Navigator.of(context);
      isLoading.value = true;

      late SecureInstanceStorage storage;
      try {
        storage = await getBiometricInstanceStorage(
          screenData.secureStorageKey,
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
        final signed = signChallenge(screenData.challenge, storage.privateKey);
        final response = await proxyApi.finishMfa(
          Uri.parse(screenData.proxyUrl),
          FinishMfaRequest(token: screenData.token, code: signed),
        );
        if (navigator.mounted) {
          navigator.pop(response.presharedKey);
          return;
        }
      } catch (e) {
        toaster.showError(
          message: "Verification failed. Please try again.",
          logMessage: "Biometric MFA challenge submit failed!",
          error: e,
        );
      }
      isLoading.value = false;
      hasFailed.value = true;
    }, [screenData]);

    return Container(
      decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: NextAppBar(
          context: context,
          showLogo: false,
          actionLeft: NextIconButton(
            icon: 'arrow_small',
            direction: NextIconDirection.left,
            onTap: () => Navigator.of(context).maybePop(),
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
                        Text(
                          "Biometric verification",
                          style: NextText.h4.copyWith(
                            color: NextColor.fgWhite100,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Confirm your identity using Face ID to continue.",
                          style: NextText.bodySm400.copyWith(
                            color: NextColor.fgWhite80,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: NextSpacing.xl),
                NextButton(
                  text: hasFailed.value ? "Retry" : "Verify now",
                  style: NextButtonStyle.primary,
                  size: NextButtonSize.big,
                  width: double.infinity,
                  loading: isLoading.value,
                  onTap: handleVerify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
