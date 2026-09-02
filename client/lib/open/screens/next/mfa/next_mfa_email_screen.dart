import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/next/mfa/next_mfa_code_screen.dart';

class NextMfaEmailScreen extends StatelessWidget {
  final NextMfaCodeScreenData screenData;

  const NextMfaEmailScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context) {
    return NextMfaCodeScreen(
      screenData: screenData,
      title: 'Two-factor authentication',
      description: 'Paste the authentication code you received in the email.',
      fieldLabel: 'Authentication Code',
      logLabel: 'Email',
    );
  }
}
