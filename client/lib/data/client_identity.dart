import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile/data/proto/client_platform_info.pb.dart';
import 'package:mobile/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum PlatformKind { android, ios, other }

/// Raw device facts, read from the platform once. Both the proxy capability
/// headers and the posture payload are derived from these, so the platform
/// branching lives in exactly one place.
class DevicePlatformFacts {
  final PlatformKind kind;
  final String osFamily;
  final String osType;
  final String osName;
  final String osVersion;
  final String? codename;
  final String? architecture;
  final String? bitness;
  final String? androidSecurityPatch;

  const DevicePlatformFacts({
    required this.kind,
    required this.osFamily,
    required this.osType,
    required this.osName,
    required this.osVersion,
    this.codename,
    this.architecture,
    this.bitness,
    this.androidSecurityPatch,
  });
}

ClientPlatformInfo clientPlatformInfo(DevicePlatformFacts facts) {
  return ClientPlatformInfo(
    osFamily: facts.osFamily,
    osType: facts.osType,
    version: facts.osVersion,
    codename: facts.codename,
    bitness: facts.bitness,
    architecture: facts.architecture,
  );
}

/// What the proxy needs in order to know which locations this client can
/// handle. A request without it gets a silently trimmed location list.
class ClientIdentity {
  final String version;
  final DevicePlatformFacts facts;
  final String platformHeader;

  ClientIdentity({required this.version, required this.facts})
    : platformHeader = base64Encode(clientPlatformInfo(facts).writeToBuffer());
}

typedef ClientIdentityResolver = Future<ClientIdentity> Function();

Future<DevicePlatformFacts> resolvePlatformFacts() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    return DevicePlatformFacts(
      kind: PlatformKind.android,
      osFamily: 'android',
      osType: 'Android',
      osName: android.version.release,
      osVersion: android.version.release,
      codename: android.version.codename,
      architecture: android.supportedAbis.firstOrNull ?? '',
      bitness: '64',
      androidSecurityPatch: android.version.securityPatch,
    );
  }

  if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    return DevicePlatformFacts(
      kind: PlatformKind.ios,
      osFamily: 'ios',
      osType: 'iOS',
      osName: ios.systemName,
      osVersion: ios.systemVersion,
      architecture: 'arm64',
      bitness: '64',
    );
  }

  return DevicePlatformFacts(
    kind: PlatformKind.other,
    osFamily: Platform.operatingSystem,
    osType: Platform.operatingSystem,
    osName: Platform.operatingSystem,
    osVersion: Platform.operatingSystemVersion,
  );
}

Future<ClientIdentity> resolveClientIdentity() async {
  final facts = await resolvePlatformFacts();
  final packageInfo = await PackageInfo.fromPlatform();
  return ClientIdentity(version: packageInfo.version, facts: facts);
}

/// Resolves the identity once and hands the same value to every caller. A
/// failed or timed out resolve is not cached, so the next caller retries.
class ClientIdentitySource {
  ClientIdentitySource(
    this._resolve, {
    this.timeout = const Duration(seconds: 5),
  });

  final ClientIdentityResolver _resolve;
  final Duration timeout;

  ClientIdentity? _resolved;
  Future<ClientIdentity>? _pending;

  ClientIdentity? get resolved => _resolved;

  Future<ClientIdentity> get() {
    final resolved = _resolved;
    if (resolved != null) return Future.value(resolved);
    return _pending ??= _resolveOnce();
  }

  Future<ClientIdentity> _resolveOnce() {
    final attempt = _resolve();
    // A resolve that lands just after its timeout is still worth keeping.
    attempt.then((identity) => _resolved ??= identity).ignore();
    return attempt.timeout(timeout).whenComplete(() => _pending = null);
  }

  Future<void> warmUp() async {
    try {
      await get();
    } catch (e, s) {
      talker.error('Failed to resolve client identity at startup', e, s);
    }
  }
}

final clientIdentity = ClientIdentitySource(resolveClientIdentity);
