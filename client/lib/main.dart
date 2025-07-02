import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/plugin.dart';
import 'package:mobile/router/routes.dart';
import 'package:mobile/theme.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: _App()));
}

final _routerNavigatorKey = GlobalKey<NavigatorState>();

class _App extends ConsumerWidget {
  final _router = GoRouter(
    routes: $appRoutes,
    navigatorKey: _routerNavigatorKey,
    observers: [TalkerRouteObserver(talker)],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_deepLinkProvider);
    ref.watch(pluginEventRouterProvider);

    return MaterialApp.router(
      routerConfig: _router,
      theme: defguardThemeData,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _deepLinkProcessorProvider = Provider<void Function(Uri)>((ref) {
  return (uri) {
    if (uri.host == 'register') {
      final encoded = uri.queryParameters['data'];
      if (encoded == null) return;

      try {
        final jsonString = utf8.decode(base64Url.decode(encoded));
        final data = QrInstanceRegistration.fromJson(jsonDecode(jsonString));

        final ctx = _routerNavigatorKey.currentContext;
        if (ctx != null) {
          RegisterFromQrScreenRoute(data).go(ctx);
        } else {
          debugPrint("❗ Router context is not yet available.");
        }
      } catch (e) {
        debugPrint("Invalid QR deep link: $e");
      }
    }
  };
});

final _deepLinkProvider = Provider((ref) {
  final appLinks = AppLinks();

  // Listen to stream
  appLinks.uriLinkStream.listen((uri) {
    debugPrint("Link received from stream $uri");
    ref.read(_deepLinkProcessorProvider)(uri);
  });

  // Handle initial link
  appLinks.getInitialLink().then((uri) {
    debugPrint("INITIAL Link received from stream $uri");
    if (uri != null) {
      ref.read(_deepLinkProcessorProvider)(uri);
    }
  });

  return appLinks;
});
