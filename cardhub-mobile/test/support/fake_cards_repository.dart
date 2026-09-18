import 'package:cardhub_mobile/features/catalog/data/cards_repository.dart';
import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:dio/dio.dart';

/// Ответ бэкенда `/api/cards/{name}` в том виде, в каком его отдаёт DRF.
/// Список состояний бэкенд считает по позициям в наличии — фикстура делает
/// так же, чтобы тестовые данные не расходились с настоящими.
Map<String, dynamic> cardJson({
  int id = 1,
  String name = 'Lightning Bolt',
  int inStock = 2,
  String? minPrice = '818.00',
  List<Map<String, dynamic>>? offers,
}) {
  final items = offers ??
      [
        {'id': 3, 'quality': 'MP', 'lang': 'en', 'foil': true, 'quantity': 1, 'price': '818.00'},
        {'id': 4, 'quality': 'NM', 'lang': 'en', 'foil': false, 'quantity': 1, 'price': '1445.00'},
      ];

  return {
      'id': id,
      'color': 'Red',
      'set_code': 'msc',
      'set_name': 'Marvel Super Heroes',
      'collection_number': '806',
      'name': name,
      'card_type': 'Instant',
      'image_url_small': 'https://cards.scryfall.io/small/a.jpg',
      'image_url_normal': 'https://cards.scryfall.io/normal/a.jpg',
      'image_url_large': '',
      'created_at': '2026-09-16T18:10:41.583091Z',
      'updated_at': '2026-09-16T18:10:41.583093Z',
      'in_stock': inStock,
      'min_price': minPrice == null ? null : double.parse(minPrice),
      'available_qualities': items
          .where((item) => (item['quantity'] as int) > 0)
          .map((item) => item['quality'] as String)
          .toSet()
          .toList()
        ..sort(),
      'offers': items,
    };
}

class FakeCardsRepository implements CardsRepository {
  FakeCardsRepository({List<MtgCard>? cards, this.failure})
      : cards = cards ?? [MtgCard.fromJson(cardJson())];

  List<MtgCard> cards;
  final Object? failure;
  final queries = <String>[];

  @override
  Future<CardSearchResult> search(String query, {CancelToken? cancelToken}) async {
    queries.add(query);
    if (failure != null) throw failure!;
    return CardSearchResult(total: cards.length, cards: cards);
  }

  @override
  Future<MtgCard> byId(int id, {CancelToken? cancelToken}) async {
    if (failure != null) throw failure!;
    return cards.firstWhere((card) => card.id == id);
  }
}
