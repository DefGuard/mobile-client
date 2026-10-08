import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/utils/error_handler.dart';

/// Names every route the MFA flow pushes, so unwinding the whole flow is one
/// `popUntil` no matter how many steps were stacked.
const String mfaStepRouteName = 'mfa-step';

/// What a step screen may tell the flow. Screens handle their own recoverable
/// errors and only report what changes the flow's course.
abstract class MfaStepHost {
  MfaFlowController get controller;

  void reportProgress(MfaStepProgress progress);

  void reportFailure({
    required String message,
    String? logMessage,
    Object? error,
  });

  /// Ends the whole connect. Earlier steps are already proven server-side, so
  /// there is no coherent step to go back to.
  void abort();
}

/// The server drops the session at the attempt limit, so the step cannot be
/// retried and the whole flow ends instead.
bool reportIfAttemptLimit(MfaStepHost host, Object error) {
  if (error is! MfaRequestException ||
      error.failure != MfaRequestFailure.attemptLimit) {
    return false;
  }
  host.reportFailure(
    message: ErrorHandler.getHumanReadableError(error),
    logMessage: 'MFA attempt limit reached',
    error: error,
  );
  return true;
}

class MfaStepScope extends StatelessWidget {
  final MfaStepHost host;
  final Widget child;

  const MfaStepScope({super.key, required this.host, required this.child});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) host.abort();
    },
    child: child,
  );
}
