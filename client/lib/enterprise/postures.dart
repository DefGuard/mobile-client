import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/client_identity.dart';

part 'postures.g.dart';

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

  factory StringCheck.value(String value) =>
      StringCheck(result: {'Value': value});

  factory StringCheck.unavailable(UnavailableReason reason) =>
      StringCheck(result: {'Unavailable': reason.value});

  factory StringCheck.fromJson(Map<String, dynamic> json) =>
      _$StringCheckFromJson(json);

  Map<String, dynamic> toJson() => _$StringCheckToJson(this);
}

@JsonSerializable()
class BoolCheck {
  final Map<String, dynamic> result;

  const BoolCheck({required this.result});

  factory BoolCheck.value(bool value) => BoolCheck(result: {'Value': value});

  factory BoolCheck.unavailable(UnavailableReason reason) =>
      BoolCheck(result: {'Unavailable': reason.value});

  factory BoolCheck.fromJson(Map<String, dynamic> json) =>
      _$BoolCheckFromJson(json);

  Map<String, dynamic> toJson() => _$BoolCheckToJson(this);
}

@JsonSerializable()
class Int32Check {
  final Map<String, dynamic> result;

  const Int32Check({required this.result});

  factory Int32Check.value(int value) => Int32Check(result: {'Value': value});

  factory Int32Check.unavailable(UnavailableReason reason) =>
      Int32Check(result: {'Unavailable': reason.value});

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
  final StringCheck? androidSecurityPatchDate;

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
    this.androidSecurityPatchDate,
  });

  factory DevicePostureData.fromJson(Map<String, dynamic> json) =>
      _$DevicePostureDataFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePostureDataToJson(this);
}

@JsonSerializable()
class PostureConnectRequest {
  final int locationId;
  final String pubkey;
  final DevicePostureData devicePostureData;
  final String token;

  const PostureConnectRequest({
    required this.locationId,
    required this.pubkey,
    required this.devicePostureData,
    required this.token,
  });

  factory PostureConnectRequest.fromJson(Map<String, dynamic> json) =>
      _$PostureConnectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PostureConnectRequestToJson(this);
}

@JsonSerializable()
class PostureConnectResponse {
  final String presharedKey;

  const PostureConnectResponse({required this.presharedKey});

  factory PostureConnectResponse.fromJson(Map<String, dynamic> json) =>
      _$PostureConnectResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PostureConnectResponseToJson(this);
}

Future<DevicePostureData> getPosture() async {
  return devicePostureData(await clientIdentity.get());
}

DevicePostureData devicePostureData(ClientIdentity identity) {
  final facts = identity.facts;
  return DevicePostureData(
    defguardClientVersion: identity.version,
    osType: facts.osType,
    osName: StringCheck.value(facts.osName),
    osVersion: facts.kind == PlatformKind.other
        ? StringCheck.unavailable(UnavailableReason.unspecified)
        : StringCheck.value(facts.osVersion),
    deviceIntegrity: facts.kind == PlatformKind.android
        // TODO: implement full google play integrity check flow
        // TODO: https://github.com/DefGuard/defguard/issues/2986
        ? BoolCheck.unavailable(UnavailableReason.unspecified)
        : BoolCheck.unavailable(UnavailableReason.notApplicable),
    diskEncryption: BoolCheck.unavailable(UnavailableReason.notApplicable),
    antivirusPresent: BoolCheck.unavailable(UnavailableReason.notApplicable),
    windowsAdDomainJoined: BoolCheck.unavailable(
      UnavailableReason.notApplicable,
    ),
    windowsSecurityUpdateAgeDays: Int32Check.unavailable(
      UnavailableReason.notApplicable,
    ),
    linuxKernelVersion: StringCheck.unavailable(
      UnavailableReason.notApplicable,
    ),
    androidSecurityPatchDate: _androidSecurityPatch(facts),
  );
}

StringCheck _androidSecurityPatch(DevicePlatformFacts facts) {
  if (facts.kind != PlatformKind.android) {
    return StringCheck.unavailable(UnavailableReason.notApplicable);
  }
  final patch = facts.androidSecurityPatch;
  return patch != null
      ? StringCheck.value(patch)
      : StringCheck.unavailable(UnavailableReason.detectionFailed);
}
