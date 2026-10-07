import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/open/screens/add_instance/add_instance_screen.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Finder _backButton() => find.byWidgetPredicate(
  (widget) => widget is DgIconButton && widget.icon == 'arrow_big',
);

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/add', builder: (_, _) => const AddInstanceScreen()),
    GoRoute(path: '/next', builder: (_, _) => const Scaffold()),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('root add instance screen has no back after returning to it', (
    tester,
  ) async {
    final router = _router('/add');
    await _pump(tester, router);
    expect(_backButton(), findsNothing);

    router.push('/next');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    await tester.pump();

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_backButton(), findsNothing);
  });

  testWidgets('pushed add instance screen keeps its back button', (
    tester,
  ) async {
    final router = _router('/home');
    await _pump(tester, router);
    router.push('/add');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_backButton(), findsOneWidget);
  });
}
