import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/icons/arrow_single.dart';
import 'package:mobile/open/widgets/icons/icon_rotation.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../../../data/db/enums.dart';

final String _title = "Two-factor authentication";

final Map<MfaMethod, String> _msg = {
  MfaMethod.totp: "Paste the authentication code from your Authenticator Application.",
  MfaMethod.email: "Paste the authentication code you received in the email.",
};

class CodeDialog extends HookConsumerWidget {
  final String token;
  final String url;
  final MfaMethod method;

  const CodeDialog({
    super.key,
    required this.token,
    required this.url,
    required this.method,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: DgColor.defaultModal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: DgSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Text(_title, style: DgText.sideBar)),
            SizedBox(height: 8),
            Column(
              spacing: DgSpacing.s,
              children: [
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _msg[method],
                ),
                _CodeForm(token: token, url: url),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<FinishMfaResponse> _handleSubmit(
  String url,
  String token,
  String code,
) async {
  debugPrint('Submitted: URL=$url, Code=$code');
  final request = FinishMfaRequest(token: token, code: code);
  final uri = Uri.parse(url);
  final response = await proxyApi.finishMfa(uri, request);
  return response;
}

class _CodeForm extends HookConsumerWidget {
  final String token;
  final String url;
  const _CodeForm({required this.token, required this.url});

  String? _validateCode(String? value, bool codeInvalid) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    if (value.length != 6 || codeInvalid) {
      return "Enter valid code";
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final codeController = useTextEditingController(text: "");
    final isLoading = useState(false);
    final codeInvalid = useState<bool>(false);

    return (Form(
      key: formKey,
      child: Column(
        spacing: DgSpacing.m,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            spacing: DgSpacing.l,
            children: [
              DgTextFormField(
                controller: codeController,
                required: true,
                hintText: "Code",
                keyboardType: TextInputType.number,
                validator: (value) => _validateCode(value, codeInvalid.value),
              ),
            ],
          ),
          Column(
            spacing: DgSpacing.m,
            children: [
              DgButton(
                text: "Submit",
                variant: DgButtonVariant.primary,
                size: DgButtonSize.big,
                width: double.infinity,
                loading: isLoading.value,
                onTap: () async {
                  codeInvalid.value = false;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  if (formKey.currentState?.validate() ?? false) {
                    isLoading.value = true;
                    try {
                      final response = await _handleSubmit(
                        url,
                        token,
                        codeController.text.trim(),
                      );
                      navigator.pop(response.presharedKey);
                    } on DioException catch (e) {
                      if (e.response?.statusCode == 401) {
                        codeInvalid.value = true;
                        formKey.currentState?.validate();
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    } finally {
                      isLoading.value = false;
                    }
                  }
                },
              ),
              DgButton(
                text: "Cancel",
                width: double.infinity,
                variant: DgButtonVariant.secondary,
                size: DgButtonSize.big,
                icon: DgIconArrowSingle(
                  direction: DgIconDirection.left,
                  size: 36,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
