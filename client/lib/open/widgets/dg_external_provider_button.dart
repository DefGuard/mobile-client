import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/theme/spacing.dart';

class DgExternalProviderButton extends StatelessWidget {
  final String text;
  final OpenIdProvider provider;
  final VoidCallback onTap;

  const DgExternalProviderButton({
    super.key,
    required this.text,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DgButton(
      text: text,
      width: double.infinity,
      spacing: DgSpacing.md,
      maxLines: 1,
      baseTextStyle: Theme.of(context).textTheme.bodyMedium,
      icon: SvgPicture.asset(
        "assets/next/icons/${provider.colorIcon}.svg",
        width: 20,
        height: 20,
      ),
      onTap: onTap,
    );
  }
}
