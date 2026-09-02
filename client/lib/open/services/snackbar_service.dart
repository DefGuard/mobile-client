import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';

import '../../logging.dart';
import '../../theme/color.dart';

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void hide() {
    messengerKey.currentState?.hideCurrentSnackBar();
  }

  static void clear() {
    messengerKey.currentState?.clearSnackBars();
  }

  static void show(
    String message, {
    Color textColor = DgColor.textBodyPrimary,
    Duration duration = const Duration(seconds: 4),
    bool dismissable = false,
    bool onlyDismiss = false,
  }) {
    messengerKey.currentState?.showSnackBar(
      dgSnackBar(
        text: message,
        customDuration: duration,
        textColor: textColor,
        onlyDismiss: onlyDismiss,
        onDismiss: dismissable ? hide : null,
      ),
    );
  }

  static void showError(
    String message, {
    String? logMessage,
    Object? error,
    StackTrace? stackTrace,
    Duration duration = const Duration(seconds: 6),
    bool onlyDismiss = false,
  }) {
    talker.error(logMessage ?? message, error, stackTrace);
    messengerKey.currentState?.showSnackBar(
      dgSnackBar(
        text: message,
        customDuration: duration,
        textColor: DgColor.textAlert,
        onDismiss: hide,
        onlyDismiss: onlyDismiss,
      ),
    );
  }
}
