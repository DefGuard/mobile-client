import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';

class NextBottomSheet extends StatelessWidget {
  final Widget? child;

  final WidgetBuilder? builder;

  final bool showDragHandle;

  final Color? backgroundColor;

  final double? elevation;

  final EdgeInsetsGeometry? contentPadding;

  const NextBottomSheet({
    super.key,
    this.child,
    this.builder,
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
        ? contentPadding!.add(
            EdgeInsets.only(bottom: bottomSafeArea + NextSpacing.xl),
          )
        : EdgeInsets.only(
            left: NextSpacing.xl,
            right: NextSpacing.xl,
            top: NextSpacing.sm,
            bottom: NextSpacing.xl + bottomSafeArea,
          );

    return Material(
      color: Colors.transparent,
      elevation: elevation ?? 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: backgroundColor ?? NextColor.bgDarkBlue80,
          child: Column(
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
          ),
        ),
      ),
    );
  }
}

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
    barrierColor: barrierColor ?? const Color(0x80000000),
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    builder: (modalContext) {
      return NextBottomSheet(
        showDragHandle: showDragHandle,
        backgroundColor: backgroundColor,
        contentPadding: contentPadding,
        builder: builder,
        child: child,
      );
    },
  );
}

@Preview(name: 'NextBottomSheet Default', group: 'NextBottomSheet')
Widget previewNextBottomSheetDefault() {
  return NextPreviewWrapper(
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
