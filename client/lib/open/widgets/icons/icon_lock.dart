import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/theme/color.dart';

import 'dg_icon.dart';

enum DgIconLockVariant { connected, disconnected }

const Color _mappedColor = DgColor.positivePrimary;

class _Mapper extends ColorMapper {
  final DgIconLockVariant variant;

  const _Mapper({required this.variant});

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (variant == DgIconLockVariant.disconnected && color == _mappedColor) {
      return DgColor.important;
    }
    return color;
  }
}

class DgIconLock extends DgIcon {
  final DgIconLockVariant variant;

  const DgIconLock({
    super.key,
    required this.variant,
    super.asset = "assets/icons/icon-lock.svg",
    super.size = 18,
  });

  @override
  ColorMapper? getColorMapper() => _Mapper(variant: variant);
}
