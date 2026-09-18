import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/message_state.dart';
import '../application/catalog_providers.dart';
import '../domain/card.dart';
import 'widgets/card_tile.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Каталог')),
      body: Column(
        children: [
          const _SearchField(),
          Expanded(
            child: isSearchable(query) ? _Results(query: query) : const _SearchHint(),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 12),
      child: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, child) => TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
          onSubmitted: (value) => ref.read(searchQueryProvider.notifier).update(value, delay: Duration.zero),
          decoration: InputDecoration(
            hintText: 'Название карты на английском',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 24, AppSpacing.gutter, 32),
      children: [
        const MessageState(
          icon: Icons.search_rounded,
          title: 'Найдите нужную карту',
          description: 'Введите минимум ${AppConfig.minSearchLength} символа названия — '
              'поиск идёт по каталогу на английском языке.',
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Популярное', style: Theme.of(context).textTheme.labelSmall),
        ),
        const SizedBox(height: 12),
        const _PopularQueries(),
      ],
    );
  }
}

class _PopularQueries extends ConsumerWidget {
  const _PopularQueries();

  static const _queries = ['Sol Ring', 'Lightning Bolt', 'Counterspell', 'Birds of Paradise'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final query in _queries)
          ActionChip(
            label: Text(query),
            onPressed: () => ref.read(searchQueryProvider.notifier).update(query, delay: Duration.zero),
          ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => MessageState(
        icon: Icons.cloud_off_rounded,
        accent: AppColors.danger,
        title: 'Каталог недоступен',
        description: '$error',
        onRetry: () => ref.invalidate(searchResultsProvider(query)),
      ),
      data: (result) => result.cards.isEmpty
          ? const MessageState(
              icon: Icons.search_off_rounded,
              title: 'Ничего не нашли',
              description: 'Попробуйте английское название карты или другое написание.',
            )
          : _CardsGrid(query: query, result: result),
    );
  }
}

class _CardsGrid extends ConsumerWidget {
  const _CardsGrid({required this.query, required this.result});

  final String query;
  final CardSearchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleCountProvider).clamp(0, result.cards.length);
    final cards = result.cards.take(visible).toList();
    final hasMore = visible < result.cards.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Вся выдача уже в памяти, поэтому «показать ещё» — это просто
        // увеличение числа отрисованных плиток, без запроса к серверу.
        final tileWidth = (constraints.maxWidth - AppSpacing.gutter * 2 - 14) / 2;
        final tileHeight = CardTile.tileHeight(context, tileWidth);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(searchResultsProvider(query)),
          color: AppColors.violet,
          backgroundColor: AppColors.panel,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Найдено ${cardsCount(result.total)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    mainAxisExtent: tileHeight,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CardTile(
                      card: cards[index],
                      onTap: () => context.push(AppRoutes.cardDetails(cards[index].id), extra: cards[index]),
                    ),
                    childCount: cards.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 20, AppSpacing.gutter, 32),
                  child: hasMore
                      ? OutlinedButton(
                          onPressed: () => ref.read(visibleCountProvider.notifier).showMore(),
                          child: Text('Показать ещё (осталось ${result.cards.length - visible})'),
                        )
                      : Center(
                          child: Text(
                            'Показаны все результаты',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
