import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/widgets/next/next_qr_scanner.dart';
import 'package:mobile/router/routes.dart';

import '../../../../logging.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';

class AddInstanceQrScreen extends HookConsumerWidget {
  const AddInstanceQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final toaster = ref.read(toastManagerProvider.notifier);
    final isLoading = useState(false);

    const description = "Scan QR Code to add instance\non your phone";

    return Scaffold(
      backgroundColor: Colors.black,
      body: NextQrScanner<QrInstanceRegistration>(
        description: description,
        loading: isLoading.value,
        onCancel: () => Navigator.of(context).pop(),
        validator: (raw) {
          try {
            final decodedString = jsonDecode(utf8.decode(base64Decode(raw)));
            return QrInstanceRegistration.fromJson(decodedString);
          } catch (e) {
            talker.error("Failed to decode QR: $e");
            return null;
          }
        },
        onScan: (data, controller) async {
          isLoading.value = true;
          final url = Uri.parse(data.url);
          final requestData = EnrollmentStartRequest(token: data.token);
          try {
            final registrationResponse = await proxyApi.startEnrollment(
              url,
              requestData,
            );
            final instanceId = registrationResponse.instance.id;
            final dbInstance = await db.managers.defguardInstances
                .filter((row) => row.uuid.equals(instanceId))
                .getSingleOrNull();

            if (dbInstance != null) {
              talker.error(
                "Register Instance failed! Instance is already registered.",
              );
              toaster.showError(
                message: "Instance is already registered!",
              );
              isLoading.value = false;
              await controller.resume();
              return;
            }

            final NameDeviceScreenData routeData = NameDeviceScreenData(
              proxyUrl: url,
              startResponse: registrationResponse,
            );

            if (context.mounted) {
              NameDeviceScreenRoute(routeData).go(context);
            }
          } catch (e, st) {
            if (context.mounted) {
              toaster.showError(
                message: "Something went wrong. Try again.",
                logMessage: "Enrollment via QR start failed!",
                error: e,
                stackTrace: st,
              );
            }
            isLoading.value = false;
            await controller.resume();
          }
        },
      ),
    );
  }
}
