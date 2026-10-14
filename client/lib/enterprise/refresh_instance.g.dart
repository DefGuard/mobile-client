// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_instance.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EnterpriseRefresh)
final enterpriseRefreshProvider = EnterpriseRefreshProvider._();

final class EnterpriseRefreshProvider
    extends $NotifierProvider<EnterpriseRefresh, bool> {
  EnterpriseRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enterpriseRefreshProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enterpriseRefreshHash();

  @$internal
  @override
  EnterpriseRefresh create() => EnterpriseRefresh();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$enterpriseRefreshHash() => r'7969a84c1a8a45a2eb3e7ca85007353d5d53b2c0';

abstract class _$EnterpriseRefresh extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
