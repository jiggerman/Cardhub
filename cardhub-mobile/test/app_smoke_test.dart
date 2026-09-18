import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('приложение открывается на каталоге и показывает все вкладки', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Каталог'), findsOneWidget);
    for (final tab in ['Каталог', 'Корзина', 'Заказы', 'Профиль']) {
      expect(find.widgetWithText(NavigationDestination, tab), findsOneWidget);
    }
  });

  testWidgets('вкладки переключаются', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Заказы'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Мои заказы'), findsOneWidget);
  });
}
