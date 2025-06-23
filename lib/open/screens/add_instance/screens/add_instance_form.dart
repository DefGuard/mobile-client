import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_client/open/widgets/buttons/dg_button.dart';
import 'package:mobile_client/open/widgets/icons/arrow_single.dart';
import 'package:mobile_client/open/widgets/icons/asset_icons_simple.dart';
import 'package:mobile_client/open/widgets/icons/icon_rotation.dart';

import '../../../../theme/color.dart';
import '../../../widgets/nav.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_client/data/db/database.dart';
import 'package:mobile_client/data/proxy/enrollment.dart';
import 'package:mobile_client/open/api.dart';
import 'package:mobile_client/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile_client/router/routes.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

class AddInstanceFormScreen extends HookConsumerWidget {
  const AddInstanceFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: DgAppBar(title: "Add instance"),
      drawer: DgDrawer(),
      body: Container(
        color: DgColor.frameBg,
        child: Column(
          children: [
            SizedBox(height: DgSpacing.m + DgSpacing.xl),
            Text("Please, enter instance URL and token", style: DgText.body1),
            SizedBox(height: DgSpacing.m),
            _AddInstanceForm(),
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
    NameDeviceScreenRoute(routeData).go(context);
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
    final db = ref.read(databaseProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final urlController = useTextEditingController(
      text: "http://10.0.2.2:8080",
    );
    final tokenController = useTextEditingController();
    final isLoading = useState(false);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: (Form(
        key: formKey,
        child: Column(
          spacing: DgSpacing.m,
          mainAxisSize: MainAxisSize.min,
          children: [
            // URL Field
            TextFormField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _validateUrl(value),
            ),
            const SizedBox(height: 16),
            // Token Field
            TextFormField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'This field is required'
                  : null,
            ),
            const SizedBox(height: 24),
            DgButton(
              text: "Add Instance",
              variant: DgButtonVariant.primary,
              size: DgButtonSize.big,
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
              variant: DgButtonVariant.secondary,
              size: DgButtonSize.big,
              icon: DgIconArrowSingle(
                direction: DgIconDirection.left,
                size: 36,
              ),
              onTap: () {
                AddInstanceScreenRoute().go(context);
              },
            ),
          ],
        ),
      )),
    );
  }
}
