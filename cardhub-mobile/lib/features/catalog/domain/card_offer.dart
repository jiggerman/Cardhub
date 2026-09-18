import '../../../core/utils/json_parsing.dart';

/// Складская позиция (`CardInventory` на бэкенде): конкретный экземпляр карты
/// с состоянием, языком и ценой. Именно её id уходит в заказ типа «покупка».
class CardOffer {
  const CardOffer({
    required this.id,
    required this.quality,
    required this.language,
    required this.foil,
    required this.quantity,
    required this.price,
  });

  final int id;
  final String quality;
  final String language;
  final bool foil;
  final int quantity;
  final double price;

  bool get isAvailable => quantity > 0;

  factory CardOffer.fromJson(Map<String, dynamic> json) => CardOffer(
        id: asInt(json['id']),
        quality: asString(json['quality'], fallback: 'NM'),
        language: asString(json['lang'], fallback: 'en'),
        foil: asBool(json['foil']),
        quantity: asInt(json['quantity']),
        price: asDouble(json['price']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'quality': quality,
        'lang': language,
        'foil': foil,
        'quantity': quantity,
        'price': price,
      };
}
