import 'package:cardhub_mobile/app.dart';
import 'package:cardhub_mobile/features/catalog/data/cards_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cards_repository.dart';

/// Поднимает приложение в окне размером с iPhone 16 Pro: на стандартных для
/// тестов 800×600 плитки каталога не помещаются и тапы уходят мимо.
Future<void> pumpApp(WidgetTester tester, {FakeCardsRepository? repository}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null) cardsRepositoryProvider.overrideWithValue(repository),
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
Future<void> scrollTo(WidgetTester tester, Finder finder, {double step = 300}) =>
    tester.scrollUntilVisible(finder, step, scrollable: find.byType(Scrollable).last);
