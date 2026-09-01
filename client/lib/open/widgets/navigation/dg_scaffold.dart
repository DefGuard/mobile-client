import 'package:material_ui/material_ui.dart';
import 'package:mobile/theme/color.dart';

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
        child: child,
      ),
    );
  }
}
