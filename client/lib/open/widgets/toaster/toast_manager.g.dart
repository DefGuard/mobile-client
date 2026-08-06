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
    extends $NotifierProvider<ToastManager, List<ToastData>> {
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
  Override overrideWithValue(List<ToastData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ToastData>>(value),
    );
  }
}

String _$toastManagerHash() => r'74289bbdb571bc6704c109ff8277a455d0815c55';

abstract class _$ToastManager extends $Notifier<List<ToastData>> {
  List<ToastData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ToastData>, List<ToastData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ToastData>, List<ToastData>>,
              List<ToastData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
