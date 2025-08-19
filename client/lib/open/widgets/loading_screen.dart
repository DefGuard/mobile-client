import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/buttons/dg_text_button.dart';
import 'package:mobile/open/widgets/circular_progress.dart';
import 'package:mobile/utils/screen_padding.dart';

import '../../theme/color.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = screenPadding(
      top: 0,
      bottom: 0,
      horizontal: 0,
      context: context,
    );
    return Container(
      color: DgColor.mainPrimary,
      child: LayoutBuilder(
        builder: (context, constrains) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constrains.maxHeight - padding.vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                  DgCircularProgress(color: DgColor.iconSecondary, size: 92),
              ],
            ),
          );
        },
      ),
    );
  }
}
