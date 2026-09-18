import 'package:cardhub_mobile/core/network/api_exception.dart';
import 'package:cardhub_mobile/core/network/session.dart';
import 'package:cardhub_mobile/features/auth/application/auth_controller.dart';
import 'package:cardhub_mobile/features/auth/data/auth_repository.dart';
import 'package:cardhub_mobile/features/auth/data/credentials_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

({ProviderContainer container, FakeAuthRepository repository, FakeCredentialsStorage storage}) setup({
  Credentials? saved,
  FakeAuthRepository? repository,
}) {
  final auth = repository ?? FakeAuthRepository();
  final storage = FakeCredentialsStorage(saved);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    credentialsStorageProvider.overrideWithValue(storage),
  ]);
  addTearDown(container.dispose);
  return (container: container, repository: auth, storage: storage);
}

void main() {
  test('без сохранённых данных пользователь не авторизован', () async {
    final (:container, :repository, :storage) = setup();

    final user = await container.read(authProvider.future);

    expect(user, isNull);
    expect(repository.logins, isEmpty);
  });

  test('вход сохраняет пароль и токены', () async {
    final (:container, :repository, :storage) = setup();
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).signIn(email: 'ios@test.dev', password: 'Str0ngPass!42');

    expect(container.read(authProvider).value?.email, 'ios@test.dev');
    expect(storage.credentials?.password, 'Str0ngPass!42');
    expect(container.read(sessionProvider).accessToken, 'access-1');
    expect(container.read(isSignedInProvider), isTrue);
  });

  test('неверный пароль оставляет ошибку и не сохраняется', () async {
    final (:container, :repository, :storage) = setup();
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).signIn(email: 'ios@test.dev', password: 'wrong');

    final state = container.read(authProvider);
    expect(state.hasError, isTrue);
    expect((state.error as ApiException).message, 'Неверные данные');
    expect(storage.credentials, isNull);
  });

  test('сохранённый пароль восстанавливает сессию при запуске', () async {
    final (:container, :repository, :storage) = setup(
      saved: const Credentials(email: 'ios@test.dev', password: 'Str0ngPass!42'),
    );

    final user = await container.read(authProvider.future);

    expect(user?.email, 'ios@test.dev');
    expect(repository.logins, ['ios@test.dev']);
    expect(container.read(sessionProvider).accessToken, 'access-1');
  });

  test('устаревший пароль просто не пускает в аккаунт', () async {
    final (:container, :repository, :storage) = setup(
      saved: const Credentials(email: 'ios@test.dev', password: 'old-password'),
    );

    final user = await container.read(authProvider.future);

    expect(user, isNull);
    expect(storage.credentials, isNull, reason: 'негодный пароль удаляется из Keychain');
  });

  group('молчаливый повторный вход', () {
    test('обновляет токен, когда истёк access', () async {
      final (:container, :repository, :storage) = setup(
        saved: const Credentials(email: 'ios@test.dev', password: 'Str0ngPass!42'),
      );
      await container.read(authProvider.future);
      final session = container.read(sessionProvider);

      final renewed = await session.renew();

      expect(renewed, isTrue);
      expect(session.accessToken, 'access-2');
      expect(repository.logins.length, 2);
    });

    test('несколько параллельных запросов входят только один раз', () async {
      final (:container, :repository, :storage) = setup(
        saved: const Credentials(email: 'ios@test.dev', password: 'Str0ngPass!42'),
      );
      await container.read(authProvider.future);
      final session = container.read(sessionProvider);

      final results = await Future.wait([session.renew(), session.renew(), session.renew()]);

      expect(results, [true, true, true]);
      expect(repository.logins.length, 2, reason: 'один вход при запуске и один общий повторный');
    });

    test('если пароль перестал подходить — выходим из аккаунта', () async {
      final repository = FakeAuthRepository();
      final (container: container, repository: _, storage: storage) = setup(
        saved: const Credentials(email: 'ios@test.dev', password: 'Str0ngPass!42'),
        repository: repository,
      );
      await container.read(authProvider.future);

      repository.loginFailure = const ApiException('Неверные данные', statusCode: 401);
      final renewed = await container.read(sessionProvider).renew();

      expect(renewed, isFalse);
      expect(container.read(authProvider).value, isNull);
      expect(storage.credentials, isNull);
    });
  });

  test('выход отзывает refresh token и чистит Keychain', () async {
    final (:container, :repository, :storage) = setup();
    await container.read(authProvider.future);
    await container.read(authProvider.notifier).signIn(email: 'ios@test.dev', password: 'Str0ngPass!42');

    await container.read(authProvider.notifier).signOut();

    expect(repository.loggedOutTokens, ['refresh-1']);
    expect(container.read(authProvider).value, isNull);
    expect(container.read(sessionProvider).accessToken, isNull);
    expect(storage.credentials, isNull);
  });

  test('регистрация сразу выполняет вход', () async {
    final (:container, :repository, :storage) = setup();
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).signUp(
          email: 'new@test.dev',
          username: 'new',
          password: 'Str0ngPass!42',
          passwordConfirmation: 'Str0ngPass!42',
        );

    expect(repository.registrations, ['new@test.dev']);
    expect(container.read(authProvider).value, isNotNull);
    expect(storage.credentials?.email, 'new@test.dev');
  });

  test('обновление профиля кладёт свежего пользователя в состояние', () async {
    final (:container, :repository, :storage) = setup();
    await container.read(authProvider.future);
    await container.read(authProvider.notifier).signIn(email: 'ios@test.dev', password: 'Str0ngPass!42');

    await container.read(authProvider.notifier).updateProfile(telegramUsername: 'ios_tester');

    expect(repository.profileUpdates.single['telegram_username'], 'ios_tester');
    expect(container.read(authProvider).value?.telegramUsername, 'ios_tester');
  });
}
