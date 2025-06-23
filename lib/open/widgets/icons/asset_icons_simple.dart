import 'package:mobile_client/theme/color.dart';

import 'dg_icon.dart';

const String _defaultPath = "assets/icons";

class DgIconQr extends DgIcon {
  const DgIconQr({
    super.key,
    super.size = 32,
    super.asset = "$_defaultPath/icon-qr.svg",
    super.color = DgColor.iconSecondary,
  });
}

class DgIconX extends DgIcon {
  const DgIconX({
    super.key,
    super.size = 40,
    super.asset = "$_defaultPath/icon-x.svg",
  });
}

class DgIconPlus extends DgIcon {
  const DgIconPlus({
    super.key,
    super.size = 36,
    super.asset = "$_defaultPath/icon-plus.svg",
  });
}
