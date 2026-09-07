import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/dg_code_entry_layout.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/utils/error_handler.dart';

class MfaCodeScreenData {
  final String proxyUrl;
  final String token;

  const MfaCodeScreenData({required this.proxyUrl, required this.token});
}

class MfaCodeScreen extends ConsumerWidget {
  final MfaCodeScreenData screenData;
  final String title;
  final String description;
  final String fieldLabel;

  final String logLabel;

  const MfaCodeScreen({
    super.key,
    required this.screenData,
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.logLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toaster = ref.read(toastManagerProvider.notifier);

    return DgCodeEntryLayout(
      title: title,
      description: description,
      fieldLabel: fieldLabel,
      onSubmit: (code, setError) async {
        final navigator = Navigator.of(context);
        try {
          final response = await proxyApi.finishMfa(
            Uri.parse(screenData.proxyUrl),
            FinishMfaRequest(token: screenData.token, code: code),
          );
          if (navigator.mounted) {
            navigator.pop(response.presharedKey);
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            setError('Enter valid code');
            return;
          }
          toaster.showError(
            message: ErrorHandler.getHumanReadableError(e),
            logMessage: "$logLabel MFA code submit failed!",
            error: e,
          );
        } catch (e) {
          toaster.showError(
            message: ErrorHandler.getHumanReadableError(e),
            logMessage: "$logLabel MFA code submit failed!",
            error: e,
          );
        }
      },
    );
  }
}
