import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_toggle.dart';
import 'package:mobile/open/widgets/next_mfa_selector.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

class NextConnectDialog extends HookConsumerWidget {
  final DefguardInstance instance;
  final Location location;
  final Future<void> Function(RoutingMethod traffic, MfaMethod? mfa) onConnect;

  const NextConnectDialog({
    super.key,
    required this.instance,
    required this.location,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricsStatus = ref.watch(biometricsCapabilityProvider);
    // must stay the same predicate TunnelService branches on, otherwise the
    // sheet offers a factor the connect flow never asks for
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
      // if (instance.mfaKeysStored && biometricsStatus.canOpenStorage) {
      //   methods.insert(0, MfaMethod.biometric);
      // }
      return methods;
    }, [instance, location, biometricsStatus]);

    final selectedMfaMethod = useState<MfaMethod>(
      location.mfaMethod ?? availableMfaMethods.first,
    );

    final mfaController = useMemoized(() => ExpansibleController(), []);
    useEffect(() => mfaController.dispose, [mfaController]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Connect ${location.name} location",
          style: NextText.bodyPrimary600.copyWith(color: NextColor.fgWhite100),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 16),
          child: Divider(height: 1, color: NextColor.bgWhite10),
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
                  style: NextText.bodySm400.copyWith(
                    color: NextColor.fgWhite100,
                  ),
                ),
                NextToggle(value: allTraffic.value),
              ],
            ),
          ),
        ),
        if (isMfaEnabled) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: NextColor.bgWhite10, height: 1),
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
              onTap: () => mfaController.toggle(),
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
                        color: NextColor.bgWhite100,
                      ),
                      child: Text(
                        "MFA",
                        style: NextText.bodyXs500.copyWith(
                          color: const Color(0xff061a74),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedMfaMethod.value.toUiString(
                          openidDisplayName: instance.openidDisplayName,
                        ),
                        style: NextText.bodySm400.copyWith(
                          color: NextColor.fgWhite100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    NextIcon(
                      "arrow_small",
                      size: 20,
                      color: NextColor.fgWhite100,
                      rotation: animation.value * (math.pi / 2),
                    ),
                  ],
                ),
              ),
            ),
            bodyBuilder: (context, animation) => Padding(
              padding: const EdgeInsets.only(top: NextSpacing.md),
              child: Column(
                spacing: NextSpacing.md,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: availableMfaMethods
                    .map(
                      (method) => NextMfaSelector(
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
          padding: EdgeInsets.symmetric(vertical: NextSpacing.xl2),
          child: Divider(height: 1, color: NextColor.bgWhite10),
        ),
        NextButton(
          text: "Connect VPN",
          size: NextButtonSize.big,
          style: NextButtonStyle.primary,
          loading: isLoading.value,
          onTap: () async {
            isLoading.value = true;
            try {
              final traffic = allTraffic.value
                  ? RoutingMethod.all
                  : RoutingMethod.predefined;
              final mfa = isMfaEnabled ? selectedMfaMethod.value : null;

              await onConnect(traffic, mfa);
              if (context.mounted) {
                Navigator.of(context).pop();
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
