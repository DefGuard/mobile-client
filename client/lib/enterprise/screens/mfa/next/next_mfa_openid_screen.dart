import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/icons/openid_open.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../openid_mfa_screen.dart';
import '../openid_mfa_waiting_screen.dart';
import '../../../../logging.dart';
import '../../../../open/services/snackbar_service.dart';
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
    final String title = "Two-factor authentication";
    final String providerName = screenData.openidDisplayName ?? 'OpenID';

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
                  title,
                  style: NextText.h4.copyWith(color: NextColor.fgWhite100),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "In order to connect to VPN please login with $providerName. To do so, please click \"Authenticate with $providerName\" button below.",
                  style: NextText.bodySm400.copyWith(
                    color: NextColor.fgWhite60,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "This will open a new window in your Web Browser and automatically redirect you to the $providerName login page. After authenticating with $providerName please get back here.",
                  style: NextText.bodySm400.copyWith(
                    color: NextColor.fgWhite60,
                  ),
                ),
                const Spacer(),
                Center(child: DgIconOpenidOpen(size: 160)),
                const Spacer(),
                const SizedBox(height: 20),
                NextButton(
                  text: 'Authenticate with $providerName',
                  width: double.infinity,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    try {
                      final launched = await _launchUrl();
                      if (!launched) {
                        SnackbarService.showError(
                          "Failed to open the browser.",
                        );
                      } else {
                        // Navigate to waiting screen and await result
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

                        // Return the result to the tunnel service
                        if (context.mounted) {
                          navigator.pop(result);
                        }
                      }
                    } catch (e) {
                      talker.error("Failed to open browser! Reason: $e");
                      SnackbarService.showError("Failed to open the browser.");
                    }
                  },
                ),
                const SizedBox(height: 12),
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
