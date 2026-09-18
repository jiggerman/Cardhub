import 'package:cardhub_mobile/features/cart/domain/cart_item.dart';
import 'package:cardhub_mobile/features/cart/domain/order_type.dart';
import 'package:cardhub_mobile/features/orders/data/orders_repository.dart';
import 'package:cardhub_mobile/features/orders/domain/order.dart';

/// Ответ `/api/orders/` в том виде, в каком его отдаёт DRF.
Map<String, dynamic> orderJson({
  int id = 1,
  String type = 'purchase',
  String status = 'pending',
  String tracking = '',
  String? unitPrice = '818.00',
  int quantity = 2,
}) =>
    {
      'id': id,
      'orderType': type,
      'user': 2,
      'status': status,
      'shipping_method': 'cdek',
      'tracking_number': tracking.isEmpty ? null : tracking,
      'shipping_address': {'address': 'Санкт-Петербург'},
      'created_at': '2026-09-18T12:49:57.679118Z',
      'paid_at': null,
      'assembled_at': null,
      'delivered_at': null,
      'items': [
        {
          'id': id * 10,
          'card': {
            'id': 10293,
            'name': 'Lightning Bolt',
            'set_code': 'msc',
            'collection_number': '806',
            'image_url_small': 'https://cards.scryfall.io/small/a.jpg',
          },
          'card_inventory': unitPrice == null ? null : 3,
          'quality': 'MP',
          'quantity': quantity,
          'unit_price': unitPrice,
          'subtotal': unitPrice == null ? null : (double.parse(unitPrice) * quantity).toStringAsFixed(2),
        },
      ],
    };

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({List<Order>? orders, this.createFailure, this.failingType})
      : orders = orders ?? [];

  List<Order> orders;

  /// Ошибка, которую бросает [create] — для проверки частичного оформления.
  Object? createFailure;
  OrderType? failingType;

  final created = <({OrderType type, List<CartItem> items, String shipping, Map<String, dynamic> address})>[];

  @override
  Future<List<Order>> list() async => orders;

  @override
  Future<Order> create({
    required OrderType type,
    required List<CartItem> items,
    required String shippingMethod,
    required Map<String, dynamic> shippingAddress,
  }) async {
    if (createFailure != null && (failingType == null || failingType == type)) throw createFailure!;

    created.add((type: type, items: items, shipping: shippingMethod, address: shippingAddress));
    final order = Order.fromJson(orderJson(id: created.length, type: type.apiValue));
    orders = [order, ...orders];
    return order;
  }
}
