import 'package:json_annotation/json_annotation.dart';

import '../db/enums.dart';

part 'plugin.g.dart';

@JsonSerializable()
class PluginConnectPayload {
  // config
  final String publicKey;
  final String devicePublicKey;
  final String privateKey;
  final String address;
  final String? dns;
  final String endpoint;
  final String allowedIps;
  final int keepalive;
  String? presharedKey;

  // context
  final String locationName;
  final int locationId;
  final int instanceId;
  final int networkId;
  RoutingMethod traffic;
  final bool postureCheckRequired;

  /// MFA method actually used to authorize this connection.
  /// `null` means the tunnel was established without MFA.
  MfaMethod? mfaMethod;

  PluginConnectPayload({
    required this.publicKey,
    required this.devicePublicKey,
    required this.privateKey,
    required this.address,
    required this.endpoint,
    required this.allowedIps,
    required this.keepalive,
    required this.locationName,
    required this.locationId,
    required this.instanceId,
    required this.traffic,
    required this.networkId,
    this.dns,
    this.presharedKey,
    required this.postureCheckRequired,
    this.mfaMethod,
  });

  factory PluginConnectPayload.fromJson(Map<String, dynamic> json) =>
      _$PluginConnectPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PluginConnectPayloadToJson(this);
}

@JsonSerializable()
class PluginTunnelEventData {
  final int instanceId;
  final int locationId;
  final RoutingMethod traffic;

  /// MFA method used to authorize the active connection.
  /// `null` means no MFA was used, or the tunnel was started by a native
  /// build predating this field.
  final MfaMethod? mfaMethod;

  const PluginTunnelEventData({
    required this.instanceId,
    required this.locationId,
    required this.traffic,
    this.mfaMethod,
  });

  factory PluginTunnelEventData.fromJson(Map<String, dynamic> json) =>
      _$PluginTunnelEventDataFromJson(json);

  Map<String, dynamic> toJson() => _$PluginTunnelEventDataToJson(this);
}
