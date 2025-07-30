import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/buttons/dg_text_button.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

SnackBar dgSnackBar({
  required String text,
  // sets default timeout to 1 day
  bool onlyDismiss = false,
  Color textColor = DgColor.textBodyPrimary,
  Duration? customDuration,
  Function()? onDismiss,
}) {
  final bool isDismissable = onDismiss != null;
  Duration? duration = customDuration;
  if (isDismissable && onlyDismiss) {
    duration = Duration(days: 1);
  }
  duration ??= Duration(seconds: 10);

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
                    style: DgText.modal1.copyWith(color: textColor),
                    textAlign: TextAlign.left,
                  ),
                ),
                if (isDismissable)
                  DgTextButton(onTap: onDismiss, text: "Close"),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
