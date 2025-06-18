import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/color.dart';

class DgIconCheckmark extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const DgIconCheckmark({
    super.key,
    this.width = 18,
    this.height = 18,
    this.color = DgColor.textButtonPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/icons/.svg",
      width: width,
      height: height,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
