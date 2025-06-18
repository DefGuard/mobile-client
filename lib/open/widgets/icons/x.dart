import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DgIconX extends StatelessWidget {
  final double width;
  final double height;

  const DgIconX({super.key, this.width = 40, this.height = 40});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/icons/icon-x.svg",
      width: width,
      height: height,
    );
  }
}
