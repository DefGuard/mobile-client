import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/theme/next/color.dart';

/// Direction enum for Next design system icons.
enum NextIconDirection { right, down, left, up }

typedef NextDirection = NextIconDirection;

/// Icon renderer widget for Next design system icons.
///
/// Automatically resolves icon asset names relative to `assets/next/icons/`
/// and appends `.svg` extension if omitted. Supports auto-rotation based on
/// icon [direction].
class NextIcon extends StatelessWidget {
  /// Global map specifying the base direction of icons.
  /// Defaults to [NextIconDirection.right] if an icon is not present in this map.
  static final Map<String, NextIconDirection> baseDirections = {
    'arrow_big': NextIconDirection.right,
    'arrow_small': NextIconDirection.right,
  };

  /// Register or override the base direction for a specific icon asset name.
  static void registerBaseDirection(
    String name,
    NextIconDirection baseDirection,
  ) {
    baseDirections[_cleanName(name)] = baseDirection;
  }

  /// Register multiple icon base directions at once.
  static void registerBaseDirections(
    Map<String, NextIconDirection> directions,
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
    NextIconDirection targetDirection, {
    NextIconDirection baseDirection = NextIconDirection.right,
  }) {
    final steps = (targetDirection.index - baseDirection.index) % 4;
    return steps * (math.pi / 2);
  }

  /// Name or relative path of the icon asset (e.g., `'arrow_small'`).
  final String name;

  /// Icon tint color. Defaults to [NextColor.fgAction].
  final Color color;

  /// Square size of the icon (width and height). Defaults to `20`.
  final double size;

  /// Additional rotation angle in radians. Defaults to `0`.
  final double rotation;

  /// Target direction of the icon.
  ///
  /// When provided, automatically calculates additional rotation angle based on
  /// the icon's configured base direction.
  final NextIconDirection? direction;

  const NextIcon(
    this.name, {
    super.key,
    this.color = NextColor.fgAction,
    this.size = 20,
    this.rotation = 0,
    this.direction,
  });

  /// Named constructor accepting `name` as a named argument.
  const NextIcon.named({
    required String name,
    Key? key,
    Color color = NextColor.fgAction,
    double size = 20,
    double rotation = 0,
    NextIconDirection? direction,
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
  NextIconDirection get iconBaseDirection {
    final clean = _cleanName(name);
    return baseDirections[clean] ?? NextIconDirection.right;
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

  /// Creates a copy of this [NextIcon] with given fields replaced.
  NextIcon copyWith({
    String? name,
    Color? color,
    double? size,
    double? rotation,
    NextIconDirection? direction,
  }) {
    return NextIcon(
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

Widget _previewWrapper(Widget child) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-0.72, -0.69),
        end: Alignment(0.72, 0.69),
        colors: [Color(0xFF141517), Color(0xFF191A1C)],
      ),
    ),
    padding: const EdgeInsets.all(24.0),
    child: Center(child: child),
  );
}

@Preview(name: 'Arrow Small Directions', group: 'NextIcon')
Widget previewArrowSmallDirections() {
  return _previewWrapper(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        NextIcon('arrow_small', direction: NextIconDirection.right),
        SizedBox(width: 16),
        NextIcon('arrow_small', direction: NextIconDirection.down),
        SizedBox(width: 16),
        NextIcon('arrow_small', direction: NextIconDirection.left),
        SizedBox(width: 16),
        NextIcon('arrow_small', direction: NextIconDirection.up),
      ],
    ),
  );
}

@Preview(name: 'Arrow Big Directions', group: 'NextIcon')
Widget previewArrowBigDirections() {
  return _previewWrapper(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        NextIcon('arrow_big', direction: NextIconDirection.right),
        SizedBox(width: 16),
        NextIcon('arrow_big', direction: NextIconDirection.down),
        SizedBox(width: 16),
        NextIcon('arrow_big', direction: NextIconDirection.left),
        SizedBox(width: 16),
        NextIcon('arrow_big', direction: NextIconDirection.up),
      ],
    ),
  );
}

@Preview(name: 'Arrow Colors & Sizes', group: 'NextIcon')
Widget previewArrowColorsAndSizes() {
  return _previewWrapper(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        NextIcon('arrow_small', size: 16, color: NextColor.fgWhite100),
        SizedBox(width: 16),
        NextIcon('arrow_big', size: 20, color: NextColor.fgAction),
        SizedBox(width: 16),
        NextIcon('arrow_small', size: 24, color: NextColor.fgAttention),
        SizedBox(width: 16),
        NextIcon('arrow_big', size: 32, color: NextColor.fgCritical),
      ],
    ),
  );
}
