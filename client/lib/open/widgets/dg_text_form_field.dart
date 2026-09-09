import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/open/widgets/dg_preview_wrapper.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

enum DgTextFormFieldSize { primary, big }

class DgTextFormField extends FormField<String> {
  final DgTextFormFieldSize size;
  final String? label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool required;
  final int maxLines;
  final bool disabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? identifier;

  DgTextFormField({
    super.key,
    this.size = DgTextFormFieldSize.primary,
    this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.focusNode,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.maxLines = 1,
    super.validator,
    this.disabled = false,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
    super.onSaved,
    this.identifier,
    String? initialValue,
  }) : assert(
         initialValue == null || controller == null,
         'If controller is specified, initialValue must be null.',
       ),
       super(
         initialValue: controller != null
             ? controller.text
             : (initialValue ?? ''),
         enabled: !disabled,
         builder: (FormFieldState<String> field) {
           return _NextTextFormFieldContent(
             state: field,
             size: size,
             label: label,
             hintText: hintText,
             errorText: errorText,
             controller: controller,
             focusNode: focusNode,
             obscureText: obscureText,
             keyboardType: keyboardType,
             required: required,
             maxLines: maxLines,
             disabled: disabled,
             readOnly: readOnly,
             onChanged: onChanged,
             onFieldSubmitted: onFieldSubmitted,
             identifier: identifier,
           );
         },
       );
}

class _NextTextFormFieldContent extends HookWidget {
  final FormFieldState<String> state;
  final DgTextFormFieldSize size;
  final String? label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool required;
  final int maxLines;
  final bool disabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? identifier;

  const _NextTextFormFieldContent({
    required this.state,
    required this.size,
    this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.focusNode,
    required this.obscureText,
    required this.keyboardType,
    required this.required,
    required this.maxLines,
    required this.disabled,
    required this.readOnly,
    this.onChanged,
    this.onFieldSubmitted,
    this.identifier,
  });

  Widget _withIdentifier(Widget child) {
    if (identifier == null) {
      return child;
    }
    return Semantics(identifier: identifier, container: true, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFocusNode = focusNode ?? useFocusNode();
    final effectiveController =
        controller ?? useTextEditingController(text: state.value ?? '');

    final isFocused = useState(effectiveFocusNode.hasFocus);

    useEffect(() {
      void handleFocusChange() {
        if (isFocused.value != effectiveFocusNode.hasFocus) {
          isFocused.value = effectiveFocusNode.hasFocus;
        }
      }

      effectiveFocusNode.addListener(handleFocusChange);
      return () => effectiveFocusNode.removeListener(handleFocusChange);
    }, [effectiveFocusNode]);

    // Sync controller changes -> FormFieldState
    useEffect(() {
      void handleControllerChange() {
        if (state.value != effectiveController.text) {
          state.didChange(effectiveController.text);
        }
      }

      effectiveController.addListener(handleControllerChange);
      return () => effectiveController.removeListener(handleControllerChange);
    }, [effectiveController, state]);

    // Sync FormFieldState -> controller (e.g. FormState.reset())
    useEffect(() {
      if (effectiveController.text != (state.value ?? '')) {
        effectiveController.text = state.value ?? '';
      }
      return null;
    }, [state.value]);

    final String? effectiveError = disabled
        ? null
        : (errorText ?? state.errorText);
    final bool hasError = effectiveError != null && effectiveError.isNotEmpty;

    final Color borderColor;
    if (disabled) {
      borderColor = DgColor.borderDisabled;
    } else if (hasError) {
      borderColor = DgColor.borderCritical;
    } else if (isFocused.value) {
      borderColor = DgColor.borderEmphasis;
    } else {
      borderColor = DgColor.borderDefault;
    }

    final Color backgroundColor = disabled
        ? DgColor.bgWhite10
        : Colors.transparent;

    final TextStyle baseTextStyle = size == DgTextFormFieldSize.big
        ? DgText.inputBig
        : DgText.inputPrimary;
    final TextStyle inputTextStyle = baseTextStyle.copyWith(
      color: disabled ? DgColor.fgWhite50 : DgColor.fgWhite100,
    );
    final TextStyle hintTextStyle = baseTextStyle.copyWith(
      color: DgColor.fgWhite50,
    );

    final EdgeInsets padding = size == DgTextFormFieldSize.big
        ? const EdgeInsets.symmetric(
            vertical: DgSpacing.sm,
            horizontal: DgSpacing.xl,
          )
        : const EdgeInsets.symmetric(
            vertical: DgSpacing.sm,
            horizontal: DgSpacing.md,
          );

    final BorderRadius borderRadius = size == DgTextFormFieldSize.big
        ? BorderRadius.circular(100)
        : BorderRadius.circular(8);

    final double trackHeight = size == DgTextFormFieldSize.big ? 44.0 : 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (required) ...[
                  Text(
                    '*',
                    style: DgText.inputTitle.copyWith(
                      color: DgColor.fgWhite60,
                    ),
                  ),
                  const SizedBox(width: DgSpacing.xs),
                ],
                Text(
                  label!,
                  style: DgText.inputTitle.copyWith(
                    color: DgColor.fgWhite80,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DgSpacing.xs),
        ],
        GestureDetector(
          onTap: effectiveFocusNode.requestFocus,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: trackHeight,
            alignment: Alignment.centerLeft,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: _withIdentifier(
              TextField(
                controller: effectiveController,
                focusNode: effectiveFocusNode,
                enabled: !disabled,
                readOnly: readOnly,
                obscureText: obscureText,
                keyboardType: keyboardType,
                maxLines: maxLines,
                onChanged: (value) {
                  onChanged?.call(value);
                },
                onSubmitted: onFieldSubmitted,
                style: inputTextStyle,
                cursorColor: DgColor.fgWhite100,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: hintText,
                  hintStyle: hintTextStyle,
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: (hasError)
              ? Padding(
                  padding: const EdgeInsets.only(top: DgSpacing.sm),
                  child: Text(
                    effectiveError,
                    style: DgText.inputError.copyWith(
                      color: DgColor.bgCriticalMuted,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

@Preview(name: 'Default', group: 'Primary')
Widget previewPrimaryDefault() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.primary,
      hintText: 'Enter text...',
    ),
  );
}

@Preview(name: 'With Label & Required', group: 'Primary')
Widget previewPrimaryWithLabel() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.primary,
      label: 'Email address',
      required: true,
      hintText: 'name@example.com',
    ),
  );
}

@Preview(name: 'With Text', group: 'Primary')
Widget previewPrimaryWithText() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.primary,
      label: 'Username',
      controller: TextEditingController(text: 'antigravity_user'),
    ),
  );
}

@Preview(name: 'Disabled', group: 'Primary')
Widget previewPrimaryDisabled() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.primary,
      label: 'Role',
      controller: TextEditingController(text: 'Administrator'),
      disabled: true,
    ),
  );
}

@Preview(name: 'With Error', group: 'Primary')
Widget previewPrimaryWithError() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.primary,
      label: 'Password',
      required: true,
      obscureText: true,
      controller: TextEditingController(text: '123'),
      errorText: 'Password must be at least 8 characters long',
    ),
  );
}

@Preview(name: 'Default', group: 'Big')
Widget previewBigDefault() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.big,
      hintText: 'Search location...',
    ),
  );
}

@Preview(name: 'With Label & Required', group: 'Big')
Widget previewBigWithLabel() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.big,
      label: 'Server Name',
      required: true,
      hintText: 'e.g. US-East-1',
    ),
  );
}

@Preview(name: 'Disabled', group: 'Big')
Widget previewBigDisabled() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.big,
      label: 'Server Name',
      controller: TextEditingController(text: 'Production Server'),
      disabled: true,
    ),
  );
}

@Preview(name: 'With Error', group: 'Big')
Widget previewBigWithError() {
  return DgPreviewWrapper(
    maxWidth: 320,
    child: DgTextFormField(
      size: DgTextFormFieldSize.big,
      label: 'Port',
      required: true,
      controller: TextEditingController(text: '99999'),
      errorText: 'Port number must be between 1 and 65535',
    ),
  );
}
