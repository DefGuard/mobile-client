// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExcludeAndroidAuto)
final excludeAndroidAutoProvider = ExcludeAndroidAutoProvider._();

final class ExcludeAndroidAutoProvider
    extends
        $AsyncNotifierProvider<ExcludeAndroidAuto, ExcludeAndroidAutoState> {
  ExcludeAndroidAutoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'excludeAndroidAutoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$excludeAndroidAutoHash();

  @$internal
  @override
  ExcludeAndroidAuto create() => ExcludeAndroidAuto();
}

String _$excludeAndroidAutoHash() =>
    r'2e35bb360063f3fbe0a705d976dd329bfd7e54ec';

abstract class _$ExcludeAndroidAuto
    extends $AsyncNotifier<ExcludeAndroidAutoState> {
  FutureOr<ExcludeAndroidAutoState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ExcludeAndroidAutoState>,
              ExcludeAndroidAutoState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ExcludeAndroidAutoState>,
                ExcludeAndroidAutoState
              >,
              AsyncValue<ExcludeAndroidAutoState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
