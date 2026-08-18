import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class DgLogo extends StatelessWidget {
  const DgLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset("assets/next/img/app_bar_logo.svg");
  }
}
