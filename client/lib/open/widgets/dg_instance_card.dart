import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import 'icons/dg_icon.dart';

class DgInstanceCard extends StatelessWidget {
  final int locationsCount;
  final int connectedCount;
  final String name;
  final VoidCallback? onTap;

  const DgInstanceCard({
    super.key,
    required this.locationsCount,
    required this.connectedCount,
    required this.name,
    this.onTap,
  });

  bool get isConnected => connectedCount != 0;
  String get icon => isConnected ? "connected_devices" : "device_ip";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: .directional(start: 8, top: 8, end: 12, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: .circular(20),
          color: DgColor.bgDarkBlue20,
        ),
        child: Row(
          crossAxisAlignment: .center,
          mainAxisAlignment: .start,
          children: [
            Container(
              height: 48,
              width: 48,
              alignment: .center,
              decoration: BoxDecoration(
                borderRadius: .circular(14),
                color: isConnected ? DgColor.bgWhite100 : DgColor.bgDarkBlue20,
              ),
              child: DgIcon(
                icon,
                size: 24,
                color: isConnected ? DgColor.fgAction : DgColor.fgWhite60,
              ),
            ),
            SizedBox(width: DgSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    name,
                    style: DgText.bodyPrimary600.copyWith(
                      color: DgColor.fgWhite100,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: .center,
                    mainAxisAlignment: .start,
                    spacing: 8,
                    children: [
                      if (locationsCount == 0)
                        Text(
                          "No locations available",
                          style: DgText.bodyXs400.copyWith(
                            color: DgColor.fgWhite60,
                          ),
                        ),
                      if (locationsCount > 0)
                        Text(
                          "$locationsCount locations",
                          style: DgText.bodyXs400.copyWith(
                            color: DgColor.fgWhite60,
                          ),
                        ),
                      if (connectedCount > 0) ...[
                        Text(
                          "•",
                          style: DgText.bodyXs400.copyWith(
                            color: DgColor.fgWhite60,
                          ),
                        ),
                        Text(
                          "$connectedCount online",
                          style: DgText.bodyXs400.copyWith(
                            color: Color(0xff74ffb8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: DgSpacing.sm),
            DgIcon(
              "arrow_small",
              direction: .right,
              color: DgColor.fgWhite60,
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Connected', group: 'DgInstanceCard')
Widget previewConnected() {
  return const DgPreviewWrapper(
    child: DgInstanceCard(
      locationsCount: 5,
      connectedCount: 2,
      name: "Warsaw Office",
    ),
  );
}

@Preview(name: 'Disconnected', group: 'DgInstanceCard')
Widget previewDisconnected() {
  return const DgPreviewWrapper(
    child: DgInstanceCard(
      locationsCount: 3,
      connectedCount: 0,
      name: "Berlin Studio",
    ),
  );
}
