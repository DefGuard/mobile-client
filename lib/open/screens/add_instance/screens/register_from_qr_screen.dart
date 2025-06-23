import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_client/data/proxy/enrollment.dart';
import 'package:mobile_client/data/proxy/qr_register.dart';
import 'package:mobile_client/open/api.dart';
import 'package:mobile_client/open/screens/add_instance/screens/name_device_screen.dart';
import 'package:mobile_client/open/widgets/circular_progress.dart';
import 'package:mobile_client/router/routes.dart';
import 'package:mobile_client/theme/color.dart';
import 'package:mobile_client/theme/spacing.dart';
import 'package:mobile_client/theme/text.dart';

class RegisterFromQrScreen extends HookConsumerWidget {
  final QrInstanceRegistration instanceRegistration;

  const RegisterFromQrScreen({super.key, required this.instanceRegistration});

  Future<void> _handleRegistration(BuildContext context) async {
    final url = Uri.parse(instanceRegistration.url);
    final requestData = EnrollmentStartRequest(
      token: instanceRegistration.token,
    );
    debugPrint(
      "Start Enrollment request data:\ntoken:${instanceRegistration.token}\nurl:${instanceRegistration.url.toString()}",
    );
    try {
      final registrationResponse = await proxyApi.startEnrollment(
        url,
        requestData,
      );
      final NameDeviceScreenData routeData = NameDeviceScreenData(
        proxyUrl: url,
        startResponse: registrationResponse,
      );
      if (context.mounted) {
        NameDeviceScreenRoute(routeData).go(context);
      }
    } catch (e) {
      debugPrint("Enrollment start error! $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      _handleRegistration(context);
      return null;
    }, const []);

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
