import 'package:cardhub_mobile/features/catalog/domain/card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_cards_repository.dart';

void main() {
  group('MtgCard.fromJson', () {
    test('разбирает ответ каталога', () {
      final card = MtgCard.fromJson(cardJson());

      expect(card.id, 1);
      expect(card.name, 'Lightning Bolt');
      expect(card.setCode, 'msc');
      expect(card.inStock, 2);
      expect(card.minPrice, 818.0);
      expect(card.availableQualities, ['MP', 'NM']);
      expect(card.isPreorder, isFalse);
    });

    test('цена предложения приходит строкой и становится числом', () {
      final card = MtgCard.fromJson(cardJson());

      expect(card.offers.first.price, 818.0);
      expect(card.offers.first.foil, isTrue);
      expect(card.offers.map((offer) => offer.id), [3, 4]);
    });

    test('карта без остатков считается предзаказом', () {
      final card = MtgCard.fromJson(cardJson(inStock: 0, minPrice: null, offers: []));

      expect(card.isPreorder, isTrue);
      expect(card.minPrice, isNull);
      expect(card.availableOffers, isEmpty);
    });

    test('позиции с нулевым остатком не попадают в доступные', () {
      final card = MtgCard.fromJson(cardJson(offers: [
        {'id': 7, 'quality': 'NM', 'lang': 'en', 'foil': false, 'quantity': 0, 'price': '100.00'},
        {'id': 8, 'quality': 'SP', 'lang': 'ru', 'foil': false, 'quantity': 4, 'price': '90.00'},
      ]));

      expect(card.offers.length, 2);
      expect(card.availableOffers.map((offer) => offer.id), [8]);
    });

    test('у двусторонних карт пустые картинки — берём что есть', () {
      final json = cardJson()
        ..['image_url_normal'] = ''
        ..['image_url_large'] = '';
      final card = MtgCard.fromJson(json);

      expect(card.previewImage, 'https://cards.scryfall.io/small/a.jpg');
      expect(card.detailImage, 'https://cards.scryfall.io/small/a.jpg');
    });
  });

  test('CardSearchResult читает counter и cards', () {
    final result = CardSearchResult.fromJson({
      'counter': 2,
      'cards': [cardJson(id: 1), cardJson(id: 2, name: 'Sol Ring')],
    });

    expect(result.total, 2);
    expect(result.cards.map((card) => card.name), ['Lightning Bolt', 'Sol Ring']);
  });
}
