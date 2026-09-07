import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/mfa/mfa_code_screen.dart';

class MfaEmailScreen extends StatelessWidget {
  final MfaCodeScreenData screenData;

  const MfaEmailScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context) {
    return MfaCodeScreen(
      screenData: screenData,
      title: 'Two-factor authentication',
      description: 'Paste the authentication code you received in the email.',
      fieldLabel: 'Authentication Code',
      logLabel: 'Email',
    );
  }
}
