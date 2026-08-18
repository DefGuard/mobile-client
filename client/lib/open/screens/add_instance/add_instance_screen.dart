import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/add_instance/data_gathering_dialog.dart';
import 'package:mobile/open/screens/scan_qr_screen.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/next/color.dart';
import '../../../theme/next/spacing.dart';

final agreementPrefsKey = "DATA_GATHERING_AGREEMENT";

class AddInstanceScreen extends HookConsumerWidget {
  const AddInstanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrefs = useMemoized(() => SharedPreferencesAsync(), []);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: NextAppBar(
        showLogo: true,
        actionLeft: canPop
            ? NextIconButton(
                icon: "arrow_big",
                direction: NextIconDirection.left,
                onTap: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
        child: SafeArea(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(bottom: NextSpacing.xs),
                      child: Text(
                        "Add instance",
                        style: NextText.h3.copyWith(
                          color: NextColor.fgWhite100,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      "Scan QR code or add it manually.",
                      style: NextText.bodySm400.copyWith(
                        color: NextColor.fgWhite80,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 82),
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: RiveAssetAnimation(
                        'assets/next/rive/add_instance.riv',
                        fit: rive.Fit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: Text(
                            "To connect this device to your Defguard instance, you need to add it to your Defguard profile, or if you are enrolling, the instance details should already be shown",
                            style: NextText.bodyXs400.copyWith(
                              color: NextColor.fgWhite60,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: NextSpacing.xl3),
                        NextButton(
                          text: "Scan QR Code",
                          style: NextButtonStyle.primary,
                          size: NextButtonSize.big,
                          width: double.infinity,
                          onTap: () async {
                            final isAgreed = await asyncPrefs.getBool(
                              agreementPrefsKey,
                            );
                            if (isAgreed ?? false) {
                              if (context.mounted) {
                                QRScreenRoute(
                                  QrScreenData(
                                    intent: QrScreenIntent.addInstance,
                                  ),
                                ).push(context);
                              }
                            } else {
                              if (context.mounted) {
                                final dialogResult = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => const DataGatheringDialog(),
                                );
                                if (dialogResult ?? false) {
                                  await asyncPrefs.setBool(
                                    agreementPrefsKey,
                                    true,
                                  );
                                  if (context.mounted) {
                                    QRScreenRoute(
                                      QrScreenData(
                                        intent: QrScreenIntent.addInstance,
                                      ),
                                    ).push(context);
                                  }
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(height: NextSpacing.md),
                        NextButton(
                          text: "Add instance Manually",
                          style: NextButtonStyle.secondary,
                          size: NextButtonSize.big,
                          width: double.infinity,
                          onTap: () async {
                            final isAgreed = await asyncPrefs.getBool(
                              agreementPrefsKey,
                            );
                            if (isAgreed ?? false) {
                              if (context.mounted) {
                                AddInstanceFormScreenRoute().push(context);
                              }
                            } else {
                              if (context.mounted) {
                                final dialogResult = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => const DataGatheringDialog(),
                                );
                                if (dialogResult ?? false) {
                                  await asyncPrefs.setBool(
                                    agreementPrefsKey,
                                    true,
                                  );
                                  if (context.mounted) {
                                    AddInstanceFormScreenRoute().push(context);
                                  }
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
