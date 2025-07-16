import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/open/widgets/icons/openid_wait.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../../../logging.dart';

final String _title = "Two-factor authentication";
final String _mfaMsg = "Waiting for authentication in your browser...";
final String _cancelMsg = "Cancel";
final timeoutDuration = Duration(minutes: 2);

class OpenidMfaWaitingDialog extends HookConsumerWidget {
  final String proxyUrl;
  final String token;

  const OpenidMfaWaitingDialog({
    super.key,
    required this.proxyUrl,
    required this.token,
  });

  Future<FinishMfaResponse?> _pollOpenidMfa() async {
    final request = FinishMfaRequest(token: token);
    final uri = Uri.parse(proxyUrl);
    
    final startTime = DateTime.now();
    
    while (true) {
      // Check if timeout has been reached
      if (DateTime.now().difference(startTime) >= timeoutDuration) {
        talker.warning("OpenID MFA polling timed out after 2 minutes");
        return null;
      }
      
      try {
        final response = await proxyApi.finishMfa(uri, request);
        return response;
      } on DioException catch (e) {
        if (e.response?.statusCode == 428) {
          talker.debug("User did not complete openid browser login, waiting");
          await Future.delayed(Duration(seconds: 2));
        } else {
          rethrow;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Start polling automatically when dialog opens
    useEffect(() {
      _pollOpenidMfa()
          .then((finishMfaResponse) {
            if (finishMfaResponse == null) {
              // Timeout occurred
              messenger.showSnackBar(
                SnackBar(content: Text("Authentication timed out. Please try again.")),
              );
            }
            // Return the preshared key when polling completes
            navigator.pop(finishMfaResponse);
          })
          .catchError((error) {
            talker.error("OpenID MFA polling error: $error");
            messenger.showSnackBar(
              SnackBar(content: Text("Error: $error")),
            );
            navigator.pop(null);
          });
      return null;
    }, []);

    return DgDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              _title,
              style: DgText.body1,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          Center(
            child: DgIconOpenidWait(size: 128),
          ),
          SizedBox(height: 32),
          Text(
            _mfaMsg,
            style: DgText.modal1.copyWith(color: DgColor.textBodySecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: DgSpacing.s,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.all(DgSpacing.s),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: DgButton(
                        text: _cancelMsg,
                        size: DgButtonSize.standard,
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
