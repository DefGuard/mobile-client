import 'package:mobile/theme/color.dart';

import 'package:flutter/material.dart';

import 'dg_icon.dart';

enum DgIconConnectionVariant { connected, disconnected }

class DgIconConnection extends DgIcon {
  final DgIconConnectionVariant variant;

  DgIconConnection({
    super.key,
    super.size = 24,
    super.asset = "assets/icons/icon-connection.svg",
    required this.variant,
  }) : super(color: _getIconColor(variant));

  static Color _getIconColor(DgIconConnectionVariant variant) {
    switch (variant) {
      case DgIconConnectionVariant.connected:
        return DgColor.positivePrimary;
      case DgIconConnectionVariant.disconnected:
        return DgColor.important;
    }
  }
}
