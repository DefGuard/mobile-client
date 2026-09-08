import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/mfa/mfa_code_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';

class MfaEmailScreen extends StatelessWidget {
  final MfaStepHost host;

  const MfaEmailScreen({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    return MfaCodeScreen(
      host: host,
      title: 'Two-factor authentication',
      description: 'Paste the authentication code you received in the email.',
      fieldLabel: 'Authentication Code',
      logLabel: 'Email',
    );
  }
}
