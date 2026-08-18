// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_instances_list_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_nextInstancesListData)
final _nextInstancesListDataProvider = _NextInstancesListDataProvider._();

final class _NextInstancesListDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<_InstanceItemData>>,
          List<_InstanceItemData>,
          Stream<List<_InstanceItemData>>
        >
    with
        $FutureModifier<List<_InstanceItemData>>,
        $StreamProvider<List<_InstanceItemData>> {
  _NextInstancesListDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_nextInstancesListDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_nextInstancesListDataHash();

  @$internal
  @override
  $StreamProviderElement<List<_InstanceItemData>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<_InstanceItemData>> create(Ref ref) {
    return _nextInstancesListData(ref);
  }
}

String _$_nextInstancesListDataHash() =>
    r'1f221757df2b93f7b9ecac78569fc42bdc344611';
