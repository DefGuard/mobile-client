import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart' as j;

@j.JsonEnum()
enum LocationTrafficMethod {
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
  email(1);

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
