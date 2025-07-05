import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_message_box.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/icons/arrow_single.dart';
import 'package:mobile/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile/open/widgets/icons/icon_rotation.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

import '../../../widgets/nav.dart';

class AddInstanceFormScreen extends HookConsumerWidget {
  const AddInstanceFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: DgAppBar(title: "Add instance"),
      drawer: DgDrawer(),
      body: DgSingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: DgSpacing.xl),
            Text(
              "Please, enter instance URL and token",
              style: DgText.body1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DgSpacing.m),
            _AddInstanceForm(),
            SizedBox(height: DgSpacing.m),
          ],
        ),
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
  String url,
  String token,
) async {
  debugPrint('Submitted: URL=$url, Token=$token');
  final requestData = EnrollmentStartRequest(token: token);
  final uri = Uri.parse(url);
  final enrolmentResponse = await proxyApi.startEnrollment(uri, requestData);
  final routeData = NameDeviceScreenData(
    startResponse: enrolmentResponse,
    proxyUrl: uri,
  );
  if (context.mounted) {
    NameDeviceScreenRoute(routeData).push(context);
  }
}

class _AddInstanceForm extends HookConsumerWidget {
  const _AddInstanceForm();

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    if (!_isValidUri(value)) {
      return "Enter valid URL";
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final urlController = useTextEditingController(
      text: "http://10.0.2.2:8080",
    );
    final tokenController = useTextEditingController();
    final isLoading = useState(false);

    return (Form(
      key: formKey,
      child: Column(
        spacing: DgSpacing.m,
        mainAxisSize: MainAxisSize.min,
        children: [
          DgMessageBox(
            width: double.infinity,
            text: "Please continue by entering a received URL and token below.",
          ),
          Column(
            spacing: DgSpacing.l,
            children: [
              DgTextFormField(
                controller: urlController,
                required: true,
                hintText: "URL",
                keyboardType: TextInputType.url,
                validator: (value) => _validateUrl(value),
              ),
              // Token Field
              DgTextFormField(
                controller: tokenController,
                hintText: 'Token',
                required: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Field is required' : null,
              ),
            ],
          ),
          Column(
            spacing: DgSpacing.m,
            children: [
              DgButton(
                text: "Add Instance",
                variant: DgButtonVariant.primary,
                size: DgButtonSize.big,
                width: double.infinity,
                icon: DgIconPlus(size: 32),
                loading: isLoading.value,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (formKey.currentState?.validate() ?? false) {
                    isLoading.value = true;
                    try {
                      await _handleSubmit(
                        context,
                        urlController.text.trim(),
                        tokenController.text.trim(),
                      );
                    } catch (e) {
                      print("Submit Error: $e");
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Device registration failed! Error $e'),
                        ),
                      );
                    } finally {
                      isLoading.value = false;
                    }
                  }
                },
              ),
              DgButton(
                text: "Cancel",
                width: double.infinity,
                variant: DgButtonVariant.secondary,
                size: DgButtonSize.big,
                icon: DgIconArrowSingle(
                  direction: DgIconDirection.left,
                  size: 36,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
