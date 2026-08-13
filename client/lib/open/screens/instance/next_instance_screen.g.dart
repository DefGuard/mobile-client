// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_instance_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_nextScreenData)
final _nextScreenDataProvider = _NextScreenDataFamily._();

final class _NextScreenDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<_ScreenData?>,
          _ScreenData?,
          Stream<_ScreenData?>
        >
    with $FutureModifier<_ScreenData?>, $StreamProvider<_ScreenData?> {
  _NextScreenDataProvider._({
    required _NextScreenDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_nextScreenDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_nextScreenDataHash();

  @override
  String toString() {
    return r'_nextScreenDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<_ScreenData?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<_ScreenData?> create(Ref ref) {
    final argument = this.argument as String;
    return _nextScreenData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _NextScreenDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_nextScreenDataHash() => r'69aa74e48fef68558e56e37db30d82a243516f63';

final class _NextScreenDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<_ScreenData?>, String> {
  _NextScreenDataFamily._()
    : super(
        retry: null,
        name: r'_nextScreenDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _NextScreenDataProvider call(String id) =>
      _NextScreenDataProvider._(argument: id, from: this);

  @override
  String toString() => r'_nextScreenDataProvider';
}
