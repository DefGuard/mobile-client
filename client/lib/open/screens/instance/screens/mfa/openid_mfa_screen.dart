import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/screens/instance/screens/mfa/openid_mfa_waiting_screen.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/icons/openid_open.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:url_launcher/url_launcher.dart';

final String _title = "Two-factor authentication";
final String _mfaMsg1 =
    "In order to connect to VPN please login with your OpenID provider. To do so, pease click \"Authenticate with OpenId\"";

final String _mfaMsg2 =
    "This will open a new window in your web browser and automatically redirect you to your OpenID provider login page. After authenticating please get back here";

final String _authenticateMsg = "Authenticate with OpenId";

class OpenIdMfaScreen extends HookConsumerWidget {
  final String proxyUrl;
  final String token;

  const OpenIdMfaScreen({
    super.key,
    required this.proxyUrl,
    required this.token,
  });

  Future<bool> _launchUrl() async {
    final url = Uri.parse("${proxyUrl}openid/mfa?token=$token");
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DgColor.defaultModal,
      appBar: AppBar(
        backgroundColor: DgColor.defaultModal,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DgColor.textBodyPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DgSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        _title,
                        style: DgText.body1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 32),
                    Center(child: DgIconOpenidOpen(size: 128)),
                    SizedBox(height: 32),
                    Text(
                      _mfaMsg1,
                      style: DgText.modal1.copyWith(
                        color: DgColor.textBodySecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _mfaMsg2,
                      style: DgText.modal1.copyWith(
                        color: DgColor.textBodySecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: DgButton(
                      text: _authenticateMsg,
                      variant: DgButtonVariant.primary,
                      size: DgButtonSize.standard,
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
                                  proxyUrl: proxyUrl,
                                  token: token,
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
                  ),
                  SizedBox(height: DgSpacing.s),
                  SizedBox(
                    width: double.infinity,
                    child: DgButton(
                      text: "Cancel",
                      size: DgButtonSize.standard,
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
    );
  }
}
