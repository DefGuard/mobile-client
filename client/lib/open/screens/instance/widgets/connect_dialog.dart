import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_toggle.dart';
import 'package:mobile/open/widgets/dg_mfa_selector.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class ConnectDialog extends HookConsumerWidget {
  final DefguardInstance instance;
  final Location location;
  final Future<ConnectResult> Function(RoutingMethod traffic, MfaMethod? mfa)
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
    final isMfaEnabled = TunnelService.checkMfaEnabled(location);

    final bool canChangeTraffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.none;
    final bool initialAllTraffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.forceAllTraffic ||
        (canChangeTraffic && location.trafficMethod == RoutingMethod.all);

    final allTraffic = useState(initialAllTraffic);
    final isLoading = useState(false);

    final availableMfaMethods = useMemoized(() {
      if (location.locationMfaMode == LocationMfaMode.external) {
        return [MfaMethod.openid];
      }
      final methods = [MfaMethod.totp, MfaMethod.email];
      if (instance.mfaKeysStored && biometricsStatus.canOpenStorage) {
        methods.insert(0, MfaMethod.biometric);
      }
      return methods;
    }, [instance, location, biometricsStatus]);

    // The remembered choice on the location row can have gone stale - the
    // device lost its strong biometry, or the admin flipped the location
    // between internal and external MFA. Fall back to the first offered
    // method rather than pre-selecting something the list does not offer.
    final selectedMfaMethod = useState<MfaMethod>(
      availableMfaMethods.contains(location.mfaMethod)
          ? location.mfaMethod!
          : availableMfaMethods.first,
    );

    // ...and re-clamp if the offer shrinks while the sheet is open, e.g. the
    // user backgrounds the app and unenrolls their fingerprint.
    useEffect(() {
      if (!availableMfaMethods.contains(selectedMfaMethod.value)) {
        selectedMfaMethod.value = availableMfaMethods.first;
      }
      return null;
    }, [availableMfaMethods]);

    final mfaController = useMemoized(() => ExpansibleController(), []);
    useEffect(() => mfaController.dispose, [mfaController]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Connect ${location.name} location",
          style: DgText.bodyPrimary600.copyWith(color: DgColor.fgWhite100),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 16),
          child: Divider(height: 1, color: DgColor.bgWhite10),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canChangeTraffic
              ? () => allTraffic.value = !allTraffic.value
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  allTraffic.value ? "All traffic" : "Predefined traffic only",
                  style: DgText.bodySm400.copyWith(
                    color: DgColor.fgWhite100,
                  ),
                ),
                DgToggle(value: allTraffic.value),
              ],
            ),
          ),
        ),
        if (isMfaEnabled) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: DgColor.bgWhite10, height: 1),
          ),
          Expansible(
            controller: mfaController,
            expansibleBuilder: (context, header, body, animation) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, body],
            ),
            headerBuilder: (context, animation) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: availableMfaMethods.length > 1
                  ? () => mfaController.toggle()
                  : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: DgColor.bgWhite100,
                      ),
                      child: Text(
                        "MFA",
                        style: DgText.bodyXs500.copyWith(
                          color: const Color(0xff061a74),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedMfaMethod.value.toUiString(),
                        style: DgText.bodySm400.copyWith(
                          color: DgColor.fgWhite100,
                        ),
                      ),
                    ),
                    if (availableMfaMethods.length > 1) ...[
                      const SizedBox(width: 4),
                      DgIcon(
                        "arrow_small",
                        size: 20,
                        color: DgColor.fgWhite100,
                        rotation: animation.value * (math.pi / 2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            bodyBuilder: (context, animation) => Padding(
              padding: const EdgeInsets.only(top: DgSpacing.md),
              child: Column(
                spacing: DgSpacing.md,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: availableMfaMethods
                    .map(
                      (method) => DgMfaSelector(
                        active: selectedMfaMethod.value == method,
                        factor: method,
                        onTap: () {
                          selectedMfaMethod.value = method;
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: DgSpacing.xl2),
          child: Divider(height: 1, color: DgColor.bgWhite10),
        ),
        DgButton(
          text: "Connect VPN",
          size: DgButtonSize.big,
          style: DgButtonStyle.primary,
          loading: isLoading.value,
          onTap: () async {
            isLoading.value = true;
            try {
              final traffic = allTraffic.value
                  ? RoutingMethod.all
                  : RoutingMethod.predefined;
              final mfa = isMfaEnabled ? selectedMfaMethod.value : null;

              final result = await onConnect(traffic, mfa);
              if (context.mounted) {
                Navigator.of(context).pop(result);
              }
            } finally {
              isLoading.value = false;
            }
          },
        ),
      ],
    );
  }
}
