import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../domain/card.dart';
import 'card_artwork.dart';
import 'stock_badge.dart';

/// Плитка карты в сетке результатов поиска.
class CardTile extends StatelessWidget {
  const CardTile({required this.card, required this.onTap, super.key});

  final MtgCard card;
  final VoidCallback onTap;

  /// Высота подписи под картинкой при системном размере шрифта.
  /// Сетке она нужна заранее, чтобы посчитать высоту плитки.
  static const _baseTextHeight = 96.0;

  /// Картинка занимает остаток плитки, поэтому при увеличенном шрифте
  /// подпись не обрезается, а картинка становится чуть меньше.
  static double tileHeight(BuildContext context, double tileWidth) =>
      tileWidth / CardArtwork.aspectRatio + MediaQuery.textScalerOf(context).scale(_baseTextHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Stack(
              children: [
                CardArtwork(imageUrl: card.previewImage),
                Positioned(
                  left: 8,
                  top: 8,
                  child: StockBadge(inStock: card.inStock, compact: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '${card.setCode.toUpperCase()} · #${card.collectorNumber}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            card.minPrice == null ? 'по запросу' : 'от ${formatPrice(card.minPrice)}',
            maxLines: 1,
            style: theme.textTheme.titleMedium?.copyWith(
              color: card.minPrice == null ? AppColors.muted : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
