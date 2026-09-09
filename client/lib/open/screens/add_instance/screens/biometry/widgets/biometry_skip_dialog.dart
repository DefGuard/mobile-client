import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/theme/spacing.dart';

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
    return DgDialog(
      onClose: onCancel,
      children: [
        const DgDialogTitle('Skip biometric configuration'),
        const SizedBox(height: DgSpacing.md),
        const DgDialogDescription(
          'If you skip this step, you will need to use other MFA methods configured in your user profile (Such as TOTP / Authenticator app or email verification code)',
        ),
        const SizedBox(height: DgSpacing.xl2),
        DgButton(
          identifier: 'skip_biometry_confirm',
          text: 'Skip biometric configuration',
          style: DgButtonStyle.primary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: onSkip,
        ),
        const SizedBox(height: DgSpacing.md),
        DgButton(
          text: 'Cancel',
          style: DgButtonStyle.secondary,
          size: DgButtonSize.big,
          width: double.infinity,
          onTap: onCancel,
        ),
      ],
    );
  }
}
