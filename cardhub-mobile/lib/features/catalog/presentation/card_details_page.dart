import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/message_state.dart';
import '../../cart/presentation/widgets/buy_box.dart';
import '../application/catalog_providers.dart';
import '../domain/card.dart';
import '../domain/card_offer.dart';
import 'widgets/card_artwork.dart';
import 'widgets/stock_badge.dart';

/// Карточка карты. [initialCard] приходит из списка, чтобы экран открывался
/// мгновенно, а свежие остатки подгружаются следом.
class CardDetailsPage extends ConsumerWidget {
  const CardDetailsPage({required this.cardId, this.initialCard, super.key});

  final int cardId;
  final MtgCard? initialCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(cardDetailsProvider(cardId));
    final card = details.valueOrNull ?? initialCard;

    return Scaffold(
      appBar: AppBar(title: Text(card?.name ?? 'Карта')),
      body: switch ((card, details)) {
        (null, AsyncError(:final error)) => MessageState(
            icon: Icons.error_outline_rounded,
            accent: AppColors.danger,
            title: 'Не удалось открыть карту',
            description: '$error',
            onRetry: () => ref.invalidate(cardDetailsProvider(cardId)),
          ),
        (null, _) => const Center(child: CircularProgressIndicator()),
        (final MtgCard card, _) => _Details(card: card, refreshing: details.isLoading, cardId: cardId),
      },
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.card, required this.refreshing, required this.cardId});

  final MtgCard card;
  final bool refreshing;
  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: AppColors.violet,
      backgroundColor: AppColors.panel,
      onRefresh: () async => ref.refresh(cardDetailsProvider(cardId).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: CardArtwork(imageUrl: card.detailImage, radius: 18),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${card.setCode.toUpperCase()} · #${card.collectorNumber}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
              StockBadge(inStock: card.inStock),
            ],
          ),
          const SizedBox(height: 8),
          Text(card.name, style: theme.textTheme.headlineMedium),
          if (card.type.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(card.type, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          _Facts(card: card),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Предложения', style: theme.textTheme.titleLarge),
              const SizedBox(width: 10),
              if (refreshing)
                const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          if (card.availableOffers.isEmpty)
            const _NoOffers()
          else
            for (final offer in card.availableOffers) ...[
              _OfferRow(offer: offer),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          Text(
            'Остатки меняются: потяните экран вниз, чтобы обновить.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 28),
          BuyBox(key: ValueKey(card.id), card: card),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.card});

  final MtgCard card;

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[
      ('Сет', card.setName.isEmpty ? card.setCode.toUpperCase() : card.setName),
      ('Цвет', card.color.isEmpty ? '—' : card.color),
      ('На складе', card.inStock == 0 ? 'нет' : '${card.inStock} шт.'),
      ('Цена от', formatPrice(card.minPrice)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          children: [
            for (final (label, value) in facts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Узкая колонка под подпись: названия сетов длинные,
                    // им нужно больше места, иначе текст ломается на три строки
                    SizedBox(
                      width: 96,
                      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final CardOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.panelSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(offer.quality, style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [offer.language.toUpperCase(), if (offer.foil) 'foil'].join(' · '),
                  style: theme.textTheme.bodyLarge,
                ),
                Text('${offer.quantity} шт.', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(formatPrice(offer.price), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _NoOffers extends StatelessWidget {
  const _NoOffers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Карты нет на складе. Её можно взять в предзаказ или заказать у партнёра — '
              'цену и сроки подтвердит менеджер.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
