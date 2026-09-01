import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/open/widgets/next/next_preview_wrapper.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

import 'icons/next_icon.dart';

class NextInstanceCard extends StatelessWidget {
  final int locationsCount;
  final int connectedCount;
  final String name;
  final VoidCallback? onTap;

  const NextInstanceCard({
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
          color: NextColor.bgDarkBlue20,
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
                color: isConnected
                    ? NextColor.bgWhite100
                    : NextColor.bgDarkBlue20,
              ),
              child: NextIcon(
                icon,
                size: 24,
                color: isConnected ? NextColor.fgAction : NextColor.fgWhite60,
              ),
            ),
            SizedBox(width: NextSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    name,
                    style: NextText.bodyPrimary600.copyWith(
                      color: NextColor.fgWhite100,
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
                          style: NextText.bodyXs400.copyWith(
                            color: NextColor.fgWhite60,
                          ),
                        ),
                      if (locationsCount > 0)
                        Text(
                          "$locationsCount locations",
                          style: NextText.bodyXs400.copyWith(
                            color: NextColor.fgWhite60,
                          ),
                        ),
                      if (connectedCount > 0) ...[
                        Text(
                          "•",
                          style: NextText.bodyXs400.copyWith(
                            color: NextColor.fgWhite60,
                          ),
                        ),
                        Text(
                          "$connectedCount online",
                          style: NextText.bodyXs400.copyWith(
                            color: Color(0xff74ffb8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: NextSpacing.sm),
            NextIcon(
              "arrow_small",
              direction: .right,
              color: NextColor.fgWhite60,
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Connected', group: 'NextInstanceCard')
Widget previewConnected() {
  return const NextPreviewWrapper(
    child: NextInstanceCard(
      locationsCount: 5,
      connectedCount: 2,
      name: "Warsaw Office",
    ),
  );
}

@Preview(name: 'Disconnected', group: 'NextInstanceCard')
Widget previewDisconnected() {
  return const NextPreviewWrapper(
    child: NextInstanceCard(
      locationsCount: 3,
      connectedCount: 0,
      name: "Berlin Studio",
    ),
  );
}
