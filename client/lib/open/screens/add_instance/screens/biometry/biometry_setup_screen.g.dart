// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometry_setup_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_screenData)
final _screenDataProvider = _ScreenDataFamily._();

final class _ScreenDataProvider
    extends $FunctionalProvider<AsyncValue<dynamic>, dynamic, Stream<dynamic>>
    with $FutureModifier<dynamic>, $StreamProvider<dynamic> {
  _ScreenDataProvider._({
    required _ScreenDataFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'_screenDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_screenDataHash();

  @override
  String toString() {
    return r'_screenDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<dynamic> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<dynamic> create(Ref ref) {
    final argument = this.argument as int;
    return _screenData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _ScreenDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_screenDataHash() => r'814d13abd5143e8758c3b4d16bde3a3aa3af19bf';

final class _ScreenDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<dynamic>, int> {
  _ScreenDataFamily._()
    : super(
        retry: null,
        name: r'_screenDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _ScreenDataProvider call(int id) =>
      _ScreenDataProvider._(argument: id, from: this);

  @override
  String toString() => r'_screenDataProvider';
}
