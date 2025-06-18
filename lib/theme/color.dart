import 'dart:ui';

class _Primitive {
  _Primitive._();

  static const Color positive = Color(0xff14bc6e);
  static const Color error = Color(0xffcb3f3f);
  static const Color errorX = Color(0xffd765ff);
  static const Color warning = Color(0xffb88f30);
  static const Color main = Color(0xff0c8ce0);
  static const Color hoverPositiveSecondary = Color(0xff10a15e);
  static const Color hoverErrorSecondary = Color(0xffb53030);
  static const Color hoverMainSecondary = Color(0xff0876be);
  static const Color lightWarningTertiary = Color(0xfffbf5e7);
  static const Color lightErrorTertiary = Color(0xfffceeee);
  static const Color lightPositiveTertiary = Color(0xffd7f8e9);
  static const Color darkWarningTertiary = Color(0xff302712);
  static const Color darkErrorTertiary = Color(0xff391b1b);
  static const Color darkPositiveTertiary = Color(0xff183d2c);
  static const Color greyscale0 = Color(0xffffffff);
  static const Color greyscale10 = Color(0xfff9f9f9);
  static const Color greyscale20 = Color(0xffe8e8e8);
  static const Color greyscale30 = Color(0xffcbcbcb);
  static const Color greyscale40 = Color(0xffc4c4c4);
  static const Color greyscale50 = Color(0xff899ca8);
  static const Color greyscale60 = Color(0xff617684);
  static const Color greyscale70 = Color(0xff485964);
  static const Color greyscale80 = Color(0xff2f3233);
  static const Color greyscale90 = Color(0xff222222);
  static const Color greyscale100 = Color(0xff000000);
}

class DgColor {
  DgColor._();

  // Text
  static const Color textBodyPrimary = _Primitive.greyscale90;
  static const Color textButtonPrimary = _Primitive.greyscale70;
  static const Color textBodySecondary = _Primitive.greyscale60;
  static const Color textBodyTertiary = _Primitive.greyscale50;
  static const Color textPositive = _Primitive.positive;
  static const Color textImportant = _Primitive.warning;
  static const Color textAlert = _Primitive.error;
  static const Color textButtonTertiary = _Primitive.main;
  static const Color textButtonSecondary = _Primitive.greyscale0;

  // Border
  static const Color borderPrimary = _Primitive.greyscale20;
  static const Color borderAlert = _Primitive.error;
  static const Color borderSeparator = _Primitive.greyscale40;
  static const Color borderSecondary = _Primitive.greyscale20;

  // Surface
  static const Color infoModal = _Primitive.greyscale10;
  static const Color tagModal = _Primitive.greyscale20;
  static const Color defaultModal = _Primitive.greyscale0;
  static const Color navBg = _Primitive.greyscale0;
  static const Color modalAccent = _Primitive.greyscale30;
  static const Color button = _Primitive.greyscale10;
  static const Color important = _Primitive.warning;
  static const Color alertAccent = _Primitive.lightErrorTertiary;
  static const Color positiveAccent = _Primitive.lightPositiveTertiary;
  static const Color iconPrimary = _Primitive.greyscale50;
  static const Color iconSecondary = _Primitive.greyscale0;
  static const Color mainPrimary = _Primitive.main;
  static const Color alertPrimary = _Primitive.error;
  static const Color positivePrimary = _Primitive.positive;
  static const Color mainSecondary = _Primitive.hoverMainSecondary;
  static const Color alertSecondary = _Primitive.hoverErrorSecondary;
  static const Color positiveSecondary = _Primitive.hoverPositiveSecondary;
  static const Color frameBg = _Primitive.greyscale10;
  static const Color importantAccent = _Primitive.lightWarningTertiary;
  static const Color scrollInactive = _Primitive.greyscale30;
  static const Color scrollActive = _Primitive.greyscale50;
}
