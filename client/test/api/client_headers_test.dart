import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/client_identity.dart';
import 'package:mobile/open/client_headers_interceptor.dart';

const _facts = DevicePlatformFacts(
  kind: PlatformKind.android,
  osFamily: 'android',
  osType: 'Android',
  osName: '14',
  osVersion: '14',
  codename: 'REL',
  architecture: 'arm64-v8a',
  bitness: '64',
);

ClientIdentity _identity() => ClientIdentity(version: '1.6.0', facts: _facts);

final _endpoint = Uri.parse('https://proxy.example/api/v1/poll');

/// Records the composed request at the dispatch boundary, so "a request never
/// goes out without the headers" is directly assertable.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.status = 200});

  final int status;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(ClientIdentitySource identity, _RecordingAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(ClientHeadersInterceptor(identity));
  return dio;
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  test('a request carries both capability headers', () async {
    final adapter = _RecordingAdapter();
    final dio = _dioWith(
      ClientIdentitySource(() async => _identity()),
      adapter,
    );

    await dio.postUri(_endpoint, data: {'token': 't'});

    final sent = adapter.requests.single.headers;
    expect(sent[clientVersionHeader], '1.6.0');
    expect(sent[clientPlatformHeader], _identity().platformHeader);
  });

  test(
    'a request issued before the identity resolves still carries the headers',
    () async {
      final gate = Completer<ClientIdentity>();
      final adapter = _RecordingAdapter();
      final dio = _dioWith(ClientIdentitySource(() => gate.future), adapter);

      final pending = dio.postUri(_endpoint, data: {'token': 't'});
      await pumpEventQueue();
      expect(adapter.requests, isEmpty);

      gate.complete(_identity());
      await pending;

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.headers[clientVersionHeader], '1.6.0');
      expect(adapter.requests.single.headers[clientPlatformHeader], isNotNull);
    },
  );

  test('no request is dispatched when the identity cannot be built', () async {
    final adapter = _RecordingAdapter();
    final dio = _dioWith(
      ClientIdentitySource(() async => throw StateError('no device info')),
      adapter,
    );

    await expectLater(
      dio.postUri(_endpoint, data: {'token': 't'}),
      throwsA(
        isA<DioException>().having((e) => e.error, 'error', isA<StateError>()),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('no request is dispatched when the identity build times out', () async {
    final adapter = _RecordingAdapter();
    final dio = _dioWith(
      ClientIdentitySource(
        () => Completer<ClientIdentity>().future,
        timeout: const Duration(milliseconds: 20),
      ),
      adapter,
    );

    await expectLater(
      dio.postUri(_endpoint, data: {'token': 't'}),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<TimeoutException>(),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('a failed identity build is retried on the next request', () async {
    var calls = 0;
    final adapter = _RecordingAdapter();
    final dio = _dioWith(
      ClientIdentitySource(() async {
        calls++;
        if (calls == 1) throw StateError('no device info');
        return _identity();
      }),
      adapter,
    );

    await expectLater(
      dio.postUri(_endpoint, data: {'token': 't'}),
      throwsA(isA<DioException>()),
    );
    await dio.postUri(_endpoint, data: {'token': 't'});

    expect(calls, 2);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.headers[clientVersionHeader], '1.6.0');
  });

  test(
    'concurrent first requests all carry the headers and resolve once',
    () async {
      var calls = 0;
      final gate = Completer<ClientIdentity>();
      final adapter = _RecordingAdapter();
      final dio = _dioWith(
        ClientIdentitySource(() {
          calls++;
          return gate.future;
        }),
        adapter,
      );

      final pending = [
        dio.postUri(_endpoint, data: {'token': 'a'}),
        dio.postUri(_endpoint, data: {'token': 'b'}),
        dio.postUri(_endpoint, data: {'token': 'c'}),
      ];
      gate.complete(_identity());
      await Future.wait(pending);

      expect(calls, 1);
      expect(adapter.requests, hasLength(3));
      for (final sent in adapter.requests) {
        expect(sent.headers[clientVersionHeader], '1.6.0');
        expect(sent.headers[clientPlatformHeader], isNotNull);
      }
    },
  );

  test('a custom validateStatus still governs the response', () async {
    final adapter = _RecordingAdapter(status: 404);
    final dio = _dioWith(
      ClientIdentitySource(() async => _identity()),
      adapter,
    );

    final response = await dio.postUri(
      _endpoint,
      data: {'token': 't'},
      options: Options(validateStatus: (status) => status! < 500),
    );

    expect(response.statusCode, 404);
  });
}
