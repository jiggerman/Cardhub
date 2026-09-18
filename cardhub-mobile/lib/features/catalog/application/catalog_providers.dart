import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/cards_repository.dart';
import '../domain/card.dart';

/// Запрос, введённый пользователем (обновляется с задержкой — см. [SearchQuery]).
final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

class SearchQuery extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  /// Ждём паузу в наборе: запрос к бэкенду тяжёлый, дёргать его на каждую букву нельзя.
  void update(String value, {Duration delay = const Duration(milliseconds: 400)}) {
    _debounce?.cancel();
    final query = value.trim();
    if (query == state) return;
    _debounce = Timer(delay, () => state = query);
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

bool isSearchable(String query) => query.trim().length >= AppConfig.minSearchLength;

/// Результаты поиска. Ключ — сам запрос, поэтому смена запроса отменяет
/// предыдущий HTTP-вызов через [CancelToken].
final searchResultsProvider = FutureProvider.autoDispose.family<CardSearchResult, String>((ref, query) async {
  if (!isSearchable(query)) return CardSearchResult.empty;

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  // Экран каталога остаётся в дереве при переходе на карточку и при смене
  // вкладки, поэтому выдача не перезапрашивается и кеш поверх не нужен.
  return ref.watch(cardsRepositoryProvider).search(query, cancelToken: cancelToken);
});

/// Сколько карт из выдачи показано сейчас (подгрузка при прокрутке).
final visibleCountProvider = NotifierProvider<VisibleCount, int>(VisibleCount.new);

class VisibleCount extends Notifier<int> {
  @override
  int build() {
    // При смене запроса список всегда начинается заново.
    ref.listen(searchQueryProvider, (previous, next) => state = AppConfig.searchPageSize);
    return AppConfig.searchPageSize;
  }

  void showMore() => state += AppConfig.searchPageSize;
}

/// Карточка товара: сначала показываем данные из списка, затем обновляем их
/// свежим ответом — остатки и цены меняются.
final cardDetailsProvider = FutureProvider.autoDispose.family<MtgCard, int>((ref, id) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.watch(cardsRepositoryProvider).byId(id, cancelToken: cancelToken);
});
