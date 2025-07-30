import 'package:flutter/material.dart';
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
    return LayoutBuilder(
      builder: (context, constrains) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constrains.maxHeight - padding.vertical,
          ),
          child: Column(
            children: [
              Center(
                child: DgCircularProgress(color: DgColor.mainPrimary, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}
