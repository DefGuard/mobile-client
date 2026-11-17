import 'package:collection/collection.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';

/// A pre-2.2 server sends no steps, so this derives them from the legacy fields
/// on each read.
List<MfaStep> effectiveMfaSteps(Location location) =>
    location.mfaSteps.isNotEmpty
    ? location.mfaSteps
    : legacyMfaSteps(location.locationMfaMode, location.mfaEnabled);

bool shouldStartMfa(Location location) =>
    effectiveMfaSteps(location).isNotEmpty;

int mfaStepCount(Location location) => effectiveMfaSteps(location).length;

/// Runs on the write path, where biometric usability is unknown, so it keeps
/// biometric as a choice. `resolveMfaStepPlan` drops it when biometrics are
/// unusable.
List<MfaMethod?> sanitizeMfaStepPlan(
  List<MfaMethod?> plan,
  List<MfaStep> steps,
) {
  return List<MfaMethod?>.generate(steps.length, (index) {
    final choices = steps[index].methods
        .where((entry) => entry.method != null && _isSetUpOnServer(entry))
        .map((entry) => entry.method!)
        .toList(growable: false);
    final saved = index < plan.length ? plan[index] : null;
    if (saved != null && choices.contains(saved)) {
      return saved;
    }
    return choices.firstOrNull;
  }, growable: false);
}

class MfaCapabilities {
  final bool biometricAvailable;
  final MfaContract contract;

  const MfaCapabilities({
    required this.biometricAvailable,
    required this.contract,
  });

  /// The legacy contract carries one step and has no FIDO2 proof.
  bool get supportsMultipleSteps => contract == MfaContract.multiStep;

  bool supports(MfaMethod method) =>
      method != MfaMethod.fido2 || contract == MfaContract.multiStep;

  bool canRun(List<MfaStep> steps) =>
      steps.length <= 1 || supportsMultipleSteps;
}

/// Why a step's method cannot be used right now.
enum MfaMethodAvailability {
  usable,

  /// Supported, but the user has not set it up on the server.
  notConfigured,

  /// Biometric, but this device has no usable biometric storage.
  biometryUnavailable,
  unsupported,
}

enum MfaUnpassableReason {
  setUpBiometry,
  registerSecurityKey,
  notConfigured,
  desktopOnly,
}

/// Core sets `configured` before the biometric key is registered, so the stored
/// flag for biometric can be stale. `MfaCapabilities.biometricAvailable`
/// decides instead.
bool _isSetUpOnServer(MfaStepMethod entry) =>
    entry.method == MfaMethod.biometric || entry.configured;

MfaMethodAvailability mfaMethodAvailability(
  MfaStepMethod entry, {
  required MfaCapabilities capabilities,
}) {
  final method = entry.method;
  if (method == null || !capabilities.supports(method)) {
    return MfaMethodAvailability.unsupported;
  }
  if (!_isSetUpOnServer(entry)) return MfaMethodAvailability.notConfigured;
  if (method == MfaMethod.biometric && !capabilities.biometricAvailable) {
    return MfaMethodAvailability.biometryUnavailable;
  }
  return MfaMethodAvailability.usable;
}

/// Methods of [step] this device can actually prove right now.
List<MfaStepMethod> usableMfaMethods(
  MfaStep step, {
  required MfaCapabilities capabilities,
}) => step.methods
    .where(
      (entry) =>
          mfaMethodAvailability(entry, capabilities: capabilities) ==
          MfaMethodAvailability.usable,
    )
    .toList(growable: false);

/// Methods of [step] worth showing, unusable ones included so the user can see
/// why. Falls back to the raw list so a step made entirely of factors this
/// client cannot perform still renders something.
List<MfaStepMethod> pickableMfaMethods(
  MfaStep step, {
  required MfaCapabilities capabilities,
}) {
  final supported = step.methods
      .where(
        (entry) => entry.method != null && capabilities.supports(entry.method!),
      )
      .toList(growable: false);
  return supported.isNotEmpty ? supported : step.methods;
}

/// The method to use for each step, in flow order. `null` marks a step nothing
/// can satisfy, which [hasUnpassableMfaStep] then blocks the connect on.
List<MfaMethod?> resolveMfaStepPlan(
  Location location, {
  List<MfaMethod?> oneOff = const [],
  required MfaCapabilities capabilities,
}) {
  final steps = effectiveMfaSteps(location);
  if (!capabilities.canRun(steps)) {
    return List<MfaMethod?>.filled(steps.length, null, growable: false);
  }
  final saved = location.mfaStepPlan;

  return List<MfaMethod?>.generate(steps.length, (index) {
    final usable = usableMfaMethods(steps[index], capabilities: capabilities);
    bool isUsable(MfaMethod? method) =>
        method != null && usable.any((entry) => entry.method == method);

    final once = index < oneOff.length ? oneOff[index] : null;
    if (isUsable(once)) return once;
    final stored = index < saved.length ? saved[index] : null;
    if (isUsable(stored)) return stored;
    return usable.firstOrNull?.method;
  }, growable: false);
}

List<MfaMethod>? resolveMfaRetryPlan(
  Location location, {
  required MfaCapabilities attempt,
  required MfaContract refreshedContract,
  List<MfaMethod?> oneOff = const [],
}) {
  if (attempt.contract != refreshedContract) return null;
  final plan = resolveMfaStepPlan(
    location,
    oneOff: oneOff,
    capabilities: attempt,
  );
  if (plan.isEmpty || plan.contains(null)) return null;
  return plan.cast<MfaMethod>();
}

bool hasUnpassableMfaStep(
  Location location, {
  required MfaCapabilities capabilities,
}) {
  final steps = effectiveMfaSteps(location);
  return !capabilities.canRun(steps) ||
      steps.any(
        (step) => usableMfaMethods(step, capabilities: capabilities).isEmpty,
      );
}

MfaUnpassableReason? unpassableStepReason(
  Location location, {
  required MfaCapabilities capabilities,
}) {
  final steps = effectiveMfaSteps(location);
  if (!capabilities.canRun(steps)) return MfaUnpassableReason.desktopOnly;
  final step = steps.firstWhereOrNull(
    (step) => usableMfaMethods(step, capabilities: capabilities).isEmpty,
  );
  if (step == null) return null;

  MfaMethodAvailability availability(MfaStepMethod entry) =>
      mfaMethodAvailability(entry, capabilities: capabilities);
  final states = step.methods.map(availability).toSet();
  if (states.contains(MfaMethodAvailability.biometryUnavailable)) {
    return MfaUnpassableReason.setUpBiometry;
  }
  final notConfigured = step.methods.where(
    (entry) => availability(entry) == MfaMethodAvailability.notConfigured,
  );
  if (notConfigured.isNotEmpty &&
      notConfigured.every((entry) => entry.method == MfaMethod.fido2)) {
    return MfaUnpassableReason.registerSecurityKey;
  }
  if (notConfigured.isNotEmpty) return MfaUnpassableReason.notConfigured;
  return MfaUnpassableReason.desktopOnly;
}

String mfaStepsToText(int count) => '$count-step verification';
