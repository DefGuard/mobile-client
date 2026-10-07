import 'package:collection/collection.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';

/// The flow to use for a location. A pre-2.2 server sends no steps, so they are
/// synthesized from the legacy fields on read rather than backfilled on write.
List<MfaStep> effectiveMfaSteps(Location location) =>
    location.mfaSteps.isNotEmpty
    ? location.mfaSteps
    : legacyMfaSteps(location.locationMfaMode, location.mfaEnabled);

bool shouldStartMfa(Location location) =>
    effectiveMfaSteps(location).isNotEmpty;

int mfaStepCount(Location location) => effectiveMfaSteps(location).length;

/// Realigns a stored plan onto [steps] after the server changed them. Runs on
/// the write path, so it cannot know whether biometrics are currently usable and
/// must keep a saved biometric choice; only `resolveMfaStepPlan` gates on that.
List<MfaMethod?> sanitizeMfaStepPlan(
  List<MfaMethod?> plan,
  List<MfaStep> steps,
) {
  return List<MfaMethod?>.generate(steps.length, (index) {
    final choices = steps[index].methods
        .where((entry) => entry.configured && entry.method != null)
        .map((entry) => entry.method!)
        .toList(growable: false);
    final saved = index < plan.length ? plan[index] : null;
    if (saved != null && choices.contains(saved)) {
      return saved;
    }
    return choices.firstOrNull;
  }, growable: false);
}

/// Why a step's method cannot be used right now.
enum MfaMethodAvailability {
  usable,
  notConfigured,
  biometryUnavailable,
  unsupported,
}

/// Why a whole step cannot be passed, in the order worth telling the user about.
enum MfaUnpassableReason { setUpBiometry, notConfigured, desktopOnly }

MfaMethodAvailability mfaMethodAvailability(
  MfaStepMethod entry, {
  required bool biometricAvailable,
  MfaContract contract = MfaContract.legacy,
}) {
  final method = entry.method;
  if (method == null ||
      (method == MfaMethod.fido2 && contract == MfaContract.legacy)) {
    return MfaMethodAvailability.unsupported;
  }
  if (!entry.configured) return MfaMethodAvailability.notConfigured;
  if (method == MfaMethod.biometric && !biometricAvailable) {
    return MfaMethodAvailability.biometryUnavailable;
  }
  return MfaMethodAvailability.usable;
}

/// Methods of [step] this device can actually prove right now.
List<MfaStepMethod> usableMfaMethods(
  MfaStep step, {
  required bool biometricAvailable,
  MfaContract contract = MfaContract.legacy,
}) => step.methods
    .where(
      (entry) =>
          mfaMethodAvailability(
            entry,
            biometricAvailable: biometricAvailable,
            contract: contract,
          ) ==
          MfaMethodAvailability.usable,
    )
    .toList(growable: false);

/// Methods of [step] worth showing, unusable ones included so the user can see
/// why. Falls back to the raw list so a step made entirely of factors this
/// client cannot perform still renders something.
List<MfaStepMethod> pickableMfaMethods(
  MfaStep step, {
  MfaContract contract = MfaContract.legacy,
}) {
  final supported = step.methods
      .where(
        (entry) =>
            entry.method != null &&
            !(contract == MfaContract.legacy &&
                entry.method == MfaMethod.fido2),
      )
      .toList(growable: false);
  return supported.isNotEmpty ? supported : step.methods;
}

/// The method to use for each step, in flow order. `null` marks a step nothing
/// can satisfy, which [hasUnpassableMfaStep] then blocks the connect on.
List<MfaMethod?> resolveMfaStepPlan(
  Location location, {
  List<MfaMethod?> oneOff = const [],
  required bool biometricAvailable,
  MfaContract contract = MfaContract.legacy,
}) {
  final steps = effectiveMfaSteps(location);
  if (contract == MfaContract.legacy && steps.length > 1) {
    return List<MfaMethod?>.filled(steps.length, null, growable: false);
  }
  final saved = location.mfaStepPlan;

  return List<MfaMethod?>.generate(steps.length, (index) {
    final usable = usableMfaMethods(
      steps[index],
      biometricAvailable: biometricAvailable,
      contract: contract,
    );
    bool isUsable(MfaMethod? method) =>
        method != null && usable.any((entry) => entry.method == method);

    final once = index < oneOff.length ? oneOff[index] : null;
    if (isUsable(once)) return once;
    final stored = index < saved.length ? saved[index] : null;
    if (isUsable(stored)) return stored;
    return usable.firstOrNull?.method;
  }, growable: false);
}

/// Resolves a retry only when refresh kept the contract used for this attempt.
List<MfaMethod>? resolveMfaRetryPlan(
  Location location, {
  required MfaContract attemptContract,
  required MfaContract refreshedContract,
  List<MfaMethod?> oneOff = const [],
  required bool biometricAvailable,
}) {
  if (attemptContract != refreshedContract) return null;
  final plan = resolveMfaStepPlan(
    location,
    oneOff: oneOff,
    biometricAvailable: biometricAvailable,
    contract: refreshedContract,
  );
  if (plan.isEmpty || plan.contains(null)) return null;
  return plan.cast<MfaMethod>();
}

bool hasUnpassableMfaStep(
  Location location, {
  required bool biometricAvailable,
  MfaContract contract = MfaContract.legacy,
}) {
  final steps = effectiveMfaSteps(location);
  return (contract == MfaContract.legacy && steps.length > 1) ||
      steps.any(
        (step) => usableMfaMethods(
          step,
          biometricAvailable: biometricAvailable,
          contract: contract,
        ).isEmpty,
      );
}

MfaUnpassableReason? unpassableStepReason(
  Location location, {
  required bool biometricAvailable,
  MfaContract contract = MfaContract.legacy,
}) {
  final steps = effectiveMfaSteps(location);
  if (contract == MfaContract.legacy && steps.length > 1) {
    return MfaUnpassableReason.desktopOnly;
  }
  final step = steps.firstWhereOrNull(
    (step) => usableMfaMethods(
      step,
      biometricAvailable: biometricAvailable,
      contract: contract,
    ).isEmpty,
  );
  if (step == null) return null;

  final states = step.methods
      .map(
        (entry) => mfaMethodAvailability(
          entry,
          biometricAvailable: biometricAvailable,
          contract: contract,
        ),
      )
      .toSet();
  if (states.contains(MfaMethodAvailability.biometryUnavailable)) {
    return MfaUnpassableReason.setUpBiometry;
  }
  if (states.contains(MfaMethodAvailability.notConfigured)) {
    return MfaUnpassableReason.notConfigured;
  }
  return MfaUnpassableReason.desktopOnly;
}

String mfaStepsToText(int count) => '$count-step verification';
