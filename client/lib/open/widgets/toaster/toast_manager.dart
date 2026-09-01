import "dart:async";

import "package:flutter/widget_previews.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:mobile/open/widgets/next/next_button.dart";
import "package:mobile/open/widgets/toaster/next_toast.dart";
import "package:mobile/theme/next/color.dart";
import "package:mobile/theme/next/spacing.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:uuid/uuid.dart";

import "../../../logging.dart";

part "toast_manager.g.dart";

enum ToastVariant { primary, success, critical }

class ToastData {
  final String id;
  final String message;
  final ToastVariant variant;

  const ToastData({
    required this.id,
    required this.message,
    this.variant = ToastVariant.primary,
  });
}

const _toastDuration = Duration(seconds: 5);
const _animationDuration = Duration(milliseconds: 200);

@Riverpod(keepAlive: true)
class ToastManager extends _$ToastManager {
  Timer? _timer;

  @override
  ToastData? build() {
    ref.onDispose(_cancelTimer);
    return null;
  }

  /// Default variant, use it for normal notices.
  void show({required String message, String? id}) {
    _show(message: message, variant: ToastVariant.primary, id: id);
  }

  /// Reserved for an instance being added successfully.
  void showSuccess({required String message, String? id}) {
    _show(message: message, variant: ToastVariant.success, id: id);
  }

  /// Reserved for errors. [message] is the only part shown to the user, pass
  /// [error] and [stackTrace] separately, those are logged, never displayed.
  void showError({
    required String message,
    String? logMessage,
    Object? error,
    StackTrace? stackTrace,
    String? id,
  }) {
    talker.error(logMessage ?? message, error, stackTrace);
    _show(message: message, variant: ToastVariant.critical, id: id);
  }

  void _show({
    required String message,
    required ToastVariant variant,
    String? id,
  }) {
    // only one toast at a time, further calls are dropped
    if (state != null) return;

    _cancelTimer();
    final innerId = id ?? Uuid().v4();
    talker.debug("Showing toast: $innerId");
    state = ToastData(id: innerId, message: message, variant: variant);
    _timer = Timer(_toastDuration, () => remove(id: innerId));
  }

  /// With [id] given the toast is only removed if it is still the one on
  /// screen, so a stale dismiss cannot clear a newer toast.
  void remove({String? id}) {
    if (id != null && state?.id != id) return;
    _cancelTimer();
    state = null;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

class ToastPositioner extends ConsumerWidget {
  const ToastPositioner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastManagerProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NextSpacing.md,
            vertical: NextSpacing.md,
          ),
          child: AnimatedSwitcher(
            duration: _animationDuration,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              );
              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
            child: toast == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    key: ValueKey(toast.id),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref
                        .read(toastManagerProvider.notifier)
                        .remove(id: toast.id),
                    child: NextToast(
                      message: toast.message,
                      variant: toast.variant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

@Preview()
Widget previewToastManager() {
  return const ProviderScope(
    child: _ToastManagerPreview(),
  );
}

class _ToastManagerPreview extends ConsumerWidget {
  const _ToastManagerPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastManager = ref.read(toastManagerProvider.notifier);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    NextButton(
                      text: 'Spawn Primary',
                      style: NextButtonStyle.secondary,
                      onTap: () => toastManager.show(
                        message:
                            'Primary Toast: This is a primary toast message',
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    NextButton(
                      text: 'Spawn Success',
                      style: NextButtonStyle.primary,
                      onTap: () => toastManager.showSuccess(
                        message:
                            'Success Toast: This is a success toast message',
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    NextButton(
                      text: 'Spawn Critical',
                      style: NextButtonStyle.critical,
                      onTap: () => toastManager.showError(
                        message:
                            'Critical Toast: This is a critical toast message',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const ToastPositioner(),
          ],
        ),
      ),
    );
  }
}
