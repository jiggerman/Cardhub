import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../catalog/presentation/widgets/card_artwork.dart';
import '../../domain/cart_item.dart';
import '../../domain/order_type.dart';

class CartRow extends StatelessWidget {
  const CartRow({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onTap,
    super.key,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(width: 64, child: CardArtwork(imageUrl: item.card.previewImage, radius: 10)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(type: item.orderType),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    item.card.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.card.setCode.toUpperCase()} · #${item.card.collectorNumber} · ${item.quality}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityStepper(
                      value: item.quantity,
                      onChanged: onQuantityChanged,
                    ),
                    const SizedBox(width: 8),
                    // Подпись «уточняется» длиннее цены и не помещалась рядом
                    // со счётчиком
                    Expanded(
                      child: Text(
                        item.priceIsPending ? 'уточняется' : formatPrice(item.subtotal),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: item.priceIsPending ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.mutedSoft),
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final OrderType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      OrderType.purchase => AppColors.mint,
      OrderType.reservation => AppColors.amber,
      OrderType.import => AppColors.coral,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        type.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => onChanged(value - 1), tooltip: 'Меньше'),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1), tooltip: 'Больше'),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}
