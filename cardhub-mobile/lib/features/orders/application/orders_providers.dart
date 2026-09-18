import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/domain/order_type.dart';
import '../../catalog/data/cards_repository.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

/// История заказов. Перечитывается после оформления и по свайпу вниз.
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return const [];
  return ref.watch(ordersRepositoryProvider).list();
});

/// Данные, которые пользователь заполняет на оформлении. Уходят на бэкенд
/// целиком в поле shipping_address — так же делает веб-клиент.
class CheckoutForm {
  const CheckoutForm({
    required this.name,
    required this.email,
    required this.phone,
    required this.telegram,
    required this.address,
    required this.shipping,
    required this.payment,
  });

  final String name;
  final String email;
  final String phone;
  final String telegram;
  final String address;
  final ShippingMethod shipping;
  final PaymentMethod payment;

  Map<String, dynamic> toShippingAddress() => {
        'name': name,
        'email': email,
        'phone': phone,
        'telegram': telegram,
        'address': address,
        'payment': payment.apiValue,
      };
}

/// Итог оформления: какие заказы созданы и что не удалось.
class CheckoutOutcome {
  const CheckoutOutcome({required this.orders, this.warning});

  final List<Order> orders;
  final String? warning;

  bool get isPartial => warning != null;
}

final checkoutProvider = AsyncNotifierProvider<CheckoutController, CheckoutOutcome?>(CheckoutController.new);

class CheckoutController extends AsyncNotifier<CheckoutOutcome?> {
  @override
  Future<CheckoutOutcome?> build() async => null;

  /// Корзина может содержать все три типа сразу, а бэкенд создаёт один заказ
  /// на один тип — поэтому отправляем по заказу на каждый тип, как веб.
  Future<void> submit(CheckoutForm form) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = ref.read(cartProvider);
      if (items.isEmpty) throw const ApiException('Корзина пуста');

      await _ensureOffersAreFresh(items);

      final grouped = <OrderType, List<CartItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.orderType, () => []).add(item);
      }

      final repository = ref.read(ordersRepositoryProvider);
      final created = <Order>[];
      final done = <OrderType>{};
      String? warning;

      for (final entry in grouped.entries) {
        try {
          created.add(await repository.create(
            type: entry.key,
            items: entry.value,
            shippingMethod: form.shipping.apiValue,
            shippingAddress: form.toShippingAddress(),
          ));
          done.add(entry.key);
        } on ApiException catch (error) {
          // Часть заказов уже создана — сообщаем и оставляем в корзине остаток.
          if (created.isEmpty) rethrow;
          warning = 'Создано заказов: ${created.length}. Остальные позиции остались в корзине: ${error.message}';
          break;
        }
      }

      ref.read(cartProvider.notifier).removeTypes(done);
      ref.invalidate(ordersProvider);
      return CheckoutOutcome(orders: created, warning: warning);
    });
  }

  /// Остатки меняются, а корзина хранит их снимок. Перед отправкой
  /// перепроверяем позиции для покупки, чтобы вместо ошибки сервера показать
  /// понятное объяснение.
  Future<void> _ensureOffersAreFresh(List<CartItem> items) async {
    final purchases = items.where((item) => item.orderType.needsOffer).toList();
    if (purchases.isEmpty) return;

    final cards = ref.read(cardsRepositoryProvider);
    for (final cardId in purchases.map((item) => item.card.id).toSet()) {
      final fresh = await cards.byId(cardId);
      for (final item in purchases.where((item) => item.card.id == cardId)) {
        final offer = fresh.offers.where((offer) => offer.id == item.offerId).firstOrNull;
        if (offer == null || offer.quantity < item.quantity) {
          throw ApiException(
            'Карты «${fresh.name}» осталось меньше, чем в корзине. '
            'Откройте карточку и добавьте позицию заново',
          );
        }
      }
    }
  }

  void reset() => state = const AsyncData(null);
}
