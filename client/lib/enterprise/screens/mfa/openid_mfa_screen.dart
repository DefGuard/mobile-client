import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_mfa_step_label.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/logging.dart';
import 'openid_mfa_waiting_screen.dart';

class OpenIdMfaScreen extends HookConsumerWidget {
  final MfaStepHost host;
  final String proxyUrl;
  final String? openidDisplayName;

  const OpenIdMfaScreen({
    super.key,
    required this.host,
    required this.proxyUrl,
    this.openidDisplayName,
  });

  Future<bool> _launchUrl() async {
    final url = Uri.parse(
      "${proxyUrl}openid/mfa?token=${host.controller.token}",
    );
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = "Continue with OpenID";
    final String providerName = openidDisplayName ?? 'OpenID';
    final toaster = ref.read(toastManagerProvider.notifier);

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
                    title,
                    style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Confirm your identity to continue. You'll be redirected to your identity provider to complete verification.",
                    style: DgText.bodyXs400.copyWith(color: DgColor.fgWhite60),
                  ),
                  const Spacer(),
                  DgButton(
                    text: 'Continue with $providerName',
                    width: double.infinity,
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      try {
                        final launched = await _launchUrl();
                        if (!launched) {
                          toaster.showError(
                            message: "Failed to open the browser.",
                          );
                          return;
                        }
                        navigator.push(
                          MaterialPageRoute(
                            settings: const RouteSettings(
                              name: mfaStepRouteName,
                            ),
                            builder: (context) =>
                                OpenIdMfaWaitingScreen(host: host),
                          ),
                        );
                      } catch (e) {
                        talker.error("Failed to open browser! Reason: $e");
                        toaster.showError(
                          message: "Failed to open the browser.",
                        );
                      }
                    },
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
