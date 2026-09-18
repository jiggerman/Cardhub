import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/cart_page.dart';
import '../../features/catalog/presentation/catalog_page.dart';
import '../../features/orders/presentation/orders_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import 'home_shell.dart';

abstract final class AppRoutes {
  static const catalog = '/catalog';
  static const cart = '/cart';
  static const orders = '/orders';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.catalog,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.catalog, builder: (context, state) => const CatalogPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.cart, builder: (context, state) => const CartPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.orders, builder: (context, state) => const OrdersPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfilePage())],
          ),
        ],
      ),
    ],
  );
});
