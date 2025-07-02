import 'dart:math' as math;
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/icons/icon_rotation.dart';

class DgIconArrowSingle extends DgIcon {
  final DgIconDirection direction;

  DgIconArrowSingle({
    super.key,
    this.direction = DgIconDirection.right,
    super.asset = "assets/icons/arrow-single.svg",
    super.size = 24,
  }) : super(rotation: _getRotation(direction));

  static double _getRotation(DgIconDirection direction) {
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
}
