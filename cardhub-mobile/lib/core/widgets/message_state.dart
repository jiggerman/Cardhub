import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Единый вид для пустых экранов и ошибок: иконка, заголовок, пояснение
/// и необязательная кнопка повтора.
class MessageState extends StatelessWidget {
  const MessageState({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
    this.retryLabel = 'Повторить',
    this.accent = AppColors.violet,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: AppColors.panel,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(minimumSize: const Size(180, 48)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
