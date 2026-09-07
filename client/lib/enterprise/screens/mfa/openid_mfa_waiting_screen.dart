import 'package:dio/dio.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

import 'package:mobile/logging.dart';
import 'package:mobile/utils/error_handler.dart';

class OpenIdMfaWaitingScreenData {
  final String proxyUrl;
  final String token;

  const OpenIdMfaWaitingScreenData({
    required this.proxyUrl,
    required this.token,
  });
}

class OpenIdMfaWaitingScreen extends HookConsumerWidget {
  final OpenIdMfaWaitingScreenData screenData;

  const OpenIdMfaWaitingScreen({super.key, required this.screenData});

  Future<FinishMfaResponse?> _pollOpenidMfa(bool Function() isCancelled) async {
    final request = FinishMfaRequest(token: screenData.token);
    final uri = Uri.parse(screenData.proxyUrl);

    final startTime = DateTime.now();
    const timeoutDuration = Duration(minutes: 2);

    while (true) {
      if (isCancelled()) {
        talker.debug("OpenID MFA polling cancelled");
        return null;
      }

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
    final route = ModalRoute.of(context);
    final toaster = ref.read(toastManagerProvider.notifier);

    useEffect(() {
      bool isGone() => route != null && !route.isActive;

      _pollOpenidMfa(isGone)
          .then((finishMfaResponse) {
            if (isGone()) return;
            if (finishMfaResponse == null) {
              toaster.showError(
                message: "Authentication timed out. Please try again.",
              );
              navigator.pop();
            } else {
              navigator.pop(finishMfaResponse.presharedKey);
            }
          })
          .catchError((error) {
            if (isGone()) return;
            toaster.showError(
              message: ErrorHandler.getHumanReadableError(error),
              logMessage: "OpenID MFA polling error!",
              error: error,
            );
            navigator.pop();
          });

      return null;
    }, []);

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
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: .fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Two-factor authentication",
                  style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "Waiting for authentication in your browser...",
                  style: DgText.bodyXs400.copyWith(
                    color: DgColor.fgWhite60,
                  ),
                ),
                const Spacer(),
                DgButton(
                  text: 'Cancel',
                  style: DgButtonStyle.outlined,
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
