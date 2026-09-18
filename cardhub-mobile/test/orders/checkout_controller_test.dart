import 'package:cardhub_mobile/core/network/api_exception.dart';
import 'package:cardhub_mobile/features/cart/application/cart_controller.dart';
import 'package:cardhub_mobile/features/cart/data/cart_storage.dart';
import 'package:cardhub_mobile/features/cart/domain/order_type.dart';
import 'package:cardhub_mobile/features/catalog/data/cards_repository.dart';
import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:cardhub_mobile/features/orders/application/orders_providers.dart';
import 'package:cardhub_mobile/features/orders/data/orders_repository.dart';
import 'package:cardhub_mobile/features/orders/domain/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_cards_repository.dart';
import '../support/fake_cart_storage.dart';
import '../support/fake_orders_repository.dart';

const _form = CheckoutForm(
  name: 'Иван',
  email: 'ios@test.dev',
  phone: '+7 999 000-00-00',
  telegram: 'ios_tester',
  address: 'Санкт-Петербург, Невский 1',
  shipping: ShippingMethod.cdek,
  payment: PaymentMethod.card,
);

MtgCard _card({int id = 1, int quantity = 9}) => MtgCard.fromJson(cardJson(id: id, inStock: quantity, offers: [
      {'id': 100 + id, 'quality': 'NM', 'lang': 'en', 'foil': false, 'quantity': quantity, 'price': '100.00'},
    ]));

({ProviderContainer container, FakeOrdersRepository orders, FakeCardsRepository cards}) _setup({
  FakeOrdersRepository? orders,
  List<MtgCard>? cards,
}) {
  final ordersRepository = orders ?? FakeOrdersRepository();
  final cardsRepository = FakeCardsRepository(cards: cards ?? [_card()]);
  final container = ProviderContainer(overrides: [
    ordersRepositoryProvider.overrideWithValue(ordersRepository),
    cardsRepositoryProvider.overrideWithValue(cardsRepository),
    cartStorageProvider.overrideWithValue(FakeCartStorage()),
  ]);
  addTearDown(container.dispose);
  return (container: container, orders: ordersRepository, cards: cardsRepository);
}

void main() {
  test('позиции разных типов уходят разными заказами', () async {
    final (:container, :orders, :cards) = _setup();
    final cart = container.read(cartProvider.notifier);
    cart.add(_card(), orderType: OrderType.purchase, quantity: 2);
    cart.add(_card(), orderType: OrderType.reservation);

    await container.read(checkoutProvider.notifier).submit(_form);

    expect(orders.created.map((order) => order.type), [OrderType.purchase, OrderType.reservation]);
    expect(container.read(checkoutProvider).value?.orders.length, 2);
    expect(container.read(cartProvider), isEmpty, reason: 'оформленные позиции уходят из корзины');
  });

  test('в заказ уходят складская позиция, состояние и количество', () async {
    final (:container, :orders, :cards) = _setup();
    container.read(cartProvider.notifier).add(_card(), orderType: OrderType.purchase, quantity: 3);

    await container.read(checkoutProvider.notifier).submit(_form);

    final sent = orders.created.single;
    expect(sent.items.single.offerId, 101);
    expect(sent.items.single.quantity, 3);
    expect(sent.shipping, 'cdek');
    expect(sent.address['address'], 'Санкт-Петербург, Невский 1');
    expect(sent.address['payment'], 'card');
    expect(sent.address['phone'], '+7 999 000-00-00');
  });

  test('история заказов перечитывается после оформления', () async {
    final (:container, :orders, :cards) = _setup();
    container.read(cartProvider.notifier).add(_card(), orderType: OrderType.purchase);

    await container.read(checkoutProvider.notifier).submit(_form);

    expect(orders.orders.single.id, 1);
  });

  group('проверка остатков перед отправкой', () {
    test('исчезнувшая позиция объясняется человеку, заказ не создаётся', () async {
      final (:container, :orders, :cards) = _setup();
      container.read(cartProvider.notifier).add(_card(), orderType: OrderType.purchase, quantity: 2);
      // На сервере позиция закончилась, пока карта лежала в корзине.
      cards.cards = [MtgCard.fromJson(cardJson(id: 1, inStock: 0, offers: []))];

      await container.read(checkoutProvider.notifier).submit(_form);

      final state = container.read(checkoutProvider);
      expect(state.hasError, isTrue);
      expect((state.error as ApiException).message, contains('осталось меньше'));
      expect(orders.created, isEmpty);
      expect(container.read(cartProvider), hasLength(1), reason: 'корзина остаётся нетронутой');
    });

    test('предзаказ проверять нечего — складской позиции у него нет', () async {
      final (:container, :orders, :cards) = _setup(cards: []);
      container.read(cartProvider.notifier).add(
            MtgCard.fromJson(cardJson(id: 5, inStock: 0, offers: [])),
            orderType: OrderType.reservation,
          );

      await container.read(checkoutProvider.notifier).submit(_form);

      expect(container.read(checkoutProvider).hasError, isFalse);
      expect(orders.created.single.type, OrderType.reservation);
    });
  });

  test('если второй заказ не создался, первый остаётся и корзина чистится частично', () async {
    final orders = FakeOrdersRepository(
      createFailure: const ApiException('Недостаточно карты «Lightning Bolt» в наличии', statusCode: 400),
      failingType: OrderType.reservation,
    );
    final (container: container, orders: _, cards: _) = _setup(orders: orders);
    final cart = container.read(cartProvider.notifier);
    cart.add(_card(), orderType: OrderType.purchase);
    cart.add(_card(), orderType: OrderType.reservation);

    await container.read(checkoutProvider.notifier).submit(_form);

    final outcome = container.read(checkoutProvider).value;
    expect(outcome?.orders.length, 1);
    expect(outcome?.isPartial, isTrue);
    expect(outcome?.warning, contains('остались в корзине'));
    expect(container.read(cartProvider).single.orderType, OrderType.reservation);
  });

  test('пустая корзина не отправляется', () async {
    final (:container, :orders, :cards) = _setup();

    await container.read(checkoutProvider.notifier).submit(_form);

    expect(container.read(checkoutProvider).hasError, isTrue);
    expect(orders.created, isEmpty);
  });
}
