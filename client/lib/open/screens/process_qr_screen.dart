import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/screens/scan_qr_screen.dart';
import 'package:mobile/open/widgets/dg_single_child_scroll_view.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/spacing.dart';

import '../../data/proxy/enrollment.dart';
import '../../logging.dart';
import '../../theme/text.dart';
import '../../utils/secure_storage.dart';
import '../api.dart';
import '../services/snackbar_service.dart';
import '../widgets/buttons/dg_text_button.dart';
import '../widgets/circular_progress.dart';
import 'add_instance/screens/name_device_screen.dart';

class ProcessQrScreenData {
  final QrScreenIntent intent;
  final RemoteMfaQr? remoteMfaQr;
  final QrInstanceRegistration? registerInstanceData;
  final DefguardInstance? instance;

  const ProcessQrScreenData({
    required this.intent,
    this.remoteMfaQr,
    this.instance,
    this.registerInstanceData,
  });
}

class ProcessQrScreen extends HookConsumerWidget {
  final ProcessQrScreenData screenData;

  const ProcessQrScreen({super.key, required this.screenData});

  Future<void> abortScreen(BuildContext context) async {
    switch (screenData.intent) {
      case QrScreenIntent.addInstance:
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted) {
          AddInstanceScreenRoute().go(context);
        }
        break;
      case QrScreenIntent.remoteMfa:
        if (screenData.instance != null) {
          await WidgetsBinding.instance.endOfFrame;
          if (context.mounted) {
            InstanceScreenRoute(
              id: screenData.instance!.id.toString(),
            ).go(context);
          }
        } else {
          await WidgetsBinding.instance.endOfFrame;
          if (context.mounted) {
            HomeScreenRoute().go(context);
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    final registerInstance = useCallback(() async {
      final data = screenData.registerInstanceData!;
      final url = Uri.parse(data.url);
      // give router some time after last redirect
      await Future.delayed(Duration(seconds: 1));
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
          SnackbarService.showError("Instance is already registered!");
          if (context.mounted) {
            unawaited(abortScreen(context));
          }
          return;
        }
        final NameDeviceScreenData routeData = NameDeviceScreenData(
          proxyUrl: url,
          startResponse: registrationResponse,
        );
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted) {
          NameDeviceScreenRoute(routeData).go(context);
        }
      } catch (e) {
        talker.error("Enrollment via QR start failed!", e);
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted) {
          SnackbarService.showError("Something went wrong. Try again.");
          unawaited(abortScreen(context));
        }
      }
    }, []);

    // handle remote MFA should return to instance screen afterwards or back to scanning screen
    final authorizeDesktop = useCallback(() async {
      final data = screenData.remoteMfaQr!;
      final instance = screenData.instance!;
      try {
        talker.debug("Waiting after camera usage");
        late SecureInstanceStorage storage;
        await Future.delayed(Duration(seconds: 3));
        await WidgetsBinding.instance.endOfFrame;
        try {
          storage = await getBiometricInstanceStorage(
            instance.secureStorageKey,
          );
        } on PlatformException catch (e) {
          final message = getErrorMessageFromBiometricsException(e);
          talker.error("Failed biometric auth! Reason: $message");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              SnackbarService.showError(
                "Biometric authentication failed! Reason: $message",
              );
              InstanceScreenRoute(id: instance.id.toString()).go(context);
            }
          });
          return;
        } on UserCanceledAuth {
          talker.error("User canceled biometric auth");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              InstanceScreenRoute(id: instance.id.toString()).go(context);
            }
          });
          return;
        }
        final signature = signChallenge(data.challenge, storage.privateKey);
        final requestData = FinishMfaRequest(
          token: data.token,
          code: signature,
          authPubKey: storage.publicKey,
        );
        await proxyApi.finishRemoteMfa(
          Uri.parse(instance.proxyUrl),
          requestData,
        );
        talker.info("Successfully authorized instance ${instance.logName}.");
        SnackbarService.show("Desktop client authorized successfully.");
      } catch (e) {
        talker.error(e);
        SnackbarService.showError("Failed to authenticate desktop client.");
      } finally {
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted) {
          InstanceScreenRoute(id: instance.id.toString()).go(context);
        }
      }
    }, []);

    useEffect(() {
      Future<void> onStartup() async {
        await WidgetsBinding.instance.endOfFrame;
        switch (screenData.intent) {
          case QrScreenIntent.addInstance:
            talker.debug("Add instance");
            if (screenData.registerInstanceData != null) {
              registerInstance();
            } else {
              talker.error("Bad screen data");
            }
            break;
          case QrScreenIntent.remoteMfa:
            talker.debug(
              "Handle remote MFA  | ${screenData.remoteMfaQr} | ${screenData.instance}",
            );
            if (screenData.remoteMfaQr != null && screenData.instance != null) {
              authorizeDesktop();
            } else {
              talker.error("Bad screen data");
            }
            break;
        }
      }

      onStartup();
      return null;
    }, const []);

    return Container(
      color: DgColor.mainPrimary,
      child: DgSingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DgCircularProgress(color: DgColor.iconSecondary, size: 96),
            SizedBox(height: DgSpacing.xl),
            Text(
              "Waiting for Defguard response...",
              style: DgText.modal1.copyWith(
                color: DgColor.textButtonSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: DgSpacing.m),
            DgTextButton(
              text: "Cancel",
              textStyle: DgText.modal1.copyWith(
                color: DgColor.textButtonSecondary,
              ),
              onTap: () {
                // exit as if errored out.
                unawaited(abortScreen(context));
              },
            ),
          ],
        ),
      ),
    );
  }
}
