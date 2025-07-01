import 'package:json_annotation/json_annotation.dart';

part 'plugin.g.dart';

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

  const PluginConnectPayload({
    required this.publicKey,
    required this.privateKey,
    required this.address,
    required this.endpoint,
    required this.allowedIps,
    required this.keepalive,
    required this.locationName,
    required this.locationId,
    required this.instanceId,
    this.dns,
    this.presharedKey,
  });

  factory PluginConnectPayload.fromJson(Map<String, dynamic> json) =>
      _$PluginConnectPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PluginConnectPayloadToJson(this);
}
