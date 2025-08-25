import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/enterprise/config_update.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/riverpod/router/router.dart';
import 'package:mobile/plugin.dart';
import 'package:mobile/theme.dart';

import 'package:mobile/utils/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(
    ProviderScope(
      child: ConfigurationUpdater(child: BiometricsController(child: _App())),
    ),
  );
}

class _App extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pluginEventRouterProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: defguardThemeData,
      debugShowCheckedModeBanner: false,
    );
  }
}
