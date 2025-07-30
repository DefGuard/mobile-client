import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/buttons/dg_text_button.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

SnackBar dgSnackBar({
  required String text,
  bool dismissable = false,
  Duration? customDuration,
  Function()? onDismiss,
}) {
  var duration = customDuration;
  if (!dismissable && onDismiss != null) {
    dismissable = true;
  }
  if (dismissable && onDismiss != null && customDuration == null) {
    duration = Duration(days: 1);
  }
  duration ??= Duration(seconds: 20);

  return SnackBar(
    elevation: 0,
    duration: duration,
    backgroundColor: Colors.transparent,
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsetsGeometry.zero,
    margin: EdgeInsetsGeometry.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(width: 0, color: Colors.transparent),
    ),
    content: Padding(
      padding: EdgeInsetsGeometry.directional(
        bottom: DgSpacing.s,
        start: DgSpacing.xs,
        end: DgSpacing.xs,
      ),
      child: Material(
        color: DgColor.navBg,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: DgSpacing.xs,
            horizontal: DgSpacing.xs,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              spacing: DgSpacing.xs,
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: DgText.modal1,
                    textAlign: TextAlign.left,
                  ),
                ),
                if (dismissable && onDismiss != null)
                  DgTextButton(onTap: onDismiss ?? () {}, text: "Close"),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
