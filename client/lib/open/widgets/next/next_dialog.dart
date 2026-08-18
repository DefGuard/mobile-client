import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/text.dart';

import '../../../theme/next/spacing.dart';
import 'icons/next_icon.dart';

class NextDialog extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onClose;

  const NextDialog({super.key, required this.children, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
          // Dialog Box
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: NextColor.gradientPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Close Button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: NextIcon(
                              'assets/icons/icon-x',
                              size: 24,
                              color: NextColor.fgWhite100,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
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
        ],
      ),
    );
  }
}

class NextDialogDescription extends StatelessWidget {
  final String description;

  const NextDialogDescription(this.description, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .only(bottom: NextSpacing.xl3),
      child: Text(
        description,
        style: NextText.bodySm400.copyWith(color: NextColor.fgWhite90),
      ),
    );
  }
}

class NextDialogTitle extends StatelessWidget {
  final String title;

  const NextDialogTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NextSpacing.md),
      child: Text(
        title,
        style: NextText.h5.copyWith(color: NextColor.fgWhite100),
      ),
    );
  }
}

@Preview(name: 'NextDialog Default', group: 'NextDialog')
Widget previewNextDialog() {
  return NextPreviewWrapper(
    padding: EdgeInsets.zero,
    child: NextDialog(
      onClose: () {},
      children: [
        const NextDialogTitle('Dialog Title'),
        Text(
          'This is a description of the dialog content. It can span multiple lines if necessary.',
          style: NextText.bodySm400.copyWith(color: NextColor.fgWhite70),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
