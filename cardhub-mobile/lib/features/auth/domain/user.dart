import '../../../core/utils/json_parsing.dart';

/// Пользователь из `/api/user/me/`.
class User {
  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.telegramUsername,
    required this.telegramVerified,
    required this.emailVerified,
    required this.shippingAddress,
  });

  final int id;
  final String email;
  final String username;
  final String role;
  final String telegramUsername;
  final bool telegramVerified;
  final bool emailVerified;

  /// Бэкенд хранит адрес в JSON-поле. Веб кладёт туда `{'address': '...'}`,
  /// но в старых записях лежит просто строка — читаем оба варианта.
  final Object? shippingAddress;

  String get address => switch (shippingAddress) {
        final String value => value,
        final Map<String, dynamic> value => asString(value['address']),
        _ => '',
      };

  String get displayName => username.isNotEmpty ? username : email;

  String get initial => displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asInt(json['id']),
        email: asString(json['email']),
        username: asString(json['username']),
        role: asString(json['role'], fallback: 'user'),
        telegramUsername: asString(json['telegram_username']),
        telegramVerified: asBool(json['telegram_verified']),
        emailVerified: asBool(json['email_verified']),
        shippingAddress: json['shipping_address'],
      );
}
