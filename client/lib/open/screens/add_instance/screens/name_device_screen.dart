import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/screens/add_instance/generate_wireguard.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/nav.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';

import '../../../api.dart';

class NameDeviceScreenData {
  final EnrollmentStartResponse startResponse;
  final Uri proxyUrl;

  const NameDeviceScreenData({
    required this.startResponse,
    required this.proxyUrl,
  });
}

class NameDeviceScreen extends HookConsumerWidget {
  final NameDeviceScreenData screenData;

  const NameDeviceScreen({super.key, required this.screenData});

  Future<String> _handleRegistration(
    BuildContext context,
    AppDatabase db,
    String name,
  ) async {
    final keyPair = await generateWireguardKeyPair();
    final createDeviceData = CreateDeviceRequest(
      name: name,
      pubkey: keyPair.pubKey,
    );
    final createResponse = await proxyApi.createDevice(
      screenData.proxyUrl,
      createDeviceData,
    );
    final instance = await db.managers.defguardInstances.createReturning(
      (o) => o(
        id: drift.Value.absent(),
        pubKey: keyPair.pubKey,
        privateKey: keyPair.privKey,
        name: createResponse.instance.name,
        uuid: createResponse.instance.id,
        enterpriseEnabled: createResponse.instance.enterpriseEnabled,
        disableAllTraffic: createResponse.instance.disableAllTraffic,
        proxyUrl: createResponse.instance.proxyUrl,
        url: screenData.startResponse.instance.url,
        username: createResponse.instance.username,
        token: createResponse.token,
      ),
      mode: drift.InsertMode.insertOrFail,
    );
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
    return instance.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();

    return Scaffold(
      appBar: DgAppBar(title: "Add instance"),
      drawer: DgDrawer(),
      body: Container(
        color: DgColor.frameBg,
        child: Padding(
          padding: const EdgeInsets.all(DgSpacing.m),
          child: Column(
            children: [
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: DgSpacing.m,
                  children: [
                    DgTextFormField(
                      controller: nameController,
                      hintText: "Name",
                    ),
                    DgButton(
                      variant: DgButtonVariant.primary,
                      size: DgButtonSize.big,
                      width: double.infinity,
                      text: "Submit",
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final instanceName = await _handleRegistration(
                            context,
                            db,
                            nameController.text.trim(),
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                "Instance $instanceName registered successfully.",
                              ),
                            ),
                          );
                          if (context.mounted) {
                            HomeScreenRoute().go(context);
                          }
                        } catch (e) {
                          debugPrint("Registration failed, Reason:\n$e");
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
