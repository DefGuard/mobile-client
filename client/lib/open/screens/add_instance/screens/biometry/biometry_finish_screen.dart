import 'package:flutter/material.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/widgets/biometry_setup_banner.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

const String message = r"""
Biometrics have been successfully enabled as a Multi-Factor Authentication (MFA) method. You can now use your device’s biometric capabilities when connecting to locations that require MFA.
""";

class BiometryFinishScreen extends StatelessWidget {
  const BiometryFinishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(
      title: "Add Instance",
      child: DgSingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: DgSpacing.m,
          children: [
            Center(
              child: Text(
                "Biometric Authentication Enabled",
                style: DgText.body1,
                textAlign: TextAlign.center,
              ),
            ),
            BiometrySetupBanner(),
            Text(
              message,
              style: DgText.body2.copyWith(color: DgColor.textBodySecondary),
            ),
            DgButton(
              text: "Continue",
              width: double.infinity,
              size: DgButtonSize.big,
              variant: DgButtonVariant.primary,
              onTap: () {
                HomeScreenRoute().go(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
