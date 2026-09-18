import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Проверка связи с бэкендом: на этапе каркаса это единственный живой запрос,
/// на следующем этапе экран заменит настоящий поиск.
final apiHealthProvider = FutureProvider.autoDispose<int>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/api/cards/${Uri.encodeComponent('lightning bolt')}');
  return (response as Map<String, dynamic>)['counter'] as int? ?? 0;
});

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Каталог')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
        children: [
          Text('Поиск карт', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Экран поиска и карточка карты появятся на следующем этапе.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('СВЯЗЬ С API', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 10),
                  Text(AppConfig.apiBaseUrl, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  health.when(
                    loading: () => const Row(
                      children: [
                        SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Проверяем…'),
                      ],
                    ),
                    error: (error, _) => _Status(
                      color: AppColors.danger,
                      icon: Icons.error_outline_rounded,
                      text: '$error',
                    ),
                    data: (counter) => _Status(
                      color: AppColors.mint,
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Бэкенд отвечает: «lightning bolt» — $counter карт',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(apiHealthProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Проверить снова'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color)),
        ),
      ],
    );
  }
}
