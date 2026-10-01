import 'package:fido2_plugin/fido2_plugin.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/fido2_step.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_mfa_step_label.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/error_handler.dart';

const _plugin = Fido2Plugin();

class MfaFido2Screen extends HookConsumerWidget {
  final MfaStepHost host;

  /// Host of the instance URL, which is what the core registers keys under.
  final String rpId;

  const MfaFido2Screen({super.key, required this.host, required this.rpId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toaster = ref.read(toastManagerProvider.notifier);
    final pinController = useTextEditingController();
    final nfcStatus = useState<Fido2NfcStatus?>(null);
    final waiting = useState(false);
    final pinError = useState<String?>(null);

    useEffect(() {
      _refreshNfc(context, nfcStatus);
      return () => _plugin.cancel().ignore();
    }, const []);

    useOnAppLifecycleStateChange((_, state) {
      if (state == AppLifecycleState.resumed) _refreshNfc(context, nfcStatus);
    });

    final handleVerify = useCallback(() async {
      final controller = host.controller;
      final challenge = controller.challenge;
      if (challenge == null || controller.credentialIds.isEmpty) {
        host.reportFailure(
          message: "Verification failed. Please try again.",
          logMessage: "FIDO2 step opened without a challenge or credentials",
        );
        return;
      }

      final pin = pinController.text.isEmpty ? null : pinController.text;
      pinError.value = null;
      waiting.value = true;

      final attempt = await const Fido2StepRunner().attempt(
        rpId: rpId,
        challenge: challenge,
        credentialIds: controller.credentialIds,
        pin: pin,
      );
      if (!context.mounted) return;

      switch (attempt) {
        case Fido2Success(:final assertion):
          try {
            final progress = await controller.submitFido2(
              signature: assertion.signature,
              authData: assertion.authenticatorData,
              credentialId: assertion.credentialId,
            );
            if (progress is! MfaStepAwaiting) {
              host.reportProgress(progress);
              return;
            }
            toaster.showError(
              message: "Unexpected verification state. Please try again.",
              logMessage: "FIDO2 step returned an out-of-band outcome",
            );
          } on MfaCodeRejectedException catch (e) {
            toaster.showError(
              message: "Your security key was not accepted. Please try again.",
              logMessage: "FIDO2 MFA assertion rejected",
              error: e,
            );
          } catch (e) {
            toaster.showError(
              message: ErrorHandler.getHumanReadableError(e),
              logMessage: "FIDO2 MFA assertion submit failed",
              error: e,
            );
          }
        case Fido2NeedsPin():
          pinError.value =
              "This security key requires a PIN. Enter it and tap the key again.";
        case Fido2PinNotSet():
          pinError.value =
              "This security key has no PIN. Leave this field empty.";
        case Fido2PinMalformed():
          pinError.value = "Incorrect PIN. A PIN has 4 to 63 characters.";
        case Fido2WrongKey():
          toaster.showError(
            message: "This security key is not registered for your account.",
            logMessage: "FIDO2 key holds none of the offered credentials",
          );
        case Fido2PinInvalid(:final retries):
          pinController.clear();
          pinError.value = switch (retries) {
            null => "Incorrect PIN. Try again.",
            1 => "Incorrect PIN. 1 attempt left before the key locks.",
            _ => "Incorrect PIN. $retries attempts left.",
          };
        case Fido2Failed(:final error):
          if (error.code == Fido2ErrorCode.nfcDisabled) {
            _refreshNfc(context, nfcStatus);
          }
          final message = _failureMessage(error.code);
          if (message != null) {
            toaster.showError(
              message: message,
              logMessage: "FIDO2 MFA assertion failed",
              error: error,
            );
          }
      }
      if (context.mounted) waiting.value = false;
    }, [host, rpId]);

    final nfcOff = nfcStatus.value == Fido2NfcStatus.disabled;
    final nfcMissing = nfcStatus.value == Fido2NfcStatus.unsupported;

    return MfaStepScope(
      host: host,
      child: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: DgAppBar(
            context: context,
            showLogo: false,
            actionLeft: DgIconButton(
              icon: 'arrow_small',
              direction: DgIconDirection.left,
              onTap: host.abort,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 70),
                          const DgIcon(
                            'key',
                            size: 72,
                            color: DgColor.fgWhite100,
                          ),
                          const SizedBox(height: 60),
                          DgMfaStepLabel(host.controller.stepLabel),
                          Text(
                            "Security key",
                            style: DgText.h4.copyWith(
                              color: DgColor.fgWhite100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _description(
                              nfcOff: nfcOff,
                              nfcMissing: nfcMissing,
                              waiting: waiting.value,
                            ),
                            style: DgText.bodySm400.copyWith(
                              color: DgColor.fgWhite80,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DgSpacing.xl),
                          DgTextFormField(
                            identifier: "mfa_fido2_pin",
                            label: "Security key PIN (if set)",
                            controller: pinController,
                            obscureText: true,
                            disabled: waiting.value,
                            errorText: pinError.value,
                            onFieldSubmitted: (_) => handleVerify(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DgSpacing.xl),
                  if (nfcOff)
                    DgButton(
                      identifier: "mfa_fido2_enable_nfc",
                      text: "Turn on NFC",
                      style: DgButtonStyle.primary,
                      size: DgButtonSize.big,
                      width: double.infinity,
                      onTap: () => _plugin.openNfcSettings().ignore(),
                    )
                  else
                    DgButton(
                      identifier: "mfa_fido2_verify",
                      text: waiting.value ? "Waiting for key…" : "Verify now",
                      style: DgButtonStyle.primary,
                      size: DgButtonSize.big,
                      width: double.infinity,
                      loading: waiting.value,
                      disabled: nfcMissing,
                      onTap: handleVerify,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _refreshNfc(BuildContext context, ValueNotifier<Fido2NfcStatus?> status) {
  _plugin.nfcStatus().then(
    (value) {
      if (context.mounted) status.value = value;
    },
    onError: (_) {
      if (context.mounted) status.value = Fido2NfcStatus.unsupported;
    },
  );
}

String _description({
  required bool nfcOff,
  required bool nfcMissing,
  required bool waiting,
}) {
  if (nfcMissing) {
    return "This device has no NFC, so a security key cannot be used.";
  }
  if (nfcOff) return "Turn on NFC to use your security key.";
  if (waiting) return "Hold your security key against the back of the phone.";
  return "Tap Verify, then hold your security key against the back of the phone.";
}

/// Null when the user caused it and needs no telling.
String? _failureMessage(Fido2ErrorCode code) => switch (code) {
  Fido2ErrorCode.cancelled => null,
  Fido2ErrorCode.timeout => "No security key was detected. Please try again.",
  Fido2ErrorCode.tagLost =>
    "Keep the key against the phone until verification finishes.",
  Fido2ErrorCode.pinBlocked =>
    "This security key's PIN is blocked. Reset the key to use it again.",
  Fido2ErrorCode.pinAuthBlocked =>
    "Too many wrong PINs. Move the key away, then tap it again.",
  Fido2ErrorCode.unsupportedKey => "This key does not support FIDO2.",
  Fido2ErrorCode.nfcDisabled => "Turn on NFC to use your security key.",
  Fido2ErrorCode.nfcUnavailable => "NFC is not available on this device.",
  _ => "Security key verification failed. Please try again.",
};
