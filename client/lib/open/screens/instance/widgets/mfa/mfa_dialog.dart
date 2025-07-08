import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/main.dart';

final String _title = "Two-factor authentication";
final String _mfaMsg =
    "For this connection, two-factor authentication (2FA) is mandatory. Select your preferred authentication method.";

final String _useAuthenticatorMsg = "Authenticator app";
final String _useEmailMsg = "Email code";

enum MfaMethod { totp, email }

Future<StartMfaResponse> _handleSubmit(
  String url,
  String pubkey,
  int locationId,
  int method,
) async {
  debugPrint('Submitted: URL=$url, Token=$pubkey');
  final request = StartMfaRequest(
    pubkey: pubkey,
    locationId: locationId,
    method: method,
  );

  final uri = Uri.parse(url);
  final response = await proxyApi.startMfa(uri, request);
  return response;
}

class MfaStartDialog extends HookConsumerWidget {
  final String url;
  final String publicKey;
  final int locationId;
  final int method;

  const MfaStartDialog({
    super.key,
    required this.url,
    required this.publicKey,
    required this.locationId,
    required this.method,
  });

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
                  text: _mfaMsg,
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DgButton(
                      text: _useAuthenticatorMsg,
                      variant: DgButtonVariant.secondary,
                      size: DgButtonSize.standard,
                      onTap: () async {
                        final response = await _handleSubmit(
                          url,
                          publicKey,
                          locationId,
                          method,
                        );
                        talker.error("MFA start response:", response);
                        Navigator.of(context).pop((MfaMethod.totp, response.token));
                      },
                    ),
                    DgButton(
                      text: _useEmailMsg,
                      variant: DgButtonVariant.secondary,
                      size: DgButtonSize.standard,
                      onTap: () async {
                        final response = await _handleSubmit(
                          url,
                          publicKey,
                          locationId,
                          method,
                        );
                        talker.error("MFA start response:", response);
                        Navigator.of(context).pop((MfaMethod.totp, response.token));
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
