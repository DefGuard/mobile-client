import 'package:flutter/material.dart';
import 'package:mobile/theme/color.dart';

import '../toaster/toast_manager.dart';
import 'dg_app_bar.dart';
import 'dg_drawer.dart';

class DgScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const DgScaffold({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DgAppBar(title: title),
      drawer: DgDrawer(),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Container(
        decoration: BoxDecoration(color: DgColor.frameBg),
        child: Stack(children: [child, ToastPositioner()]),
      ),
    );
  }
}
