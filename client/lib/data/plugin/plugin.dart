import 'package:json_annotation/json_annotation.dart';

part 'plugin.g.dart';

@JsonEnum()
enum TunnelTraffic {
  @JsonValue('all')
  all,
  @JsonValue('predefined')
  predefined,
}

@JsonSerializable()
class PluginConnectPayload {
  // config
  final String publicKey;
  final String privateKey;
  final String address;
  final String? dns;
  final String endpoint;
  final String allowedIps;
  final int keepalive;
  final String? presharedKey;

  // context
  final String locationName;
  final int locationId;
  final int instanceId;
  TunnelTraffic traffic;

  PluginConnectPayload({
    required this.publicKey,
    required this.privateKey,
    required this.address,
    required this.endpoint,
    required this.allowedIps,
    required this.keepalive,
    required this.locationName,
    required this.locationId,
    required this.instanceId,
    required this.traffic,
    this.dns,
    this.presharedKey,
  });

  factory PluginConnectPayload.fromJson(Map<String, dynamic> json) =>
      _$PluginConnectPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PluginConnectPayloadToJson(this);
}


@JsonSerializable()
class PluginTunnelEventData {
  final int instanceId;
  final int locationId;
  final TunnelTraffic traffic;

  const PluginTunnelEventData({
    required this.instanceId,
    required this.locationId,
    required this.traffic,
  });

  factory PluginTunnelEventData.fromJson(Map<String, dynamic> json) => _$PluginTunnelEventDataFromJson(json);

  Map<String, dynamic> toJson() => _$PluginTunnelEventDataToJson(this);
}