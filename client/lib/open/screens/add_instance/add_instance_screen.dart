import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/nav.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../widgets/icons/asset_icons_simple.dart';

class AddInstanceScreen extends StatelessWidget {
  const AddInstanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DgAppBar(title: "Add Instance"),
      drawer: DgDrawer(),
      body: Container(
        padding: EdgeInsets.all(DgSpacing.s),
        color: DgColor.frameBg,
        child: Column(
          children: [
            SizedBox(height: 120),
            Text(
              "Please, scan QR Code to add instance",
              style: DgText.body1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DgSpacing.l),
            DgMessageBox(
              variant: DgMessageBoxVariant.info,
              width: double.infinity,
              text:
                  "To activate this device, you need to add your Defguard instance. You can Add a new device  in your Defguard profile, or, if you are completing the enrollment process, the instance details should already be displayed.",
            ),
            SizedBox(height: DgSpacing.l),
            DgButton(
              text: "Scan QR Code",
              variant: DgButtonVariant.primary,
              size: DgButtonSize.big,
              width: double.infinity,
              icon: DgIconQr(),
              onTap: () {
                ScanInstanceQrRoute().go(context);
              },
            ),
            SizedBox(height: DgSpacing.m),
            Center(child: Text("or", style: DgText.sideBar)),
            SizedBox(height: DgSpacing.m),
            DgButton(
              text: "Add instance Manually",
              variant: DgButtonVariant.secondary,
              size: DgButtonSize.big,
              width: double.infinity,
              onTap: () {
                AddInstanceFormScreenRoute().go(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
