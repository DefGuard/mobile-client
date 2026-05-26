import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/db/enums.dart';

part 'mfa.g.dart';

enum UnavailableReason {
  unspecified(0),
  insufficientPermissions(1),
  notApplicable(2),
  detectionFailed(3);

  final int value;

  const UnavailableReason(this.value);
}

@JsonSerializable()
class StringCheck {
  final Map<String, dynamic> result;

  const StringCheck({required this.result});

  factory StringCheck.value(String value) => StringCheck(
    result: {'Value': value},
  );

  factory StringCheck.unavailable(UnavailableReason reason) => StringCheck(
    result: {'Unavailable': reason.value},
  );

  factory StringCheck.fromJson(Map<String, dynamic> json) =>
      _$StringCheckFromJson(json);

  Map<String, dynamic> toJson() => _$StringCheckToJson(this);
}

@JsonSerializable()
class BoolCheck {
  final Map<String, dynamic> result;

  const BoolCheck({required this.result});

  factory BoolCheck.value(bool value) => BoolCheck(
    result: {'Value': value},
  );

  factory BoolCheck.unavailable(UnavailableReason reason) => BoolCheck(
    result: {'Unavailable': reason.value},
  );

  factory BoolCheck.fromJson(Map<String, dynamic> json) =>
      _$BoolCheckFromJson(json);

  Map<String, dynamic> toJson() => _$BoolCheckToJson(this);
}

@JsonSerializable()
class Int32Check {
  final Map<String, dynamic> result;

  const Int32Check({required this.result});

  factory Int32Check.value(int value) => Int32Check(
    result: {'Value': value},
  );

  factory Int32Check.unavailable(UnavailableReason reason) => Int32Check(
    result: {'Unavailable': reason.value},
  );

  factory Int32Check.fromJson(Map<String, dynamic> json) =>
      _$Int32CheckFromJson(json);

  Map<String, dynamic> toJson() => _$Int32CheckToJson(this);
}

@JsonSerializable()
class DevicePostureData {
  final String defguardClientVersion;
  final String osType;
  final StringCheck? osName;
  final StringCheck? osVersion;
  final BoolCheck? diskEncryption;
  final BoolCheck? antivirusPresent;
  final BoolCheck? windowsAdDomainJoined;
  final Int32Check? windowsSecurityUpdateAgeDays;
  final StringCheck? linuxKernelVersion;
  final BoolCheck? deviceIntegrity;

  const DevicePostureData({
    required this.defguardClientVersion,
    required this.osType,
    this.osName,
    this.osVersion,
    this.diskEncryption,
    this.antivirusPresent,
    this.windowsAdDomainJoined,
    this.windowsSecurityUpdateAgeDays,
    this.linuxKernelVersion,
    this.deviceIntegrity,
  });

  factory DevicePostureData.fromJson(Map<String, dynamic> json) =>
      _$DevicePostureDataFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePostureDataToJson(this);
}

DevicePostureData getPosture() {
  final notApplicable = UnavailableReason.notApplicable;

  return DevicePostureData(
    defguardClientVersion: '2.1.0',
    osType: 'Android',
    osName: StringCheck.value('Android'),
    osVersion: StringCheck.value('16'),
    diskEncryption: BoolCheck.unavailable(notApplicable),
    antivirusPresent: BoolCheck.unavailable(notApplicable),
    windowsAdDomainJoined: BoolCheck.unavailable(notApplicable),
    windowsSecurityUpdateAgeDays: Int32Check.unavailable(notApplicable),
    linuxKernelVersion: StringCheck.unavailable(notApplicable),
    deviceIntegrity: BoolCheck.value(true),
  );
}

@JsonSerializable()
class StartMfaRequest {
  final String pubkey;
  final int locationId;
  final MfaMethod method;
  final DevicePostureData? postureData;

  const StartMfaRequest({
    required this.pubkey,
    required this.locationId,
    required this.method,
    this.postureData,
  });

  factory StartMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$StartMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaRequestToJson(this);
}

@JsonSerializable()
class StartMfaResponse {
  final String token;
  final String? challenge;

  factory StartMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$StartMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaResponseToJson(this);

  const StartMfaResponse({required this.token, required this.challenge});
}

@JsonSerializable()
class FinishMfaRequest {
  final String token;
  final String? code;
  final String? authPubKey;

  const FinishMfaRequest({required this.token, this.code, this.authPubKey});

  factory FinishMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaRequestToJson(this);
}

@JsonSerializable()
class FinishMfaResponse {
  final String? presharedKey;

  factory FinishMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaResponseToJson(this);

  const FinishMfaResponse({this.presharedKey});
}

@JsonSerializable()
class SecureInstanceStorage {
  final String privateKey;
  final String publicKey;

  factory SecureInstanceStorage.fromJson(Map<String, dynamic> json) =>
      _$SecureInstanceStorageFromJson(json);

  Map<String, dynamic> toJson() => _$SecureInstanceStorageToJson(this);

  const SecureInstanceStorage({
    required this.privateKey,
    required this.publicKey,
  });
}

@JsonSerializable()
class RemoteMfaQr {
  final String instanceId;
  final String token;
  final String challenge;

  factory RemoteMfaQr.fromJson(Map<String, dynamic> json) =>
      _$RemoteMfaQrFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteMfaQrToJson(this);

  const RemoteMfaQr({
    required this.instanceId,
    required this.token,
    required this.challenge,
  });
}
