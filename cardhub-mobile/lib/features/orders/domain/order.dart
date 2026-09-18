import '../../../core/utils/json_parsing.dart';
import '../../cart/domain/order_type.dart';

/// Статусы заказа с бэкенда (`OrderStatus`). Подписи — как в веб-клиенте.
enum OrderStatus {
  pending('pending', 'Ожидает оплаты'),
  assembly('assembly', 'Сборка'),
  inTransit('in_transit', 'В доставке'),
  delivered('delivered', 'Доставлен'),
  cancelled('cancelled', 'Отменён'),
  verification('verification', 'Сверка позиций'),
  shippingToSpb('shipping_to_spb', 'Едет в Санкт-Петербург'),
  notified('notified', 'Ожидает клиента'),
  underConsideration('under_consideration', 'На рассмотрении'),
  unknown('', 'Статус уточняется');

  const OrderStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isFinished => this == OrderStatus.delivered || this == OrderStatus.cancelled;

  static OrderStatus fromApi(String value) =>
      OrderStatus.values.firstWhere((status) => status.apiValue == value, orElse: () => OrderStatus.unknown);
}

/// Карта в составе заказа: бэкенд отдаёт только краткие сведения.
class OrderCard {
  const OrderCard({
    required this.id,
    required this.name,
    required this.setCode,
    required this.collectorNumber,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String setCode;
  final String collectorNumber;
  final String imageUrl;

  factory OrderCard.fromJson(Map<String, dynamic> json) => OrderCard(
        id: asInt(json['id']),
        name: asString(json['name']),
        setCode: asString(json['set_code']),
        collectorNumber: asString(json['collection_number']),
        imageUrl: asString(json['image_url_small']),
      );
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.card,
    required this.quality,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final int id;
  final OrderCard card;
  final String quality;
  final int quantity;

  /// У предзаказа и заказа у партнёра цены нет — её подтверждает менеджер.
  final double? unitPrice;
  final double? subtotal;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: asInt(json['id']),
        card: OrderCard.fromJson(json['card'] as Map<String, dynamic>? ?? const {}),
        quality: asString(json['quality'], fallback: 'NM'),
        quantity: asInt(json['quantity']),
        unitPrice: asDouble(json['unit_price']),
        subtotal: asDouble(json['subtotal']),
      );
}

class Order {
  const Order({
    required this.id,
    required this.type,
    required this.status,
    required this.shippingMethod,
    required this.trackingNumber,
    required this.createdAt,
    required this.lines,
  });

  final int id;
  final OrderType type;
  final OrderStatus status;
  final String shippingMethod;
  final String trackingNumber;
  final DateTime? createdAt;
  final List<OrderLine> lines;

  int get itemsCount => lines.fold(0, (sum, line) => sum + line.quantity);

  double get total => lines.fold(0, (sum, line) => sum + (line.subtotal ?? 0));

  bool get hasPendingPrices => lines.any((line) => line.unitPrice == null);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: asInt(json['id']),
        type: OrderType.fromApi(asString(json['orderType'], fallback: 'purchase')),
        status: OrderStatus.fromApi(asString(json['status'])),
        shippingMethod: asString(json['shipping_method']),
        trackingNumber: asString(json['tracking_number']),
        createdAt: DateTime.tryParse(asString(json['created_at']))?.toLocal(),
        lines: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => OrderLine.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

/// Способы доставки повторяют веб-клиент: бэкенд принимает произвольную строку.
enum ShippingMethod {
  cdek('cdek', 'СДЭК', 'До пункта выдачи'),
  post('post', 'Почта России', 'В любое отделение'),
  pickup('pickup', 'Самовывоз', 'Санкт-Петербург');

  const ShippingMethod(this.apiValue, this.label, this.hint);

  final String apiValue;
  final String label;
  final String hint;
}

enum PaymentMethod {
  card('card', 'Банковская карта'),
  sbp('sbp', 'СБП'),
  balance('balance', 'Баланс аккаунта');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
