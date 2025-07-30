import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/spacing.dart';

import '../widgets/navigation/dg_scaffold.dart';

class ToastTestScreen extends StatelessWidget {
  const ToastTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DgScaffold(title: "Toaster tests", child: _Content());
  }
}

class _Content extends HookConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = useMemoized(() {
      return ScaffoldMessenger.of(context);
    }, [context]);

    final toasterNotifier = ref.read(toastManagerProvider.notifier);

    final showSnackBar = useCallback((String text) {
      msg.showSnackBar(
        dgSnackBar(
          text: text,
          onDismiss: () {
            msg.hideCurrentSnackBar();
          },
        ),
      );
    }, [msg, context]);

    return Padding(
      padding: EdgeInsetsGeometry.only(top: DgSpacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: DgSpacing.s,
        children: [
          Center(
            child: DgButton(
              text: "Show toast",
              onTap: () {
                toasterNotifier.showInfo(
                  title: "Test",
                  message: "Test message",
                );
              },
            ),
          ),
          Center(
            child: DgButton(
              text: "Show snackBar",
              onTap: () {
                showSnackBar(
                  "Custom message in snackBar...................................................................................",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
