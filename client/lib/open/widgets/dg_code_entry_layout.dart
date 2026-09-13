import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_mfa_step_label.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

typedef DgCodeEntrySubmit =
    Future<void> Function(String code, void Function(String?) setError);

/// Length of a Defguard MFA code, both TOTP and e-mail.
const int _codeLength = 6;

class DgCodeEntryLayout extends HookWidget {
  final String title;
  final String description;
  final String fieldLabel;
  final DgCodeEntrySubmit onSubmit;

  /// Set only for a flow with more than one step.
  final String? stepLabel;

  final VoidCallback? onBack;

  const DgCodeEntryLayout({
    super.key,
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.onSubmit,
    this.stepLabel,
    this.onBack,
  });

  /// Local checks, so an obviously incomplete code never costs a round trip.
  /// A code the server rejects comes back through `setError` instead.
  static String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return "This field is required";
    }
    if (code.length != _codeLength) {
      return "Enter valid code";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final codeController = useTextEditingController();
    final isLoading = useState(false);
    final errorText = useState<String?>(null);

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
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SafeArea(
                    bottom: true,
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 20,
                        right: 20,
                        bottom: 20,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DgMfaStepLabel(stepLabel),
                            Text(
                              title,
                              style: DgText.h4.copyWith(
                                color: DgColor.fgWhite100,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: DgText.bodySm400.copyWith(
                                color: DgColor.fgWhite60,
                              ),
                            ),
                            const SizedBox(height: 32),
                            DgTextFormField(
                              identifier: 'mfa_code_input',
                              required: true,
                              size: .big,
                              label: fieldLabel,
                              controller: codeController,
                              errorText: errorText.value,
                              validator: _validateCode,
                              onChanged: (_) => errorText.value = null,
                              keyboardType: TextInputType.number,
                            ),
                            const Spacer(),
                            const SizedBox(height: 20),
                            DgButton(
                              identifier: 'mfa_code_submit',
                              text: 'Submit',
                              loading: isLoading.value,
                              width: double.infinity,
                              onTap: () async {
                                // a server side error would otherwise mask the
                                // validator message for the same field
                                errorText.value = null;
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                isLoading.value = true;
                                try {
                                  await onSubmit(
                                    codeController.text.trim(),
                                    (error) => errorText.value = error,
                                  );
                                } finally {
                                  isLoading.value = false;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

@Preview(name: 'Email MFA', group: 'MFA')
Widget previewEmailMfa() {
  return DgPreviewWrapper(
    child: DgCodeEntryLayout(
      title: 'Two-factor authentication',
      description: 'Paste the authentication code you received in the email.',
      fieldLabel: 'Authentication Code',
      onSubmit: (code, setError) async {
        await Future.delayed(const Duration(seconds: 1));
        if (code != '123456') {
          setError('Invalid code');
        }
      },
    ),
  );
}

@Preview(name: 'TOTP MFA', group: 'MFA')
Widget previewTotpMfa() {
  return DgPreviewWrapper(
    child: DgCodeEntryLayout(
      title: 'Two-factor authentication',
      description:
          'Paste the authentication code from your Authenticator Application.',
      fieldLabel: 'Authentication Code',
      onSubmit: (code, setError) async {
        await Future.delayed(const Duration(seconds: 1));
        if (code != '123456') {
          setError('Invalid code');
        }
      },
    ),
  );
}
