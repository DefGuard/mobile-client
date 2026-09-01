import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/icons/openid_wait.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';

import '../openid_mfa_waiting_screen.dart';
import '../../../../../logging.dart';
import '../../../../../utils/error_handler.dart';
import '../../../../open/services/snackbar_service.dart';

class NextOpenIdMfaWaitingScreen extends HookConsumerWidget {
  final OpenIdMfaWaitingScreenData screenData;

  const NextOpenIdMfaWaitingScreen({super.key, required this.screenData});

  Future<FinishMfaResponse?> _pollOpenidMfa() async {
    final request = FinishMfaRequest(token: screenData.token);
    final uri = Uri.parse(screenData.proxyUrl);

    final startTime = DateTime.now();
    const timeoutDuration = Duration(minutes: 2);

    while (true) {
      if (DateTime.now().difference(startTime) >= timeoutDuration) {
        talker.warning("OpenID MFA polling timed out after 2 minutes");
        return null;
      }

      try {
        final response = await proxyApi.finishMfa(uri, request);
        return response;
      } on DioException catch (e) {
        final isNetworkError =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            (e.error?.toString().contains("-1005") ?? false) ||
            (e.message?.contains("-1005") ?? false);

        if (e.response?.statusCode == 428 || isNetworkError) {
          if (isNetworkError) {
            talker.warning("Network error during MFA polling, retrying: $e");
          } else {
            talker.debug("User did not complete openid browser login, waiting");
          }
          await Future.delayed(const Duration(seconds: 2));
        } else {
          rethrow;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);

    useEffect(() {
      _pollOpenidMfa()
          .then((finishMfaResponse) {
            if (finishMfaResponse == null) {
              SnackbarService.show(
                "Authentication timed out. Please try again.",
                textColor:
                    NextColor.fgWhite100, // Adjusted color for Next theme
                dismissable: true,
              );
              if (context.mounted) navigator.pop();
            } else {
              if (context.mounted) {
                navigator.pop(finishMfaResponse.presharedKey);
              }
            }
          })
          .catchError((error) {
            talker.error("OpenID MFA polling error: $error");
            final message = ErrorHandler.getHumanReadableError(error);
            SnackbarService.show(
              message,
              textColor: NextColor.fgWhite100,
              dismissable: true,
            );
            if (context.mounted) navigator.pop();
          });
      return null;
    }, []);

    return Container(
      decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: NextAppBar(
          context: context,
          showLogo: false,
          actionLeft: NextIconButton(
            icon: 'arrow_small',
            direction: NextIconDirection.left,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Two-factor authentication",
                  style: NextText.h4.copyWith(color: NextColor.fgWhite100),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "Waiting for authentication in your browser...",
                  style: NextText.bodySm400.copyWith(
                    color: NextColor.fgWhite60,
                  ),
                ),
                const Spacer(),
                Center(child: DgIconOpenidWait(size: 160)),
                const Spacer(),
                const SizedBox(height: 20),
                NextButton(
                  text: 'Cancel',
                  style: NextButtonStyle.outlined,
                  width: double.infinity,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
