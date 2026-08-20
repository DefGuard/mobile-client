import 'package:flutter/material.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_setup_banner.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

const String message = r"""
Biometrics have been successfully enabled as a Multi-Factor Authentication (MFA) method. You can now use your device’s biometric capabilities when connecting to locations that require MFA.
""";

class NextBiometryFinishScreen extends StatelessWidget {
  const NextBiometryFinishScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      spacing: NextSpacing.md,
                      children: [
                        Center(
                          child: Text(
                            "Biometric Authentication Enabled",
                            style: NextText.h4.copyWith(
                              color: NextColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const BiometrySetupBanner(),
                        Text(
                          message,
                          style: NextText.bodyPrimary400.copyWith(
                            color: NextColor.fgWhite80,
                          ),
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
                    const InstancesListScreenRoute().go(context);
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
