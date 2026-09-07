import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/mfa/mfa_code_screen.dart';

class MfaTotpScreen extends StatelessWidget {
  final MfaCodeScreenData screenData;

  const MfaTotpScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context) {
    return MfaCodeScreen(
      screenData: screenData,
      title: 'Two-factor authentication',
      description:
          'Paste the authentication code from your Authenticator Application.',
      fieldLabel: 'Authentication Code',
      logLabel: 'TOTP',
    );
  }
}
