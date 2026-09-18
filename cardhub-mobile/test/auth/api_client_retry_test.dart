import 'dart:convert';
import 'dart:typed_data';

import 'package:cardhub_mobile/core/network/api_client.dart';
import 'package:cardhub_mobile/core/network/api_exception.dart';
import 'package:cardhub_mobile/core/network/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Отдаёт заранее подготовленные ответы и запоминает запросы.
class _QueuedAdapter implements HttpClientAdapter {
  _QueuedAdapter(this.responses);

  final List<ResponseBody> responses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancelFuture) async {
    requests.add(options);
    return responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

({ApiClient client, _QueuedAdapter adapter}) _client(Session session, List<ResponseBody> responses) {
  final adapter = _QueuedAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'))..httpClientAdapter = adapter;
  return (client: ApiClient(baseUrl: 'http://localhost:8000', session: session, dio: dio), adapter: adapter);
}

void main() {
  test('токен подставляется в заголовок', () async {
    final session = Session()..accessToken = 'access-1';
    final (:client, :adapter) = _client(session, [_json({'id': 2}, 200)]);

    await client.get('/api/user/me/');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('на 401 выполняется повторный вход и запрос повторяется', () async {
    final session = Session()..accessToken = 'expired';
    session.reauthenticate = () async {
      session.accessToken = 'fresh';
      return true;
    };
    final (:client, :adapter) = _client(session, [
      _json({'detail': 'Given token not valid'}, 401),
      _json({'id': 2, 'email': 'ios@test.dev'}, 200),
    ]);

    final response = await client.get('/api/user/me/') as Map<String, dynamic>;

    expect(response['email'], 'ios@test.dev');
    expect(adapter.requests.length, 2);
    expect(adapter.requests.first.headers['Authorization'], 'Bearer expired');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer fresh');
  });

  test('без повторного входа ошибка доходит до вызывающего кода', () async {
    final session = Session()..accessToken = 'expired';
    session.reauthenticate = () async => false;
    final (:client, :adapter) = _client(session, [
      _json({'detail': 'Given token not valid'}, 401),
    ]);

    await expectLater(
      client.get('/api/user/me/'),
      throwsA(isA<ApiException>().having((error) => error.isUnauthorized, 'isUnauthorized', isTrue)),
    );
    expect(adapter.requests.length, 1);
  });

  test('повтор выполняется только один раз', () async {
    var logins = 0;
    final session = Session()..accessToken = 'expired';
    session.reauthenticate = () async {
      logins++;
      return true;
    };
    final (:client, :adapter) = _client(session, [
      _json({'detail': 'Given token not valid'}, 401),
      _json({'detail': 'Given token not valid'}, 401),
    ]);

    await expectLater(client.get('/api/user/me/'), throwsA(isA<ApiException>()));
    expect(adapter.requests.length, 2);
    expect(logins, 1);
  });

  test('вход и выход не уходят в повторную авторизацию', () async {
    var logins = 0;
    final session = Session();
    session.reauthenticate = () async {
      logins++;
      return true;
    };
    final (:client, :adapter) = _client(session, [
      _json({'error': 'Неверные данные'}, 401),
    ]);

    await expectLater(
      client.post('/api/login/', body: {'email': 'a@b.c', 'password': 'nope'}, extra: skipAuth),
      throwsA(isA<ApiException>().having((error) => error.message, 'message', 'Неверные данные')),
    );
    expect(logins, 0);
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });
}
