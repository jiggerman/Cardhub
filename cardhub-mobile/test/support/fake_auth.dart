import 'package:cardhub_mobile/core/network/api_exception.dart';
import 'package:cardhub_mobile/features/auth/data/auth_repository.dart';
import 'package:cardhub_mobile/features/auth/data/credentials_storage.dart';
import 'package:cardhub_mobile/features/auth/domain/user.dart';

Map<String, dynamic> userJson({
  int id = 2,
  String email = 'ios@test.dev',
  String username = 'ios',
  String telegramUsername = '',
  bool telegramVerified = false,
  Object? shippingAddress,
}) =>
    {
      'id': id,
      'role': 'user',
      'email': email,
      'username': username,
      'telegram_chat_id': null,
      'telegram_username': telegramUsername,
      'telegram_verified': telegramVerified,
      'shipping_address': shippingAddress,
      'email_verified': false,
      'created_at': '2026-09-16T18:11:07.176567Z',
    };

/// Хранилище учётных данных в памяти вместо Keychain.
class FakeCredentialsStorage implements CredentialsStorage {
  FakeCredentialsStorage([this.credentials]);

  Credentials? credentials;
  int clears = 0;

  @override
  Future<Credentials?> read() async => credentials;

  @override
  Future<void> save(Credentials value) async => credentials = value;

  @override
  Future<void> clear() async {
    credentials = null;
    clears++;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.password = 'Str0ngPass!42',
    Map<String, dynamic>? user,
    this.loginFailure,
    this.profileFailure,
  }) : user = User.fromJson(user ?? userJson());

  final String password;
  User user;
  Object? loginFailure;
  Object? profileFailure;

  final logins = <String>[];
  final registrations = <String>[];
  final profileUpdates = <Map<String, String?>>[];
  final loggedOutTokens = <String>[];
  int meCalls = 0;

  @override
  Future<AuthTokens> login(String email, String userPassword) async {
    logins.add(email);
    if (loginFailure != null) throw loginFailure!;
    if (userPassword != password) {
      throw const ApiException('Неверные данные', statusCode: 401);
    }
    return AuthTokens(access: 'access-${logins.length}', refresh: 'refresh-${logins.length}');
  }

  @override
  Future<AuthTokens> register({
    required String email,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    registrations.add(email);
    if (loginFailure != null) throw loginFailure!;
    return const AuthTokens(access: 'access-new', refresh: 'refresh-new');
  }

  @override
  Future<User> me() async {
    meCalls++;
    return user;
  }

  @override
  Future<User> updateProfile({String? telegramUsername, String? address}) async {
    profileUpdates.add({'telegram_username': telegramUsername, 'address': address});
    if (profileFailure != null) throw profileFailure!;
    user = User.fromJson(userJson(
      telegramUsername: telegramUsername ?? user.telegramUsername,
      shippingAddress: address == null ? user.shippingAddress : {'address': address},
    ));
    return user;
  }

  @override
  Future<void> logout(String refreshToken) async => loggedOutTokens.add(refreshToken);
}
