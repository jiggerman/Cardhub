import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../catalog/domain/card.dart';
import '../../../catalog/domain/card_offer.dart';
import '../../application/cart_controller.dart';
import '../../domain/order_type.dart';

/// Блок покупки на карточке карты: способ получения, состояние, количество.
/// Повторяет логику веб-клиента (`pages/Product.jsx`).
class BuyBox extends ConsumerStatefulWidget {
  const BuyBox({required this.card, super.key});

  final MtgCard card;

  @override
  ConsumerState<BuyBox> createState() => _BuyBoxState();
}

class _BuyBoxState extends ConsumerState<BuyBox> {
  static const _allQualities = ['NM', 'SP', 'MP', 'HP', 'DM'];

  late OrderType _orderType = widget.card.isPreorder ? OrderType.reservation : OrderType.purchase;
  late String _quality = _qualities.first;
  int _quantity = 1;

  /// Для покупки состояния берём из самих складских позиций, а не из поля
  /// available_qualities: иначе можно выбрать состояние, которого нет в
  /// продаже, и экран покажет «уточняется» с недоступной кнопкой.
  List<String> get _qualities {
    if (!_orderType.needsOffer) return _allQualities;
    final fromOffers = widget.card.availableOffers.map((offer) => offer.quality).toSet().toList()
      ..sort((a, b) => _allQualities.indexOf(a).compareTo(_allQualities.indexOf(b)));
    return fromOffers.isEmpty ? _allQualities : fromOffers;
  }

  /// Для покупки цена и остаток берутся из конкретной складской позиции.
  CardOffer? get _offer => _orderType.needsOffer
      ? (widget.card.availableOffers.where((offer) => offer.quality == _quality).toList()
            ..sort((a, b) => a.price.compareTo(b.price)))
          .firstOrNull
      : null;

  int get _maxQuantity => _orderType.needsOffer
      ? (_offer?.quantity ?? 1).clamp(1, AppConfig.maxItemQuantity)
      : AppConfig.maxItemQuantity;

  void _selectType(OrderType type) {
    setState(() {
      _orderType = type;
      _quantity = 1;
      if (!_qualities.contains(_quality)) _quality = _qualities.first;
    });
  }

  void _addToCart() {
    final result = ref.read(cartProvider.notifier).add(
          widget.card,
          orderType: _orderType,
          quality: _quality,
          quantity: _quantity,
        );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.panelSoft : AppColors.danger.withValues(alpha: 0.9),
        ),
      );
    if (result.isSuccess) setState(() => _quantity = 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = _offer?.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Способ получения', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final type in OrderType.values) ...[
          _TypeOption(
            type: type,
            selected: _orderType == type,
            enabled: !(type.needsOffer && widget.card.isPreorder),
            onTap: () => _selectType(type),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Text('Состояние', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final quality in _qualities)
              ChoiceChip(
                label: Text(quality),
                selected: _quality == quality,
                onSelected: (_) => setState(() {
                  _quality = quality;
                  _quantity = 1;
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Количество', style: theme.textTheme.titleMedium),
            const Spacer(),
            _Stepper(
              value: _quantity,
              max: _maxQuantity,
              onChanged: (value) => setState(() => _quantity = value),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _orderType.needsOffer ? 'Итого' : 'Цена после подтверждения',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    price == null ? 'уточняется' : formatPrice(price * _quantity),
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _orderType.needsOffer && _offer == null ? null : _addToCart,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              label: const Text('В корзину'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({required this.type, required this.selected, required this.enabled, required this.onTap});

  final OrderType type;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.violetStrong.withValues(alpha: 0.16) : AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: selected ? AppColors.violet : AppColors.line),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.violet : AppColors.mutedSoft,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.label, style: theme.textTheme.titleMedium),
                    Text(
                      enabled ? type.hint : 'Нет в наличии',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.max, required this.onChanged});

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Меньше',
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Больше',
          ),
        ],
      ),
    );
  }
}
