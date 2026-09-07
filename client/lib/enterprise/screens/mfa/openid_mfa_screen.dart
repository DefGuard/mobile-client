import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/logging.dart';
import 'openid_mfa_waiting_screen.dart';

class OpenIdMfaScreenData {
  final String proxyUrl;
  final String token;
  final String? openidDisplayName;

  const OpenIdMfaScreenData({
    required this.proxyUrl,
    required this.token,
    this.openidDisplayName,
  });
}

class OpenIdMfaScreen extends HookConsumerWidget {
  final OpenIdMfaScreenData screenData;

  const OpenIdMfaScreen({super.key, required this.screenData});

  Future<bool> _launchUrl() async {
    final url = Uri.parse(
      "${screenData.proxyUrl}openid/mfa?token=${screenData.token}",
    );
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = "Continue with OpenID";
    final String providerName = screenData.openidDisplayName ?? 'OpenID';
    final toaster = ref.read(toastManagerProvider.notifier);

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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "Confirm your identity to continue. You'll be redirected to your identity provider to complete verification.",
                  style: DgText.bodyXs400.copyWith(
                    color: DgColor.fgWhite60,
                  ),
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
                      } else {
                        final result = await navigator.push<String?>(
                          MaterialPageRoute(
                            builder: (context) => OpenIdMfaWaitingScreen(
                              screenData: OpenIdMfaWaitingScreenData(
                                proxyUrl: screenData.proxyUrl,
                                token: screenData.token,
                              ),
                            ),
                          ),
                        );

                        if (context.mounted) {
                          navigator.pop(result);
                        }
                      }
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
    );
  }
}
