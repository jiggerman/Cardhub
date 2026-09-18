import 'package:cardhub_mobile/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(dynamic body, int status) {
  final options = RequestOptions(path: '/api/test/');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('ApiException разбирает ответы DRF', () {
    test('поле error', () {
      final error = ApiException.fromDio(_badResponse({'error': 'Неверные данные'}, 401));

      expect(error.message, 'Неверные данные');
      expect(error.statusCode, 401);
      expect(error.isUnauthorized, isTrue);
    });

    test('поле detail', () {
      final error = ApiException.fromDio(
        _badResponse({'detail': 'Authentication credentials were not provided.'}, 401),
      );

      expect(error.message, 'Authentication credentials were not provided.');
    });

    test('ошибки валидации по полям', () {
      final error = ApiException.fromDio(
        _badResponse({
          'password': ['Пароль слишком короткий.', 'Пароль слишком простой.'],
          'email': ['Пользователь с таким email уже существует'],
        }, 400),
      );

      expect(error.fieldErrors['email'], 'Пользователь с таким email уже существует');
      expect(error.fieldErrors['password'], contains('слишком короткий'));
      expect(error.message, contains('слишком простой'));
    });

    test('вложенные ошибки заказа', () {
      final error = ApiException.fromDio(
        _badResponse({'cards': ['Недостаточно карты «Lightning Bolt» в наличии']}, 400),
      );

      expect(error.message, 'Недостаточно карты «Lightning Bolt» в наличии');
    });

    test('пустой ответ даёт запасной текст', () {
      final error = ApiException.fromDio(_badResponse(null, 500));

      expect(error.message, 'Что-то пошло не так');
    });
  });

  test('обрыв связи описывается понятно', () {
    final error = ApiException.fromDio(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/api/test/'),
        reason: 'offline',
      ),
    );

    expect(error.message, contains('Нет связи'));
  });
}
