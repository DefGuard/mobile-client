import 'dart:io' show Platform;
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/utils/secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometrics_state.g.dart';

final LocalAuthentication _auth = LocalAuthentication();

class BiometricsState {
  bool isSupported;
  bool canCheck;
  bool storageCapabilityCheck;
  List<BiometricType> enrolledOptions;

  BiometricsState({
    required this.isSupported,
    required this.canCheck,
    required this.enrolledOptions,
    required this.storageCapabilityCheck,
  });

  bool get isStrong {
    if (enrolledOptions.isNotEmpty) {
      if (Platform.isAndroid) {
        return enrolledOptions.contains(BiometricType.strong);
      }
      return enrolledOptions.contains(BiometricType.face) ||
          enrolledOptions.contains(BiometricType.fingerprint);
    }
    return false;
  }

  bool get isWeak {
    if (Platform.isAndroid) {
      return enrolledOptions.isNotEmpty &&
          enrolledOptions.contains(BiometricType.weak) &&
          !enrolledOptions.contains(BiometricType.strong);
    }
    return false;
  }

  bool get canOpenStorage {
    if (!isSupported || !canCheck || !storageCapabilityCheck) return false;
    return isStrong;
  }
}

@Riverpod(keepAlive: true)
class BiometricsCapability extends _$BiometricsCapability {
  @override
  BiometricsState build() {
    final result = BiometricsState(
      isSupported: false,
      canCheck: false,
      storageCapabilityCheck: false,
      enrolledOptions: [],
    );
    return result;
  }

  void update(BiometricsState value) {
    state = value;
  }
}

class BiometricsController extends HookConsumerWidget {
  final Widget child;

  const BiometricsController({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = useAppLifecycleState();
    final stateProvider = ref.read(biometricsCapabilityProvider.notifier);

    final updateProvider = useCallback(() async {
      final result = BiometricsState(
        isSupported: false,
        canCheck: false,
        storageCapabilityCheck: false,
        enrolledOptions: [],
      );
      try {
        final storageCheck = await biometricSecureStorage.canAuthenticate();
        result.storageCapabilityCheck =
            storageCheck == CanAuthenticateResponse.success;
      } catch (e) {
        talker.error(
          "Failed to check capability flag for biometric storage.\nReason: ${e.toString()}",
        );
      }
      if (await _auth.canCheckBiometrics) {
        result.canCheck = true;
        if (await _auth.isDeviceSupported()) {
          result.isSupported = true;
          final list = await _auth.getAvailableBiometrics();
          result.enrolledOptions = list;
        }
      }
      stateProvider.update(result);
    }, []);

    useEffect(() {
      if (lifecycle == AppLifecycleState.resumed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateProvider();
        });
      }
      return null;
    }, [lifecycle]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateProvider();
      });
      return null;
    }, []);

    return child;
  }
}
