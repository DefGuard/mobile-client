import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/buttons/dg_text_button.dart';
import 'package:mobile/open/widgets/icons/icon_info.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class ToastData {
  final String id;
  final String title;
  final String message;

  const ToastData({
    required this.id,
    required this.title,
    required this.message,
  });
}

class Toast extends HookConsumerWidget {
  final String title;
  final String message;
  final String id;

  const Toast({
    super.key,
    required this.title,
    required this.message,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasterNotifier = ref.read(toastManagerProvider.notifier);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(boxShadow: [dgBoxShadow]),
        child: Material(
          color: DgColor.navBg,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(
              vertical: DgSpacing.xs,
              horizontal: DgSpacing.s,
            ),
            child: Column(
              spacing: DgSpacing.xs / 2,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: DgSpacing.xs,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: DgIconInfo(
                          variant: DgIconInfoVariant.info,
                          size: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: DgText.modal1,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(message, style: DgText.modal2, textAlign: TextAlign.left),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: SizedBox(height: 1)),
                    DgTextButton(
                      onTap: () {
                        toasterNotifier.remove(id);
                      },
                      text: "Dismiss",
                      textStyle: DgText.copyright,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
