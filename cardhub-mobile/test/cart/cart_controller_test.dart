import 'package:cardhub_mobile/features/cart/application/cart_controller.dart';
import 'package:cardhub_mobile/features/cart/data/cart_storage.dart';
import 'package:cardhub_mobile/features/cart/domain/cart_item.dart';
import 'package:cardhub_mobile/features/cart/domain/order_type.dart';
import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_cards_repository.dart';
import '../support/fake_cart_storage.dart';

final _card = MtgCard.fromJson(cardJson());

/// Карта с большим остатком одной позиции — удобно проверять лимиты.
MtgCard _cardWithStock(int quantity, {int id = 1}) => MtgCard.fromJson(cardJson(
      id: id,
      inStock: quantity,
      offers: [
        {'id': 100 + id, 'quality': 'NM', 'lang': 'en', 'foil': false, 'quantity': quantity, 'price': '100.00'},
      ],
    ));

({ProviderContainer container, FakeCartStorage storage}) _setup([FakeCartStorage? storage]) {
  final cartStorage = storage ?? FakeCartStorage();
  final container = ProviderContainer(overrides: [cartStorageProvider.overrideWithValue(cartStorage)]);
  addTearDown(container.dispose);
  return (container: container, storage: cartStorage);
}

void main() {
  group('добавление', () {
    test('покупка подбирает складскую позицию нужного состояния', () {
      final (:container, :storage) = _setup();

      final result = container.read(cartProvider.notifier).add(_card, orderType: OrderType.purchase, quality: 'NM');

      expect(result, CartAddResult.added);
      final item = container.read(cartProvider).single;
      expect(item.quality, 'NM');
      expect(item.offerId, 4);
      expect(item.unitPrice, 1445.0);
      expect(item.orderType, OrderType.purchase);
    });

    test('если нужного состояния нет, берётся самая дешёвая позиция', () {
      final (:container, :storage) = _setup();

      container.read(cartProvider.notifier).add(_card, orderType: OrderType.purchase, quality: 'HP');

      final item = container.read(cartProvider).single;
      expect(item.quality, 'MP');
      expect(item.unitPrice, 818.0);
    });

    test('предзаказ обходится без складской позиции и без цены', () {
      final (:container, :storage) = _setup();

      container.read(cartProvider.notifier).add(
            MtgCard.fromJson(cardJson(inStock: 0, minPrice: null, offers: [])),
            orderType: OrderType.reservation,
            quality: 'SP',
          );

      final item = container.read(cartProvider).single;
      expect(item.offerId, isNull);
      expect(item.unitPrice, isNull);
      expect(item.quality, 'SP');
      expect(item.priceIsPending, isTrue);
    });

    test('купить нельзя, когда остатков нет', () {
      final (:container, :storage) = _setup();

      final result = container.read(cartProvider.notifier).add(
            MtgCard.fromJson(cardJson(inStock: 0, offers: [])),
            orderType: OrderType.purchase,
          );

      expect(result, CartAddResult.outOfStock);
      expect(container.read(cartProvider), isEmpty);
    });

    test('повторное добавление увеличивает количество позиции', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      cart.add(_cardWithStock(10), orderType: OrderType.purchase);
      cart.add(_cardWithStock(10), orderType: OrderType.purchase);

      expect(container.read(cartProvider).single.quantity, 2);
    });

    test('одна и та же карта разного типа — разные позиции', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      cart.add(_cardWithStock(10), orderType: OrderType.purchase);
      cart.add(_cardWithStock(10), orderType: OrderType.reservation, quality: 'NM');

      expect(container.read(cartProvider).length, 2);
    });
  });

  group('лимиты', () {
    test('больше четырёх одинаковых карт не берём', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      cart.add(_cardWithStock(10), orderType: OrderType.purchase, quantity: 4);
      final result = cart.add(_cardWithStock(10), orderType: OrderType.purchase);

      expect(result, CartAddResult.itemLimit);
      expect(container.read(cartProvider).single.quantity, 4);
    });

    test('количество ограничено остатком на складе', () {
      final (:container, :storage) = _setup();

      container.read(cartProvider.notifier).add(_cardWithStock(2), orderType: OrderType.purchase, quantity: 4);

      expect(container.read(cartProvider).single.quantity, 2);
    });

    test('в корзину помещается не больше двадцати карт', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      // 5 карт по 4 штуки = 20
      for (var id = 1; id <= 5; id++) {
        cart.add(_cardWithStock(10, id: id), orderType: OrderType.purchase, quantity: 4);
      }
      final result = cart.add(_cardWithStock(10, id: 6), orderType: OrderType.purchase);

      expect(result, CartAddResult.cartLimit);
      expect(container.read(cartSummaryProvider).count, 20);
    });

    test('добавляем столько, сколько влезает', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      for (var id = 1; id <= 4; id++) {
        cart.add(_cardWithStock(10, id: id), orderType: OrderType.purchase, quantity: 4);
      }
      cart.add(_cardWithStock(10, id: 9), orderType: OrderType.purchase, quantity: 4);

      expect(container.read(cartSummaryProvider).count, 20);
    });

    test('изменение количества уважает те же границы', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);
      cart.add(_cardWithStock(3), orderType: OrderType.purchase);

      cart.setQuantity(container.read(cartProvider).single, 9);

      expect(container.read(cartProvider).single.quantity, 3);
    });

    test('количество меньше единицы удаляет позицию', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);
      cart.add(_cardWithStock(3), orderType: OrderType.purchase);

      cart.setQuantity(container.read(cartProvider).single, 0);

      expect(container.read(cartProvider), isEmpty);
    });
  });

  group('итоги', () {
    test('считают только позиции с ценой', () {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      cart.add(_cardWithStock(10), orderType: OrderType.purchase, quantity: 2); // 2 × 100
      cart.add(_cardWithStock(10, id: 2), orderType: OrderType.reservation);

      final summary = container.read(cartSummaryProvider);
      expect(summary.total, 200);
      expect(summary.count, 3);
      expect(summary.hasPendingPrices, isTrue);
      expect(summary.byType(OrderType.purchase).length, 1);
      expect(summary.types, {OrderType.purchase, OrderType.reservation});
    });
  });

  group('хранение', () {
    test('корзина сохраняется при каждом изменении', () async {
      final (:container, :storage) = _setup();
      final cart = container.read(cartProvider.notifier);

      cart.add(_cardWithStock(10), orderType: OrderType.purchase);
      await Future<void>.delayed(Duration.zero);

      expect(storage.items.single.card.id, 1);
      expect(storage.saves, 1);
    });

    test('сохранённая корзина восстанавливается при запуске', () async {
      final saved = CartItem(
        card: _card,
        quality: 'NM',
        quantity: 2,
        orderType: OrderType.purchase,
        offerId: 4,
        unitPrice: 1445,
        addedAt: DateTime(2026, 9, 18),
      );
      final (:container, :storage) = _setup(FakeCartStorage([saved]));

      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      final item = container.read(cartProvider).single;
      expect(item.card.name, 'Lightning Bolt');
      expect(item.quantity, 2);
      expect(item.unitPrice, 1445);
    });

    test('позиция переживает сохранение и чтение', () {
      final item = CartItem(
        card: _card,
        quality: 'MP',
        quantity: 3,
        orderType: OrderType.import,
        offerId: null,
        unitPrice: null,
        addedAt: DateTime(2026, 9, 18, 12, 30),
      );

      final restored = CartItem.fromJson(item.toJson());

      expect(restored.card.id, item.card.id);
      expect(restored.card.offers.length, item.card.offers.length);
      expect(restored.quality, 'MP');
      expect(restored.quantity, 3);
      expect(restored.orderType, OrderType.import);
      expect(restored.unitPrice, isNull);
      expect(restored.addedAt, item.addedAt);
    });
  });

  test('очистка и удаление по типам', () {
    final (:container, :storage) = _setup();
    final cart = container.read(cartProvider.notifier);
    cart.add(_cardWithStock(10), orderType: OrderType.purchase);
    cart.add(_cardWithStock(10, id: 2), orderType: OrderType.reservation);

    cart.removeTypes({OrderType.purchase});
    expect(container.read(cartProvider).single.orderType, OrderType.reservation);

    cart.clear();
    expect(container.read(cartProvider), isEmpty);
  });
}
