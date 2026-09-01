import "package:material_ui/material_ui.dart";
import "package:mobile/open/widgets/toaster/toast_manager.dart";

/// Mounts the toast layer above [child].
///
/// Used once, in `MaterialApp.router`'s builder, so toasts render above routes,
/// dialogs and bottom sheets and are unaffected by route changes.
class ToasterProvider extends StatelessWidget {
  final Widget? child;

  const ToasterProvider({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (child != null) Positioned.fill(child: child!),
        const ToastPositioner(),
      ],
    );
  }
}
