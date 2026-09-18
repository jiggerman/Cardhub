import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/domain/order_type.dart';
import '../domain/order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => OrdersRepository(ref.watch(apiClientProvider)));

class OrdersRepository {
  const OrdersRepository(this._client);

  final ApiClient _client;

  /// `GET /api/orders/` — заказы текущего пользователя, свежие сверху.
  Future<List<Order>> list() async {
    final response = await _client.get('/api/orders/');
    return (response as List<dynamic>).map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// `POST /api/orders/`. Цену и владельца заказа считает сервер: клиент шлёт
  /// только карту, складскую позицию, состояние и количество.
  Future<Order> create({
    required OrderType type,
    required List<CartItem> items,
    required String shippingMethod,
    required Map<String, dynamic> shippingAddress,
  }) async {
    final response = await _client.post('/api/orders/', body: {
      'order': {
        'orderType': type.apiValue,
        'shipping_method': shippingMethod,
        'shipping_address': shippingAddress,
      },
      'cards': [
        for (final item in items)
          {
            'card': item.card.id,
            'card_inventory': type.needsOffer ? item.offerId : null,
            'quality': item.quality,
            'quantity': item.quantity,
          },
      ],
    });
    return Order.fromJson(response as Map<String, dynamic>);
  }
}
