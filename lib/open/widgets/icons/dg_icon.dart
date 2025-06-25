import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DgIcon extends StatelessWidget {
  final Color? color;
  final String asset;
  final double size;
  final double? rotation;

  const DgIcon({
    super.key,
    required this.size,
    required this.asset,
    this.color,
    this.rotation,
  });

  DgIcon copyWith({
    Color? color,
    double? size,
    double? rotation,
    ColorMapper? colorMapper,
  }) {
    return DgIcon(
      color: color ?? this.color,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      asset: asset,
    );
  }

  ColorMapper? getColorMapper() {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = SvgPicture.asset(
      asset,
      height: size,
      width: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      colorMapper: getColorMapper(),
    );

    if (rotation != null) {
      return Transform.rotate(angle: rotation ?? 0, child: result);
    } else {
      return result;
    }
  }
}
