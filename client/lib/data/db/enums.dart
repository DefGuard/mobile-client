import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart' as j;
import 'package:mobile/logging.dart';

@j.JsonEnum()
enum RoutingMethod {
  @j.JsonValue("all")
  all,
  @j.JsonValue("predefined")
  predefined;

  String toUiString() {
    switch (this) {
      case RoutingMethod.all:
        return "All Traffic";
      case RoutingMethod.predefined:
        return "Predefined";
    }
  }
}

@j.JsonEnum()
enum MfaMethod {
  @j.JsonValue(0)
  totp(0),
  @j.JsonValue(1)
  email(1),
  @j.JsonValue(2)
  openid(2),
  @j.JsonValue(3)
  biometric(3);

  final int value;

  const MfaMethod(this.value);

  static MfaMethod fromValue(int value) =>
      MfaMethod.values.firstWhere((e) => e.value == value);

  static MfaMethod? tryFromValue(int value) =>
      MfaMethod.values.where((e) => e.value == value).firstOrNull;

  String toReadableString() => _readableNames[this] ?? 'Unknown';

  static const Map<MfaMethod, String> _readableNames = {
    MfaMethod.totp: 'Totp',
    MfaMethod.email: 'Email',
    MfaMethod.openid: 'OpenId',
    MfaMethod.biometric: "Biometric",
  };

  String toUiString({String? openidDisplayName}) {
    switch (this) {
      case MfaMethod.totp:
        return "Authenticator App";
      case MfaMethod.biometric:
        return "Biometric";
      case MfaMethod.email:
        return "Email";
      case MfaMethod.openid:
        return openidDisplayName ?? "OpenID";
    }
  }
}

class MfaMethodConverter extends TypeConverter<MfaMethod, int> {
  const MfaMethodConverter();

  @override
  MfaMethod fromSql(int fromDb) {
    final method = MfaMethod.tryFromValue(fromDb);
    if (method == null) {
      // Throwing here would fail the whole locations query, not just this row.
      talker.error("Unknown stored MfaMethod value $fromDb, reading as totp");
      return MfaMethod.totp;
    }
    return method;
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

  static LocationMfaMode? tryFromValue(int value) =>
      LocationMfaMode.values.where((e) => e.value == value).firstOrNull;
}

class LocationMfaModeConverter extends TypeConverter<LocationMfaMode, int> {
  const LocationMfaModeConverter();

  @override
  LocationMfaMode fromSql(int fromDb) {
    final mode = LocationMfaMode.tryFromValue(fromDb);
    if (mode == null) {
      talker.error(
        "Unknown stored LocationMfaMode value $fromDb, reading as unspecified",
      );
      return LocationMfaMode.unspecified;
    }
    return mode;
  }

  @override
  int toSql(LocationMfaMode value) {
    return value.value;
  }
}

@j.JsonEnum()
enum ClientTrafficPolicy {
  @j.JsonValue(0)
  none(0),
  @j.JsonValue(1)
  disableAllTraffic(1),
  @j.JsonValue(2)
  forceAllTraffic(2);

  final int value;

  const ClientTrafficPolicy(this.value);

  static ClientTrafficPolicy fromValue(int value) =>
      ClientTrafficPolicy.values.firstWhere((e) => e.value == value);
}

class ClientTrafficPolicyConverter
    extends TypeConverter<ClientTrafficPolicy, int> {
  const ClientTrafficPolicyConverter();

  @override
  ClientTrafficPolicy fromSql(int fromDb) {
    return ClientTrafficPolicy.fromValue(fromDb);
  }

  @override
  int toSql(ClientTrafficPolicy value) {
    return value.value;
  }
}
