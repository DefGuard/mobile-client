import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_method_api.dart';
import 'package:mobile/logging.dart';

class MfaStepMethod {
  final ApiMfaMethod apiMethod;
  final bool configured;

  const MfaStepMethod({required this.apiMethod, required this.configured});

  MfaStepMethod.supported(MfaMethod method, {this.configured = true})
    : apiMethod = ApiMfaMethod.of(method);

  MfaMethod? get method => apiMethod.supported;

  factory MfaStepMethod.fromJson(Map<String, dynamic> json) => MfaStepMethod(
    apiMethod: ApiMfaMethod.fromWire(json['method'] as int? ?? -1),
    configured: json['configured'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'method': apiMethod.value,
    'configured': configured,
  };

  @override
  bool operator ==(Object other) =>
      other is MfaStepMethod &&
      other.apiMethod == apiMethod &&
      other.configured == configured;

  @override
  int get hashCode => Object.hash(apiMethod, configured);
}

class MfaStep {
  final List<MfaStepMethod> methods;

  const MfaStep(this.methods);

  factory MfaStep.fromJson(Map<String, dynamic> json) => MfaStep(
    ((json['methods'] as List<dynamic>?) ?? const [])
        .map((e) => MfaStepMethod.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'methods': methods.map((m) => m.toJson()).toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is MfaStep && encodeMfaSteps([other]) == encodeMfaSteps([this]);

  @override
  int get hashCode => encodeMfaSteps([this]).hashCode;
}

/// Both sides of every steps comparison come from this encoder, so its output
/// doubles as the canonical form for equality.
String encodeMfaSteps(List<MfaStep> steps) =>
    jsonEncode(steps.map((s) => s.toJson()).toList(growable: false));

List<MfaStep> decodeMfaSteps(String source) {
  try {
    return (jsonDecode(source) as List<dynamic>)
        .map((e) => MfaStep.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  } catch (e) {
    talker.error("Failed to decode stored MFA steps", e);
    return const [];
  }
}

String encodeMfaStepPlan(List<MfaMethod?> plan) =>
    jsonEncode(plan.map((m) => m?.value).toList(growable: false));

List<MfaMethod?> decodeMfaStepPlan(String source) {
  try {
    return (jsonDecode(source) as List<dynamic>)
        .map((e) => e == null ? null : MfaMethod.tryFromValue(e as int))
        .toList(growable: false);
  } catch (e) {
    talker.error("Failed to decode stored MFA step plan", e);
    return const [];
  }
}

/// The single step a pre-2.2 server implies. Deliberately unlike the desktop
/// client, which synthesizes `[totp, email, mobileApprove]`: mobile has to offer
/// exactly what its connect sheet offered before multi-step, or legacy locations
/// change behaviour.
List<MfaStep> legacyMfaSteps(LocationMfaMode? mode, bool? mfaEnabled) {
  if (mode == LocationMfaMode.external) {
    return [
      MfaStep([MfaStepMethod.supported(MfaMethod.openid)]),
    ];
  }
  if (mode != LocationMfaMode.internal && mfaEnabled != true) {
    return const [];
  }
  return [
    MfaStep(
      const [
        MfaMethod.biometric,
        MfaMethod.totp,
        MfaMethod.email,
      ].map(MfaStepMethod.supported).toList(growable: false),
    ),
  ];
}

class MfaStepsConverter extends TypeConverter<List<MfaStep>, String> {
  const MfaStepsConverter();

  @override
  List<MfaStep> fromSql(String fromDb) => decodeMfaSteps(fromDb);

  @override
  String toSql(List<MfaStep> value) => encodeMfaSteps(value);
}

class MfaStepPlanConverter extends TypeConverter<List<MfaMethod?>, String> {
  const MfaStepPlanConverter();

  @override
  List<MfaMethod?> fromSql(String fromDb) => decodeMfaStepPlan(fromDb);

  @override
  String toSql(List<MfaMethod?> value) => encodeMfaStepPlan(value);
}
