import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_drawer.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import 'package:mobile/open/widgets/toaster/toast_manager.dart';

class AddInstanceFormScreen extends HookConsumerWidget {
  const AddInstanceFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const DgDrawer(),
      extendBodyBehindAppBar: true,
      appBar: DgAppBar(
        context: context,
        showLogo: false,
        actionLeft: DgIconButton(
          icon: "arrow_big",
          direction: DgIconDirection.left,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: DgColor.gradientPrimary),
        child: const SafeArea(child: _AddInstanceFormContent()),
      ),
    );
  }
}

class _AddInstanceFormContent extends HookConsumerWidget {
  const _AddInstanceFormContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final toaster = ref.read(toastManagerProvider.notifier);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final urlController = useTextEditingController();
    final tokenController = useTextEditingController();
    final isLoading = useState(false);

    String? validateUrl(String? value) {
      if (value == null || value.trim().isEmpty) {
        return "This field is required";
      }
      if (!_isValidUri(value)) {
        return "Enter valid URL";
      }
      return null;
    }

    return Form(
      key: formKey,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  "Add Instance Manually",
                  style: DgText.h4.copyWith(color: DgColor.fgWhite100),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: DgSpacing.sm),
                Text(
                  "Enter the token and URL provided by your system administrator. These details are required to securely connect your system and complete the setup.",
                  style: DgText.bodySm400.copyWith(
                    color: DgColor.fgWhite60,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: DgSpacing.xl3),
                DgTextFormField(
                  identifier: "add_instance_url",
                  size: .big,
                  controller: urlController,
                  label: "URL",
                  required: true,
                  hintText: "Instance URL",
                  keyboardType: TextInputType.url,
                  validator: validateUrl,
                ),
                const SizedBox(height: DgSpacing.xl),
                DgTextFormField(
                  identifier: "add_instance_token",
                  size: .big,
                  controller: tokenController,
                  label: "Token",
                  required: true,
                  hintText: "Enrollment token",
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Field is required'
                      : null,
                ),
              ]),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DgButton(
                  identifier: "add_instance_submit",
                  text: "Continue",
                  style: DgButtonStyle.primary,
                  size: DgButtonSize.big,
                  width: double.infinity,
                  loading: isLoading.value,
                  onTap: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      isLoading.value = true;
                      try {
                        await _handleSubmit(
                          context,
                          db,
                          toaster,
                          urlController.text.trim(),
                          tokenController.text.trim(),
                        );
                      } catch (e, st) {
                        toaster.showError(
                          message:
                              "Device registration failed. Please try again.",
                          logMessage: "Device registration failed!",
                          error: e,
                          stackTrace: st,
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    }
                  },
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
  try {
    final uri = Uri.parse(value);
    return uri.hasScheme && uri.hasAuthority;
  } catch (_) {
    return false;
  }
}

Future<void> _handleSubmit(
  BuildContext context,
  AppDatabase db,
  ToastManager toaster,
  String url,
  String token,
) async {
  final requestData = EnrollmentStartRequest(token: token);
  final uri = Uri.parse(url);
  final enrolmentResponse = await proxyApi.startEnrollment(uri, requestData);
  final instanceId = enrolmentResponse.instance.id;
  final dbInstance = await db.managers.defguardInstances
      .filter((row) => row.uuid.equals(instanceId))
      .getSingleOrNull();
  if (dbInstance != null) {
    toaster.showError(message: "Instance is already registered!");
    return;
  }
  final routeData = NameDeviceScreenData(
    startResponse: enrolmentResponse,
    proxyUrl: uri,
  );
  if (context.mounted) {
    NameDeviceScreenRoute(routeData).push(context);
  }
}
