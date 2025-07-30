import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/webauthn.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/navigation/dg_scaffold.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:passkeys/authenticator.dart';

class TestPasskeyScreen extends StatelessWidget {
  const TestPasskeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(
      title: "Test biometry",
      child: DgSingleChildScrollView(child: _PageContent()),
    );
  }
}

class _PageContent extends HookConsumerWidget {
  const _PageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final isLoading = useState(false);
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: DgSpacing.s,
      children: [
        DgMessageBox(
          text:
              "Start passkey registration in core and paste init response from core here.",
        ),
        DgTextFormField(
          controller: textController,
          hintText: "Registration JSON",
          validator: (value) {
            if (value is String && value.isEmpty) {
              return "Field is required";
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.always,
        ),
        DgButton(
          text: "Test",
          loading: isLoading.value,
          size: DgButtonSize.big,
          variant: DgButtonVariant.primary,
          width: double.infinity,
          onTap: () async {
            isLoading.value = true;
            final msg = ScaffoldMessenger.of(context);
            final authenticator = PasskeyAuthenticator(debugMode: true);
            try {
              final challenge = textController.text;
              final registrationProps = parseProxyPasskeyRegistrationResponse(
                challenge,
              );
              final authenticatorResponse = await authenticator.register(
                registrationProps,
              );
              msg.showSnackBar(
                dgSnackBar(text: "Registration succeeded ! That's it for now."),
              );
              talker.debug(
                "Passkey registration succeeded}",
                authenticatorResponse,
              );
            } catch (e) {
              talker.error("Passkey registration failed!", e);
              msg.showSnackBar(
                dgSnackBar(
                  text: "Passkey registration failed ! Error: ${e.toString()}",
                  textColor: DgColor.textAlert,
                  onlyDismiss: true,
                  onDismiss: () {
                    msg.hideCurrentSnackBar();
                  },
                ),
              );
            } finally {
              textController.clear();
              isLoading.value = false;
            }
          },
        ),
      ],
    );
  }
}
