import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_cards_repository.dart';
import '../support/fake_cart_storage.dart';
import '../support/pump_app.dart';

/// Карта с запасом на складе, чтобы количество упиралось в лимит корзины,
/// а не в остаток.
final _inStock = MtgCard.fromJson(cardJson(inStock: 9, offers: [
  {'id': 11, 'quality': 'NM', 'lang': 'en', 'foil': false, 'quantity': 9, 'price': '100.00'},
]));

Future<void> _addFromCard(WidgetTester tester, {int taps = 1}) async {
  await search(tester, 'bolt');
  await openCard(tester, 'Lightning Bolt');
  await scrollTo(tester, find.widgetWithText(FilledButton, 'В корзину'));
  for (var i = 0; i < taps; i++) {
    await tester.tap(find.widgetWithText(FilledButton, 'В корзину'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('пустая корзина зовёт в каталог', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository());

    await openTab(tester, 'Корзина');

    expect(find.text('Корзина пока пуста'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Перейти в каталог'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Каталог'), findsOneWidget);
  });

  testWidgets('карта из карточки попадает в корзину и на счётчик вкладки', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]));

    await _addFromCard(tester);

    expect(find.text('Добавлено в корзину'), findsOneWidget);
    expect(find.widgetWithText(Badge, '1'), findsOneWidget);

    await openTab(tester, 'Корзина');

    expect(find.text('Lightning Bolt'), findsOneWidget);
    expect(find.text('Покупка'), findsOneWidget);
    expect(find.text('1 карта из 20 возможных'), findsOneWidget);
    expect(find.text('100 ₽'), findsWidgets);
  });

  testWidgets('количество меняется прямо в корзине', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]));
    await _addFromCard(tester);
    await openTab(tester, 'Корзина');

    await tester.tap(find.byTooltip('Больше'));
    await tester.pumpAndSettle();

    expect(find.text('2 карты из 20 возможных'), findsOneWidget);
    expect(find.text('200 ₽'), findsWidgets);
  });

  testWidgets('позиция удаляется', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]));
    await _addFromCard(tester);
    await openTab(tester, 'Корзина');

    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Корзина пока пуста'), findsOneWidget);
  });

  testWidgets('очистка спрашивает подтверждение', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]));
    await _addFromCard(tester);
    await openTab(tester, 'Корзина');

    await tester.tap(find.widgetWithText(TextButton, 'Очистить'));
    await tester.pumpAndSettle();
    expect(find.text('Очистить корзину?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Lightning Bolt'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Очистить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Очистить').last);
    await tester.pumpAndSettle();
    expect(find.text('Корзина пока пуста'), findsOneWidget);
  });

  testWidgets('пятая карта того же вида не добавляется', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]));

    await _addFromCard(tester, taps: 5);

    expect(find.text('Одной карты можно взять не больше 4 штук'), findsOneWidget);
    expect(find.widgetWithText(Badge, '4'), findsOneWidget);
  });

  testWidgets('предзаказ добавляется без цены', (tester) async {
    await pumpApp(
      tester,
      repository: FakeCardsRepository(
        cards: [MtgCard.fromJson(cardJson(inStock: 0, minPrice: null, offers: []))],
      ),
    );

    await search(tester, 'bolt');
    await openCard(tester, 'Lightning Bolt');
    await scrollTo(tester, find.widgetWithText(FilledButton, 'В корзину'));
    await tester.tap(find.widgetWithText(FilledButton, 'В корзину'));
    await tester.pumpAndSettle();

    await openTab(tester, 'Корзина');

    expect(find.text('Предзаказ'), findsOneWidget);
    expect(find.text('уточняется'), findsOneWidget);
    expect(find.textContaining('подтвердит менеджер'), findsOneWidget);
  });

  testWidgets('корзина восстанавливается после перезапуска', (tester) async {
    final storage = FakeCartStorage();
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]), cartStorage: storage);
    await _addFromCard(tester);

    // Второй запуск приложения с тем же хранилищем.
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_inStock]), cartStorage: storage);
    await tester.pumpAndSettle();
    await openTab(tester, 'Корзина');

    expect(find.text('Lightning Bolt'), findsOneWidget);
    expect(find.text('1 карта из 20 возможных'), findsOneWidget);
  });
}
