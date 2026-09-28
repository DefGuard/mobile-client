import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_plugin/qr_plugin.dart';

const _plugin = MethodChannel('net.defguard.qr_plugin');
const _codec = StandardMethodCodec();

TestDefaultBinaryMessenger get messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

void main() {
  late List<MethodCall> pluginCalls;
  late List<MethodCall> scannerCalls;
  late int scannerId;

  MethodChannel scannerChannel() =>
      MethodChannel('net.defguard.qr_plugin/scanner_$scannerId');

  Future<void> sendFromNative(String method, Object? arguments) =>
      messenger.handlePlatformMessage(
        scannerChannel().name,
        _codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );

  setUp(() {
    pluginCalls = [];
    scannerCalls = [];
    messenger.setMockMethodCallHandler(_plugin, (call) async {
      pluginCalls.add(call);
      if (call.method == 'create') {
        scannerId = call.arguments as int;
        messenger.setMockMethodCallHandler(scannerChannel(), (call) async {
          scannerCalls.add(call);
          return null;
        });
        return 7;
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(_plugin, null));

  Widget scanner(
    QrScannerController controller, {
    ValueChanged<String>? onCode,
    ValueChanged<QrScannerException>? onError,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: QrScannerView(
      controller: controller,
      onCode: onCode ?? (_) {},
      onError: onError ?? (_) {},
    ),
  );

  testWidgets('shows the texture rotated once native reports its size', (
    tester,
  ) async {
    await tester.pumpWidget(scanner(QrScannerController()));
    await tester.pump();
    expect(find.byType(Texture), findsNothing);

    await sendFromNative('size', {
      'width': 1920,
      'height': 1080,
      'quarterTurns': 1,
    });
    await tester.pump();

    final texture = tester.widget<Texture>(find.byType(Texture));
    expect(texture.textureId, 7);
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 1);
    expect(
      tester.getSize(find.byType(Texture)),
      const Size(1920, 1080),
    );
  });

  testWidgets('forwards codes only while running', (tester) async {
    final controller = QrScannerController();
    final codes = <String>[];
    await tester.pumpWidget(scanner(controller, onCode: codes.add));
    await tester.pump();

    await sendFromNative('code', 'a');
    await controller.stop();
    await sendFromNative('code', 'b');

    expect(codes, ['a']);
    expect(scannerCalls.map((c) => c.method), ['stop']);
  });

  testWidgets('sends a stop issued before create completes', (tester) async {
    final controller = QrScannerController();
    await controller.stop();
    await tester.pumpWidget(scanner(controller));
    await tester.pump();

    expect(scannerCalls.map((c) => c.method), ['stop']);
  });

  testWidgets('maps native errors and disposes on unmount', (tester) async {
    final errors = <QrScannerException>[];
    await tester.pumpWidget(
      scanner(QrScannerController(), onError: errors.add),
    );
    await tester.pump();

    await sendFromNative('error', {'code': 'noCamera', 'message': 'none'});
    expect(errors.single.code, QrScannerError.noCamera);

    await tester.pumpWidget(const SizedBox());
    expect(pluginCalls.map((c) => c.method), ['create', 'dispose']);
    expect(pluginCalls.last.arguments, scannerId);
  });

  testWidgets('reports a failed create as a scanner error', (tester) async {
    messenger.setMockMethodCallHandler(_plugin, (call) async {
      throw PlatformException(code: 'cameraError', message: 'no activity');
    });
    final errors = <QrScannerException>[];
    await tester.pumpWidget(
      scanner(QrScannerController(), onError: errors.add),
    );
    await tester.pump();

    expect(errors.single.code, QrScannerError.cameraError);
    expect(errors.single.message, 'no activity');
  });
}
