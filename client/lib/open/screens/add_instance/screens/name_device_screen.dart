import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/screens/add_instance/generate_wireguard.dart';
import 'package:mobile/open/widgets/dg_app_bar.dart';
import 'package:mobile/open/widgets/dg_button.dart';
import 'package:mobile/open/widgets/dg_drawer.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_text_form_field.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';
import 'package:mobile/utils/instance_secrets.dart';

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
    final uuid = createResponse.instance.id;
    final deviceId = createResponse.device.id;
    // secrets live in the keychain, not in the database
    await storeInstanceSecrets(
      uuid: uuid,
      deviceId: deviceId,
      privateKey: keyPair.privKey,
      poolingToken: createResponse.token,
    );
    try {
      final instance = await db.managers.defguardInstances.createReturning(
        (o) => o(
          id: drift.Value.absent(),
          pubKey: keyPair.pubKey,
          name: createResponse.instance.name,
          uuid: uuid,
          deviceId: deviceId,
          enterpriseEnabled: createResponse.instance.enterpriseEnabled,
          clientTrafficPolicy: drift.Value(createResponse.instance.getPolicy()),
          proxyUrl: createResponse.instance.proxyUrl,
          url: screenData.startResponse.instance.url,
          username: createResponse.instance.username,
          mfaKeysStored: false,
          openidDisplayName: drift.Value(
            createResponse.instance.openidDisplayName,
          ),
        ),
        mode: drift.InsertMode.insertOrFail,
      );
      await db.managers.locations.bulkCreate(
        (o) => createResponse.configs.map(
          (config) => config.toCompanion(instanceId: instance.id),
        ),
      );
      return instance;
    } catch (e) {
      // do not leave secrets of an instance that was never stored
      await removeInstanceSecrets(uuid: uuid, deviceId: deviceId);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final toaster = ref.read(toastManagerProvider.notifier);
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
            suggestedName = "${android.manufacturer} ${android.model}";
          } else if (Platform.isIOS) {
            final ios = await deviceInfo.iosInfo;
            suggestedName = ios.name;
          } else {
            suggestedName = "";
          }
          nameController.text = suggestedName;
        } catch (e) {
          talker.error("Failed to get suggested device name! Reason: $e");
        }
      }

      startup();
      return null;
    }, const []);

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
        child: SafeArea(
          child: Form(
            key: formKey,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        "Add Instance",
                        style: DgText.h4.copyWith(
                          color: DgColor.fgWhite100,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: DgSpacing.sm),
                      Text(
                        "Name your device to help you quickly identify it in the list.\nChoose something meaningful and easy to recognize.",
                        style: DgText.bodySm400.copyWith(
                          color: DgColor.fgWhite60,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: DgSpacing.xl3),
                      DgTextFormField(
                        size: DgTextFormFieldSize.big,
                        controller: nameController,
                        label: "Device Name",
                        required: true,
                        hintText: "Name this device",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Field is required";
                          }
                          final matchedName = screenData
                              .startResponse
                              .user
                              .deviceNames
                              .firstWhereOrNull(
                                (name) =>
                                    name.toLowerCase() ==
                                    value.toLowerCase().trim(),
                              );
                          if (matchedName != null) {
                            return "Name is already used";
                          }
                          return null;
                        },
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
                        identifier: "device_name_submit",
                        text: "Submit",
                        style: DgButtonStyle.primary,
                        size: DgButtonSize.big,
                        width: double.infinity,
                        loading: isLoading.value,
                        onTap: () async {
                          if (formKey.currentState?.validate() ?? false) {
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
                            } catch (e, st) {
                              toaster.showError(
                                message:
                                    "Something went wrong. Please try again.",
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
          ),
        ),
      ),
    );
  }
}
