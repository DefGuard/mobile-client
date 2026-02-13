// This is a generated file - do not edit.
//
// Generated from client_platform_info.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ClientPlatformInfo extends $pb.GeneratedMessage {
  factory ClientPlatformInfo({
    $core.String? osFamily,
    $core.String? osType,
    $core.String? version,
    $core.String? edition,
    $core.String? codename,
    $core.String? bitness,
    $core.String? architecture,
  }) {
    final result = create();
    if (osFamily != null) result.osFamily = osFamily;
    if (osType != null) result.osType = osType;
    if (version != null) result.version = version;
    if (edition != null) result.edition = edition;
    if (codename != null) result.codename = codename;
    if (bitness != null) result.bitness = bitness;
    if (architecture != null) result.architecture = architecture;
    return result;
  }

  ClientPlatformInfo._();

  factory ClientPlatformInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientPlatformInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientPlatformInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'defguard.proxy'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'osFamily')
    ..aOS(2, _omitFieldNames ? '' : 'osType')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..aOS(4, _omitFieldNames ? '' : 'edition')
    ..aOS(5, _omitFieldNames ? '' : 'codename')
    ..aOS(6, _omitFieldNames ? '' : 'bitness')
    ..aOS(7, _omitFieldNames ? '' : 'architecture')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientPlatformInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientPlatformInfo copyWith(void Function(ClientPlatformInfo) updates) =>
      super.copyWith((message) => updates(message as ClientPlatformInfo))
          as ClientPlatformInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientPlatformInfo create() => ClientPlatformInfo._();
  @$core.override
  ClientPlatformInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientPlatformInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientPlatformInfo>(create);
  static ClientPlatformInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get osFamily => $_getSZ(0);
  @$pb.TagNumber(1)
  set osFamily($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOsFamily() => $_has(0);
  @$pb.TagNumber(1)
  void clearOsFamily() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get osType => $_getSZ(1);
  @$pb.TagNumber(2)
  set osType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOsType() => $_has(1);
  @$pb.TagNumber(2)
  void clearOsType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get edition => $_getSZ(3);
  @$pb.TagNumber(4)
  set edition($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEdition() => $_has(3);
  @$pb.TagNumber(4)
  void clearEdition() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get codename => $_getSZ(4);
  @$pb.TagNumber(5)
  set codename($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCodename() => $_has(4);
  @$pb.TagNumber(5)
  void clearCodename() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get bitness => $_getSZ(5);
  @$pb.TagNumber(6)
  set bitness($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBitness() => $_has(5);
  @$pb.TagNumber(6)
  void clearBitness() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get architecture => $_getSZ(6);
  @$pb.TagNumber(7)
  set architecture($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasArchitecture() => $_has(6);
  @$pb.TagNumber(7)
  void clearArchitecture() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
