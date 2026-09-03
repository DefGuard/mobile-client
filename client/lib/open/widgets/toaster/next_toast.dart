import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

class NextToast extends StatelessWidget {
  final String message;
  final ToastVariant variant;

  const NextToast({
    super.key,
    required this.message,
    this.variant = ToastVariant.primary,
  });

  Color get _backgroundColor {
    return switch (variant) {
      ToastVariant.primary => NextColor.bgWhite100,
      ToastVariant.success => NextColor.bgSuccess,
      ToastVariant.critical => NextColor.bgCritical,
    };
  }

  Color get _textColor {
    return switch (variant) {
      ToastVariant.primary => NextColor.fgFaded,
      ToastVariant.success => NextColor.fgBlack,
      ToastVariant.critical => NextColor.fgWhite100,
    };
  }

  Widget get _icon {
    final iconName = switch (variant) {
      ToastVariant.primary => 'check',
      ToastVariant.success => 'check_filled',
      ToastVariant.critical => 'warning_filled',
    };

    return NextIcon(
      iconName,
      size: 20,
      color: _textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _icon,
            const SizedBox(width: NextSpacing.md),
            Flexible(
              child: Text(
                message,
                style: NextText.bodySm400.copyWith(color: _textColor),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'NextToast Primary', group: 'NextToast')
Widget previewNextToastPrimary() {
  return const NextPreviewWrapper(
    child: NextToast(
      message:
          'This is a primary toast message that might span multiple lines.',
      variant: ToastVariant.primary,
    ),
  );
}

@Preview(name: 'NextToast Success', group: 'NextToast')
Widget previewNextToastSuccess() {
  return const NextPreviewWrapper(
    child: NextToast(
      message: 'Action completed successfully!',
      variant: ToastVariant.success,
    ),
  );
}

@Preview(name: 'NextToast Critical', group: 'NextToast')
Widget previewNextToastCritical() {
  return const NextPreviewWrapper(
    child: NextToast(
      message: 'A critical error occurred. Please try again later.',
      variant: ToastVariant.critical,
    ),
  );
}
