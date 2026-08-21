import 'package:flutter/material.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_skip_dialog.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

class NextBiometrySetupFailedScreen extends StatelessWidget {
  final String instanceId;

  const NextBiometrySetupFailedScreen({super.key, required this.instanceId});

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
                      spacing: NextSpacing.lg,
                      children: [
                        Center(
                          child: Text(
                            "Biometric Setup Failed",
                            style: NextText.h4.copyWith(
                              color: NextColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          "We couldn't enable biometric authentication. Please try again.",
                          style: NextText.bodyPrimary400.copyWith(
                            color: NextColor.fgWhite80,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: NextSpacing.xl),
                Row(
                  spacing: NextSpacing.md,
                  children: [
                    Expanded(
                      child: NextButton(
                        text: "Skip",
                        style: NextButtonStyle.secondary,
                        onTap: () {
                          showDialog(
                            context: context,
                            useSafeArea: false,
                            barrierColor: Colors.transparent,
                            builder: (context) => BiometrySkipDialog(
                              onSkip: () {
                                InstanceScreenRoute(id: instanceId).go(context);
                              },
                              onCancel: () => Navigator.of(context).pop(),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: NextButton(
                        text: "Retry",
                        style: NextButtonStyle.primary,
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
