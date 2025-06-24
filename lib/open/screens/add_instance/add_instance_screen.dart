import 'package:flutter/material.dart';
import 'package:mobile_client/open/widgets/buttons/dg_button.dart';
import 'package:mobile_client/open/widgets/nav.dart';
import 'package:mobile_client/router/routes.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

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
            Text("Please, enter instance URL", style: DgText.body1),
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
