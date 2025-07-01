import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_client/theme/color.dart';

import 'dg_icon.dart';

enum DgIconInfoVariant { info, important, alert }

class _InfoColorMapper extends ColorMapper {
  final DgIconInfoVariant variant;

  const _InfoColorMapper({required this.variant});

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0Xff899ca8)) {
      switch (variant) {
        case DgIconInfoVariant.important:
          return DgColor.important;
        case DgIconInfoVariant.alert:
          return DgColor.alertPrimary;
        case DgIconInfoVariant.info:
          return DgColor.iconPrimary;
      }
    }
    return color;
  }
}

class DgIconInfo extends DgIcon {
  final DgIconInfoVariant variant;

  const DgIconInfo({
    super.key,
    super.size = 18,
    super.asset = "assets/icons/icon-info.svg",
    this.variant = DgIconInfoVariant.info,
  });

  @override
  ColorMapper? getColorMapper() {
    return _InfoColorMapper(variant: variant);
  }
}
