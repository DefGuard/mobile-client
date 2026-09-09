import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import 'dg_main_cta.dart';

class DgLocationCard extends StatelessWidget {
  final Location location;
  final bool isConnected;
  final bool loading;
  final MfaMethod? mfaMethod;

  /// Replaces the method name, for a flow no single method describes.
  final String? mfaLabel;
  final RoutingMethod? routingMethod;
  final VoidCallback? onConnectTap;
  final VoidCallback? onDisconnectTap;

  const DgLocationCard({
    super.key,
    required this.location,
    this.isConnected = false,
    this.loading = false,
    this.mfaMethod,
    this.mfaLabel,
    this.routingMethod,
    this.onConnectTap,
    this.onDisconnectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      return _buildConnectedLayout(context);
    } else {
      return _buildNotConnectedLayout(context);
    }
  }

  Widget _buildConnectedLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: DgColor.bgDarkBlue20,
      ),
      padding: const EdgeInsets.all(DgSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/next/img/location_connected_globe.png",
                width: 40,
                height: 40,
                semanticLabel: "Connected location globe",
              ),
              const SizedBox(width: DgSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: DgText.bodyXs400.copyWith(
                      color: DgColor.fgWhite70,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: DgSpacing.sm,
                    children: [
                      Text(
                        location.name,
                        style: DgText.bodyPrimary600.copyWith(
                          color: DgColor.fgWhite100,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 1,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF74FFB8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Online",
                          style: DgText.bodyXxs600.copyWith(
                            color: const Color(0xFF2F50C2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DgSpacing.md),
          const Divider(height: 1, color: DgColor.bgWhite20),
          const SizedBox(height: DgSpacing.md),
          Row(
            spacing: DgSpacing.md,
            children: [
              Expanded(
                child: routingMethod != null
                    ? _InnerInfoCard(routing: routingMethod)
                    : _InnerInfoCard(
                        mfaMethod: mfaMethod,
                        mfaLabel: mfaLabel,
                      ),
              ),
              Expanded(
                child: routingMethod != null
                    ? _InnerInfoCard(mfaMethod: mfaMethod, mfaLabel: mfaLabel)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: DgSpacing.lg),
          DgMainCta(
            text: "Disconnect",
            connected: false,
            onTap: onDisconnectTap,
          ),
        ],
      ),
    );
  }

  Widget _buildNotConnectedLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: DgColor.bgDarkBlue20,
      ),
      padding: const EdgeInsets.fromLTRB(
        DgSpacing.sm,
        DgSpacing.sm,
        DgSpacing.md,
        DgSpacing.sm,
      ),
      child: Row(
        spacing: DgSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(
              "assets/next/img/location_avatar.png",
              width: 48,
              height: 48,
              fit: BoxFit.fill,
              semanticLabel: "Location avatar",
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: DgSpacing.xs,
              children: [
                Text(
                  "Location",
                  style: DgText.bodyXs400.copyWith(
                    color: DgColor.fgWhite40,
                  ),
                ),
                Text(
                  location.name,
                  style: DgText.bodySm500.copyWith(
                    color: DgColor.fgWhite100,
                  ),
                ),
              ],
            ),
          ),
          DgButton(
            text: "Connect",
            onTap: onConnectTap,
            loading: loading,
            size: DgButtonSize.big,
            style: DgButtonStyle.secondary,
            height: 36,
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Connected', group: 'DgLocationCard')
Widget previewConnected() {
  return DgPreviewWrapper(
    child: DgLocationCard(isConnected: true, location: _mockLocation()),
  );
}

@Preview(name: 'Connected + MFA TOTP', group: 'DgLocationCard')
Widget previewConnectedMfaTotp() {
  return DgPreviewWrapper(
    child: DgLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.totp,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Connected + MFA Biometric', group: 'DgLocationCard')
Widget previewConnectedMfaBiometric() {
  return DgPreviewWrapper(
    child: DgLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.biometric,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Connected + MFA Email', group: 'DgLocationCard')
Widget previewConnectedMfaEmail() {
  return DgPreviewWrapper(
    child: DgLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.email,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Connected + MFA OpenID', group: 'DgLocationCard')
Widget previewConnectedMfaOpenId() {
  return DgPreviewWrapper(
    child: DgLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.openid,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Not Connected', group: 'DgLocationCard')
Widget previewNotConnected() {
  return DgPreviewWrapper(
    child: DgLocationCard(isConnected: false, location: _mockLocation()),
  );
}

@Preview(name: 'Loading', group: 'DgLocationCard')
Widget previewLoading() {
  return DgPreviewWrapper(
    child: DgLocationCard(
      isConnected: false,
      loading: true,
      location: _mockLocation(),
    ),
  );
}

class _InnerInfoCard extends StatelessWidget {
  final RoutingMethod? routing;
  final MfaMethod? mfaMethod;
  final String? mfaLabel;

  const _InnerInfoCard({this.routing, this.mfaMethod, this.mfaLabel});

  bool get isMfa => mfaMethod != null || mfaLabel != null;
  bool get isRouting => routing != null;
  bool get isEmpty => !isMfa && routing == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DgSpacing.sm,
        horizontal: DgSpacing.md,
      ),
      decoration: BoxDecoration(
        color: DgColor.bgWhite5,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: DgSpacing.md,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: DgColor.bgWhite10,
            ),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: getIcon(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                getLabel(),
                style: DgText.bodyXxs400.copyWith(color: DgColor.fgWhite50),
              ),
              Text(
                getText(),
                style: DgText.bodyXs500.copyWith(color: getTextColor()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget getIcon() {
    Color iconColor = DgColor.fgWhite100;
    String iconFileName = "lock_open";
    if (isEmpty) {
      iconFileName = "lock_open";
      iconColor = DgColor.fgWhite60;
    } else if (isRouting) {
      iconFileName = "globe";
    } else if (isMfa) {
      switch (mfaMethod) {
        case .totp:
          iconFileName = "mobile_lock";
          break;
        case .biometric:
          iconFileName = "biometric";
          break;
        case .email:
          iconFileName = "mail";
          break;
        case null:
          iconFileName = "mobile_lock";
          break;
        case .openid:
          iconFileName = "key";
          break;
      }
    }
    return DgIcon(iconFileName, size: 20, color: iconColor);
  }

  String getLabel() {
    if (isMfa) {
      return "MFA";
    }
    if (isRouting) {
      return "Traffic";
    }
    return "MFA";
  }

  String getText() {
    if (isMfa) {
      return mfaLabel ?? mfaMethod?.toUiString() ?? "MFA";
    }
    if (isRouting) {
      return routing?.toUiString() ?? "Traffic";
    }
    return "Not required";
  }

  Color getTextColor() {
    if (isEmpty) {
      return DgColor.fgWhite60;
    }
    return DgColor.fgWhite100;
  }
}

Location _mockLocation({bool mfaEnabled = false}) {
  return Location(
    id: 1,
    instance: 1,
    networkId: 1,
    name: 'Warsaw Office',
    address: '10.0.0.1/24',
    pubKey: 'pubkey',
    endpoint: 'vpn.example.com:51820',
    allowedIps: '0.0.0.0/0',
    keepAliveInterval: 25,
    mfaEnabled: mfaEnabled,
    locationMfaMode: mfaEnabled
        ? LocationMfaMode.internal
        : LocationMfaMode.unspecified,
    mfaSteps: const [],
    mfaStepPlan: const [],
  );
}
