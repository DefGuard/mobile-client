import 'package:mobile_client/theme/color.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum DgIconConnectionVariant { connected, disconnected }

class DgIconConnection extends StatelessWidget {
  final double width;
  final double height;
  final DgIconConnectionVariant variant;

  const DgIconConnection({
    super.key,
    this.variant = DgIconConnectionVariant.disconnected,
    this.width = 24,
    this.height = 24,
  });

  Color _getIconColor() {
    switch (variant) {
      case DgIconConnectionVariant.disconnected:
        return DgColor.important;
      case DgIconConnectionVariant.connected:
        return DgColor.positivePrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/icons/icon-connection.svg",
      width: width,
      height: height,
      colorFilter: ColorFilter.mode(_getIconColor(), BlendMode.srcIn),
    );
  }
}
