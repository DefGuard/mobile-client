import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_client/data/db/database.dart';
import 'package:mobile_client/data/proxy/enrollment.dart';
import 'package:mobile_client/open/api.dart';
import 'package:mobile_client/open/screens/add_instance/generate_wireguard.dart';
import 'package:mobile_client/open/widgets/nav.dart';
import 'package:mobile_client/router/routes.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

bool _isValidUri(String value) {
  try {
    final uri = Uri.parse(value);
    return uri.hasScheme && uri.hasAuthority;
  } catch (_) {
    return false;
  }
}

class AddInstanceScreen extends StatelessWidget {
  const AddInstanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DgAppBar(title: "Add Instance"),
      drawer: DgDrawer(),
      body: Expanded(
        child: Container(
          color: DgColor.frameBg,
          child: Column(
            children: [
              SizedBox(height: DgSpacing.m + DgSpacing.xl),
              Text("Please, enter instance URL", style: DgText.body1),
              SizedBox(height: DgSpacing.m),
              _AddInstanceForm(),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _handleSubmit(AppDatabase db, String url, String token) async {
  debugPrint('Submitted: URL=$url, Token=$token');
  final requestData = EnrollmentStartRequest(token: token);
  final uri = Uri.parse(url);
  print("Sending start enrollment");
  final enrolmentResponse = await proxyApi.startEnrollment(uri, requestData);
  final testDeviceName = "Test mobile";
  final keyPair = await generateWireguardKeyPair();
  print("Keypair generated");
  final createDeviceData = CreateDeviceRequest(
    name: testDeviceName,
    pubkey: keyPair.pubKey,
  );
  print("Creating device");
  final createResponse = await proxyApi.createDevice(uri, createDeviceData);
  print("Device created");
  print("Saving instance info");
  final instance = await db.managers.defguardInstances.createReturning(
    (o) => o(
      id: drift.Value.absent(),
      pubKey: keyPair.pubKey,
      privKey: keyPair.privKey,
      name: createResponse.instance.name,
      uuid: createResponse.instance.id,
      enterpriseEnabled: createResponse.instance.enterpriseEnabled,
      disableAllTraffic: createResponse.instance.disableAllTraffic,
      proxyUrl: createResponse.instance.proxyUrl,
      url: enrolmentResponse.instance.url,
      username: createResponse.instance.username,
      token: createResponse.token,
    ),
    mode: drift.InsertMode.insertOrFail,
  );
  print("Instance info saved");
  await db.managers.locations.bulkCreate(
    (o) => createResponse.configs.map(
      (config) => o(
        id: drift.Value.absent(),
        name: config.networkName,
        networkId: config.networkId,
        pubKey: config.pubkey,
        dns: drift.Value(config.dns),
        keepAliveInterval: config.keepaliveInterval,
        routeAllTraffic: false,
        allowedIps: config.allowedIps,
        instance: instance.id,
        mfaEnabled: config.mfaEnabled,
        address: config.assignedIp,
        endpoint: config.endpoint,
      ),
    ),
  );
  print("Instance locations saved");
}

class _AddInstanceForm extends HookConsumerWidget {
  const _AddInstanceForm({super.key});

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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (formKey.currentState?.validate() ?? false) {
                          isLoading.value = true;
                          try {
                            await _handleSubmit(
                              db,
                              urlController.text.trim(),
                              tokenController.text.trim(),
                            );
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Device registration completed successfully',
                                ),
                              ),
                            );
                            if (context.mounted) {
                              HomeScreenRoute().go(context);
                            }
                          } catch (e) {
                            print("Submit Error: ${e}");
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Device registration failed! Error $e',
                                ),
                              ),
                            );
                          } finally {
                            isLoading.value = false;
                          }
                        }
                      },
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
