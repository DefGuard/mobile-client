import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/instance/services/tunnel_service.dart';
import 'package:mobile/open/screens/instance/widgets/connect_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/connect_pane.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_settings_pane.dart';
import 'package:mobile/open/widgets/dg_icon_button.dart';
import 'package:mobile/open/widgets/dg_mfa_selector.dart';

class _StubBiometrics extends BiometricsCapability {
  @override
  BiometricsState build() => BiometricsState(
    isSupported: true,
    canCheck: true,
    enrolledOptions: const [BiometricType.strong, BiometricType.fingerprint],
  );
}

const _instance = DefguardInstance(
  id: 1,
  name: 'Defguard',
  uuid: 'uuid',
  url: 'https://vpn.example',
  deviceId: 7,
  proxyUrl: 'https://proxy.example',
  username: 'user',
  clientTrafficPolicy: ClientTrafficPolicy.none,
  enterpriseEnabled: false,
  pubKey: 'instance-pubkey',
  mfaKeysStored: true,
);

MfaStep _step(List<MfaMethod> methods) =>
    MfaStep(methods.map(MfaStepMethod.supported).toList());

Location _location({List<MfaMethod?> plan = const []}) => Location(
  id: 1,
  instance: 1,
  networkId: 11,
  name: 'Szczecin',
  address: '10.0.0.1/24',
  pubKey: 'pubkey',
  endpoint: 'vpn.example:51820',
  allowedIps: '0.0.0.0/0',
  keepAliveInterval: 25,
  mfaSteps: [
    _step([MfaMethod.totp, MfaMethod.email]),
    _step([MfaMethod.biometric, MfaMethod.email]),
  ],
  mfaStepPlan: plan,
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          biometricsCapabilityProvider.overrideWith(_StubBiometrics.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConnectDialog(
                instance: _instance,
                location: _location(),
                onConnect: (_, _) async => const ConnectResult.cancelled(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMfaPane(WidgetTester tester) async {
    await tester.tap(find.text('Change default MFA methods'));
    await tester.pumpAndSettle();
  }

  bool isShowing(WidgetTester tester, Type pane) =>
      tester.getTopLeft(find.byType(pane)).dx.abs() < 1;

  Finder rowIn(Type pane, MfaMethod method) => find.descendant(
    of: find.byType(pane),
    matching: find.byWidgetPredicate(
      (w) => w is DgMfaSelector && w.factor == method,
    ),
  );

  testWidgets('the MFA pane opens inside the sheet, pushing no route', (
    tester,
  ) async {
    await pumpSheet(tester);
    expect(isShowing(tester, ConnectPane), isTrue);
    expect(isShowing(tester, MfaSettingsPane), isFalse);

    await openMfaPane(tester);

    expect(find.text('MFA Settings'), findsOneWidget);
    expect(isShowing(tester, MfaSettingsPane), isTrue);
    expect(isShowing(tester, ConnectPane), isFalse);
    expect(find.byType(Scaffold, skipOffstage: false), findsOneWidget);
  });

  testWidgets('the back arrow returns to the connect pane', (tester) async {
    await pumpSheet(tester);
    await openMfaPane(tester);

    await tester.tap(find.byType(DgIconButton));
    await tester.pumpAndSettle();

    expect(isShowing(tester, ConnectPane), isTrue);
    expect(isShowing(tester, MfaSettingsPane), isFalse);
  });

  testWidgets('system back returns to the connect pane, not dismissal', (
    tester,
  ) async {
    await pumpSheet(tester);
    await openMfaPane(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Connect Szczecin location'), findsOneWidget);
    expect(isShowing(tester, ConnectPane), isTrue);
  });

  testWidgets('the parked pane cannot be tapped through', (tester) async {
    await pumpSheet(tester);

    expect(
      tester
          .widget<DgMfaSelector>(rowIn(MfaSettingsPane, MfaMethod.email).last)
          .onTap,
      isNotNull,
    );
    await tester.tap(
      rowIn(MfaSettingsPane, MfaMethod.email).last,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DgMfaSelector>(rowIn(MfaSettingsPane, MfaMethod.biometric))
          .active,
      isTrue,
    );
  });

  testWidgets('saving writes the plan and slides back', (tester) async {
    await db
        .into(db.defguardInstances)
        .insert(_instance, mode: InsertMode.insertOrReplace);
    await db
        .into(db.locations)
        .insert(_location(), mode: InsertMode.insertOrReplace);

    await pumpSheet(tester);
    await openMfaPane(tester);

    await tester.tap(rowIn(MfaSettingsPane, MfaMethod.email).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(isShowing(tester, ConnectPane), isTrue);
    final stored = await db.select(db.locations).getSingle();
    expect(stored.mfaStepPlan, [MfaMethod.totp, MfaMethod.email]);
  });

  testWidgets('leaving without saving discards the edit', (tester) async {
    await pumpSheet(tester);
    await openMfaPane(tester);

    await tester.tap(rowIn(MfaSettingsPane, MfaMethod.email).last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DgMfaSelector>(rowIn(MfaSettingsPane, MfaMethod.biometric))
          .active,
      isFalse,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openMfaPane(tester);

    expect(
      tester
          .widget<DgMfaSelector>(rowIn(MfaSettingsPane, MfaMethod.biometric))
          .active,
      isTrue,
    );
  });
}
