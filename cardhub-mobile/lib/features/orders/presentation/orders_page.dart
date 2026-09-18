import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/message_state.dart';
import '../../auth/application/auth_controller.dart';
import '../application/orders_providers.dart';
import 'widgets/order_card.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : auth.valueOrNull == null
          ? MessageState(
              icon: Icons.receipt_long_outlined,
              title: 'Войдите, чтобы увидеть заказы',
              description: 'История заказов хранится в аккаунте.',
              onRetry: () => context.push(AppRoutes.auth),
              retryLabel: 'Войти',
            )
          : orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => MessageState(
                icon: Icons.cloud_off_rounded,
                accent: AppColors.danger,
                title: 'Не удалось загрузить заказы',
                description: '$error',
                onRetry: () => ref.invalidate(ordersProvider),
              ),
              data: (orders) => orders.isEmpty
                  ? MessageState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Заказов пока нет',
                      description: 'Здесь появятся состав заказа, статус и трек-номер.',
                      onRetry: () => context.go(AppRoutes.catalog),
                      retryLabel: 'Найти карту',
                    )
                  : RefreshIndicator(
                      color: AppColors.violet,
                      backgroundColor: AppColors.panel,
                      onRefresh: () => ref.refresh(ordersProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
                        itemCount: orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => OrderCard(order: orders[index]),
                      ),
                    ),
            ),
    );
  }
}
