import 'package:json_annotation/json_annotation.dart';

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
