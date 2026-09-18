import 'package:cardhub_mobile/app.dart';
import 'package:cardhub_mobile/features/catalog/presentation/catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Проверку связи с API подменяем, чтобы тест не ходил в сеть.
Widget _app() => ProviderScope(
      overrides: [apiHealthProvider.overrideWith((ref) => 3)],
      child: const CardHubApp(),
    );

void main() {
  testWidgets('приложение открывается на каталоге и показывает все вкладки', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Каталог'), findsOneWidget);
    for (final tab in ['Каталог', 'Корзина', 'Заказы', 'Профиль']) {
      expect(find.widgetWithText(NavigationDestination, tab), findsOneWidget);
    }
  });

  testWidgets('вкладки переключаются', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Заказы'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Мои заказы'), findsOneWidget);
  });

  testWidgets('каталог показывает ответ бэкенда', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('3 карт'), findsOneWidget);
  });
}
