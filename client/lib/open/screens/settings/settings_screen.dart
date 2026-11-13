import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/app_settings.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_toggle.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _toggleLabel = 'Exclude Android Auto from VPN';
  static const _description =
      'Allows Android Auto traffic to bypass the VPN tunnel, preventing connectivity issues with Android Auto. Other apps keep using the VPN as configured. Changes take effect the next time you connect.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(excludeAndroidAutoProvider);
    final settingState = setting.value;
    final value = settingState?.value;
    final isLoading = setting.isLoading || (settingState?.isSaving ?? false);
    final hasError = setting.hasError || settingState?.error != null;

    void setValue(bool value) {
      ref
          .read(excludeAndroidAutoProvider.notifier)
          .setExcludeAndroidAuto(value);
    }

    return Container(
      decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DgAppBar(
          context: context,
          title: 'Settings',
          actionLeft: DgIconButton(
            icon: 'arrow_big',
            direction: DgIconDirection.left,
            onTap: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DgSpacing.xl),
            child: Container(
              decoration: BoxDecoration(
                color: DgColor.bgWhite5,
                border: Border.all(color: DgColor.bgWhite10),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(DgSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DgIcon(
                        'android_auto',
                        size: 20,
                        color: DgColor.fgWhite100,
                      ),
                      const SizedBox(width: DgSpacing.md),
                      Expanded(
                        child: Text(
                          _toggleLabel,
                          style: DgText.bodySm500.copyWith(
                            color: DgColor.fgWhite100,
                          ),
                        ),
                      ),
                      if (value == null)
                        SizedBox(
                          width: 64,
                          height: 28,
                          child: isLoading
                              ? Center(
                                  child: SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DgColor.fgWhite100,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        )
                      else
                        Semantics(
                          label: _toggleLabel,
                          toggled: value,
                          enabled: !isLoading,
                          onTap: isLoading ? null : () => setValue(!value),
                          child: ExcludeSemantics(
                            child: DgToggle(
                              value: value,
                              onTap: isLoading ? null : setValue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DgSpacing.lg),
                  Text(
                    _description,
                    style: DgText.bodyXs400.copyWith(
                      color: DgColor.fgWhite60,
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: DgSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            value != null
                                ? 'Could not save this setting. The previous value is still active.'
                                : 'Could not load this setting.',
                            style: DgText.bodyXs400.copyWith(
                              color: DgColor.fgWhite60,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(excludeAndroidAutoProvider.notifier)
                              .retry(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
