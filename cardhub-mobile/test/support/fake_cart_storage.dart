import 'package:cardhub_mobile/features/cart/data/cart_storage.dart';
import 'package:cardhub_mobile/features/cart/domain/cart_item.dart';

/// Хранилище корзины в памяти: тесты не трогают SharedPreferences.
class FakeCartStorage implements CartStorage {
  FakeCartStorage([this.items = const []]);

  List<CartItem> items;
  int saves = 0;

  @override
  Future<List<CartItem>> load() async => items;

  @override
  Future<void> save(List<CartItem> items) async {
    this.items = items;
    saves++;
  }
}
