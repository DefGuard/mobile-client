import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:mobile/open/widgets/toaster/toast.dart";
import "package:mobile/theme/spacing.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:uuid/uuid.dart";

import "../../../logging.dart";

part "toast_manager.g.dart";

@Riverpod(keepAlive: true)
class ToastManager extends _$ToastManager {
  @override
  List<ToastData> build() {
    return [];
  }

  void showInfo({required String title, required String message, String? id}) {
    String innerId;
    if (id != null) {
      innerId = id;
    } else {
      final uuid = Uuid();
      innerId = uuid.v4();
    }
    state = [...state, ToastData(id: innerId, title: title, message: message)];
  }

  void remove(String id) {
    state = state.where((toastData) => toastData.id != id).toList();
  }
}

class ToastPositioner extends HookConsumerWidget {
  const ToastPositioner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastManagerProvider);

    useEffect(() {
      talker.debug("Positioner reads ${toasts.length} toasts");
      return null;
    }, [toasts]);

    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsGeometry.only(
            right: DgSpacing.m,
            top: DgSpacing.m,
            left: DgSpacing.m,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: DgSpacing.s,
            children: toasts
                .map(
                  (toastData) => Toast(
                    message: toastData.message,
                    title: toastData.title,
                    id: toastData.id,
                    key: Key(toastData.id),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
