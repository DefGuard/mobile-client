import 'package:flutter/material.dart';
import 'package:mobile_client/theme/color.dart';

final String _poppins = "Poppins";

final String _roboto = "Roboto";

final Color _defaultTextColor = DgColor.textBodyPrimary;

class DgText {
  DgText._();

  static TextStyle body1 = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: _defaultTextColor,
  );
  static TextStyle modal1 = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _defaultTextColor,
  );
  static TextStyle buttonL = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _defaultTextColor,
  );
  static TextStyle buttonS = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _defaultTextColor,
  );
  static TextStyle buttonXS = TextStyle(
    fontFamily: _roboto,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: _defaultTextColor,
  );
  static TextStyle sideBar = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: _defaultTextColor,
  );
  static TextStyle copyright = TextStyle(
    fontFamily: _poppins,
    fontSize: 10,
    fontWeight: FontWeight.w300,
    color: _defaultTextColor,
  );
  static TextStyle input = TextStyle(
    fontFamily: _roboto,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _defaultTextColor,
  );
}
