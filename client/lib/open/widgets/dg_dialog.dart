import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

import 'package:mobile/theme/spacing.dart';

class DgDialog extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onClose;

  const DgDialog({super.key, required this.children, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: DgColor.gradientPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        right: 16,
                        child: DgIconButton(
                          onTap: onClose,
                          icon: 'close',
                          size: .small,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DgDialogDescription extends StatelessWidget {
  final String description;

  const DgDialogDescription(this.description, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DgSpacing.xl3),
      child: Text(
        description,
        style: DgText.bodySm400.copyWith(color: DgColor.fgWhite90),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class DgDialogTitle extends StatelessWidget {
  final String title;

  const DgDialogTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DgSpacing.md),
      child: Text(
        title,
        style: DgText.h5.copyWith(color: DgColor.fgWhite100),
        textAlign: TextAlign.center,
      ),
    );
  }
}

@Preview(name: 'DgDialog Default', group: 'DgDialog')
Widget previewDgDialog() {
  return DgPreviewWrapper(
    padding: EdgeInsets.zero,
    child: DgDialog(
      onClose: () {},
      children: [
        const DgDialogTitle('Dialog Title'),
        Text(
          'This is a description of the dialog content. It can span multiple lines if necessary.',
          style: DgText.bodySm400.copyWith(color: DgColor.fgWhite70),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
