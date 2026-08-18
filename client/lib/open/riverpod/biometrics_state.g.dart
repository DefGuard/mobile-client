// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometrics_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BiometricsCapability)
final biometricsCapabilityProvider = BiometricsCapabilityProvider._();

final class BiometricsCapabilityProvider
    extends $NotifierProvider<BiometricsCapability, BiometricsState> {
  BiometricsCapabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricsCapabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricsCapabilityHash();

  @$internal
  @override
  BiometricsCapability create() => BiometricsCapability();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricsState>(value),
    );
  }
}

String _$biometricsCapabilityHash() =>
    r'443b39915554d21ebbb63f65697aa62e8f6673d0';

abstract class _$BiometricsCapability extends $Notifier<BiometricsState> {
  BiometricsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BiometricsState, BiometricsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BiometricsState, BiometricsState>,
              BiometricsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
