import 'package:flutter/material.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/utils/screen_padding.dart';

// solves the problem of keyboard covering elements
// takes into account optional system navigation in form of buttons
// applies the typical screen padding
class DgSingleChildScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DgSingleChildScrollView({super.key, this.padding, required this.child});

  EdgeInsetsGeometry getPadding(BuildContext context) {
    if (padding != null) {
      return padding!;
    }
    final innerPadding = screenPadding(
      top: DgSpacing.m,
      bottom: DgSpacing.m,
      horizontal: DgSpacing.s,
      context: context,
    );
    return innerPadding;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        return SingleChildScrollView(
          padding: getPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constrains.maxHeight - getPadding(context).vertical,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
