import 'package:drift/drift.dart' show Value;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/screens/instance/widgets/connect_pane.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_settings_pane.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_unavailable_dialog.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';

const _paneDuration = Duration(milliseconds: 250);
const _paneCurve = Curves.easeOut;

class ConnectDialog extends HookConsumerWidget {
  final DefguardInstance instance;
  final Location location;
  final Future<ConnectResult> Function(
    RoutingMethod traffic,
    List<MfaMethod?> mfaPlan,
  )
  onConnect;

  const ConnectDialog({
    super.key,
    required this.instance,
    required this.location,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricsStatus = ref.watch(biometricsCapabilityProvider);
    final biometricAvailable =
        instance.mfaKeysStored && biometricsStatus.canOpenStorage;
    final steps = effectiveMfaSteps(location);

    final bool canChangeTraffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.none;
    final bool initialAllTraffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.forceAllTraffic ||
        (canChangeTraffic && location.trafficMethod == RoutingMethod.all);

    final allTraffic = useState(initialAllTraffic);
    final isLoading = useState(false);
    final savedPlan = useState<List<MfaMethod?>>(location.mfaStepPlan);
    final selection = useState<MfaMethod?>(null);

    final plan = useMemoized(
      () => resolveMfaStepPlan(
        location.copyWith(mfaStepPlan: savedPlan.value),
        oneOff: selection.value == null ? const [] : [selection.value],
        biometricAvailable: biometricAvailable,
      ),
      [location, savedPlan.value, selection.value, biometricAvailable],
    );

    final unpassable = plan.contains(null);
    final canEditDefaults =
        steps.length > 1 &&
        steps.any(
          (step) =>
              usableMfaMethods(
                step,
                biometricAvailable: biometricAvailable,
              ).length >
              1,
        );

    List<MfaMethod?> mfaDefaults(List<MfaMethod?> saved) => resolveMfaStepPlan(
      location.copyWith(mfaStepPlan: saved),
      biometricAvailable: biometricAvailable,
    );

    final showingMfa = useState(false);
    final paneController = useAnimationController(duration: _paneDuration);
    final mfaWorking = useState<List<MfaMethod?>>(mfaDefaults(savedPlan.value));
    final isSaving = useState(false);

    void openMfaSettings() {
      mfaWorking.value = mfaDefaults(savedPlan.value);
      showingMfa.value = true;
      paneController.forward();
    }

    void closeMfaSettings() {
      showingMfa.value = false;
      paneController.reverse();
    }

    Future<void> saveMfaPlan() async {
      isSaving.value = true;
      final db = ref.read(databaseProvider);
      final edited = mfaWorking.value;
      try {
        await (db.update(db.locations)..where((t) => t.id.equals(location.id)))
            .write(LocationsCompanion(mfaStepPlan: Value(edited)));
        savedPlan.value = edited;
        isSaving.value = false;
        closeMfaSettings();
      } catch (e) {
        ref
            .read(toastManagerProvider.notifier)
            .showError(
              message: "Failed to save the MFA settings.",
              logMessage:
                  "Failed to write mfaStepPlan for location ${location.id}",
              error: e,
            );
        isSaving.value = false;
      }
    }

    Future<void> connect() async {
      isLoading.value = true;
      try {
        final traffic = allTraffic.value
            ? RoutingMethod.all
            : RoutingMethod.predefined;

        final result = await onConnect(traffic, plan);
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      } finally {
        isLoading.value = false;
      }
    }

    final connectPane = ConnectPane(
      locationName: location.name,
      steps: steps,
      plan: plan,
      savedPlan: savedPlan.value,
      biometricAvailable: biometricAvailable,
      allTraffic: allTraffic.value,
      canChangeTraffic: canChangeTraffic,
      isLoading: isLoading.value,
      canEditDefaults: canEditDefaults,
      onToggleTraffic: () => allTraffic.value = !allTraffic.value,
      onMethodSelected: (method) => selection.value = method,
      onConnectTap: unpassable
          ? () => showMfaUnavailableDialog(
              context,
              reason: unpassableStepReason(
                location,
                biometricAvailable: biometricAvailable,
              ),
              instanceId: instance.id,
            )
          : connect,
      onOpenMfaSettings: openMfaSettings,
    );

    if (!canEditDefaults) return connectPane;

    return PopScope(
      canPop: !showingMfa.value,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) closeMfaSettings();
      },
      child: _PaneSwitcher(
        animation: paneController,
        showingSecond: showingMfa.value,
        first: connectPane,
        second: MfaSettingsPane(
          steps: steps,
          working: mfaWorking.value,
          savedPlan: savedPlan.value,
          biometricAvailable: biometricAvailable,
          isSaving: isSaving.value,
          onSelected: (index, method) {
            final next = [...mfaWorking.value];
            next[index] = method;
            mfaWorking.value = next;
          },
          onBack: closeMfaSettings,
          onSave: saveMfaPlan,
        ),
      ),
    );
  }
}

class _PaneSwitcher extends StatelessWidget {
  final Animation<double> animation;
  final bool showingSecond;
  final Widget first;
  final Widget second;

  const _PaneSwitcher({
    required this.animation,
    required this.showingSecond,
    required this.first,
    required this.second,
  });

  Widget _pane({
    required Offset offset,
    required bool inactive,
    required Widget child,
  }) {
    final shifted = FractionalTranslation(
      translation: offset,
      child: ExcludeSemantics(
        excluding: inactive,
        child: IgnorePointer(ignoring: inactive, child: child),
      ),
    );

    return inactive
        ? Positioned(top: 0, left: 0, right: 0, child: shifted)
        : shifted;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: _paneDuration,
        curve: _paneCurve,
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = _paneCurve.transform(animation.value);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _pane(
                  offset: Offset(-t, 0),
                  inactive: showingSecond,
                  child: first,
                ),
                _pane(
                  offset: Offset(1 - t, 0),
                  inactive: !showingSecond,
                  child: second,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
