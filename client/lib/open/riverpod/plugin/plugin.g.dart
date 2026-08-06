// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PluginActiveTunnelState)
final pluginActiveTunnelStateProvider = PluginActiveTunnelStateProvider._();

final class PluginActiveTunnelStateProvider
    extends $NotifierProvider<PluginActiveTunnelState, PluginTunnelEventData?> {
  PluginActiveTunnelStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginActiveTunnelStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginActiveTunnelStateHash();

  @$internal
  @override
  PluginActiveTunnelState create() => PluginActiveTunnelState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PluginTunnelEventData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PluginTunnelEventData?>(value),
    );
  }
}

String _$pluginActiveTunnelStateHash() =>
    r'55599a4824466a2d18b3333ee242975b0de1c68b';

abstract class _$PluginActiveTunnelState
    extends $Notifier<PluginTunnelEventData?> {
  PluginTunnelEventData? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<PluginTunnelEventData?, PluginTunnelEventData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PluginTunnelEventData?, PluginTunnelEventData?>,
              PluginTunnelEventData?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
