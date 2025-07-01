import 'package:flutter_test/flutter_test.dart';
import 'package:wireguard_plugin/wireguard_plugin.dart';
import 'package:wireguard_plugin/wireguard_plugin_platform_interface.dart';
import 'package:wireguard_plugin/wireguard_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWireguardPluginPlatform
    with MockPlatformInterfaceMixin
    implements WireguardPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WireguardPluginPlatform initialPlatform = WireguardPluginPlatform.instance;

  test('$MethodChannelWireguardPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWireguardPlugin>());
  });

  test('getPlatformVersion', () async {
    WireguardPlugin wireguardPlugin = WireguardPlugin();
    MockWireguardPluginPlatform fakePlatform = MockWireguardPluginPlatform();
    WireguardPluginPlatform.instance = fakePlatform;

    expect(await wireguardPlugin.getPlatformVersion(), '42');
  });
}
