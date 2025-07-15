import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
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

class OpenIdMfaStartDialog extends HookConsumerWidget {
  final String proxyUrl;
  final String token;

  const OpenIdMfaStartDialog({
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
    return Dialog(
      backgroundColor: DgColor.defaultModal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: DgSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Text(_title, style: DgText.sideBar)),
            SizedBox(height: 8),
            Column(
              spacing: DgSpacing.s,
              children: [
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _mfaMsg1,
                ),
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _mfaMsg2,
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DgButton(
                      text: _authenticateMsg,
                      variant: DgButtonVariant.secondary,
                      size: DgButtonSize.standard,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final errorSnack = SnackBar(
                          content: Text("Error: Failed to open the browser."),
                        );
                        try {
                          final launched = await _launchUrl();
                          if (!launched) {
                            messenger.showSnackBar(errorSnack);
                          }
                          navigator.pop(launched);
                        } catch (_) {
                          messenger.showSnackBar(errorSnack);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
