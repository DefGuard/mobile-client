import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';

PluginConnectPayload _payload({
  String devicePublicKey = 'device-key',
  int networkId = 7,
  bool postureCheckRequired = false,
  bool excludeAndroidAuto = false,
  String endpoint = 'old.example:51820',
}) => PluginConnectPayload(
  publicKey: 'location-key',
  devicePublicKey: devicePublicKey,
  privateKey: 'private-key',
  address: '10.0.0.2/32',
  endpoint: endpoint,
  allowedIps: '10.0.0.0/24',
  keepalive: 25,
  locationName: 'office',
  locationId: 1,
  instanceId: 1,
  traffic: RoutingMethod.predefined,
  networkId: networkId,
  postureCheckRequired: postureCheckRequired,
  excludeAndroidAuto: excludeAndroidAuto,
);

void main() {
  test('connect payload serializes Android Auto exclusion in snake case', () {
    expect(
      _payload(excludeAndroidAuto: true).toJson()['exclude_android_auto'],
      isTrue,
    );
    expect(_payload().toJson()['exclude_android_auto'], isFalse);
  });

  test('a retry reuses the attempt when only tunnel settings changed', () {
    expect(
      TunnelService.canReuseMfaAttempt(
        _payload(),
        _payload(endpoint: 'new.example:51820'),
      ),
      isTrue,
    );
  });

  test('a retry abandons the attempt when its binding changed', () {
    for (final refreshed in [
      _payload(networkId: 8),
      _payload(devicePublicKey: 'other-key'),
      _payload(postureCheckRequired: true),
    ]) {
      expect(TunnelService.canReuseMfaAttempt(_payload(), refreshed), isFalse);
    }
  });
}
