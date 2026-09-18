import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_page.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/catalog/domain/card.dart';
import '../../features/catalog/presentation/card_details_page.dart';
import '../../features/catalog/presentation/catalog_page.dart';
import '../../features/orders/presentation/checkout_page.dart';
import '../../features/orders/presentation/orders_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import 'home_shell.dart';

abstract final class AppRoutes {
  static const catalog = '/catalog';
  static const cart = '/cart';
  static const orders = '/orders';
  static const profile = '/profile';

  /// Карточка карты лежит внутри вкладки каталога, поэтому таб-бар остаётся на месте.
  static String cardDetails(int cardId) => '$catalog/card/$cardId';

  /// Вход открывается поверх вкладок — на него уходят и из профиля, и из оформления.
  static const auth = '/auth';

  static const checkout = '$cart/checkout';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.catalog,
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (context, state) => const CatalogPage(),
                routes: [
                  GoRoute(
                    path: 'card/:cardId',
                    builder: (context, state) => CardDetailsPage(
                      cardId: int.parse(state.pathParameters['cardId']!),
                      initialCard: state.extra as MtgCard?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartPage(),
                routes: [
                  GoRoute(path: 'checkout', builder: (context, state) => const CheckoutPage()),
                ],
              ),
            ],
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
