import 'package:cardhub_mobile/app.dart';
import 'package:cardhub_mobile/features/cart/data/cart_storage.dart';
import 'package:cardhub_mobile/features/catalog/data/cards_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cards_repository.dart';
import 'fake_cart_storage.dart';

/// Поднимает приложение в окне размером с iPhone 16 Pro: на стандартных для
/// тестов 800×600 плитки каталога не помещаются и тапы уходят мимо.
/// Корзина всегда получает хранилище в памяти — SharedPreferences в тестах нет.
Future<void> pumpApp(WidgetTester tester, {FakeCardsRepository? repository, FakeCartStorage? cartStorage}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null) cardsRepositoryProvider.overrideWithValue(repository),
        cartStorageProvider.overrideWithValue(cartStorage ?? FakeCartStorage()),
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

/// Прокручивает до элемента. Явно указываем список страницы: у поля поиска
/// есть собственный Scrollable, и без этого scrollUntilVisible не понимает,
/// какой из них крутить. Списки строятся лениво, поэтому без прокрутки
/// нижние элементы просто не существуют в дереве.
Future<void> scrollTo(WidgetTester tester, Finder finder, {double step = 300}) async {
  await tester.scrollUntilVisible(finder, step, scrollable: find.byType(Scrollable).last);
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
