import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';

/// A styled [BottomSheet] widget adhering to Next design specifications.
///
/// Specs:
/// - Background color: [NextColor.bgDarkBlue80] (`rgba(0, 25, 137, 0.80)`)
/// - Top corner radius: 20
/// - Content area padding: 8 top, 4 bottom (plus safe area bottom inset), 20 horizontal
/// - Top drag indicator header: 37 height with centered shape (50 width, 5 height, radius 100, color [NextColor.fgDisabled])
class NextBottomSheet extends StatelessWidget {
  /// The widget content inside the bottom sheet.
  final Widget? child;

  /// A builder that creates the widget content inside the bottom sheet.
  final WidgetBuilder? builder;

  /// Called when the bottom sheet is closed via dragging down.
  final VoidCallback? onClosing;

  /// The animation controller that controls the bottom sheet's entrance and exit.
  final AnimationController? animationController;

  /// Whether the bottom sheet can be dragged up and down and dismissed by swiping down.
  final bool enableDrag;

  /// Whether to show the top drag handle header. Defaults to true.
  final bool showDragHandle;

  /// The background color of the bottom sheet. Defaults to [NextColor.bgDarkBlue80].
  final Color? backgroundColor;

  /// The elevation of the bottom sheet. Defaults to 0.
  final double? elevation;

  /// Optional override for content padding. If null, default specs are applied.
  final EdgeInsetsGeometry? contentPadding;

  const NextBottomSheet({
    super.key,
    this.child,
    this.builder,
    this.onClosing,
    this.animationController,
    this.enableDrag = true,
    this.showDragHandle = true,
    this.backgroundColor,
    this.elevation,
    this.contentPadding,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided.',
       );

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    final effectivePadding = contentPadding != null
        ? contentPadding!.add(EdgeInsets.only(bottom: bottomSafeArea))
        : EdgeInsets.only(
            left: NextSpacing.xl,
            right: NextSpacing.xl,
            top: NextSpacing.sm,
            bottom: NextSpacing.xs + bottomSafeArea,
          );

    return BottomSheet(
      onClosing: onClosing ?? () {},
      animationController: animationController,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor ?? NextColor.bgDarkBlue80,
      elevation: elevation ?? 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle)
              SizedBox(
                height: 37,
                child: Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: NextColor.fgDisabled,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: effectivePadding,
              child: builder?.call(context) ?? child!,
            ),
          ],
        );
      },
    );
  }
}

/// Helper function to display a [NextBottomSheet] as a modal bottom sheet.
Future<T?> showNextBottomSheet<T>({
  required BuildContext context,
  WidgetBuilder? builder,
  Widget? child,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  Color? barrierColor,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  EdgeInsetsGeometry? contentPadding,
}) {
  assert(
    builder != null || child != null,
    'Either builder or child must be provided.',
  );

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    builder: (modalContext) {
      return NextBottomSheet(
        enableDrag: enableDrag,
        showDragHandle: showDragHandle,
        backgroundColor: backgroundColor,
        contentPadding: contentPadding,
        onClosing: () {
          if (Navigator.canPop(modalContext)) {
            Navigator.pop(modalContext);
          }
        },
        builder: builder,
        child: child,
      );
    },
  );
}

@Preview(name: 'NextBottomSheet Default', group: 'NextBottomSheet')
Widget previewNextBottomSheetDefault() {
  return Center(
    child: NextBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Add new instance',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Scan QR code',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 16),
          Text(
            'Add manually',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
