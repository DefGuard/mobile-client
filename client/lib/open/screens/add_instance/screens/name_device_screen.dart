import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/screens/add_instance/generate_wireguard.dart';
import 'package:mobile/open/widgets/buttons/dg_button.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/utils/screen_padding.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../../logging.dart';
import '../../../api.dart';
import '../../../services/snackbar_service.dart';
import '../../../widgets/navigation/dg_scaffold.dart';

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

  Future<DefguardInstance> _handleRegistration(
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
        deviceId: createResponse.device.id,
        enterpriseEnabled: createResponse.instance.enterpriseEnabled,
        clientTrafficPolicy: createResponse.instance.clientTrafficPolicy,
        proxyUrl: createResponse.instance.proxyUrl,
        url: screenData.startResponse.instance.url,
        username: createResponse.instance.username,
        poolingToken: createResponse.token,
        mfaKeysStored: false,
      ),
      mode: drift.InsertMode.insertOrFail,
    );
    await db.managers.locations.bulkCreate(
      (o) => createResponse.configs.map(
        (config) => config.toCompanion(instanceId: instance.id),
      ),
    );
    return instance;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final isLoading = useState(false);

    useEffect(() {
      Future<void> startup() async {
        try {
          final deviceInfo = DeviceInfoPlugin();
          late String suggestedName;

          if (Platform.isAndroid) {
            final android = await deviceInfo.androidInfo;
            // Combine manufacturer + model for readability
            suggestedName = "${android.manufacturer} ${android.model}";
            // e.g. "Samsung Galaxy S22"
          } else if (Platform.isIOS) {
            final ios = await deviceInfo.iosInfo;
            suggestedName = ios.name;
            // e.g. "John’s iPhone"
          } else {
            suggestedName = "";
          }
          nameController.text = suggestedName;
        } catch(e) {
          talker.error("Failed to get suggested device name! Reason: $e");
        }
      }

      startup();
      return null;
    }, const []);

    return DgScaffold(
      title: "Add Instance",
      child: DgSingleChildScrollView(
        padding: screenPadding(
          top: DgSpacing.m,
          bottom: DgSpacing.m,
          horizontal: DgSpacing.s,
          context: context,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
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
                    autovalidateMode: AutovalidateMode.always,
                    hintText: "Name this device",
                    validator: (value) {
                      if (value == null) {
                        return "Field is required";
                      }
                      if (value != null) {
                        final valueText = value as String;
                        final matchedName = screenData
                            .startResponse
                            .user
                            .deviceNames
                            .firstWhereOrNull(
                              (name) =>
                                  name.toLowerCase() ==
                                  valueText.toLowerCase().trim(),
                            );
                        if (matchedName != null) {
                          return "Name is already used";
                        }
                      }
                      return null;
                    },
                  ),
                  DgButton(
                    variant: DgButtonVariant.primary,
                    size: DgButtonSize.big,
                    width: double.infinity,
                    loading: isLoading.value,
                    text: "Submit",
                    onTap: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      isLoading.value = true;
                      try {
                        final instance = await _handleRegistration(
                          context,
                          db,
                          nameController.text.trim(),
                        );
                        if (context.mounted) {
                          BiometrySetupScreenRoute(
                            id: instance.id.toString(),
                          ).go(context);
                        }
                      } catch (e) {
                        SnackbarService.showError(
                          "Something went wrong. Please try again.",
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
