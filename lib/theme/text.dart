import 'package:flutter/material.dart';

final String _poppins = "Poppins";

final String _roboto = "Roboto";

class DgText {
  DgText._();

  static TextStyle body1 = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
  );
  static TextStyle modal1 = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static TextStyle buttonL = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static TextStyle buttonS = TextStyle(
    fontFamily: _roboto,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static TextStyle buttonXS = TextStyle(
    fontFamily: _roboto,
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );
  static TextStyle sideBar = TextStyle(
    fontFamily: _poppins,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static TextStyle copyright = TextStyle(
    fontFamily: _poppins,
    fontSize: 10,
    fontWeight: FontWeight.w300,
  );
}
