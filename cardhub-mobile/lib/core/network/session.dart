import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionProvider = Provider<Session>((ref) => Session());

/// Общее состояние авторизации для сетевого слоя.
///
/// На бэкенде нет эндпоинта обновления токена, а access живёт 5 минут, поэтому
/// при 401 приложение молча повторяет вход сохранёнными учётными данными —
/// эту процедуру подставляет сюда [reauthenticate].
class Session {
  String? accessToken;
  String? refreshToken;

  /// Возвращает true, если вход удался и запрос можно повторить.
  Future<bool> Function()? reauthenticate;

  Future<bool>? _inflight;

  bool get isActive => accessToken != null;

  void clear() {
    accessToken = null;
    refreshToken = null;
  }

  /// Несколько запросов могут получить 401 одновременно — вход всё равно
  /// выполняется один раз, остальные ждут его результат.
  Future<bool> renew() {
    final handler = reauthenticate;
    if (handler == null) return Future.value(false);
    return _inflight ??= handler().whenComplete(() => _inflight = null);
  }
}
