import 'package:cardhub_mobile/features/auth/data/credentials_storage.dart';
import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:cardhub_mobile/features/orders/domain/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';
import '../support/fake_cards_repository.dart';
import '../support/fake_orders_repository.dart';
import '../support/pump_app.dart';

const _saved = Credentials(email: 'ios@test.dev', password: 'Str0ngPass!42');

final _card = MtgCard.fromJson(cardJson(inStock: 9, offers: [
  {'id': 11, 'quality': 'NM', 'lang': 'en', 'foil': false, 'quantity': 9, 'price': '100.00'},
]));

Future<void> _addToCart(WidgetTester tester) async {
  await search(tester, 'bolt');
  await openCard(tester, 'Lightning Bolt');
  await scrollTo(tester, find.widgetWithText(FilledButton, 'В корзину'));
  await tester.tap(find.widgetWithText(FilledButton, 'В корзину'));
  await tester.pumpAndSettle();
  // Уведомление «Добавлено в корзину» висит внизу и перехватывает тапы.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _openCheckout(WidgetTester tester) async {
  await openTab(tester, 'Корзина');
  await scrollTo(tester, find.widgetWithText(FilledButton, 'Перейти к оформлению'));
  await tester.tap(find.widgetWithText(FilledButton, 'Перейти к оформлению'));
  await tester.pumpAndSettle();
}

Future<void> _fillContacts(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Телефон'), '+7 999 000-00-00');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Город, улица, дом, квартира'),
    'Санкт-Петербург, Невский проспект, 1',
  );
  // Пользователь убирает клавиатуру перед тем, как жать кнопку внизу формы.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await _fillContacts(tester);
  await scrollTo(tester, find.byType(CheckboxListTile));
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await scrollTo(tester, find.widgetWithText(FilledButton, 'Подтвердить заказ'));
  await tester.tap(find.widgetWithText(FilledButton, 'Подтвердить заказ'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('без входа оформление начинается с экрана авторизации', (tester) async {
    await pumpApp(tester, repository: FakeCardsRepository(cards: [_card]));
    await _addToCart(tester);
    await _openCheckout(tester);

    expect(find.text('С возвращением'), findsOneWidget);
  });

  testWidgets('оформление подставляет данные из профиля', (tester) async {
    await pumpApp(
      tester,
      repository: FakeCardsRepository(cards: [_card]),
      credentialsStorage: FakeCredentialsStorage(_saved),
      authRepository: FakeAuthRepository(
        user: userJson(telegramUsername: 'ios_tester', shippingAddress: {'address': 'Невский проспект, 1'}),
      ),
    );
    await _addToCart(tester);
    await _openCheckout(tester);

    expect(find.text('ios'), findsWidgets);
    expect(find.text('ios@test.dev'), findsOneWidget);
    expect(find.text('ios_tester'), findsOneWidget);
    expect(find.text('Невский проспект, 1'), findsOneWidget);
  });

  testWidgets('заказ создаётся и попадает в историю', (tester) async {
    final orders = FakeOrdersRepository();
    await pumpApp(
      tester,
      repository: FakeCardsRepository(cards: [_card]),
      credentialsStorage: FakeCredentialsStorage(_saved),
      ordersRepository: orders,
    );
    await _addToCart(tester);
    await _openCheckout(tester);
    await _fillAndSubmit(tester);

    expect(find.text('Готово'), findsOneWidget);
    expect(orders.created.single.items.single.offerId, 11);

    await tester.tap(find.widgetWithText(OutlinedButton, 'К моим заказам'));
    await tester.pumpAndSettle();

    expect(find.text('Заказ №1'), findsOneWidget);
    expect(find.text('Ожидает оплаты'), findsOneWidget);
    expect(find.text('Lightning Bolt'), findsOneWidget);
  });

  testWidgets('без согласия с условиями заказ не отправляется', (tester) async {
    final orders = FakeOrdersRepository();
    await pumpApp(
      tester,
      repository: FakeCardsRepository(cards: [_card]),
      credentialsStorage: FakeCredentialsStorage(_saved),
      ordersRepository: orders,
    );
    await _addToCart(tester);
    await _openCheckout(tester);

    await _fillContacts(tester);
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Подтвердить заказ'));
    await tester.tap(find.widgetWithText(FilledButton, 'Подтвердить заказ'));
    await tester.pumpAndSettle();

    expect(find.text('Подтвердите согласие с условиями'), findsOneWidget);
    expect(orders.created, isEmpty);
  });

  testWidgets('без телефона заказ не отправляется', (tester) async {
    final orders = FakeOrdersRepository();
    await pumpApp(
      tester,
      repository: FakeCardsRepository(cards: [_card]),
      credentialsStorage: FakeCredentialsStorage(_saved),
      ordersRepository: orders,
    );
    await _addToCart(tester);
    await _openCheckout(tester);

    await scrollTo(tester, find.widgetWithText(FilledButton, 'Подтвердить заказ'));
    await tester.tap(find.widgetWithText(FilledButton, 'Подтвердить заказ'));
    await tester.pumpAndSettle();

    expect(find.text('Нужен номер для связи'), findsOneWidget);
    expect(orders.created, isEmpty);
  });

  testWidgets('заказы требуют входа', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Заказы');

    expect(find.text('Войдите, чтобы увидеть заказы'), findsOneWidget);
  });

  testWidgets('история показывает статус, трек-номер и цену', (tester) async {
    await pumpApp(
      tester,
      credentialsStorage: FakeCredentialsStorage(_saved),
      ordersRepository: FakeOrdersRepository(orders: [
        Order.fromJson(orderJson(id: 7, status: 'in_transit', tracking: 'RU123456789')),
        Order.fromJson(orderJson(id: 8, type: 'reservation', status: 'under_consideration', unitPrice: null)),
      ]),
    );
    await openTab(tester, 'Заказы');

    expect(find.text('Заказ №7'), findsOneWidget);
    expect(find.text('В доставке'), findsOneWidget);
    expect(find.text('Трек-номер: RU123456789'), findsOneWidget);
    // Сумма встречается и в строке позиции, и в итоге заказа
    expect(find.text('1 636 ₽'), findsWidgets);

    await scrollTo(tester, find.text('Заказ №8'));
    expect(find.text('На рассмотрении'), findsOneWidget);
    expect(find.text('цена уточняется'), findsOneWidget);
  });
}
