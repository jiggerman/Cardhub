import 'package:cardhub_mobile/app.dart';
import 'package:cardhub_mobile/features/auth/data/auth_repository.dart';
import 'package:cardhub_mobile/features/auth/data/credentials_storage.dart';
import 'package:cardhub_mobile/features/cart/data/cart_storage.dart';
import 'package:cardhub_mobile/features/catalog/data/cards_repository.dart';
import 'package:cardhub_mobile/features/orders/data/orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fake_auth.dart';
import 'fake_cards_repository.dart';
import 'fake_cart_storage.dart';
import 'fake_orders_repository.dart';

/// Поднимает приложение в окне размером с iPhone 16 Pro: на стандартных для
/// тестов 800×600 плитки каталога не помещаются и тапы уходят мимо.
/// Хранилища подменяются на память — ни SharedPreferences, ни Keychain
/// в тестовом окружении нет.
Future<void> pumpApp(
  WidgetTester tester, {
  FakeCardsRepository? repository,
  FakeCartStorage? cartStorage,
  FakeAuthRepository? authRepository,
  FakeCredentialsStorage? credentialsStorage,
  FakeOrdersRepository? ordersRepository,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Даты заказов показываются по-русски — как и в main().
  await initializeDateFormatting('ru');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null) cardsRepositoryProvider.overrideWithValue(repository),
        cartStorageProvider.overrideWithValue(cartStorage ?? FakeCartStorage()),
        authRepositoryProvider.overrideWithValue(authRepository ?? FakeAuthRepository()),
        credentialsStorageProvider.overrideWithValue(credentialsStorage ?? FakeCredentialsStorage()),
        ordersRepositoryProvider.overrideWithValue(ordersRepository ?? FakeOrdersRepository()),
      ],
      child: const CardHubApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Вводит запрос и ждёт дебаунс (400 мс) вместе с ответом репозитория.
Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Список самой страницы. У текстовых полей есть собственные Scrollable,
/// поэтому «первый» и «последний» на экране — это не то, что нужно крутить.
Finder pageScrollable() {
  for (final type in [ListView, CustomScrollView, SingleChildScrollView]) {
    final scrollables = find.descendant(of: find.byType(type), matching: find.byType(Scrollable));
    if (scrollables.evaluate().isNotEmpty) return scrollables.first;
  }
  return find.byType(Scrollable).first;
}

/// Прокручивает до элемента. Списки строятся лениво, поэтому без прокрутки
/// нижние элементы просто не существуют в дереве.
Future<void> scrollTo(WidgetTester tester, Finder finder, {double step = 300}) async {
  await tester.scrollUntilVisible(finder, step, scrollable: pageScrollable());
  // scrollUntilVisible останавливается, как только виджет построен, а он может
  // быть ещё за нижней границей экрана — тогда тап уходит мимо.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Открывает карточку первой найденной карты.
Future<void> openCard(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Переключает нижнюю вкладку.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}
