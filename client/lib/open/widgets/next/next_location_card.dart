import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

import 'next_main_cta.dart';

class NextLocationCard extends StatelessWidget {
  final Location location;
  final bool isConnected;
  final bool loading;
  final MfaMethod? mfaMethod;
  final RoutingMethod? routingMethod;
  final VoidCallback? onConnectTap;
  final VoidCallback? onDisconnectTap;

  const NextLocationCard({
    super.key,
    required this.location,
    this.isConnected = false,
    this.loading = false,
    this.mfaMethod,
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
        color: NextColor.bgDarkBlue20,
      ),
      padding: const EdgeInsets.all(NextSpacing.md),
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
              const SizedBox(width: NextSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: NextText.bodyXs400.copyWith(
                      color: NextColor.fgWhite70,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: NextSpacing.sm,
                    children: [
                      Text(
                        location.name,
                        style: NextText.bodyPrimary600.copyWith(
                          color: NextColor.fgWhite100,
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
                          style: NextText.bodyXxs600.copyWith(
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
          const SizedBox(height: NextSpacing.md),
          const Divider(height: 1, color: NextColor.bgWhite20),
          const SizedBox(height: NextSpacing.md),
          Row(
            spacing: NextSpacing.md,
            children: [
              Expanded(
                child: routingMethod != null
                    ? _InnerInfoCard(routing: routingMethod)
                    : _InnerInfoCard(mfaMethod: mfaMethod),
              ),
              Expanded(
                child: routingMethod != null
                    ? _InnerInfoCard(mfaMethod: mfaMethod)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: NextSpacing.lg),
          NextMainCta(
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
        color: NextColor.bgDarkBlue20,
      ),
      padding: const EdgeInsets.all(NextSpacing.sm),
      child: Row(
        spacing: NextSpacing.sm,
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
              spacing: NextSpacing.xs,
              children: [
                Text(
                  "Location",
                  style: NextText.bodyXs400.copyWith(
                    color: NextColor.fgWhite40,
                  ),
                ),
                Text(
                  location.name,
                  style: NextText.bodySm500.copyWith(
                    color: NextColor.fgWhite100,
                  ),
                ),
              ],
            ),
          ),
          NextButton(
            text: "Connect",
            onTap: onConnectTap,
            size: NextButtonSize.big,
            style: NextButtonStyle.secondary,
            height: 36,
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Connected', group: 'NextLocationCard')
Widget previewConnected() {
  return NextPreviewWrapper(
    child: NextLocationCard(isConnected: true, location: _mockLocation()),
  );
}

@Preview(name: 'Connected + MFA TOTP', group: 'NextLocationCard')
Widget previewConnectedMfaTotp() {
  return NextPreviewWrapper(
    child: NextLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.totp,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Connected + MFA Biometric', group: 'NextLocationCard')
Widget previewConnectedMfaBiometric() {
  return NextPreviewWrapper(
    child: NextLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.biometric,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Connected + MFA Email', group: 'NextLocationCard')
Widget previewConnectedMfaEmail() {
  return NextPreviewWrapper(
    child: NextLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.email,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Connected + MFA OpenID', group: 'NextLocationCard')
Widget previewConnectedMfaOpenId() {
  return NextPreviewWrapper(
    child: NextLocationCard(
      isConnected: true,
      location: _mockLocation(mfaEnabled: true),
      mfaMethod: MfaMethod.openid,
      routingMethod: RoutingMethod.all,
    ),
  );
}

@Preview(name: 'Not Connected', group: 'NextLocationCard')
Widget previewNotConnected() {
  return NextPreviewWrapper(
    child: NextLocationCard(isConnected: false, location: _mockLocation()),
  );
}

@Preview(name: 'Loading', group: 'NextLocationCard')
Widget previewLoading() {
  return NextPreviewWrapper(
    child: NextLocationCard(
      isConnected: false,
      loading: true,
      location: _mockLocation(),
    ),
  );
}

class _InnerInfoCard extends StatelessWidget {
  final RoutingMethod? routing;
  final MfaMethod? mfaMethod;

  const _InnerInfoCard({this.routing, this.mfaMethod});

  bool get isMfa => mfaMethod != null;
  bool get isRouting => routing != null;
  bool get isEmpty => mfaMethod == null && routing == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: NextSpacing.sm,
        horizontal: NextSpacing.md,
      ),
      decoration: BoxDecoration(
        color: NextColor.bgWhite5,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: NextSpacing.md,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: NextColor.bgWhite10,
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
                style: NextText.bodyXxs400.copyWith(color: NextColor.fgWhite50),
              ),
              Text(
                getText(),
                style: NextText.bodyXs500.copyWith(color: getTextColor()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget getIcon() {
    Color iconColor = NextColor.fgWhite100;
    String iconFileName = "lock_open";
    if (isEmpty) {
      iconFileName = "lock_open";
      iconColor = NextColor.fgWhite60;
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
          iconFileName = "email";
          break;
        case .openid:
          iconFileName = "key";
          break;
        default:
          iconFileName = "mobile_lock";
      }
    }
    return NextIcon(iconFileName, size: 20, color: iconColor);
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
      return mfaMethod?.toUiString() ?? "MFA";
    }
    if (isRouting) {
      return routing?.toUiString() ?? "Traffic";
    }
    return "Not required";
  }

  Color getTextColor() {
    if (isEmpty) {
      return NextColor.fgWhite60;
    }
    return NextColor.fgWhite100;
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
  );
}
