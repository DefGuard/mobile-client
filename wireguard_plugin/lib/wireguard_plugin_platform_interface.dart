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

  // should ensure that user accepted all runtime permissions for the app
  Future<bool> requestPermissions();

  // starts wireguard tunnel via given config
  Future<void> startTunnel(String config);

  Future<void> closeTunnel();

  Stream<Map<String, dynamic>> get eventStream {
    throw UnimplementedError('eventStream has not been implemented.');
  }
}
