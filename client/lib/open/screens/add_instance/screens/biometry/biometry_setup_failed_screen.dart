import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/spacing.dart';

import '../../../../../theme/color.dart';
import '../../../../../theme/text.dart';

class BiometrySetupFailedScreen extends StatelessWidget {
  const BiometrySetupFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(
      title: "Add Instance",
      child: DgSingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: DgSpacing.l,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  "Biometric Setup Failed",
                  style: DgText.body1,
                  maxLines: 1,
                ),
              ),
            ),
            Text(
              "We couldn't enable biometric authentication. Please try again.",
              style: DgText.body2.copyWith(color: DgColor.textBodySecondary),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              spacing: DgSpacing.m,
              children: [
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: DgButton(
                    text: "Skip",
                    size: DgButtonSize.big,
                    variant: DgButtonVariant.secondary,
                    onTap: () {
                      HomeScreenRoute().go(context);
                    },
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: DgButton(
                    text: "Retry",
                    size: DgButtonSize.big,
                    variant: DgButtonVariant.primary,
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
    );
  }
}
