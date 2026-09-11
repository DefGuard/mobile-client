import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/add_instance/data_gathering_dialog.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_drawer.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/rive_asset_animation.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/text.dart';
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';

class AddInstanceScreen extends HookConsumerWidget {
  const AddInstanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrefs = useMemoized(() => SharedPreferencesAsync(), []);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      drawer: const DgDrawer(),
      appBar: DgAppBar(
        context: context,
        showLogo: true,
        actionLeft: canPop
            ? DgIconButton(
                icon: "arrow_big",
                direction: DgIconDirection.left,
                onTap: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: SafeArea(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(bottom: DgSpacing.xs),
                      child: Semantics(
                        identifier: "add_instance_screen_header",
                        child: Text(
                          "Add instance",
                          style: DgText.h3.copyWith(
                            color: DgColor.fgWhite100,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Text(
                      "Scan QR code or add it manually.",
                      style: DgText.bodySm400.copyWith(
                        color: DgColor.fgWhite80,
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
                            style: DgText.bodyXs400.copyWith(
                              color: DgColor.fgWhite60,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: DgSpacing.xl3),
                        DgButton(
                          text: "Scan QR Code",
                          style: DgButtonStyle.primary,
                          size: DgButtonSize.big,
                          width: double.infinity,
                          onTap: () async {
                            final isAgreed = await asyncPrefs.getBool(
                              agreementPrefsKey,
                            );
                            if (isAgreed ?? false) {
                              if (context.mounted) {
                                const AddInstanceQrScreenRoute().push(context);
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
                                    const AddInstanceQrScreenRoute().push(
                                      context,
                                    );
                                  }
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(height: DgSpacing.md),
                        DgButton(
                          identifier: "add_instance_manual_button",
                          text: "Add instance Manually",
                          style: DgButtonStyle.secondary,
                          size: DgButtonSize.big,
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
