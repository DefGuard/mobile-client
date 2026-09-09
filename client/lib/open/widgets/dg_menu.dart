import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/text.dart';

import 'package:mobile/theme/color.dart';

class DgMenuItem {
  final String text;
  final String? icon;
  final String? identifier;
  final VoidCallback onTap;

  const DgMenuItem({
    required this.text,
    required this.onTap,
    this.icon,
    this.identifier,
  });
}

class DgMenu extends HookConsumerWidget {
  final List<DgMenuItem> items;
  final OverlayPortalController controller;
  final LayerLink link;
  final Alignment targetAnchor;
  final Alignment followerAnchor;

  const DgMenu({
    super.key,
    required this.items,
    required this.controller,
    required this.link,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
  });

  static Future<void> dismiss({
    required AnimationController animationController,
    required VoidCallback onDismiss,
  }) async {
    await animationController.reverse();
    onDismiss();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              dismiss(
                animationController: animationController,
                onDismiss: () {
                  controller.hide();
                },
              );
            },
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 4),
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, _) => FadeTransition(
              opacity: animationController,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -0.05),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animationController,
                        curve: Curves.easeOut,
                      ),
                    ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.07),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Material(
                        color: DgColor.bgDarkBlue80,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: IntrinsicWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 4,
                              children: items.map((item) {
                                return _NextMenuItem(
                                  itemData: item,
                                  onTap: () {
                                    item.onTap();
                                    dismiss(
                                      animationController: animationController,
                                      onDismiss: () {
                                        controller.hide();
                                      },
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
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

class _NextMenuItem extends StatelessWidget {
  final DgMenuItem itemData;
  final VoidCallback onTap;

  const _NextMenuItem({required this.itemData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final item = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            itemData.icon != null
                ? DgIcon(
                    itemData.icon!,
                    size: 20,
                    color: DgColor.fgWhite100,
                  )
                : SizedBox(width: 20, height: 20),
            Text(
              itemData.text,
              style: DgText.bodySm400.copyWith(color: DgColor.fgWhite100),
            ),
          ],
        ),
      ),
    );

    if (itemData.identifier == null) {
      return item;
    }

    return Semantics(
      identifier: itemData.identifier,
      container: true,
      child: item,
    );
  }
}

class DgMenuPreview extends HookConsumerWidget {
  const DgMenuPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useOverlayPortalController();
    final link = useMemoized(() => LayerLink());

    return DgPreviewWrapper(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OverlayPortal(
              controller: controller,
              overlayChildBuilder: (context) {
                return DgMenu(
                  items: [
                    DgMenuItem(text: 'Delete', icon: 'delete', onTap: () {}),
                    DgMenuItem(
                      text: 'Refresh',
                      icon: 'refresh',
                      onTap: () {},
                    ),
                  ],
                  controller: controller,
                  link: link,
                );
              },
              child: CompositedTransformTarget(
                link: link,
                child: DgIconButton(
                  icon: 'menu',
                  onTap: () {
                    controller.toggle();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Menu with Anchor', group: 'DgMenu')
Widget previewNextMenu() {
  return const DgMenuPreview();
}
