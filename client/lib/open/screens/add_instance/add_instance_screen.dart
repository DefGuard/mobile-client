import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/add_instance/data_gathering_dialog.dart';
import 'package:mobile/open/screens/scan_qr_screen.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/screen_padding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/icons/asset_icons_simple.dart';

final agreementPrefsKey = "DATA_GATHERING_AGREEMENT";

class _TopIcon extends StatelessWidget {
  const _TopIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/icons/add_instance_top.svg",
      height: 66,
      width: 104,
    );
  }
}

class AddInstanceScreen extends HookConsumerWidget {
  const AddInstanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrefs = useMemoized(() => SharedPreferencesAsync(), []);

    return DgScaffold(
      title: "Add Instance",
      child: DgSingleChildScrollView(
        padding: screenPadding(
          top: 0,
          bottom: DgSpacing.m,
          horizontal: DgSpacing.s,
          context: context,
        ),
        child: Column(
          children: [
            SizedBox(height: 64),
            const _TopIcon(),
            SizedBox(height: DgSpacing.m),
            Text(
              "Please, scan QR Code to add instance",
              style: DgText.body1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DgSpacing.xs),
            Text(
              "To connect this device to your Defguard instance, you need to add it to your Defguard profile, or if you’re enrolling, the instance details should already be shown.",
              style: DgText.welcomeH2.copyWith(
                color: DgColor.textBodySecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DgSpacing.xl),
            DgButton(
              text: "Scan QR Code",
              variant: DgButtonVariant.primary,
              size: DgButtonSize.big,
              width: double.infinity,
              icon: DgIconQr(),
              onTap: () async {
                final isAgreed = await asyncPrefs.getBool(agreementPrefsKey);
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
                      builder: (_) => DataGatheringDialog(),
                    );
                    if (dialogResult ?? false) {
                      await asyncPrefs.setBool(agreementPrefsKey, true);
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
            SizedBox(height: DgSpacing.m),
            Center(child: Text("or", style: DgText.sideBar)),
            SizedBox(height: DgSpacing.m),
            DgButton(
              text: "Add instance Manually",
              variant: DgButtonVariant.secondary,
              size: DgButtonSize.big,
              width: double.infinity,
              onTap: () async {
                final isAgreed = await asyncPrefs.getBool(agreementPrefsKey);
                if (isAgreed ?? false) {
                  if (context.mounted) {
                    AddInstanceFormScreenRoute().push(context);
                  }
                } else {
                  if (context.mounted) {
                    final dialogResult = await showDialog<bool>(
                      context: context,
                      builder: (_) => DataGatheringDialog(),
                    );
                    if (dialogResult ?? false) {
                      await asyncPrefs.setBool(agreementPrefsKey, true);
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
    );
  }
}
