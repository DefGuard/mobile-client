import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wireguard_plugin_method_channel.dart';

abstract class WireguardPluginPlatform extends PlatformInterface {
  /// Constructs a WireguardPluginPlatform.
  WireguardPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static WireguardPluginPlatform _instance = MethodChannelWireguardPlugin();

  /// The default instance of [WireguardPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelWireguardPlugin].
  static WireguardPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WireguardPluginPlatform] when
  /// they register themselves.
  static set instance(WireguardPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
