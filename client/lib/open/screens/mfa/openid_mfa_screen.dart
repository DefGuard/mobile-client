import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/mfa/openid_mfa_waiting_screen.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/icons/openid_open.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/screen_padding.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenIdMfaScreenData {
  final String proxyUrl;
  final String token;

  const OpenIdMfaScreenData({required this.proxyUrl, required this.token});
}

final String _title = "Two-factor authentication";
final String _mfaMsg1 =
    "In order to connect to VPN please login with your OpenID provider. To do so, please click \"Authenticate with OpenId\"";

final String _mfaMsg2 =
    "This will open a new window in your web browser and automatically redirect you to your OpenID provider login page. After authenticating please get back here";

final String _authenticateMsg = "Authenticate with OpenID";

class OpenIdMfaScreen extends HookConsumerWidget {
  final OpenIdMfaScreenData screenData;

  const OpenIdMfaScreen({super.key, required this.screenData});

  Future<bool> _launchUrl() async {
    final url = Uri.parse(
      "${screenData.proxyUrl}openid/mfa?token=${screenData.token}",
    );
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DgScaffold(
      title: _title,
      child: DgSingleChildScrollView(
        padding: screenPadding(
          top: DgSpacing.l,
          bottom: DgSpacing.m,
          horizontal: DgSpacing.s,
          context: context,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: DgSpacing.m,
          children: [
            Center(
              child: Text(
                _title,
                style: DgText.body1,
                textAlign: TextAlign.center,
              ),
            ),
            Center(child: DgIconOpenidOpen(size: 128)),
            Text(
              _mfaMsg1,
              style: DgText.modal1.copyWith(color: DgColor.textBodySecondary),
              textAlign: TextAlign.center,
            ),
            Text(
              _mfaMsg2,
              style: DgText.modal1.copyWith(color: DgColor.textBodySecondary),
              textAlign: TextAlign.center,
            ),
            DgButton(
              text: _authenticateMsg,
              variant: DgButtonVariant.primary,
              size: DgButtonSize.big,
              width: double.infinity,
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final errorSnack = SnackBar(
                  content: Text("Error: Failed to open the browser."),
                );
                try {
                  final launched = await _launchUrl();
                  if (!launched) {
                    messenger.showSnackBar(errorSnack);
                  } else {
                    // Navigate to waiting screen and await result
                    final result = await navigator.push<String?>(
                      MaterialPageRoute(
                        builder: (context) => OpenIdMfaWaitingScreen(
                          screenData: OpenIdMfaWaitingScreenData(
                            proxyUrl: screenData.proxyUrl,
                            token: screenData.token,
                          ),
                        ),
                      ),
                    );

                    // Return the result to the tunnel service
                    navigator.pop(result);
                  }
                } catch (_) {
                  messenger.showSnackBar(errorSnack);
                }
              },
            ),
            DgButton(
              text: "Cancel",
              size: DgButtonSize.big,
              width: double.infinity,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
