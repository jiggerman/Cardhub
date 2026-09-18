import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/session.dart';
import '../data/auth_repository.dart';
import '../data/credentials_storage.dart';
import '../domain/user.dart';

/// `null` — пользователь не вошёл.
final authProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);

/// Короткий ответ на вопрос «есть ли вход» без разбора состояния загрузки.
final isSignedInProvider = Provider<bool>((ref) => ref.watch(authProvider).valueOrNull != null);

class AuthController extends AsyncNotifier<User?> {
  Credentials? _credentials;

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  CredentialsStorage get _storage => ref.read(credentialsStorageProvider);
  Session get _session => ref.read(sessionProvider);

  @override
  Future<User?> build() async {
    // Сетевой слой сам попросит повторный вход, когда токен протухнет.
    // Ссылку держим локально: на удалении провайдера читать его уже нельзя.
    final session = ref.read(sessionProvider);
    session.reauthenticate = _renewSession;
    ref.onDispose(() => session.reauthenticate = null);

    final saved = await _storage.read();
    if (saved == null) return null;

    try {
      return await _authenticate(saved);
    } catch (_) {
      // Пароль мог измениться на другом устройстве — просто начинаем без входа.
      await _forget();
      return null;
    }
  }

  Future<User> _authenticate(Credentials credentials) async {
    final tokens = await _repository.login(credentials.email, credentials.password);
    _session
      ..accessToken = tokens.access
      ..refreshToken = tokens.refresh;
    _credentials = credentials;
    return _repository.me();
  }

  /// Повторный вход по сохранённому паролю — вызывается из перехватчика при 401.
  Future<bool> _renewSession() async {
    final credentials = _credentials ?? await _storage.read();
    if (credentials == null) return false;

    try {
      final tokens = await _repository.login(credentials.email, credentials.password);
      _session
        ..accessToken = tokens.access
        ..refreshToken = tokens.refresh;
      return true;
    } catch (_) {
      await _forget();
      state = const AsyncData(null);
      return false;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credentials = Credentials(email: email.trim(), password: password);
      final user = await _authenticate(credentials);
      await _storage.save(credentials);
      return user;
    });
  }

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.register(
        email: email.trim(),
        username: username.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      // Регистрация сразу возвращает токены, но входим ещё раз — так пароль
      // проверен и сохранён ровно тем же путём, что и при обычном входе.
      final credentials = Credentials(email: email.trim(), password: password);
      final user = await _authenticate(credentials);
      await _storage.save(credentials);
      return user;
    });
  }

  Future<void> signOut() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken != null) {
      try {
        await _repository.logout(refreshToken);
      } catch (_) {
        // Сервер мог быть недоступен — локальный выход всё равно выполняем.
      }
    }
    await _forget();
    state = const AsyncData(null);
  }

  Future<void> _forget() async {
    _credentials = null;
    _session.clear();
    await _storage.clear();
  }

  Future<void> updateProfile({String? telegramUsername, String? address}) async {
    final user = await _repository.updateProfile(telegramUsername: telegramUsername, address: address);
    state = AsyncData(user);
  }

  /// Обновляет профиль с сервера (например, после подтверждения Telegram).
  Future<void> reload() async {
    if (state.valueOrNull == null) return;
    state = await AsyncValue.guard(_repository.me);
  }
}
