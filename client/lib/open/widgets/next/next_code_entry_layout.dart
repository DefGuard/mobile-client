import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/open/widgets/next/next_text_form_field.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';

typedef NextCodeEntrySubmit =
    Future<void> Function(String code, void Function(String?) setError);

class NextCodeEntryLayout extends HookWidget {
  final String title;
  final String description;
  final String fieldLabel;
  final NextCodeEntrySubmit onSubmit;

  const NextCodeEntryLayout({
    super.key,
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final codeController = useTextEditingController();
    final isLoading = useState(false);
    final errorText = useState<String?>(null);

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: NextText.h4.copyWith(
                              color: NextColor.fgWhite100,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: NextText.bodySm400.copyWith(
                              color: NextColor.fgWhite60,
                            ),
                          ),
                          const SizedBox(height: 32),
                          NextTextFormField(
                            required: true,
                            size: .big,
                            label: fieldLabel,
                            controller: codeController,
                            errorText: errorText.value,
                            onChanged: (_) => errorText.value = null,
                            keyboardType: TextInputType.number,
                          ),
                          const Spacer(),
                          const SizedBox(height: 20),
                          NextButton(
                            text: 'Submit',
                            loading: isLoading.value,
                            width: double.infinity,
                            onTap: () async {
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
  return NextPreviewWrapper(
    child: NextCodeEntryLayout(
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
  return NextPreviewWrapper(
    child: NextCodeEntryLayout(
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
