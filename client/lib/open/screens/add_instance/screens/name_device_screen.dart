import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/screens/add_instance/generate_wireguard.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/open/widgets/next/next_app_bar.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/open/widgets/next/next_drawer.dart';
import 'package:mobile/open/widgets/next/next_icon_button.dart';
import 'package:mobile/open/widgets/next/next_text_form_field.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/next/color.dart';
import 'package:mobile/theme/next/spacing.dart';
import 'package:mobile/theme/next/text.dart';

import '../../../../logging.dart';
import '../../../api.dart';
import '../../../services/snackbar_service.dart';

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
        clientTrafficPolicy: drift.Value(createResponse.instance.getPolicy()),
        proxyUrl: createResponse.instance.proxyUrl,
        url: screenData.startResponse.instance.url,
        username: createResponse.instance.username,
        poolingToken: createResponse.token,
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
        } catch (e) {
          talker.error("Failed to get suggested device name! Reason: $e");
        }
      }

      startup();
      return null;
    }, const []);

    return Scaffold(
      drawer: const NextDrawer(),
      extendBodyBehindAppBar: true,
      appBar: NextAppBar(
        context: context,
        showLogo: false,
        actionLeft: NextIconButton(
          icon: "arrow_big",
          direction: NextIconDirection.left,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: NextColor.gradientPrimary),
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
                        style: NextText.h4.copyWith(
                          color: NextColor.fgWhite100,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: NextSpacing.sm),
                      Text(
                        "Name your device to help you quickly identify it in the list.\nChoose something meaningful and easy to recognize.",
                        style: NextText.bodySm400.copyWith(
                          color: NextColor.fgWhite60,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: NextSpacing.xl3),
                      NextTextFormField(
                        size: NextTextFormFieldSize.big,
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
                      child: NextButton(
                        text: "Submit",
                        style: NextButtonStyle.primary,
                        size: NextButtonSize.big,
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
                              SnackbarService.showError(
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
