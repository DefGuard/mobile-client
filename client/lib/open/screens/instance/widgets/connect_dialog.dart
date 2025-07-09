import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_radio_box.dart';
import 'package:mobile/open/widgets/dg_separator.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../widgets/icons/asset_icons_simple.dart';

final String _predefinedMessage =
    "Only send selected traffic (e.g., company services or internal apps) through the VPN. Faster for general browsing. Ideal for hybrid work.";

final String _allMessage =
    "Route all your internet traffic through the VPN. Full encryption and privacy. Ideal for public networks.";

class ConnectDialog extends HookConsumerWidget {

  const ConnectDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionType = useState<TunnelTraffic>(TunnelTraffic.predefined);

    return Dialog(
      backgroundColor: DgColor.defaultModal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: DgSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text("Choose traffic Routing", style: DgText.sideBar),
            ),
            SizedBox(height: 8),
            Column(
              spacing: DgSpacing.s,
              children: [
                DgRadioBox(
                  text: "Predefined Traffic",
                  active: connectionType.value == TunnelTraffic.predefined,
                  onTap: () {
                    connectionType.value = TunnelTraffic.predefined;
                  },
                ),
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _predefinedMessage,
                ),
                DgSeparator(),
                DgRadioBox(
                  text: "All Traffic",
                  active: connectionType.value == TunnelTraffic.all,
                  onTap: () {
                    connectionType.value = TunnelTraffic.all;
                  },
                ),
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _allMessage,
                ),
                DgSeparator(),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DgButton(
                      text: "Cancel",
                      variant: DgButtonVariant.secondary,
                      size: DgButtonSize.standard,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    DgButton(
                      text: "Connect",
                      variant: DgButtonVariant.primary,
                      size: DgButtonSize.standard,
                      icon: DgIconCheckmark(),
                      onTap: () {
                        Navigator.of(context).pop(connectionType.value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
