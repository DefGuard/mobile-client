// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instance_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$screenDataHash() => r'c017302ad14b73b0541adefc084c5468f2cfa3c1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [_screenData].
@ProviderFor(_screenData)
const _screenDataProvider = _ScreenDataFamily();

/// See also [_screenData].
class _ScreenDataFamily extends Family<AsyncValue<_ScreenData?>> {
  /// See also [_screenData].
  const _ScreenDataFamily();

  /// See also [_screenData].
  _ScreenDataProvider call(String id) {
    return _ScreenDataProvider(id);
  }

  @override
  _ScreenDataProvider getProviderOverride(
    covariant _ScreenDataProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'_screenDataProvider';
}

/// See also [_screenData].
class _ScreenDataProvider extends AutoDisposeStreamProvider<_ScreenData?> {
  /// See also [_screenData].
  _ScreenDataProvider(String id)
    : this._internal(
        (ref) => _screenData(ref as _ScreenDataRef, id),
        from: _screenDataProvider,
        name: r'_screenDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$screenDataHash,
        dependencies: _ScreenDataFamily._dependencies,
        allTransitiveDependencies: _ScreenDataFamily._allTransitiveDependencies,
        id: id,
      );

  _ScreenDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Stream<_ScreenData?> Function(_ScreenDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: _ScreenDataProvider._internal(
        (ref) => create(ref as _ScreenDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<_ScreenData?> createElement() {
    return _ScreenDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is _ScreenDataProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin _ScreenDataRef on AutoDisposeStreamProviderRef<_ScreenData?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ScreenDataProviderElement
    extends AutoDisposeStreamProviderElement<_ScreenData?>
    with _ScreenDataRef {
  _ScreenDataProviderElement(super.provider);

  @override
  String get id => (origin as _ScreenDataProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
