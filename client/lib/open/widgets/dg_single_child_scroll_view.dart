import 'package:flutter/material.dart';

import '../../theme/spacing.dart';

// solves the problem of keyboard covering elements
// takes into account optional system navigation in form of buttons
// applies the typical screen padding
class DgSingleChildScrollView extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;
  final double verticalPadding;

  const DgSingleChildScrollView({
    super.key,
    required this.child,
    this.horizontalPadding = DgSpacing.s,
    this.verticalPadding = DgSpacing.m,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSpace =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).viewPadding.bottom;
    return LayoutBuilder(
      builder: (context, constrains) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constrains.maxHeight - verticalPadding * 2 - bottomSpace,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
