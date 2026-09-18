# CardHub Mobile (iOS)

Мобильный клиент магазина карт Magic: The Gathering. Повторяет торговый путь
веб-клиента `cardhub-frontend`: поиск по каталогу, карточка карты, корзина,
оформление заказа, история заказов и профиль. Платформа только iOS.

## Требования

- Flutter 3.41+ (проверялось на 3.41.5, Dart 3.11)
- Xcode 16.2+ с симулятором iPhone
- Запущенный бэкенд (см. `docker-compose.dev.yml` в корне репозитория)

CocoaPods не нужен: проект использует Swift Package Manager. Если Flutter вдруг
попросит `pod install`, включите SPM командой
`flutter config --enable-swift-package-manager`.

## Запуск

```bash
# Бэкенд (из корня репозитория)
docker compose -f docker-compose.dev.yml up -d

# Приложение
cd cardhub-mobile
flutter pub get
flutter run -d "iPhone 16 Pro"
```

Адрес API задаётся при запуске и по умолчанию равен `http://localhost:8000`:

```bash
# Прод
flutter run --dart-define=API_BASE_URL=https://cardhub.pw

# Реальный iPhone в одной сети с компьютером — нужен его адрес в сети,
# localhost внутри телефона указывает на сам телефон
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000
```

Для обычного HTTP в `Info.plist` открыт доступ к `localhost` и локальной сети —
это нужно только для разработки, прод работает по HTTPS.

## Проверки

```bash
flutter analyze
flutter test
```

## Структура

```
lib/
  app.dart                 корневой MaterialApp
  core/
    config/                адрес API и лимиты (--dart-define)
    network/               клиент Dio и разбор ошибок DRF
    router/                go_router и нижний таб-бар
    theme/                 цвета и типографика из веб-клиента
    widgets/               общие виджеты
  features/
    catalog/ cart/ orders/ profile/
      presentation/        экраны
```

Состояние — Riverpod, навигация — go_router, запросы — Dio, токены будут
храниться в Keychain через `flutter_secure_storage`.

## Особенности API, под которые подстроен клиент

- **Access-токен живёт 5 минут, эндпоинта обновления нет.** Приложение хранит
  учётные данные в Keychain и молча повторяет вход, когда сервер отвечает 401.
- **Поиск отдаёт всю выдачу без пагинации** (запрос «a» — это 19 МБ). Поэтому
  запрос уходит от 3 символов, результаты листаются на клиенте по 20 штук.
- **Остатки (`offers`) быстро устаревают** — перед оформлением заказа карточка
  запрашивается заново.
- Цены и владельца заказа считает сервер: клиент присылает только карту,
  складскую позицию, состояние и количество.

## Дизайн

Цвета, шрифт Manrope и скругления перенесены из `cardhub-frontend/src/App.css`.
Навигация — привычная для iOS: нижний таб-бар, свайп назад, модальные шторки.
