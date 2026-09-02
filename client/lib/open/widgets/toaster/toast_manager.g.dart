// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toast_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ToastManager)
final toastManagerProvider = ToastManagerProvider._();

final class ToastManagerProvider
    extends $NotifierProvider<ToastManager, ToastData?> {
  ToastManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toastManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toastManagerHash();

  @$internal
  @override
  ToastManager create() => ToastManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToastData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToastData?>(value),
    );
  }
}

String _$toastManagerHash() => r'3375fc0b90ca81b3d78289a8f4b99dc370daad38';

abstract class _$ToastManager extends $Notifier<ToastData?> {
  ToastData? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ToastData?, ToastData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ToastData?, ToastData?>,
              ToastData?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
