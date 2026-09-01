import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_dialog.dart';
import 'package:mobile/theme/next/spacing.dart';

class BiometrySkipDialog extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  const BiometrySkipDialog({
    super.key,
    required this.onSkip,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return NextDialog(
      onClose: onCancel,
      children: [
        const NextDialogTitle('Skip biometric configuration'),
        const SizedBox(height: NextSpacing.md),
        const NextDialogDescription(
          'If you skip this step, you will need to use other MFA methods configured in your user profile (Such as TOTP / Authenticator app or email verification code)',
        ),
        const SizedBox(height: NextSpacing.xl2),
        NextButton(
          text: 'Skip biometric configuration',
          style: NextButtonStyle.primary,
          size: NextButtonSize.big,
          width: double.infinity,
          onTap: onSkip,
        ),
        const SizedBox(height: NextSpacing.md),
        NextButton(
          text: 'Cancel',
          style: NextButtonStyle.secondary,
          size: NextButtonSize.big,
          width: double.infinity,
          onTap: onCancel,
        ),
      ],
    );
  }
}
