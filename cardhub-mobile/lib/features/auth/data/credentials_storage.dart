import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final credentialsStorageProvider = Provider<CredentialsStorage>((ref) => const KeychainCredentialsStorage());

class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;
  final String password;
}

abstract interface class CredentialsStorage {
  Future<Credentials?> read();
  Future<void> save(Credentials credentials);
  Future<void> clear();
}

/// Пароль хранится в Keychain, потому что обновлять токен на бэкенде нечем:
/// access живёт 5 минут, а эндпоинта refresh нет. Единственный способ
/// продлить сессию — тихо выполнить вход заново.
class KeychainCredentialsStorage implements CredentialsStorage {
  const KeychainCredentialsStorage();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _emailKey = 'auth_email';
  static const _passwordKey = 'auth_password';

  @override
  Future<Credentials?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return Credentials(email: email, password: password);
  }

  @override
  Future<void> save(Credentials credentials) async {
    await _storage.write(key: _emailKey, value: credentials.email);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
