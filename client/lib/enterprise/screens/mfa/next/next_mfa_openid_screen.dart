import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../logging.dart';
import '../openid_mfa_screen.dart';
import '../openid_mfa_waiting_screen.dart';
import 'next_mfa_openid_waiting_screen.dart';

class NextOpenIdMfaScreen extends HookConsumerWidget {
  final OpenIdMfaScreenData screenData;

  const NextOpenIdMfaScreen({super.key, required this.screenData});

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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NextText.h4.copyWith(color: NextColor.fgWhite100),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "Confirm your identity to continue. You'll be redirected to your identity provider to complete verification.",
                  style: NextText.bodyXs400.copyWith(
                    color: NextColor.fgWhite60,
                  ),
                ),
                const Spacer(),
                NextButton(
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
                            builder: (context) => NextOpenIdMfaWaitingScreen(
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
