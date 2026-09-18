import 'package:dio/dio.dart';

/// Ошибка API в виде, пригодном для показа пользователю.
///
/// DRF отвечает по-разному: `{"error": "..."}`, `{"detail": "..."}` или
/// `{"поле": ["сообщение"]}` — разбираем все три (как `readApiError` в вебе).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  factory ApiException.fromDio(DioException error, {String fallback = 'Что-то пошло не так'}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException('Сервер не отвечает. Попробуйте ещё раз');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException('Нет связи с сервером. Проверьте подключение');
      case DioExceptionType.badCertificate:
        return const ApiException('Сервер не прошёл проверку сертификата');
      case DioExceptionType.cancel:
        return const ApiException('Запрос отменён');
      case DioExceptionType.badResponse:
        final response = error.response;
        return ApiException(
          _messageFromBody(response?.data, fallback),
          statusCode: response?.statusCode,
          fieldErrors: _fieldErrors(response?.data),
        );
    }
  }

  static String _messageFromBody(dynamic data, String fallback) {
    if (data is Map) {
      for (final key in ['error', 'detail', 'message']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    final flattened = _flatten(data);
    return flattened.isEmpty ? fallback : flattened;
  }

  static Map<String, String> _fieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final result = <String, String>{};
    data.forEach((key, value) {
      final text = _flatten(value);
      if (key is String && text.isNotEmpty) result[key] = text;
    });
    return result;
  }

  static String _flatten(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Iterable) return value.map(_flatten).where((item) => item.isNotEmpty).join(' ');
    if (value is Map) return value.values.map(_flatten).where((item) => item.isNotEmpty).join(' ');
    return value.toString();
  }

  @override
  String toString() => message;
}
