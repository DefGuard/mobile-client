import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_screen.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/mfa/mfa_biometric_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_email_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/screens/mfa/mfa_totp_screen.dart';
import 'package:mobile/utils/error_handler.dart';

sealed class MfaFlowResult {
  const MfaFlowResult();
}

class MfaFlowConnected extends MfaFlowResult {
  const MfaFlowConnected();
}

class MfaFlowCancelled extends MfaFlowResult {
  const MfaFlowCancelled();
}

class MfaFlowFailed extends MfaFlowResult {
  final String message;
  final String? logMessage;
  final Object? error;

  const MfaFlowFailed({required this.message, this.logMessage, this.error});
}

typedef MfaStepScreenBuilder = Widget Function(MfaStepHost host);

/// Walks the user through a location's MFA steps, pushing one screen per step
/// and unwinding the lot once the flow ends. Nothing pops in between, so the
/// connect sheet underneath is never left exposed mid-flow.
class MfaStepFlow implements MfaStepHost {
  final NavigatorState navigator;
  final String proxyUrl;
  final String? secureStorageKey;
  final String? openidDisplayName;

  @override
  final MfaFlowController controller;

  /// Overridable the same way the transport is, so the flow's navigation can
  /// be driven without the real step screens.
  final MfaStepScreenBuilder? buildStepScreen;

  final Completer<MfaFlowResult> _completion = Completer<MfaFlowResult>();
  bool _finished = false;

  MfaStepFlow({
    required this.navigator,
    required this.controller,
    required this.proxyUrl,
    this.secureStorageKey,
    this.openidDisplayName,
    this.buildStepScreen,
  });

  Future<MfaFlowResult> run() async {
    await _openStep();
    return _completion.future;
  }

  Future<void> _openStep() async {
    try {
      await controller.startStep();
    } on MfaRejectedException catch (e) {
      _finish(
        MfaFlowFailed(
          message: e.message,
          logMessage: "MFA plan rejected at start",
          error: e,
        ),
      );
      return;
    } on MfaMethodNotAvailableException catch (e) {
      final method = e.method.toReadableString();
      _finish(
        MfaFlowFailed(
          message:
              "$method is not configured on your account. "
              "Select a different MFA method.",
          logMessage: "MFA method $method was not configured on the account",
          error: e,
        ),
      );
      return;
    } catch (e) {
      _finish(
        MfaFlowFailed(
          message: ErrorHandler.getHumanReadableError(e),
          logMessage: "Failed to start MFA step ${controller.stepIndex + 1}",
          error: e,
        ),
      );
      return;
    }

    if (_finished) return;
    navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: mfaStepRouteName),
        builder: (context) => buildStepScreen?.call(this) ?? _stepScreen(),
      ),
    );
  }

  @override
  void reportProgress(MfaStepProgress progress) {
    switch (progress) {
      case MfaStepAdvanced():
        _openStep();
      case MfaStepCompleted():
        _finish(const MfaFlowConnected());
      case MfaStepAwaiting():
        break;
    }
  }

  @override
  void reportFailure({
    required String message,
    String? logMessage,
    Object? error,
  }) => _finish(
    MfaFlowFailed(message: message, logMessage: logMessage, error: error),
  );

  @override
  void abort() {
    controller.cancel();
    _finish(const MfaFlowCancelled());
  }

  void _finish(MfaFlowResult result) {
    if (_finished) return;
    _finished = true;
    navigator.popUntil((route) => route.settings.name != mfaStepRouteName);
    _completion.complete(result);
  }

  Widget _stepScreen() => switch (controller.method) {
    MfaMethod.email => MfaEmailScreen(host: this),
    MfaMethod.totp => MfaTotpScreen(host: this),
    MfaMethod.biometric => MfaBiometricScreen(
      host: this,
      secureStorageKey: secureStorageKey!,
    ),
    MfaMethod.openid => OpenIdMfaScreen(
      host: this,
      proxyUrl: proxyUrl,
      openidDisplayName: openidDisplayName,
    ),
  };
}
