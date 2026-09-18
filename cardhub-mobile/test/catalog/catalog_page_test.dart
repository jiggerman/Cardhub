import 'package:cardhub_mobile/core/network/api_exception.dart';
import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_cards_repository.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('до трёх символов запрос не уходит', (tester) async {
    final repository = FakeCardsRepository();
    await pumpApp(tester, repository: repository);

    expect(find.text('Найдите нужную карту'), findsOneWidget);

    await search(tester, 'bo');

    expect(repository.queries, isEmpty);
    expect(find.text('Найдите нужную карту'), findsOneWidget);
  });

  testWidgets('поиск показывает найденные карты', (tester) async {
    final repository = FakeCardsRepository();
    await pumpApp(tester, repository: repository);

    await search(tester, 'bolt');

    expect(repository.queries, ['bolt']);
    expect(find.text('Найдено 1 карта'), findsOneWidget);
    expect(find.text('Lightning Bolt'), findsOneWidget);
    expect(find.text('от 818 ₽'), findsOneWidget);
  });

  testWidgets('быстрый набор отправляет один запрос', (tester) async {
    final repository = FakeCardsRepository();
    await pumpApp(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'bol');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'bolt');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.queries, ['bolt']);
  });

  testWidgets('подгрузка показывает следующую страницу', (tester) async {
    final repository = FakeCardsRepository(
      cards: [for (var i = 1; i <= 25; i++) MtgCard.fromJson(cardJson(id: i, name: 'Карта $i'))],
    );
    await pumpApp(tester, repository: repository);

    await search(tester, 'карта');

    expect(find.text('Найдено 25 карт'), findsOneWidget);

    // Кнопка подгрузки лежит под сеткой — сначала прокручиваем до неё.
    final showMore = find.textContaining('Показать ещё');
    await scrollTo(tester, showMore, step: 400);
    expect(find.textContaining('осталось 5'), findsOneWidget);

    await tester.tap(showMore);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Показаны все результаты'), step: 400);

    expect(find.text('Показаны все результаты'), findsOneWidget);
    expect(repository.queries, ['карта']);
  });

  testWidgets('пустая выдача объясняет, что делать', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: []));

    await search(tester, 'zzzz');

    expect(find.text('Ничего не нашли'), findsOneWidget);
  });

  testWidgets('ошибка сети показывает кнопку повтора', (tester) async {
    await pumpApp(
      tester,
      repository: FakeCardsRepository(failure: const ApiException('Нет связи с сервером')),
    );

    await search(tester, 'bolt');

    expect(find.text('Каталог недоступен'), findsOneWidget);
    expect(find.text('Нет связи с сервером'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Повторить'), findsOneWidget);
  });

  testWidgets('тап по карте открывает карточку с предложениями', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository());

    await search(tester, 'bolt');
    await tester.tap(find.text('Lightning Bolt'));
    await tester.pumpAndSettle();

    expect(find.text('На складе'), findsOneWidget);

    // Список предложений ниже картинки — докручиваем.
    await scrollTo(tester, find.text('Предложения'));
    expect(find.text('1 445 ₽'), findsOneWidget);
    expect(find.text('MP'), findsOneWidget);

    await scrollTo(tester, find.text('Добавить в корзину'));
    expect(find.widgetWithText(FilledButton, 'Добавить в корзину'), findsOneWidget);
  });

  testWidgets('карта без остатков предлагает предзаказ', (tester) async {
    await pumpApp(
      tester,
      repository: FakeCardsRepository(
        cards: [MtgCard.fromJson(cardJson(inStock: 0, minPrice: null, offers: []))],
      ),
    );

    await search(tester, 'bolt');
    await tester.tap(find.text('Lightning Bolt'));
    await tester.pumpAndSettle();

    expect(find.text('Предзаказ'), findsOneWidget);

    await scrollTo(tester, find.textContaining('Карты нет на складе'));
    await scrollTo(tester, find.text('Оформить предзаказ'));
    expect(find.widgetWithText(FilledButton, 'Оформить предзаказ'), findsOneWidget);
  });
}
