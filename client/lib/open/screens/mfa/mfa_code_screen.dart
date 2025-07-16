import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/nav.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../../../data/db/enums.dart';

class MfaCodeScreenData {
  final String token;
  final String url;
  final MfaMethod method;

  const MfaCodeScreenData({
    required this.token,
    required this.url,
    required this.method,
  });
}

final String _title = "Two-factor authentication";

final Map<MfaMethod, String> _msg = {
  MfaMethod.totp:
      "Paste the authentication code from your Authenticator Application.",
  MfaMethod.email: "Paste the authentication code you received in the email.",
};

class MfaCodeScreen extends HookConsumerWidget {
  final MfaCodeScreenData screenData;

  const MfaCodeScreen({super.key, required this.screenData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DgColor.frameBg,
      appBar: DgAppBar(title: _title),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DgSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        _title,
                        style: DgText.body1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      _msg[screenData.method] ?? "",
                      style: DgText.modal1.copyWith(
                        color: DgColor.textBodySecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DgSpacing.l),
                    _CodeForm(screenData: screenData),
                  ],
                ),
              ),
            ],
          ),
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
  final MfaCodeScreenData screenData;
  const _CodeForm({required this.screenData});

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

    return Form(
      key: formKey,
      child: Column(
        spacing: DgSpacing.m,
        mainAxisSize: MainAxisSize.min,
        children: [
          DgTextFormField(
            controller: codeController,
            required: true,
            hintText: "Authentication Code",
            keyboardType: TextInputType.number,
            validator: (value) => _validateCode(value, codeInvalid.value),
          ),
          SizedBox(height: DgSpacing.l),
          Column(
            spacing: DgSpacing.m,
            children: [
              DgButton(
                text: "Verify",
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
                        screenData.url,
                        screenData.token,
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
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
