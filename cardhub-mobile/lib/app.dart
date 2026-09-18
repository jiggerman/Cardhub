import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';

class CardHubApp extends ConsumerWidget {
  const CardHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Восстанавливаем сессию сразу при запуске: иначе первый же экран,
    // которому нужен вход, увидит «не авторизован», пока идёт проверка.
    ref.watch(authProvider);

    return MaterialApp.router(
      title: 'CardHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
