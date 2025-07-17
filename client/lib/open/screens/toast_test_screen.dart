import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/nav.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';

class ToastTestScreen extends StatelessWidget {
  const ToastTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DgAppBar(title: "Toaster test"),
      drawer: DgDrawer(),
      body: Container(
        decoration: BoxDecoration(color: DgColor.frameBg),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constrains) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constrains.maxHeight),
                  child: _Content(),
                );
              },
            ),
            ToastPositioner(),
          ],
        ),
      ),
    );
  }
}

class _Content extends HookConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasterNotifier = ref.read(toastManagerProvider.notifier);
    return Padding(
      padding: EdgeInsetsGeometry.only(top: DgSpacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: DgButton(
              text: "Show toast",
              onTap: () {
                toasterNotifier.showInfo(
                    title: "Test", message: "Test message");
              },
            ),
          ),
        ],
      ),
    );
  }
}
