import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../../../logging.dart';

final String _title = "Two-factor authentication";
final String _mfaMsg1 =
    "In order to connect to VPN please login with your OpenID provider. To do so, pease click \"Authenticate with OpenId\"";

final String _mfaMsg2 =
    "This will open a new window in your web browser and automatically redirect you to your OpenID provider login page. After authenticating please get back here";

final String _authenticateMsg = "Authenticate with OpenId";

Future<StartMfaResponse> _handleSubmit(
  String url,
  String pubkey,
  int locationId,
  MfaMethod method,
) async {
  debugPrint('Submitted: URL=$url, Token=$pubkey');
  final request = StartMfaRequest(
    pubkey: pubkey,
    locationId: locationId,
    method: method.value,
  );

  final uri = Uri.parse(url);
  final response = await proxyApi.startMfa(uri, request);
  return response;
}

class OpenIdMfaStartDialog extends HookConsumerWidget {
  final String proxyUrl;
  final String publicKey;
  final int networkId;
  final String token;

  const OpenIdMfaStartDialog({
    super.key,
    required this.proxyUrl,
    required this.publicKey,
    required this.networkId,
    required this.token,
  });

  _openBrowser() {
    talker.error("Opening browser:", "${proxyUrl}openid/mfa?token=${token}");
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
                        final navigator = Navigator.of(context);
                        _openBrowser();
                        navigator.pop();
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
