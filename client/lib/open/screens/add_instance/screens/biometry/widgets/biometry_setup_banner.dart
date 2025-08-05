import 'package:flutter/material.dart';

import '../../../../../widgets/icons/asset_icons_simple.dart';

class BiometrySetupBanner extends StatelessWidget {
  const BiometrySetupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 60,
      children: [DgIconPasskeyFingerprint(), DgIconPasskeyFace()],
    );
  }
}
