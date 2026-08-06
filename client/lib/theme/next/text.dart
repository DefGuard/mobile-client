import 'package:flutter/material.dart';

class _FontFamily {
  _FontFamily._();

  static const geist = "Geist";
}

const String _defaultFontFamily = _FontFamily.geist;

class NextText {
  NextText._();

  // Body - XXS
  static const TextStyle bodyXxs600 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
  );
  static const TextStyle bodyXxs500 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11,
  );
  static const TextStyle bodyXxs400 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 14 / 11,
  );

  // Body - XS
  static const TextStyle bodyXs600 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
  );
  static const TextStyle bodyXs500 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );
  static const TextStyle bodyXs400 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  // Body - SM
  static const TextStyle bodySm600 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
  );
  static const TextStyle bodySm500 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
  );
  static const TextStyle bodySm400 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );
  static const TextStyle bodySm300 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w300,
    height: 20 / 14,
  );

  // Body - Primary
  static const TextStyle bodyPrimary600 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );
  static const TextStyle bodyPrimary500 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
  );
  static const TextStyle bodyPrimary400 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  // Titles
  static const TextStyle h1 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 44 / 32,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 40 / 28,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );
  static const TextStyle h5 = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
  );

  // Inputs
  static const TextStyle inputTitle = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );
  static const TextStyle inputPrimary = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );
  static const TextStyle inputBig = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 20 / 16,
  );
  static const TextStyle inputError = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  // Menu
  static const TextStyle menuTitle = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 2,
  );
  static const TextStyle menuText = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 24 / 14,
  );

  // Buttons
  static const TextStyle buttonLabelBig = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle buttonLabelPrimary = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle buttonLabelSecondary = TextStyle(
    fontFamily: _defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
