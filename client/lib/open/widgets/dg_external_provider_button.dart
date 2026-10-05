import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

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
    final borderRadius = BorderRadius.circular(100);

    return Container(
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DgColor.bgWhite100,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DgSpacing.lg),
            child: Row(
              spacing: 12,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/next/icons/${provider.colorIcon}.svg",
                  width: 20,
                  height: 20,
                ),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DgText.buttonLabelBig.copyWith(
                      color: DgColor.fgAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
