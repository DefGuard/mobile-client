import 'package:mobile/data/plugin/plugin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plugin.g.dart';

@Riverpod(keepAlive: true)
class PluginActiveTunnelState extends _$PluginActiveTunnelState {
  @override
  PluginTunnelEventData? build() => null;

  void set(PluginTunnelEventData data) {
    state = data;
  }

  void clear() {
    state = null;
  }
}