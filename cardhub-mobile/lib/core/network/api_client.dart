import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'session.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl, session: ref.watch(sessionProvider));
  ref.onDispose(client.close);
  return client;
});

/// Запросы, которые не должны получать заголовок авторизации и не должны
/// приводить к повторному входу: сам вход, регистрация и выход.
const skipAuth = {'skipAuth': true};

/// Тонкая обёртка над Dio: единая база URL, таймауты, токен в заголовке
/// и приведение любых сбоев к [ApiException].
class ApiClient {
  ApiClient({required String baseUrl, required Session session, Dio? dio})
      : _session = session,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                // Поиск отдаёт всю выдачу разом, поэтому чтение ждём дольше
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 15),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final Session _session;

  Dio get dio => _dio;

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (token != null && options.extra['skipAuth'] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Access token живёт 5 минут, обновить его нечем — поэтому на 401 пробуем
  /// войти заново сохранённым паролем и повторяем запрос один раз.
  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final options = error.requestOptions;
    final retriable = error.response?.statusCode == 401 &&
        options.extra['skipAuth'] != true &&
        options.extra['retried'] != true;

    if (!retriable || !await _session.renew()) return handler.next(error);

    try {
      // Копия, а не исходный запрос: иначе повтор перезапишет его заголовки.
      final retry = await _dio.fetch<dynamic>(
        options.copyWith(
          headers: {...options.headers},
          extra: {...options.extra, 'retried': true},
        ),
      );
      handler.resolve(retry);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
  }) =>
      _send(() => _dio.get<dynamic>(
            path,
            queryParameters: query,
            cancelToken: cancelToken,
            options: Options(extra: extra),
          ));

  Future<dynamic> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
  }) =>
      _send(() => _dio.post<dynamic>(
            path,
            data: body,
            cancelToken: cancelToken,
            options: Options(extra: extra),
          ));

  Future<dynamic> patch(
    String path, {
    Object? body,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
  }) =>
      _send(() => _dio.patch<dynamic>(
            path,
            data: body,
            cancelToken: cancelToken,
            options: Options(extra: extra),
          ));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  void close() => _dio.close(force: true);
}
