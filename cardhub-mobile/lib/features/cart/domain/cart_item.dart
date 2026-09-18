import '../../../core/utils/json_parsing.dart';
import '../../catalog/domain/card.dart';
import 'order_type.dart';

/// Позиция корзины. Корзина живёт только на устройстве — на бэкенде её нет,
/// как и в вебе (там localStorage).
class CartItem {
  const CartItem({
    required this.card,
    required this.quality,
    required this.quantity,
    required this.orderType,
    required this.offerId,
    required this.unitPrice,
    required this.addedAt,
  });

  final MtgCard card;
  final String quality;
  final int quantity;
  final OrderType orderType;

  /// id складской позиции — обязателен для покупки, для остальных типов null.
  final int? offerId;

  /// Цена за штуку на момент добавления; у предзаказа и заказа её нет.
  final double? unitPrice;
  final DateTime addedAt;

  double get subtotal => (unitPrice ?? 0) * quantity;

  bool get priceIsPending => unitPrice == null;

  /// Позиции считаются одинаковыми при совпадении карты, состояния и типа заказа.
  bool matches(int cardId, String quality, OrderType orderType) =>
      card.id == cardId && this.quality == quality && this.orderType == orderType;

  String get key => '${card.id}-$quality-${orderType.apiValue}';

  CartItem copyWith({int? quantity}) => CartItem(
        card: card,
        quality: quality,
        quantity: quantity ?? this.quantity,
        orderType: orderType,
        offerId: offerId,
        unitPrice: unitPrice,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'card': card.toJson(),
        'quality': quality,
        'quantity': quantity,
        'orderType': orderType.apiValue,
        'offerId': offerId,
        'unitPrice': unitPrice,
        'addedAt': addedAt.toIso8601String(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        card: MtgCard.fromJson(json['card'] as Map<String, dynamic>),
        quality: asString(json['quality'], fallback: 'NM'),
        quantity: asInt(json['quantity'], fallback: 1),
        orderType: OrderType.fromApi(asString(json['orderType'], fallback: 'purchase')),
        offerId: json['offerId'] == null ? null : asInt(json['offerId']),
        unitPrice: asDouble(json['unitPrice']),
        addedAt: DateTime.tryParse(asString(json['addedAt'])) ?? DateTime.now(),
      );
}
