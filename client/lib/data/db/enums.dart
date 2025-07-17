import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart' as j;

@j.JsonEnum()
enum RoutingMethod {
  @j.JsonValue("all")
  all,
  @j.JsonValue("predefined")
  predefined;
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
enum LocationMfa {
  @j.JsonValue(0)
  unspecified(0),
  @j.JsonValue(1)
  disabled(1),
  @j.JsonValue(2)
  internal(2),
  @j.JsonValue(3)
  external(3);

  final int value;

  const LocationMfa(this.value);

  static LocationMfa fromValue(int value) =>
      LocationMfa.values.firstWhere((e) => e.value == value);
}

class LocationMfaConverter extends TypeConverter<LocationMfa, int> {
  const LocationMfaConverter();

  @override
  LocationMfa fromSql(int fromDb) {
    return LocationMfa.fromValue(fromDb);
  }

  @override
  int toSql(LocationMfa value) {
    return value.value;
  }
}
