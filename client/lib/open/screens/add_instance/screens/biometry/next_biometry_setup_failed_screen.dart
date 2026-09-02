import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_skip_dialog.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

class NextBiometrySetupFailedScreen extends ConsumerWidget {
  final String instanceId;

  const NextBiometrySetupFailedScreen({super.key, required this.instanceId});

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
                      children: [
                        const SizedBox(height: 70),
                        const Center(
                          child: SizedBox(
                            height: 100,
                            width: 100,
                            child: RiveAssetAnimation(
                              "assets/next/rive/biometric_sad.riv",
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 60,
                        ),
                        Center(
                          child: Text(
                            "Biometric Setup Failed",
                            style: NextText.h4.copyWith(
                              color: NextColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: NextSpacing.sm,
                        ),
                        Center(
                          child: Text(
                            "We couldn't enable biometric authentication. Please try again.",
                            style: NextText.bodySm400.copyWith(
                              color: NextColor.fgWhite80,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: NextSpacing.xl),
                Column(
                  spacing: NextSpacing.md,
                  children: [
                    NextButton(
                      text: "Retry",
                      width: double.infinity,
                      style: NextButtonStyle.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    NextButton(
                      text: "Skip",
                      width: double.infinity,
                      style: NextButtonStyle.secondary,
                      onTap: () {
                        showDialog(
                          context: context,
                          useSafeArea: false,
                          barrierColor: Colors.transparent,
                          builder: (context) => BiometrySkipDialog(
                            onSkip: () {
                              ref
                                  .read(toastManagerProvider.notifier)
                                  .showSuccess(
                                    message: "Instance added successfully",
                                  );
                              InstanceScreenRoute(id: instanceId).go(context);
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
        ),
      ),
    );
  }
}
