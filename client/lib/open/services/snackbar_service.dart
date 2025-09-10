import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';

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
    Duration duration = const Duration(seconds: 6),
    bool onlyDismiss = false,
  }) {
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
