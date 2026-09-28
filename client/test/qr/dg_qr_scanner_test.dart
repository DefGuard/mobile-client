import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/proxy/qr_register.dart';
import 'package:mobile/open/widgets/dg_qr_scanner.dart';
import 'package:qr_plugin/qr_plugin.dart';

String _encode(Object json) => base64Encode(utf8.encode(jsonEncode(json)));

QrInstanceRegistration? _decode(String raw) =>
    decodeQrPayload(raw, QrInstanceRegistration.fromJson);

void main() {
  group('decodeQrPayload', () {
    test('decodes a valid payload', () {
      final data = _decode(
        _encode({'url': 'https://vpn.example', 'token': 't'}),
      );
      expect(data?.url, 'https://vpn.example');
      expect(data?.token, 't');
    });

    test('returns null for malformed payloads', () {
      expect(_decode('not base64!'), isNull);
      expect(_decode(base64Encode([0xff, 0xfe])), isNull);
      expect(_decode(base64Encode(utf8.encode('{nope'))), isNull);
      expect(_decode(_encode(['url', 'token'])), isNull);
      expect(_decode(_encode({'url': 'https://vpn.example'})), isNull);
    });
  });

  group('DgScannerController', () {
    late DgScannerController controller;

    setUp(() => controller = DgScannerController(QrScannerController()));

    test('suppresses a code held in view', () {
      fakeAsync((async) {
        expect(controller.isNewSighting('a'), isTrue);
        async.elapse(const Duration(milliseconds: 300));
        expect(controller.isNewSighting('a'), isFalse);
        async.elapse(const Duration(milliseconds: 300));
        expect(controller.isNewSighting('a'), isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(controller.isNewSighting('a'), isTrue);
      });
    });

    test('accepts a different code immediately', () {
      fakeAsync((async) {
        expect(controller.isNewSighting('a'), isTrue);
        expect(controller.isNewSighting('b'), isTrue);
      });
    });

    test('keeps rejected codes rejected', () {
      fakeAsync((async) {
        expect(controller.isNewSighting('a'), isTrue);
        controller.reject('a');
        async.elapse(const Duration(seconds: 10));
        expect(controller.isNewSighting('a'), isFalse);
      });
    });

    test('cools down only the last handled code after resume', () {
      fakeAsync((async) {
        expect(controller.isNewSighting('a'), isTrue);
        controller.resume();
        async.elapse(const Duration(seconds: 1));
        expect(controller.isNewSighting('a'), isFalse);
        expect(controller.isNewSighting('b'), isTrue);
        async.elapse(const Duration(seconds: 5));
        expect(controller.isNewSighting('a'), isTrue);
      });
    });
  });
}
