import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// «В наличии» / «Предзаказ» — те же два состояния, что и в вебе.
class StockBadge extends StatelessWidget {
  const StockBadge({required this.inStock, this.compact = false, super.key});

  final int inStock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final available = inStock > 0;
    final color = available ? AppColors.mint : AppColors.amber;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        available ? 'В наличии' : 'Предзаказ',
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
