import 'package:intl/intl.dart';

final _price = NumberFormat.decimalPattern('ru');

/// «1 445 ₽» — разряды разделяет неразрывный пробел, как принято в русской
/// типографике (его же подставляет NumberFormat). Для позиций без цены
/// (предзаказ, заказ у партнёра) — текст-заглушка, как в вебе.
String formatPrice(double? value, {String fallback = 'по запросу'}) {
  if (value == null) return fallback;
  final rounded = value.roundToDouble() == value ? value.toInt() : value;
  return '${_price.format(rounded)} ₽';
}

/// Русское склонение: 1 карта, 2 карты, 5 карт.
String plural(int count, String one, String few, String many) {
  final mod100 = count % 100;
  final mod10 = count % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

String cardsCount(int count) => '$count ${plural(count, 'карта', 'карты', 'карт')}';
