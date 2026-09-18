import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cart_item.dart';

final cartStorageProvider = Provider<CartStorage>((ref) => const SharedPrefsCartStorage());

abstract interface class CartStorage {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
}

/// Корзина переживает перезапуск приложения — как localStorage в вебе.
class SharedPrefsCartStorage implements CartStorage {
  const SharedPrefsCartStorage();

  static const _key = 'cart';

  @override
  Future<List<CartItem>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      // Формат мог измениться между версиями приложения — лучше начать
      // с пустой корзины, чем падать на старте.
      await preferences.remove(_key);
      return const [];
    }
  }

  @override
  Future<void> save(List<CartItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(items.map((item) => item.toJson()).toList()));
  }
}
