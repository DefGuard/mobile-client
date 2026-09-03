import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/widgets/next/next_code_entry_layout.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/utils/error_handler.dart';

class NextMfaCodeScreenData {
  final String proxyUrl;
  final String token;

  const NextMfaCodeScreenData({required this.proxyUrl, required this.token});
}

class NextMfaCodeScreen extends ConsumerWidget {
  final NextMfaCodeScreenData screenData;
  final String title;
  final String description;
  final String fieldLabel;

  final String logLabel;

  const NextMfaCodeScreen({
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

    return NextCodeEntryLayout(
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
