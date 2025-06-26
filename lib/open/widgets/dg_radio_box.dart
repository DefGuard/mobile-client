import 'package:flutter/material.dart';
import 'package:mobile_client/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

class DgRadioBox extends StatelessWidget {
  final String text;
  final bool active;
  final void Function()? onTap;

  const DgRadioBox({
    super.key,
    required this.text,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 48),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.fromBorderSide(
            BorderSide(width: 1, color: DgColor.borderPrimary),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: DgSpacing.xs,
          children: [
            Expanded(
              child: Text(
                text,
                style: DgText.buttonS.copyWith(color: DgColor.textBodyPrimary),
              ),
            ),
            active ? DgIconRadioActive() : DgIconRadio(),
          ],
        ),
      ),
    );
  }
}
