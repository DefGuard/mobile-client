
import 'wireguard_plugin_platform_interface.dart';

class WireguardPlugin {
  Future<String?> getPlatformVersion() {
    return WireguardPluginPlatform.instance.getPlatformVersion();
  }
}
