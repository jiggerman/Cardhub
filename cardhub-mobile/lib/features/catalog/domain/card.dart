import '../../../core/utils/json_parsing.dart';
import 'card_offer.dart';

/// Карта каталога. Поля повторяют ответ `/api/cards/{name}` и `/api/card/{id}`.
class MtgCard {
  const MtgCard({
    required this.id,
    required this.name,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    required this.color,
    required this.type,
    required this.imageUrlSmall,
    required this.imageUrlNormal,
    required this.imageUrlLarge,
    required this.inStock,
    required this.minPrice,
    required this.availableQualities,
    required this.offers,
  });

  final int id;
  final String name;
  final String setCode;
  final String setName;
  final String collectorNumber;
  final String color;
  final String type;
  final String imageUrlSmall;
  final String imageUrlNormal;
  final String imageUrlLarge;
  final int inStock;
  final double? minPrice;
  final List<String> availableQualities;
  final List<CardOffer> offers;

  /// В вебе карта без остатков показывается как предзаказ.
  bool get isPreorder => inStock <= 0;

  /// Крупная картинка для карточки товара, мелкая — для списка.
  String get previewImage => imageUrlNormal.isNotEmpty ? imageUrlNormal : imageUrlSmall;

  String get detailImage => imageUrlLarge.isNotEmpty ? imageUrlLarge : previewImage;

  List<CardOffer> get availableOffers => offers.where((offer) => offer.isAvailable).toList();

  factory MtgCard.fromJson(Map<String, dynamic> json) => MtgCard(
        id: asInt(json['id']),
        name: asString(json['name']),
        setCode: asString(json['set_code']),
        setName: asString(json['set_name']),
        collectorNumber: asString(json['collection_number']),
        color: asString(json['color']),
        type: asString(json['card_type']),
        imageUrlSmall: asString(json['image_url_small']),
        imageUrlNormal: asString(json['image_url_normal']),
        imageUrlLarge: asString(json['image_url_large']),
        inStock: asInt(json['in_stock']),
        minPrice: asDouble(json['min_price']),
        availableQualities:
            (json['available_qualities'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(),
        offers: (json['offers'] as List<dynamic>? ?? const [])
            .map((item) => CardOffer.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

/// Результат поиска: бэкенд отдаёт всю выдачу разом (`{counter, cards}`),
/// поэтому страницы нарезаются уже на клиенте.
class CardSearchResult {
  const CardSearchResult({required this.total, required this.cards});

  final int total;
  final List<MtgCard> cards;

  static const empty = CardSearchResult(total: 0, cards: []);

  factory CardSearchResult.fromJson(Map<String, dynamic> json) => CardSearchResult(
        total: asInt(json['counter']),
        cards: (json['cards'] as List<dynamic>? ?? const [])
            .map((item) => MtgCard.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
