import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  ref.onDispose(client.close);
  return client;
});

/// Тонкая обёртка над Dio: единая база URL, таймауты и приведение любых сбоев
/// к [ApiException]. Авторизацию добавит следующий этап — токен пока
/// передаётся отдельным параметром.
class ApiClient {
  ApiClient({required String baseUrl, Dio? dio})
      : _dio = dio ??
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
            );

  final Dio _dio;

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query, String? token, CancelToken? cancelToken}) =>
      _send(() => _dio.get<dynamic>(
            path,
            queryParameters: query,
            cancelToken: cancelToken,
            options: _options(token),
          ));

  Future<dynamic> post(String path, {Object? body, String? token, CancelToken? cancelToken}) =>
      _send(() => _dio.post<dynamic>(
            path,
            data: body,
            cancelToken: cancelToken,
            options: _options(token),
          ));

  Future<dynamic> patch(String path, {Object? body, String? token, CancelToken? cancelToken}) =>
      _send(() => _dio.patch<dynamic>(
            path,
            data: body,
            cancelToken: cancelToken,
            options: _options(token),
          ));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Options? _options(String? token) =>
      token == null ? null : Options(headers: {'Authorization': 'Bearer $token'});

  void close() => _dio.close(force: true);
}
