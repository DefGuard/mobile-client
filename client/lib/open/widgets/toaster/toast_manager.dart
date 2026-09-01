import "dart:async";

import "package:material_ui/material_ui.dart";
import "package:flutter/widget_previews.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
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
  @override
  ToastData? build() {
    return null;
  }

  void showInfo({
    required String message,
    ToastVariant variant = ToastVariant.primary,
    String? id,
  }) {
    if (state != null) return;

    String innerId;
    if (id != null) {
      innerId = id;
    } else {
      final uuid = Uuid();
      innerId = uuid.v4();
    }
    state = ToastData(id: innerId, message: message, variant: variant);
  }

  void remove() {
    state = null;
  }
}

class ToastPositioner extends HookConsumerWidget {
  const ToastPositioner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastManagerProvider);

    useEffect(() {
      if (toast != null) {
        talker.debug("Positioner shows toast: ${toast.id}");
        final timer = Timer(_toastDuration, () {
          ref.read(toastManagerProvider.notifier).remove();
        });
        return timer.cancel;
      }
      return null;
    }, [toast]);

    if (toast == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NextSpacing.md,
            vertical: NextSpacing.md,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(toastManagerProvider.notifier).remove(),
            child:
                NextToast(
                      message: toast.message,
                      variant: toast.variant,
                    )
                    .animate()
                    .fadeIn(duration: _animationDuration)
                    .slideY(
                      begin: -1,
                      end: 0,
                      duration: _animationDuration,
                      curve: Curves.easeOut,
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

class _ToastManagerPreview extends HookConsumerWidget {
  const _ToastManagerPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastManager = ref.read(toastManagerProvider.notifier);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  children: [
                    const Spacer(),
                    NextButton(
                      text: 'Spawn Primary',
                      style: NextButtonStyle.secondary,
                      onTap: () => toastManager.showInfo(
                        message:
                            'Primary Toast: This is a primary toast message',
                        variant: ToastVariant.primary,
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    NextButton(
                      text: 'Spawn Success',
                      style: NextButtonStyle.primary,
                      onTap: () => toastManager.showInfo(
                        message:
                            'Success Toast: This is a success toast message',
                        variant: ToastVariant.success,
                      ),
                    ),
                    const SizedBox(height: NextSpacing.md),
                    NextButton(
                      text: 'Spawn Critical',
                      style: NextButtonStyle.critical,
                      onTap: () => toastManager.showInfo(
                        message:
                            'Critical Toast: This is a critical toast message',
                        variant: ToastVariant.critical,
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
