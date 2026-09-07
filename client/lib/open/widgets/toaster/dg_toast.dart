import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class DgToast extends StatelessWidget {
  final String message;
  final ToastVariant variant;

  const DgToast({
    super.key,
    required this.message,
    this.variant = ToastVariant.primary,
  });

  Color get _backgroundColor {
    return switch (variant) {
      ToastVariant.primary => DgColor.bgWhite100,
      ToastVariant.success => DgColor.bgSuccess,
      ToastVariant.critical => DgColor.bgCritical,
    };
  }

  Color get _textColor {
    return switch (variant) {
      ToastVariant.primary => DgColor.fgFaded,
      ToastVariant.success => DgColor.fgBlack,
      ToastVariant.critical => DgColor.fgWhite100,
    };
  }

  Widget get _icon {
    final iconName = switch (variant) {
      ToastVariant.primary => 'check',
      ToastVariant.success => 'check_filled',
      ToastVariant.critical => 'warning_filled',
    };

    return DgIcon(
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
            const SizedBox(width: DgSpacing.md),
            Flexible(
              child: Text(
                message,
                style: DgText.bodySm400.copyWith(color: _textColor),
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

@Preview(name: 'DgToast Primary', group: 'DgToast')
Widget previewNextToastPrimary() {
  return const DgPreviewWrapper(
    child: DgToast(
      message:
          'This is a primary toast message that might span multiple lines.',
      variant: ToastVariant.primary,
    ),
  );
}

@Preview(name: 'DgToast Success', group: 'DgToast')
Widget previewNextToastSuccess() {
  return const DgPreviewWrapper(
    child: DgToast(
      message: 'Action completed successfully!',
      variant: ToastVariant.success,
    ),
  );
}

@Preview(name: 'DgToast Critical', group: 'DgToast')
Widget previewNextToastCritical() {
  return const DgPreviewWrapper(
    child: DgToast(
      message: 'A critical error occurred. Please try again later.',
      variant: ToastVariant.critical,
    ),
  );
}
