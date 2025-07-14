import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_checkbox.dart';
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

enum RoutingMethodDialogIntention { connect, save, next }

class RoutingMethodDialog extends HookConsumerWidget {
  final Location location;
  final RoutingMethodDialogIntention intention;

  const RoutingMethodDialog({
    super.key,
    required this.location,
    required this.intention,
  });

  String _getSubmitText() {
    switch (intention) {
      case RoutingMethodDialogIntention.connect:
        return "Connect";
      case RoutingMethodDialogIntention.next:
        return "Next";
      case RoutingMethodDialogIntention.save:
        return "Save";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final connectionType = useState<RoutingMethod>(location.trafficMethod ?? RoutingMethod.predefined);
    final shouldRemember = useState(true);
    final isLoading = useState(false);

    final remember = useCallback<Future<void> Function(RoutingMethod traffic)>((
      RoutingMethod traffic,
    ) async {
      final dbLocation = await db.managers.locations
          .filter((row) => row.id.equals(location.id))
          .getSingleOrNull();
      if (dbLocation != null) {
        final updated = dbLocation.copyWith(
          trafficMethod: drift.Value(traffic),
        );
        try {
          await db.managers.locations.replace(updated);
        } catch (e) {
          talker.error("Location update failed", e);
        }
      } else {
        talker.error(
          "Failed to save preferred traffic for location ${location.name} (${location.id}) - Location not found in db",
        );
      }
    }, [db]);

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
                  active: connectionType.value == RoutingMethod.predefined,
                  onTap: () {
                    connectionType.value = RoutingMethod.predefined;
                  },
                ),
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _predefinedMessage,
                ),
                DgSeparator(),
                DgRadioBox(
                  text: "All Traffic",
                  active: connectionType.value == RoutingMethod.all,
                  onTap: () {
                    connectionType.value = RoutingMethod.all;
                  },
                ),
                DgMessageBox(
                  variant: DgMessageBoxVariant.infoOutlined,
                  text: _allMessage,
                ),
                DgSeparator(),
                if (intention != RoutingMethodDialogIntention.save)
                  DgCheckbox(
                    text: "Remember my choice",
                    checked: shouldRemember.value,
                    onTap: () {
                      shouldRemember.value = !shouldRemember.value;
                    },
                  ),
                if (intention != RoutingMethodDialogIntention.save)
                  SizedBox(height: DgSpacing.s),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DgButton(
                      text: "Cancel",
                      variant: DgButtonVariant.secondary,
                      size: DgButtonSize.standard,
                      minWidth: 70,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    DgButton(
                      text: _getSubmitText(),
                      variant: DgButtonVariant.primary,
                      size: DgButtonSize.standard,
                      minWidth: 70,
                      loading: isLoading.value,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        if (shouldRemember.value) {
                          isLoading.value = true;
                          await remember(connectionType.value);
                          isLoading.value = false;
                        }
                        navigator.pop(connectionType.value);
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
