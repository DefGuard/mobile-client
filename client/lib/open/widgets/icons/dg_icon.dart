import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/theme/color.dart';

import 'package:mobile/open/widgets/dg_preview_wrapper.dart';

/// Direction enum for Defguard design system icons.
enum DgIconDirection { right, down, left, up }

/// Icon renderer widget for Defguard design system icons.
///
/// Automatically resolves icon asset names relative to `assets/next/icons/`
/// and appends `.svg` extension if omitted. Supports auto-rotation based on
/// icon [direction].
class DgIcon extends StatelessWidget {
  /// Global map specifying the base direction of icons.
  /// Defaults to [DgIconDirection.right] if an icon is not present in this map.
  static final Map<String, DgIconDirection> baseDirections = {
    'arrow_big': DgIconDirection.right,
    'arrow_small': DgIconDirection.right,
  };

  /// Register or override the base direction for a specific icon asset name.
  static void registerBaseDirection(
    String name,
    DgIconDirection baseDirection,
  ) {
    baseDirections[_cleanName(name)] = baseDirection;
  }

  /// Register multiple icon base directions at once.
  static void registerBaseDirections(
    Map<String, DgIconDirection> directions,
  ) {
    directions.forEach((key, value) {
      baseDirections[_cleanName(key)] = value;
    });
  }

  /// Helper to extract base icon name without path or `.svg` extension.
  static String _cleanName(String rawName) {
    var clean = rawName.trim();
    if (clean.contains('/')) {
      clean = clean.split('/').last;
    }
    if (clean.endsWith('.svg')) {
      clean = clean.substring(0, clean.length - 4);
    }
    return clean;
  }

  /// Calculates the rotation angle in radians required to turn from [baseDirection]
  /// to [targetDirection] clockwise.
  static double getRotationForDirection(
    DgIconDirection targetDirection, {
    DgIconDirection baseDirection = DgIconDirection.right,
  }) {
    final steps = (targetDirection.index - baseDirection.index) % 4;
    return steps * (math.pi / 2);
  }

  /// Name or relative path of the icon asset (e.g., `'arrow_small'`).
  final String name;

  /// Icon tint color. Defaults to [DgColor.fgAction].
  final Color color;

  /// Square size of the icon (width and height). Defaults to `20`.
  final double size;

  /// Additional rotation angle in radians. Defaults to `0`.
  final double rotation;

  /// Target direction of the icon.
  ///
  /// When provided, automatically calculates additional rotation angle based on
  /// the icon's configured base direction.
  final DgIconDirection? direction;

  const DgIcon(
    this.name, {
    super.key,
    this.color = DgColor.fgAction,
    this.size = 20,
    this.rotation = 0,
    this.direction,
  });

  /// Named constructor accepting `name` as a named argument.
  const DgIcon.named({
    required String name,
    Key? key,
    Color color = DgColor.fgAction,
    double size = 20,
    double rotation = 0,
    DgIconDirection? direction,
  }) : this(
         name,
         key: key,
         color: color,
         size: size,
         rotation: rotation,
         direction: direction,
       );

  /// Constructs full asset path from asset name.
  String get assetPath {
    var path = name.trim();
    if (!path.startsWith('assets/')) {
      path = 'assets/next/icons/$path';
    }
    if (!path.endsWith('.svg')) {
      path = '$path.svg';
    }
    return path;
  }

  /// Returns the configured base direction for this icon.
  DgIconDirection get iconBaseDirection {
    final clean = _cleanName(name);
    return baseDirections[clean] ?? DgIconDirection.right;
  }

  /// Calculates total effective rotation angle in radians.
  double get effectiveRotation {
    double total = rotation;
    if (direction != null) {
      total += getRotationForDirection(
        direction!,
        baseDirection: iconBaseDirection,
      );
    }
    return total;
  }

  /// Creates a copy of this [DgIcon] with given fields replaced.
  DgIcon copyWith({
    String? name,
    Color? color,
    double? size,
    double? rotation,
    DgIconDirection? direction,
  }) {
    return DgIcon(
      name ?? this.name,
      color: color ?? this.color,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      direction: direction ?? this.direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    final angle = effectiveRotation;
    if (angle != 0) {
      iconWidget = Transform.rotate(angle: angle, child: iconWidget);
    }

    return iconWidget;
  }
}

@Preview(name: 'Arrow Small Directions', group: 'DgIcon')
Widget previewArrowSmallDirections() {
  return DgPreviewWrapper(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        DgIcon(
          'arrow_small',
          direction: DgIconDirection.right,
          color: DgColor.fgWhite100,
        ),
        SizedBox(width: 16),
        DgIcon(
          'arrow_small',
          direction: DgIconDirection.down,
          color: DgColor.fgWhite100,
        ),
        SizedBox(width: 16),
        DgIcon(
          'arrow_small',
          direction: DgIconDirection.left,
          color: DgColor.fgWhite100,
        ),
        SizedBox(width: 16),
        DgIcon(
          'arrow_small',
          direction: DgIconDirection.up,
          color: DgColor.fgWhite100,
        ),
      ],
    ),
  );
}

@Preview(name: 'Arrow Big Directions', group: 'DgIcon')
Widget previewArrowBigDirections() {
  return DgPreviewWrapper(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        DgIcon(
          'arrow_big',
          direction: DgIconDirection.right,
          color: DgColor.fgWhite100,
        ),
        SizedBox(width: 16),
        DgIcon(
          'arrow_big',
          direction: DgIconDirection.down,
          color: DgColor.fgWhite100,
        ),
        SizedBox(width: 16),
        DgIcon(
          'arrow_big',
          direction: DgIconDirection.left,
          color: DgColor.fgWhite100,
        ),
        SizedBox(width: 16),
        DgIcon(
          'arrow_big',
          direction: DgIconDirection.up,
          color: DgColor.fgWhite100,
        ),
      ],
    ),
  );
}

@Preview(name: 'Arrow Colors & Sizes', group: 'DgIcon')
Widget previewArrowColorsAndSizes() {
  return DgPreviewWrapper(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        DgIcon('arrow_small', size: 16, color: DgColor.fgWhite100),
        SizedBox(width: 16),
        DgIcon('arrow_big', size: 20, color: DgColor.fgAction),
        SizedBox(width: 16),
        DgIcon('arrow_small', size: 24, color: DgColor.fgAttention),
        SizedBox(width: 16),
        DgIcon('arrow_big', size: 32, color: DgColor.fgCritical),
      ],
    ),
  );
}
