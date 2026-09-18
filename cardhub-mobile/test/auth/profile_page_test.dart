import 'package:cardhub_mobile/features/auth/data/credentials_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';
import '../support/pump_app.dart';

const _saved = Credentials(email: 'ios@test.dev', password: 'Str0ngPass!42');

Future<void> _signIn(WidgetTester tester, {String password = 'Str0ngPass!42'}) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Войти или зарегистрироваться'));
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ios@test.dev');
  await tester.enterText(find.widgetWithText(TextFormField, 'Пароль'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('без входа профиль предлагает авторизоваться', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Профиль');

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Войти или зарегистрироваться'), findsOneWidget);
  });

  testWidgets('вход открывает профиль с данными пользователя', (tester) async {
    final storage = FakeCredentialsStorage();
    await pumpApp(tester, credentialsStorage: storage);
    await openTab(tester, 'Профиль');

    await _signIn(tester);

    expect(find.text('ios'), findsOneWidget);
    expect(find.text('ios@test.dev'), findsOneWidget);
    expect(storage.credentials?.password, 'Str0ngPass!42', reason: 'пароль сохраняется для повторного входа');
  });

  testWidgets('неверный пароль показывает ошибку и оставляет на экране входа', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Профиль');

    await _signIn(tester, password: 'wrong-password');

    expect(find.text('Неверные данные'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
  });

  testWidgets('короткий пароль при регистрации не отправляется на сервер', (tester) async {
    final repository = FakeAuthRepository();
    await pumpApp(tester, authRepository: repository);
    await openTab(tester, 'Профиль');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Войти или зарегистрироваться'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Регистрация'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Имя пользователя'), 'ios');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ios@test.dev');
    await tester.enterText(find.widgetWithText(TextFormField, 'Пароль'), '123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Повторите пароль'), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Создать аккаунт'));
    await tester.pumpAndSettle();

    expect(find.text('Не меньше 8 символов'), findsOneWidget);
    expect(repository.registrations, isEmpty);
  });

  testWidgets('сохранённый вход поднимает профиль сразу при запуске', (tester) async {
    await pumpApp(tester, credentialsStorage: FakeCredentialsStorage(_saved));
    await openTab(tester, 'Профиль');

    expect(find.text('ios@test.dev'), findsOneWidget);
    expect(find.text('Войдите в аккаунт'), findsNothing);
  });

  testWidgets('Telegram сохраняется без символа @', (tester) async {
    final repository = FakeAuthRepository();
    await pumpApp(tester, authRepository: repository, credentialsStorage: FakeCredentialsStorage(_saved));
    await openTab(tester, 'Профиль');

    await tester.enterText(find.widgetWithText(TextField, 'Username'), '@ios_tester');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(repository.profileUpdates.single['telegram_username'], 'ios_tester');
    expect(find.text('Сохранено'), findsOneWidget);
  });

  testWidgets('адрес доставки сохраняется', (tester) async {
    final repository = FakeAuthRepository();
    await pumpApp(tester, authRepository: repository, credentialsStorage: FakeCredentialsStorage(_saved));
    await openTab(tester, 'Профиль');

    await tester.enterText(find.widgetWithText(TextField, 'Город, улица, дом, квартира'), 'Санкт-Петербург, Невский 1');
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Сохранить адрес'));
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить адрес'));
    await tester.pumpAndSettle();

    expect(repository.profileUpdates.single['address'], 'Санкт-Петербург, Невский 1');
  });

  testWidgets('выход требует подтверждения и очищает Keychain', (tester) async {
    final storage = FakeCredentialsStorage(_saved);
    final repository = FakeAuthRepository();
    await pumpApp(tester, authRepository: repository, credentialsStorage: storage);
    await openTab(tester, 'Профиль');

    await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Выйти из аккаунта'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Выйти из аккаунта'));
    await tester.pumpAndSettle();
    expect(find.text('Выйти из аккаунта?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('Войдите в аккаунт'), findsOneWidget);
    expect(storage.credentials, isNull);
    expect(repository.loggedOutTokens, ['refresh-1']);
  });
}
