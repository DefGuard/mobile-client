import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum DgIconCheckboxVariant { checked, unchecked }

class DgIconCheckbox extends StatelessWidget {
  final DgIconCheckboxVariant variant;
  final double size;

  const DgIconCheckbox({
    super.key,
    required this.size,
    this.variant = DgIconCheckboxVariant.unchecked,
  });

  @override
  Widget build(BuildContext context) {
    String asset;

    switch (variant) {
      case DgIconCheckboxVariant.checked:
        asset = "assets/icons/checkbox-checked.svg";
        break;
      case DgIconCheckboxVariant.unchecked:
        asset = "assets/icons/checkbox-unchecked.svg";
        break;
    }

    return (SvgPicture.asset(asset, width: size, height: size));
  }
}
