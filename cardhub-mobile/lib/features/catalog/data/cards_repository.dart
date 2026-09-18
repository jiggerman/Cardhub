import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/card.dart';

final cardsRepositoryProvider = Provider<CardsRepository>(
  (ref) => CardsRepository(ref.watch(apiClientProvider)),
);

class CardsRepository {
  const CardsRepository(this._client);

  final ApiClient _client;

  /// Поиск по названию: `GET /api/cards/{name}`.
  /// Пагинации на бэкенде нет — приходит вся выдача сразу.
  Future<CardSearchResult> search(String query, {CancelToken? cancelToken}) async {
    final response = await _client.get(
      '/api/cards/${Uri.encodeComponent(query)}',
      cancelToken: cancelToken,
    );
    return CardSearchResult.fromJson(response as Map<String, dynamic>);
  }

  /// Одна карта: `GET /api/card/{id}` — внимание, без завершающего слэша,
  /// со слэшем бэкенд отвечает 404.
  Future<MtgCard> byId(int id, {CancelToken? cancelToken}) async {
    try {
      final response = await _client.get('/api/card/$id', cancelToken: cancelToken);
      return MtgCard.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.isNotFound) throw const ApiException('Карта не найдена', statusCode: 404);
      rethrow;
    }
  }
}
