import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Даты заказов показываем по-русски — символы локали нужно загрузить заранее.
  await initializeDateFormatting('ru');
  runApp(const ProviderScope(child: CardHubApp()));
}
