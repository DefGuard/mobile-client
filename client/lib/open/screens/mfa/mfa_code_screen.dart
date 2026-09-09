import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/dg_code_entry_layout.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/utils/error_handler.dart';

class MfaCodeScreen extends ConsumerWidget {
  final MfaStepHost host;
  final String title;
  final String description;
  final String fieldLabel;

  final String logLabel;

  const MfaCodeScreen({
    super.key,
    required this.host,
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.logLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toaster = ref.read(toastManagerProvider.notifier);

    return MfaStepScope(
      host: host,
      child: DgCodeEntryLayout(
        title: title,
        description: description,
        fieldLabel: fieldLabel,
        stepLabel: host.controller.stepLabel,
        onBack: host.abort,
        onSubmit: (code, setError) async {
          try {
            final progress = await host.controller.submit(code: code);
            if (progress is MfaStepAwaiting) {
              toaster.showError(
                message: "Unexpected verification state. Please try again.",
                logMessage:
                    "$logLabel step returned an out-of-band outcome for a code",
              );
              return;
            }
            host.reportProgress(progress);
          } on MfaCodeRejectedException {
            setError('Enter valid code');
          } catch (e) {
            toaster.showError(
              message: ErrorHandler.getHumanReadableError(e),
              logMessage: "$logLabel MFA code submit failed!",
              error: e,
            );
          }
        },
      ),
    );
  }
}
