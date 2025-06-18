import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_client/open/widgets/icons/icon_rotation.dart';

class DgIconArrowSingle extends StatelessWidget {
  final double width;
  final double height;
  final DgIconDirection direction;

  const DgIconArrowSingle({
    super.key,
    this.width = 24,
    this.height = 24,
    this.direction = DgIconDirection.right,
  });

  double _getRotation() {
    switch (direction) {
      case DgIconDirection.right:
        return 0;
      case DgIconDirection.left:
        return math.pi;
      case DgIconDirection.up:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DgIconDirection.bottom:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _getRotation(),
      child: SvgPicture.asset(
        "assets/icons/arrow-single.svg",
        width: width,
        height: height,
      ),
    );
  }
}
