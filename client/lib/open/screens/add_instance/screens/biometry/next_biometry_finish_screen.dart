import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

const String message = r"""
Biometrics have been successfully enabled as a Multi-Factor Authentication (MFA) method. You can now use your device’s biometric capabilities when connecting to locations that require MFA.
""";

class NextBiometryFinishScreen extends ConsumerWidget {
  final String instanceId;

  const NextBiometryFinishScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NextSpacing.xl,
              vertical: NextSpacing.xl,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 50),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: RiveAssetAnimation(
                            "assets/next/rive/biometric_check.riv",
                          ),
                        ),
                        SizedBox(height: 60),
                        Text(
                          "Biometric Authentication Enabled",
                          style: NextText.h4.copyWith(
                            color: NextColor.fgWhite100,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Biometrics have been successfully enabled as a Multi-Factor Authentication (MFA) method. You can now use your device’s biometric capabilities when connecting to locations that require MFA.",
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
                  text: "Continue",
                  width: double.infinity,
                  style: NextButtonStyle.primary,
                  onTap: () {
                    ref
                        .read(toastManagerProvider.notifier)
                        .showSuccess(message: "Instance added successfully");
                    InstanceScreenRoute(id: instanceId).go(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
