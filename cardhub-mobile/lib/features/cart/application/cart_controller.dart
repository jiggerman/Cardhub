import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../catalog/domain/card.dart';
import '../../catalog/domain/card_offer.dart';
import '../data/cart_storage.dart';
import '../domain/cart_item.dart';
import '../domain/order_type.dart';

final cartProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);

/// Итоги корзины, чтобы экраны не считали одно и то же.
final cartSummaryProvider = Provider<CartSummary>((ref) => CartSummary(ref.watch(cartProvider)));

/// Чем закончилась попытка добавить карту. Веб в таких случаях молча ничего
/// не делает или показывает alert — на телефоне отвечаем понятным сообщением.
enum CartAddResult {
  added,
  cartLimit,
  itemLimit,
  outOfStock;

  bool get isSuccess => this == CartAddResult.added;

  String get message => switch (this) {
        CartAddResult.added => 'Добавлено в корзину',
        CartAddResult.cartLimit => 'В корзину помещается не больше ${AppConfig.maxCartItems} карт',
        CartAddResult.itemLimit => 'Одной карты можно взять не больше ${AppConfig.maxItemQuantity} штук',
        CartAddResult.outOfStock => 'Эта позиция закончилась. Обновите карточку карты',
      };
}

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    _restore();
    return const [];
  }

  Future<void> _restore() async {
    final saved = await ref.read(cartStorageProvider).load();
    // Пока корзина грузилась, пользователь мог что-то добавить — не затираем.
    if (saved.isNotEmpty && state.isEmpty) state = saved;
  }

  void _update(List<CartItem> items) {
    state = items;
    ref.read(cartStorageProvider).save(items);
  }

  /// Для покупки подбираем складскую позицию: сначала нужного состояния,
  /// иначе самую дешёвую доступную (так же поступает веб-клиент).
  CardOffer? _pickOffer(MtgCard card, String quality) {
    final available = [...card.availableOffers]..sort((a, b) => a.price.compareTo(b.price));
    if (available.isEmpty) return null;
    return available.firstWhere((offer) => offer.quality == quality, orElse: () => available.first);
  }

  CartAddResult add(
    MtgCard card, {
    required OrderType orderType,
    String quality = 'NM',
    int quantity = 1,
  }) {
    final offer = orderType.needsOffer ? _pickOffer(card, quality) : null;
    if (orderType.needsOffer && offer == null) return CartAddResult.outOfStock;

    final itemQuality = offer?.quality ?? quality;
    final existing = state.where((item) => item.matches(card.id, itemQuality, orderType)).firstOrNull;

    final current = existing?.quantity ?? 0;
    final limit = _maxQuantity(offer);
    if (current >= limit) return CartAddResult.itemLimit;

    // Сколько штук ещё влезает в корзину целиком.
    final room = AppConfig.maxCartItems - _totalQuantity;
    if (room <= 0) return CartAddResult.cartLimit;

    // Просят больше, чем можно — добавляем сколько влезает.
    final target = (current + quantity).clamp(1, limit).clamp(1, current + room);

    if (existing != null) {
      _update([
        for (final item in state)
          item.matches(card.id, itemQuality, orderType) ? item.copyWith(quantity: target) : item,
      ]);
    } else {
      _update([
        ...state,
        CartItem(
          card: card,
          quality: itemQuality,
          quantity: target,
          orderType: orderType,
          offerId: offer?.id,
          unitPrice: offer?.price,
          addedAt: DateTime.now(),
        ),
      ]);
    }

    return CartAddResult.added;
  }

  int get _totalQuantity => state.fold(0, (sum, item) => sum + item.quantity);

  /// Для покупки нельзя взять больше, чем лежит на складе.
  int _maxQuantity(CardOffer? offer) =>
      offer == null ? AppConfig.maxItemQuantity : offer.quantity.clamp(1, AppConfig.maxItemQuantity);

  void setQuantity(CartItem item, int quantity) {
    if (quantity < 1) return remove(item);

    final limit = _maxQuantity(
      item.orderType.needsOffer ? item.card.offers.where((offer) => offer.id == item.offerId).firstOrNull : null,
    );
    final others = _totalQuantity - item.quantity;
    final roomForItem = (AppConfig.maxCartItems - others).clamp(1, AppConfig.maxCartItems);
    final allowed = quantity.clamp(1, limit).clamp(1, roomForItem);

    _update([
      for (final other in state)
        other.matches(item.card.id, item.quality, item.orderType) ? other.copyWith(quantity: allowed) : other,
    ]);
  }

  void remove(CartItem item) => _update([
        for (final other in state)
          if (!other.matches(item.card.id, item.quality, item.orderType)) other,
      ]);

  void clear() => _update(const []);

  /// После оформления убираем из корзины только созданные типы заказов.
  void removeTypes(Set<OrderType> types) => _update([
        for (final item in state)
          if (!types.contains(item.orderType)) item,
      ]);
}

class CartSummary {
  const CartSummary(this.items);

  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;

  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  /// Позиции без цены (предзаказ, заказ у партнёра) в сумму не попадают —
  /// их стоимость подтверждает менеджер.
  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  bool get hasPendingPrices => items.any((item) => item.priceIsPending);

  List<CartItem> byType(OrderType type) => items.where((item) => item.orderType == type).toList();

  Set<OrderType> get types => items.map((item) => item.orderType).toSet();
}
