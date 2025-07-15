import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/proxy/enrollment.dart';

part 'config.g.dart';

@JsonSerializable()
class InstanceInfoResponse {
  final ConfigurationPollResponse? deviceConfig;

  const InstanceInfoResponse({this.deviceConfig});

  factory InstanceInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$InstanceInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InstanceInfoResponseToJson(this);
}

@JsonSerializable()
class ConfigurationPollResponse {
  final Device? device;
  final List<DeviceConfig> configs;
  final InstanceInfo? instance;
  final String? token;

  const ConfigurationPollResponse({
    this.device,
    required this.configs,
    this.instance,
    this.token,
  });

  factory ConfigurationPollResponse.fromJson(Map<String, dynamic> json) =>
      _$ConfigurationPollResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigurationPollResponseToJson(this);
}
