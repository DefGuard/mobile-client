import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_checkbox.dart';
import 'package:mobile/open/widgets/dg_dialog.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_radio_box.dart';
import 'package:mobile/open/widgets/dg_separator.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../../../logging.dart';

enum MfaMethodDialogIntention { connect, save }

class MfaMethodDialog extends HookConsumerWidget {
  final Location location;
  final MfaMethodDialogIntention intention;

  const MfaMethodDialog({
    super.key,
    required this.location,
    required this.intention,
  });

  String _getSubmitText() {
    switch (intention) {
      case MfaMethodDialogIntention.save:
        return "Save";
      case MfaMethodDialogIntention.connect:
        return "Connect";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final selectedMethod = useState(location.mfaMethod ?? MfaMethod.email);
    final shouldRemember = useState(true);
    final isLoading = useState(false);

    final remember = useCallback((MfaMethod method) async {
      try {
        final toUpdate = await db.managers.locations
            .filter((row) => row.id.equals(location.id))
            .getSingle();
        await db.managers.locations.replace(
          toUpdate.copyWith(mfaMethod: drift.Value(method)),
        );
      } catch (e) {
        talker.error(
          "Failed to remember mfa choice for location ${location.id}",
          e,
        );
      }
    }, [db]);

    return DgDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              "Choose MFA Method",
              style: DgText.sideBar,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8),
          DgMessageBox(
            text:
                "This location requires 2FA to connect. Please select your preferred option.",
            variant: DgMessageBoxVariant.info,
          ),
          SizedBox(height: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: DgSpacing.s,
            children: [
              DgRadioBox(
                text: "Email",
                active: selectedMethod.value == MfaMethod.email,
                onTap: () {
                  selectedMethod.value = MfaMethod.email;
                },
              ),
              DgRadioBox(
                text: "Authenticator App",
                active: selectedMethod.value == MfaMethod.totp,
                onTap: () {
                  selectedMethod.value = MfaMethod.totp;
                },
              ),
              DgRadioBox(
                text: "Biometric",
                active: selectedMethod.value == MfaMethod.biometric,
                onTap: () {
                  selectedMethod.value = MfaMethod.biometric;
                },
              ),
              DgSeparator(),
              if (intention != MfaMethodDialogIntention.save)
                DgCheckbox(
                  text: "Remember my choice",
                  checked: shouldRemember.value,
                  onTap: () {
                    shouldRemember.value = !shouldRemember.value;
                  },
                ),
              Padding(
                padding: EdgeInsetsGeometry.all(DgSpacing.s),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DgButton(
                      text: "Cancel",
                      size: DgButtonSize.standard,
                      minWidth: 70,
                      disabled: isLoading.value,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    DgButton(
                      text: _getSubmitText(),
                      size: DgButtonSize.standard,
                      minWidth: 70,
                      variant: DgButtonVariant.primary,
                      loading: isLoading.value,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        if (shouldRemember.value) {
                          isLoading.value = true;
                          await remember(selectedMethod.value);
                          isLoading.value = false;
                        }
                        navigator.pop(selectedMethod.value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
