/// Настройки сборки. Значения задаются через --dart-define, чтобы один и тот же
/// код собирался и на локальный Docker, и на прод.
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000
abstract final class AppConfig {
  /// По умолчанию — бэкенд из docker-compose.dev.yml.
  /// Симулятор видит localhost хоста, физический iPhone — нет: ему нужен адрес
  /// компьютера в локальной сети (см. README).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Ниже этой длины запроса поиск не отправляется: бэкенд отдаёт всю выдачу
  /// целиком без пагинации (запрос «a» — это 19 МБ и 2.5 с).
  static const minSearchLength = 3;

  /// Размер страницы, которую показываем из полученной выдачи (как в вебе).
  static const searchPageSize = 20;

  /// Лимиты корзины повторяют веб-клиент.
  static const maxCartItems = 20;
  static const maxItemQuantity = 4;

  static const supportBotUrl = 'https://t.me/CardHubStore_bot';
}
