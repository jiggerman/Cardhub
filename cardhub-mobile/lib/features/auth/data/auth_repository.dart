import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/json_parsing.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

/// Пара токенов из `/api/login/` и `/api/register/`.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>? ?? const {};
    return AuthTokens(access: asString(tokens['access']), refresh: asString(tokens['refresh']));
  }
}

class AuthRepository {
  const AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthTokens> login(String email, String password) async {
    final response = await _client.post(
      '/api/login/',
      body: {'email': email, 'password': password},
      extra: skipAuth,
    );
    return AuthTokens.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthTokens> register({
    required String email,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      '/api/register/',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'password2': passwordConfirmation,
      },
      extra: skipAuth,
    );
    return AuthTokens.fromJson(response as Map<String, dynamic>);
  }

  Future<User> me() async {
    final response = await _client.get('/api/user/me/');
    return User.fromJson(response as Map<String, dynamic>);
  }

  /// Бэкенд принимает только Telegram username и адрес доставки.
  Future<User> updateProfile({String? telegramUsername, String? address}) async {
    // Адрес лежит в JSON-поле; веб хранит его как {'address': '...'}
    final shippingAddress = address == null ? null : {'address': address};
    final response = await _client.patch('/api/user/me/', body: {
      'telegram_username': ?telegramUsername,
      'shipping_address': ?shippingAddress,
    });
    return User.fromJson(response as Map<String, dynamic>);
  }

  /// Отзывает refresh token. Ошибку игнорируем: выйти локально нужно в любом случае.
  Future<void> logout(String refreshToken) async {
    await _client.post('/api/logout/', body: {'refresh_token': refreshToken}, extra: skipAuth);
  }
}
