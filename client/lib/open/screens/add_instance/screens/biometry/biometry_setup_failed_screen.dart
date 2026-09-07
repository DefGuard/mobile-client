import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_skip_dialog.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class BiometrySetupFailedScreen extends ConsumerWidget {
  final String instanceId;

  const BiometrySetupFailedScreen({super.key, required this.instanceId});

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
                            style: DgText.h4.copyWith(
                              color: DgColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: DgSpacing.sm,
                        ),
                        Center(
                          child: Text(
                            "We couldn't enable biometric authentication. Please try again.",
                            style: DgText.bodySm400.copyWith(
                              color: DgColor.fgWhite80,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DgSpacing.xl),
                Column(
                  spacing: DgSpacing.md,
                  children: [
                    DgButton(
                      text: "Retry",
                      width: double.infinity,
                      style: DgButtonStyle.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    DgButton(
                      text: "Skip",
                      width: double.infinity,
                      style: DgButtonStyle.secondary,
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
