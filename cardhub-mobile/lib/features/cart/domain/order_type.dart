/// Три способа получить карту — ровно те же, что на бэкенде (`OrderType`)
/// и в веб-клиенте. Строковые значения уходят в `/api/orders/` как есть.
enum OrderType {
  purchase('purchase', 'Покупка', 'Есть на складе'),
  reservation('reservation', 'Предзаказ', 'Сообщим о поступлении'),
  import('import', 'Под заказ', 'Проверим у партнёра');

  const OrderType(this.apiValue, this.label, this.hint);

  final String apiValue;
  final String label;
  final String hint;

  /// Покупка требует конкретной складской позиции, остальные типы — нет.
  bool get needsOffer => this == OrderType.purchase;

  static OrderType fromApi(String value) =>
      OrderType.values.firstWhere((type) => type.apiValue == value, orElse: () => OrderType.purchase);
}
