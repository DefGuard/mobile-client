import 'package:dio/dio.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_mfa_step_label.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

import 'package:mobile/logging.dart';
import 'package:mobile/utils/error_handler.dart';

class OpenIdMfaWaitingScreen extends HookConsumerWidget {
  final MfaStepHost host;

  const OpenIdMfaWaitingScreen({super.key, required this.host});

  /// Polls until the browser hop resolves. An unresolved factor comes back
  /// either as an `awaitingExternal` outcome or, from a pre-2.2 proxy, as a 428
  /// that the api layer normalizes into the same thing.
  Future<MfaStepProgress?> _pollOpenidMfa(bool Function() isCancelled) async {
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
        final progress = await host.controller.submit();
        if (progress is! MfaStepAwaiting) {
          return progress;
        }
        talker.debug("User did not complete openid browser login, waiting");
        await Future.delayed(const Duration(seconds: 2));
      } on DioException catch (e) {
        final isNetworkError =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            (e.error?.toString().contains("-1005") ?? false) ||
            (e.message?.contains("-1005") ?? false);

        if (!isNetworkError) rethrow;
        talker.warning("Network error during MFA polling, retrying: $e");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ModalRoute.of(context);
    final toaster = ref.read(toastManagerProvider.notifier);

    useEffect(() {
      bool isGone() =>
          host.controller.isCancelled || (route != null && !route.isActive);

      _pollOpenidMfa(isGone)
          .then((progress) {
            if (isGone()) return;
            if (progress == null) {
              toaster.showError(
                message: "Authentication timed out. Please try again.",
              );
              host.abort();
            } else {
              host.reportProgress(progress);
            }
          })
          .catchError((error) {
            if (isGone()) return;
            host.reportFailure(
              message: ErrorHandler.getHumanReadableError(error),
              logMessage: "OpenID MFA polling error!",
              error: error,
            );
          });

      return null;
    }, []);

    return MfaStepScope(
      host: host,
      child: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: DgAppBar(
            context: context,
            showLogo: false,
            actionLeft: DgIconButton(
              icon: 'arrow_small',
              direction: DgIconDirection.left,
              onTap: host.abort,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DgMfaStepLabel(host.controller.stepLabel),
                  Text(
                    "Two-factor authentication",
                    style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Waiting for authentication in your browser...",
                    style: DgText.bodyXs400.copyWith(color: DgColor.fgWhite60),
                  ),
                  const Spacer(),
                  DgButton(
                    text: 'Cancel',
                    style: DgButtonStyle.outlined,
                    width: double.infinity,
                    onTap: host.abort,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
