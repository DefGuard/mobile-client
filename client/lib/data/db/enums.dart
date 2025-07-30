import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart' as j;

@j.JsonEnum()
enum RoutingMethod {
  @j.JsonValue("all")
  all,
  @j.JsonValue("predefined")
  predefined,
}

@j.JsonEnum()
enum MfaMethod {
  @j.JsonValue(0)
  totp(0),
  @j.JsonValue(1)
  email(1),
  @j.JsonValue(2)
  openid(2);

  final int value;

  const MfaMethod(this.value);

  static MfaMethod fromValue(int value) =>
      MfaMethod.values.firstWhere((e) => e.value == value);

  String toReadableString() {
    switch (value) {
      case 0:
        return "Totp";
      case 1:
        return "Email";
      case 2:
        return "OpenId";
      default:
        return "Unknown";
    }
  }
}

class MfaMethodConverter extends TypeConverter<MfaMethod, int> {
  const MfaMethodConverter();

  @override
  MfaMethod fromSql(int fromDb) {
    return MfaMethod.fromValue(fromDb);
  }

  @override
  int toSql(MfaMethod value) {
    return value.value;
  }
}

@j.JsonEnum()
enum LocationMfaMode {
  @j.JsonValue(0)
  unspecified(0),
  @j.JsonValue(1)
  disabled(1),
  @j.JsonValue(2)
  internal(2),
  @j.JsonValue(3)
  external(3);

  final int value;

  const LocationMfaMode(this.value);

  static LocationMfaMode fromValue(int value) =>
      LocationMfaMode.values.firstWhere((e) => e.value == value);
}

class LocationMfaModeConverter extends TypeConverter<LocationMfaMode, int> {
  const LocationMfaModeConverter();

  @override
  LocationMfaMode fromSql(int fromDb) {
    return LocationMfaMode.fromValue(fromDb);
  }

  @override
  int toSql(LocationMfaMode value) {
    return value.value;
  }
}
