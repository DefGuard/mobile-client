import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/update_instance.dart';

class RefreshInstanceScreenData {
  final DefguardInstance instance;

  const RefreshInstanceScreenData({required this.instance});
}

class RefreshInstanceScreen extends StatelessWidget {
  final DefguardInstance instance;

  const RefreshInstanceScreen({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DgAppBar(
        context: context,
        showLogo: false,
        actionLeft: DgIconButton(
          icon: "close",
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: SafeArea(child: _RefreshInstanceContent(instance: instance)),
      ),
    );
  }
}

class _RefreshInstanceContent extends HookConsumerWidget {
  final DefguardInstance instance;

  const _RefreshInstanceContent({required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final toaster = ref.read(toastManagerProvider.notifier);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final tokenController = useTextEditingController();
    final urlController = useTextEditingController(text: instance.proxyUrl);
    final isLoading = useState(false);

    String? validateUrl(String? value) {
      if (value == null || value.trim().isEmpty) {
        return "This field is required";
      }
      if (!_isValidUri(value.trim())) {
        return "Enter valid URL";
      }
      return null;
    }

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      isLoading.value = true;
      try {
        final refreshed = await _refreshInstance(
          db,
          toaster,
          instance,
          Uri.parse(urlController.text.trim()),
          tokenController.text.trim(),
        );
        if (refreshed && context.mounted) {
          Navigator.of(context).pop();
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Form(
      key: formKey,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Semantics(
                  identifier: "refresh_instance_header",
                  child: Text(
                    "Refresh Instance",
                    style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                    textAlign: .left,
                  ),
                ),
                const SizedBox(height: DgSpacing.sm),
                Text(
                  "Enter your proxy URL and instance token to refresh the configuration.",
                  style: DgText.bodySm400.copyWith(color: DgColor.fgWhite60),
                  textAlign: .left,
                ),
                const SizedBox(height: DgSpacing.xl3),
                DgTextFormField(
                  identifier: "refresh_instance_token",
                  size: .big,
                  controller: tokenController,
                  label: "Token",
                  required: true,
                  hintText: "Instance token",
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "This field is required"
                      : null,
                ),
                const SizedBox(height: DgSpacing.xl),
                DgTextFormField(
                  identifier: "refresh_instance_url",
                  size: .big,
                  controller: urlController,
                  label: "URL",
                  required: true,
                  hintText: "Proxy URL",
                  keyboardType: .url,
                  validator: validateUrl,
                ),
              ]),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const .fromLTRB(20, 0, 20, 20),
              child: Align(
                alignment: .bottomCenter,
                child: DgButton(
                  identifier: "refresh_instance_submit",
                  text: "Refresh",
                  style: .primary,
                  size: .big,
                  width: double.infinity,
                  loading: isLoading.value,
                  onTap: submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isValidUri(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.hasScheme && uri.hasAuthority;
}

Future<bool> _refreshInstance(
  AppDatabase db,
  ToastManager toaster,
  DefguardInstance instance,
  Uri uri,
  String token,
) async {
  talker.debug("Submitting instance refresh form");
  try {
    // this is only for dio to capture cookies required for network info call
    await proxyApi.startEnrollment(uri, EnrollmentStartRequest(token: token));
    final networkInfo = await proxyApi.networkInfo(uri, instance.pubKey);
    talker.debug("Retrieved new instance information from proxy");
    final updateResult = await updateInstance(
      db: db,
      instance: instance,
      configs: networkInfo.configs,
      info: networkInfo.instance,
      token: networkInfo.token,
    );
    if (updateResult != null && updateResult.didChange) {
      final message = getInstanceUpdateMessage(instance.name, updateResult);
      toaster.show(message: "Instance ${instance.name} updated: $message");
    } else {
      toaster.show(message: "Instance information refreshed");
    }
    talker.info("Instance information refreshed successfully");
    return true;
  } catch (e, st) {
    toaster.showError(
      message: "Failed to refresh instance information",
      error: e,
      stackTrace: st,
    );
    return false;
  }
}
