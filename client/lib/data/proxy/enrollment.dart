import 'package:json_annotation/json_annotation.dart';

part 'enrollment.g.dart';

@JsonSerializable()
class EnrollmentStartRequest {
  final String token;

  const EnrollmentStartRequest({required this.token});

  factory EnrollmentStartRequest.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentStartRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentStartRequestToJson(this);
}

@JsonSerializable()
class EnrollmentSettings {
  final bool vpnSetupOptional;
  final bool onlyClientActivation;

  const EnrollmentSettings({
    required this.vpnSetupOptional,
    required this.onlyClientActivation,
  });

  factory EnrollmentSettings.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentSettingsToJson(this);
}

@JsonSerializable()
class EnrollmentStartResponse {
  final AdminInfo admin;
  final UserInfo user;
  final EnrollmentInstanceInfo instance;
  final int deadlineTimestamp;
  final String finalPageContent;
  final EnrollmentSettings settings;

  factory EnrollmentStartResponse.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentStartResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentStartResponseToJson(this);

  const EnrollmentStartResponse({
    required this.admin,
    required this.user,
    required this.instance,
    required this.deadlineTimestamp,
    required this.finalPageContent,
    required this.settings,
  });
}

@JsonSerializable()
class EnrollmentInstanceInfo {
  final String id;
  final String name;
  final String url;

  const EnrollmentInstanceInfo({
    required this.id,
    required this.name,
    required this.url,
  });

  factory EnrollmentInstanceInfo.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentInstanceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentInstanceInfoToJson(this);
}

@JsonSerializable()
class UserInfo {
  final String firstName;
  final String lastName;
  final String login;
  final String email;
  final bool isActive;
  final String? phoneNumber;
  final List<String> deviceNames;
  final bool enrolled;

  const UserInfo({
    required this.firstName,
    required this.lastName,
    required this.login,
    required this.email,
    required this.isActive,
    required this.deviceNames,
    required this.enrolled,
    this.phoneNumber,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class AdminInfo {
  final String name;
  final String email;
  final String? phoneNumber;

  const AdminInfo({required this.name, required this.email, this.phoneNumber});

  factory AdminInfo.fromJson(Map<String, dynamic> json) =>
      _$AdminInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminInfoToJson(this);
}

@JsonSerializable()
class Device {
  final int id;
  final String name;
  final String pubkey;
  final int userId;
  final int createdAt;

  const Device({
    required this.id,
    required this.name,
    required this.pubkey,
    required this.userId,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}

@JsonSerializable()
class DeviceConfig {
  final int networkId;
  final String networkName;
  final String config;
  final String endpoint;
  final String assignedIp;
  final String pubkey;
  final String allowedIps;
  final String? dns;
  final bool mfaEnabled;
  final int keepaliveInterval;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceConfigToJson(this);

  const DeviceConfig({
    required this.networkId,
    required this.networkName,
    required this.config,
    required this.endpoint,
    required this.assignedIp,
    required this.pubkey,
    required this.allowedIps,
    this.dns,
    required this.mfaEnabled,
    required this.keepaliveInterval,
  });
}

@JsonSerializable()
class CreateDeviceRequest {
  final String name;
  final String pubkey;

  const CreateDeviceRequest({required this.name, required this.pubkey});

  factory CreateDeviceRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDeviceRequestToJson(this);
}

@JsonSerializable()
class CreateDeviceResponse {
  final Device device;
  final List<DeviceConfig> configs;
  final InstanceInfo instance;
  final String token;

  const CreateDeviceResponse({
    required this.device,
    required this.configs,
    required this.instance,
    required this.token,
  });

  factory CreateDeviceResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateDeviceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDeviceResponseToJson(this);
}

@JsonSerializable()
class InstanceInfo {
  final String id;
  final String name;
  final String url;
  final String proxyUrl;
  final String username;
  final bool enterpriseEnabled;
  final bool disableAllTraffic;
  final bool useOpenidForMfa;

  const InstanceInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.proxyUrl,
    required this.username,
    required this.enterpriseEnabled,
    required this.disableAllTraffic,
    required this.useOpenidForMfa,
  });

  factory InstanceInfo.fromJson(Map<String, dynamic> json) =>
      _$InstanceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$InstanceInfoToJson(this);
}

@JsonSerializable()
class AppInfoResponse {
  final String version;

  const AppInfoResponse({required this.version});

  factory AppInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$AppInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AppInfoResponseToJson(this);
}

@JsonSerializable()
class WireguardEncodedKeyPair {
  final String pubKey;
  final String privKey;

  const WireguardEncodedKeyPair({required this.pubKey, required this.privKey});

  factory WireguardEncodedKeyPair.fromJson(Map<String, dynamic> json) =>
      _$WireguardEncodedKeyPairFromJson(json);

  Map<String, dynamic> toJson() => _$WireguardEncodedKeyPairToJson(this);
}
