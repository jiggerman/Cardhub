import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../cart/domain/order_type.dart';
import '../../../catalog/presentation/widgets/card_artwork.dart';
import '../../domain/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = switch (order.type) {
      OrderType.purchase => AppColors.mint,
      OrderType.reservation => AppColors.amber,
      OrderType.import => AppColors.coral,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(label: order.type.label, color: typeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Заказ №${order.id}',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Pill(
                label: order.status.label,
                color: order.status.isFinished ? AppColors.mutedSoft : AppColors.violet,
              ),
              const SizedBox(width: 10),
              if (order.createdAt != null)
                Expanded(
                  child: Text(
                    formatDateTime(order.createdAt!),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final line in order.lines) ...[
            _Line(line: line),
            const SizedBox(height: 10),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Text(cardsCount(order.itemsCount), style: theme.textTheme.bodyMedium),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.hasPendingPrices && order.total == 0 ? 'цена уточняется' : formatPrice(order.total),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          if (order.trackingNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(child: Text('Трек-номер: ${order.trackingNumber}', style: theme.textTheme.bodyLarge)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 40, child: CardArtwork(imageUrl: line.card.imageUrl, radius: 6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.card.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
              Text(
                '${line.card.setCode.toUpperCase()} · #${line.card.collectorNumber} · '
                '${line.quality} · ${line.quantity} шт.',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          line.unitPrice == null ? 'уточняется' : formatPrice(line.subtotal ?? line.unitPrice),
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
