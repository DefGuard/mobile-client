import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

const String message = r"""
Biometrics have been successfully enabled as a Multi-Factor Authentication (MFA) method. You can now use your device’s biometric capabilities when connecting to locations that require MFA.
""";

class BiometryFinishScreen extends ConsumerWidget {
  final String instanceId;

  const BiometryFinishScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DgSpacing.xl,
              vertical: DgSpacing.xl,
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
                          style: DgText.h4.copyWith(
                            color: DgColor.fgWhite100,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Biometrics have been successfully enabled as a Multi-Factor Authentication (MFA) method. You can now use your device’s biometric capabilities when connecting to locations that require MFA.",
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
                  identifier: "biometry_finish_continue",
                  text: "Continue",
                  width: double.infinity,
                  style: DgButtonStyle.primary,
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
