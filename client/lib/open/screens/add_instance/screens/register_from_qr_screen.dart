import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile/open/widgets/circular_progress.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/theme/text.dart';

class RegisterFromQrScreen extends HookConsumerWidget {
  final QrInstanceRegistration instanceRegistration;

  const RegisterFromQrScreen({super.key, required this.instanceRegistration});

  Future<void> _handleRegistration(BuildContext context, AppDatabase db) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = Uri.parse(instanceRegistration.url);
    final requestData = EnrollmentStartRequest(
      token: instanceRegistration.token,
    );
    talker.debug(
      "Start Enrollment request data:\ntoken:${instanceRegistration.token}\nurl:${instanceRegistration.url.toString()}",
    );
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
        messenger.showSnackBar(
          dgSnackBar(
            text: "Instance is already registered !",
            textColor: DgColor.textAlert,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            HomeScreenRoute().go(context);
            return;
          }
        });
      }
      final NameDeviceScreenData routeData = NameDeviceScreenData(
        proxyUrl: url,
        startResponse: registrationResponse,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          NameDeviceScreenRoute(routeData).push(context);
        }
      });
    } catch (e) {
      talker.error("Enrollment via QR start failed !", e);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          messenger.showSnackBar(
            dgSnackBar(
              text: "Something went wrong. Try again.",
              textColor: DgColor.textAlert,
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    useEffect(() {
      if(!context.mounted) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleRegistration(context, db));
      });
      return null;
    }, []);

    return Container(
      color: DgColor.mainPrimary,
      child: SafeArea(
        child: Column(
          spacing: DgSpacing.s,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Waiting for defguard response...",
              style: DgText.modal1.copyWith(
                color: DgColor.textButtonSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            DgCircularProgress(color: DgColor.iconSecondary),
          ],
        ),
      ),
    );
  }
}
