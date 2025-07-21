import 'package:flutter/material.dart';
import 'package:mobile/theme/color.dart';

const String _poppins = "Poppins";

const String _roboto = "Roboto";

const Color _defaultTextColor = DgColor.textBodyPrimary;

class DgText {
  DgText._();

  static const TextStyle body1 = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: _defaultTextColor,
  );
  static const TextStyle modal1 = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _defaultTextColor,
  );
  static const TextStyle buttonL = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _defaultTextColor,
  );
  static const TextStyle buttonS = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _defaultTextColor,
  );
  static const TextStyle buttonXS = TextStyle(
    fontFamily: _roboto,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: _defaultTextColor,
  );
  static const TextStyle sideBar = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: _defaultTextColor,
  );
  static const TextStyle copyright = TextStyle(
    fontFamily: _poppins,
    fontSize: 10,
    fontWeight: FontWeight.w300,
    color: _defaultTextColor,
  );
  static const TextStyle input = TextStyle(
    fontFamily: _roboto,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _defaultTextColor,
  );
  static const TextStyle modal2 = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _defaultTextColor,
  );
}
