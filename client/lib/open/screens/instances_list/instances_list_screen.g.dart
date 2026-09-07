// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instances_list_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_instancesListData)
final _instancesListDataProvider = _InstancesListDataProvider._();

final class _InstancesListDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<_InstanceItemData>>,
          List<_InstanceItemData>,
          Stream<List<_InstanceItemData>>
        >
    with
        $FutureModifier<List<_InstanceItemData>>,
        $StreamProvider<List<_InstanceItemData>> {
  _InstancesListDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_instancesListDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_instancesListDataHash();

  @$internal
  @override
  $StreamProviderElement<List<_InstanceItemData>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<_InstanceItemData>> create(Ref ref) {
    return _instancesListData(ref);
  }
}

String _$_instancesListDataHash() =>
    r'61724e4d819ae47a6afff762b2688cc8a2260d5f';
