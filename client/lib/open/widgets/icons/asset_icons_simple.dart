import 'package:mobile/theme/color.dart';

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

class DgIconAsterisk extends DgIcon {
  const DgIconAsterisk({
    super.key,
    super.size = 22,
    super.asset = "$_defaultPath/icon-asterisk.svg",
    super.color = DgColor.modalAccent,
  });
}

class DgIconRadio extends DgIcon {
  const DgIconRadio({
    super.key,
    super.size = 18,
    super.asset = "$_defaultPath/radio.svg",
  });
}

class DgIconRadioActive extends DgIcon {
  const DgIconRadioActive({
    super.key,
    super.size = 18,
    super.asset = "$_defaultPath/radio-active.svg",
  });
}

class DgIconCheckmark extends DgIcon {
  const DgIconCheckmark({
    super.key,
    super.size = 18,
    super.asset = "$_defaultPath/checkmark.svg",
    super.color = DgColor.iconSecondary,
  });
}
