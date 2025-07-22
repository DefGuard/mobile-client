import 'package:flutter/material.dart';

// solves the problem of keyboard covering elements
// takes into account optional system navigation in form of buttons
// applies the typical screen padding
class DgSingleChildScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DgSingleChildScrollView({
    super.key,
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constrains.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}
