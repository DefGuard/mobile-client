import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_external_provider_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_mfa_step_label.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

class DgOpenIdMfaLayout extends StatelessWidget {
  final String? openidDisplayName;
  final OpenIdProvider openidProvider;
  final VoidCallback onContinue;
  final String? stepLabel;
  final VoidCallback onBack;

  const DgOpenIdMfaLayout({
    super.key,
    required this.openidProvider,
    required this.onContinue,
    required this.onBack,
    this.openidDisplayName,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final providerName = MfaMethod.openid.toUiString(
      openidDisplayName: openidDisplayName,
    );

    return Container(
      decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DgAppBar(
          context: context,
          showLogo: false,
          actionLeft: DgIconButton(
            icon: 'arrow_small',
            direction: DgIconDirection.left,
            onTap: onBack,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DgMfaStepLabel(stepLabel),
                Text(
                  "Authenticate with OpenID",
                  style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Confirm your identity to continue. You'll be redirected to your identity provider to complete verification.",
                  style: DgText.bodySm400.copyWith(color: DgColor.fgWhite60),
                ),
                Expanded(
                  child: Image.asset("assets/next/img/openid_mfa.png"),
                ),
                DgExternalProviderButton(
                  text: 'Continue with $providerName',
                  provider: openidProvider,
                  onTap: onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _preview(
  String? openidDisplayName,
  OpenIdProvider openidProvider, {
  String? stepLabel,
}) {
  return DgPreviewWrapper(
    padding: EdgeInsets.zero,
    child: DgOpenIdMfaLayout(
      openidDisplayName: openidDisplayName,
      openidProvider: openidProvider,
      stepLabel: stepLabel,
      onContinue: () {},
      onBack: () {},
    ),
  );
}

@Preview(name: 'OpenID Google', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaGoogle() =>
    _preview('Google', OpenIdProvider.google, stepLabel: 'Step 2/2');

@Preview(name: 'OpenID Microsoft', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaMicrosoft() =>
    _preview('Microsoft', OpenIdProvider.microsoft);

@Preview(name: 'OpenID Okta', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaOkta() => _preview('Okta', OpenIdProvider.okta);

@Preview(name: 'OpenID JumpCloud', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaJumpCloud() =>
    _preview('JumpCloud', OpenIdProvider.jumpcloud);

@Preview(name: 'OpenID Custom', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaCustom() => _preview('Keycloak', OpenIdProvider.custom);

@Preview(name: 'OpenID No display name', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaNoDisplayName() => _preview(null, OpenIdProvider.custom);

@Preview(name: 'OpenID Long name', group: 'MFA', size: Size(375, 812))
Widget previewOpenIdMfaLongName() => _preview(
  'Very Long Corporate Identity Provider Name',
  OpenIdProvider.custom,
);
