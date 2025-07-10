import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/utils/position.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/text.dart';

class DgMenu extends HookConsumerWidget {
  final List<DgMenuItem> items;
  final OverlayPortalController controller;
  final WidgetGeometry anchorGeometry;

  const DgMenu({
    super.key,
    required this.items,
    required this.controller,
    required this.anchorGeometry,
  });

  static Future<void> dismiss({
    required AnimationController controller,
    required VoidCallback onDismiss,
  }) async {
    await controller.reverse();
    onDismiss();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topOffset = useMemoized(() => anchorGeometry.position.dy + 10 + anchorGeometry.size.height);
    final leftOffset = useMemoized(() => anchorGeometry.position.dx);
    final animationController = useAnimationController(
      duration: 100.ms,
      reverseDuration: 100.ms,
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    return Stack(
      children: [
        Positioned.fill(
          child: ModalBarrier(
            dismissible: true,
            color: Colors.transparent,
            onDismiss: () {
              dismiss(
                controller: animationController,
                onDismiss: () {
                  controller.hide();
                },
              );
            },
          ),
        ),
        Positioned(
          top: topOffset,
          left: leftOffset,
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, _) => FadeTransition(
              opacity: animationController,
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset(0, -0.05), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: animationController,
                        curve: Curves.easeOut,
                      ),
                    ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DgColor.defaultModal,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [dgBoxShadow],
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(
                        vertical: DgSpacing.xs,
                        horizontal: 0,
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 8,
                          children: items
                              .map(
                                (item) => _DgMenuItem(
                                  itemData: item,
                                  onTap: () {
                                    dismiss(
                                      controller: animationController,
                                      onDismiss: () {
                                        controller.hide();
                                        item.onTap();
                                      },
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DgMenuItem {
  final String text;
  final Function() onTap;

  const DgMenuItem({required this.text, required this.onTap});
}

class _DgMenuItem extends StatelessWidget {
  final DgMenuItem itemData;
  final Function() onTap;

  const _DgMenuItem({required this.itemData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DgColor.defaultModal,
      child: InkWell(
        splashColor: DgColor.frameBg,
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: EdgeInsetsGeometry.all(DgSpacing.xs),
          child: Center(child: Text(itemData.text, style: DgText.sideBar)),
        ),
      ),
    );
  }
}
