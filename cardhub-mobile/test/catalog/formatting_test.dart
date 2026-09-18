import 'package:cardhub_mobile/core/utils/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPrice', () {
    test('разделяет разряды неразрывным пробелом и добавляет рубль', () {
      expect(formatPrice(1445), '1 445 ₽');
      expect(formatPrice(818.0), '818 ₽');
    });

    test('копейки сохраняются', () {
      expect(formatPrice(99.5), '99,5 ₽');
    });

    test('без цены — запасной текст', () {
      expect(formatPrice(null), 'по запросу');
      expect(formatPrice(null, fallback: 'уточняется'), 'уточняется');
    });
  });

  group('склонение', () {
    test('карта / карты / карт', () {
      expect(cardsCount(1), '1 карта');
      expect(cardsCount(3), '3 карты');
      expect(cardsCount(7), '7 карт');
      expect(cardsCount(11), '11 карт');
      expect(cardsCount(21), '21 карта');
      expect(cardsCount(112), '112 карт');
    });
  });
}
