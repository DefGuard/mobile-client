import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/riverpod/package_info/package_info.dart';
import 'package:mobile/open/screens/settings/settings_screen.dart';
import 'package:mobile/open/widgets/dg_drawer.dart';
import 'package:mobile/open/widgets/dg_toggle.dart';
import 'package:mobile/router/routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('defaults off and persists the selected value', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<DgToggle>(find.byType(DgToggle)).value, isFalse);

    await tester.tap(find.byType(DgToggle));
    await tester.pumpAndSettle();

    expect(tester.widget<DgToggle>(find.byType(DgToggle)).value, isTrue);
    expect(
      await SharedPreferencesAsync().getBool('excludeAndroidAuto'),
      isTrue,
    );
  });

  testWidgets('loads the stored value', (tester) async {
    await SharedPreferencesAsync().setBool('excludeAndroidAuto', true);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<DgToggle>(find.byType(DgToggle)).value, isTrue);
  });

  testWidgets('shows retry when the preference cannot be read', (
    tester,
  ) async {
    final preferences = _FailingPreferences.withData({
      'excludeAndroidAuto': true,
    })..failNextRead = true;
    SharedPreferencesAsyncPlatform.instance = preferences;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DgToggle), findsNothing);
    expect(find.text('Could not load this setting.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(tester.widget<DgToggle>(find.byType(DgToggle)).value, isTrue);
  });

  testWidgets('keeps the stored value and can retry a failed write', (
    tester,
  ) async {
    final preferences = _FailingPreferences.withData({
      'excludeAndroidAuto': true,
    })..failNextWrite = true;
    SharedPreferencesAsyncPlatform.instance = preferences;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DgToggle));
    await tester.pumpAndSettle();

    expect(tester.widget<DgToggle>(find.byType(DgToggle)).value, isTrue);
    expect(
      find.text(
        'Could not save this setting. The previous value is still active.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(tester.widget<DgToggle>(find.byType(DgToggle)).value, isFalse);
    expect(
      await SharedPreferencesAsync().getBool('excludeAndroidAuto'),
      isFalse,
    );
  });

  testWidgets('drawer shows Settings on Android and navigates to it', (
    tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final router = _drawerRouter(scaffoldKey);
    addTearDown(router.dispose);

    await _pumpDrawer(tester, router, scaffoldKey, isAndroid: true);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Application Logs'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings screen'), findsOneWidget);
  });

  testWidgets('drawer hides Settings on iOS and keeps Application Logs', (
    tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final router = _drawerRouter(scaffoldKey);
    addTearDown(router.dispose);

    await _pumpDrawer(tester, router, scaffoldKey, isAndroid: false);

    expect(find.text('Settings'), findsNothing);
    expect(find.text('Application Logs'), findsOneWidget);
  });

  test('settings route is /settings', () {
    expect(const SettingsScreenRoute().location, '/settings');
  });
}

GoRouter _drawerRouter(GlobalKey<ScaffoldState> scaffoldKey) => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => Scaffold(
        key: scaffoldKey,
        drawer: const DgDrawer(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const Scaffold(body: Text('Settings screen')),
    ),
    GoRoute(path: '/talker', builder: (_, _) => const Scaffold()),
  ],
);

base class _FailingPreferences extends InMemorySharedPreferencesAsync {
  _FailingPreferences.withData(super.data) : super.withData();

  bool failNextRead = false;
  bool failNextWrite = false;

  @override
  Future<bool?> getBool(
    String key,
    SharedPreferencesOptions options,
  ) async {
    if (failNextRead) {
      failNextRead = false;
      throw StateError('simulated preference read failure');
    }
    return super.getBool(key, options);
  }

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated preference write failure');
    }
    return super.setBool(key, value, options);
  }
}

Future<void> _pumpDrawer(
  WidgetTester tester,
  GoRouter router,
  GlobalKey<ScaffoldState> scaffoldKey, {
  required bool isAndroid,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isAndroidProvider.overrideWithValue(isAndroid),
        allInstancesProvider.overrideWith((ref) => Stream.value([])),
        packageInfoProvider.overrideWith(
          (ref) => Future.value(
            PackageInfo(
              appName: 'Test',
              packageName: 'test',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();
}
