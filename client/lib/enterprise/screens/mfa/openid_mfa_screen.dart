import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/dg_openid_mfa_layout.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/logging.dart';
import 'openid_mfa_waiting_screen.dart';

class OpenIdMfaScreen extends HookConsumerWidget {
  final MfaStepHost host;
  final String proxyUrl;
  final String? openidDisplayName;
  final OpenIdProvider openidProvider;

  const OpenIdMfaScreen({
    super.key,
    required this.host,
    required this.proxyUrl,
    required this.openidProvider,
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
    final toaster = ref.read(toastManagerProvider.notifier);

    return MfaStepScope(
      host: host,
      child: DgOpenIdMfaLayout(
        openidDisplayName: openidDisplayName,
        openidProvider: openidProvider,
        stepLabel: host.controller.stepLabel,
        onBack: host.abort,
        onContinue: () async {
          final navigator = Navigator.of(context);
          try {
            final launched = await _launchUrl();
            if (!launched) {
              toaster.showError(message: "Failed to open the browser.");
              return;
            }
            navigator.push(
              MaterialPageRoute(
                settings: const RouteSettings(name: mfaStepRouteName),
                builder: (context) => OpenIdMfaWaitingScreen(host: host),
              ),
            );
          } catch (e) {
            talker.error("Failed to open browser! Reason: $e");
            toaster.showError(message: "Failed to open the browser.");
          }
        },
      ),
    );
  }
}
