import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/message_state.dart';
import '../../auth/application/auth_controller.dart';
import '../application/cart_controller.dart';
import 'widgets/cart_row.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: [
          if (!summary.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Очистить'),
            ),
        ],
      ),
      body: summary.isEmpty
          ? MessageState(
              icon: Icons.shopping_bag_outlined,
              title: 'Корзина пока пуста',
              description: 'Найдите карту в каталоге и добавьте её отсюда.',
              onRetry: () => context.go(AppRoutes.catalog),
              retryLabel: 'Перейти в каталог',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
              children: [
                Text(
                  '${cardsCount(summary.count)} из ${AppConfig.maxCartItems} возможных',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final item in summary.items) ...[
                  CartRow(
                    item: item,
                    onQuantityChanged: (quantity) => cart.setQuantity(item, quantity),
                    onRemove: () => cart.remove(item),
                    onTap: () => context.go(AppRoutes.cardDetails(item.card.id), extra: item.card),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                const _Summary(),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Очистить корзину?'),
        content: const Text('Все добавленные карты будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) ref.read(cartProvider.notifier).clear();
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();

  /// Оформление доступно только с аккаунтом: заказ создаётся от имени
  /// пользователя. Если входа нет — сначала открываем его, потом продолжаем.
  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    // Сессия может ещё восстанавливаться после запуска — дожидаемся ответа,
    // чтобы не просить войти того, кто уже вошёл.
    var user = await ref.read(authProvider.future);
    if (!context.mounted) return;

    if (user == null) {
      await context.push(AppRoutes.auth);
      if (!context.mounted) return;
      user = ref.read(authProvider).valueOrNull;
      if (user == null) return;
    }
    if (context.mounted) context.push(AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(cartSummaryProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ИТОГО', style: theme.textTheme.labelSmall),
          const SizedBox(height: 12),
          _Line(label: 'Товары', value: formatPrice(summary.total, fallback: '0 ₽')),
          const SizedBox(height: 8),
          _Line(label: 'Доставка', value: 'рассчитаем далее', muted: true),
          const Divider(height: 28),
          Row(
            children: [
              Text('К оплате', style: theme.textTheme.titleLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatPrice(summary.total, fallback: '0 ₽'),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          if (summary.hasPendingPrices) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Стоимость предзаказа и позиций под заказ подтвердит менеджер — в сумму они не входят.',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _checkout(context, ref),
            child: const Text('Перейти к оформлению'),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 12),
        // Длинные подписи («рассчитаем далее») и крупный системный шрифт
        // иначе не помещаются в строку
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: muted ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
