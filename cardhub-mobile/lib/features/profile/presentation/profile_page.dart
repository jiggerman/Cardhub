import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/message_state.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/user.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: switch (auth) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncData(value: final User user) => _Profile(user: user),
        _ => MessageState(
            icon: Icons.person_outline_rounded,
            title: 'Войдите в аккаунт',
            description: 'Аккаунт нужен, чтобы оформлять заказы и следить за их статусом.',
            onRetry: () => context.push(AppRoutes.auth),
            retryLabel: 'Войти или зарегистрироваться',
          ),
      },
    );
  }
}

class _Profile extends ConsumerStatefulWidget {
  const _Profile({required this.user});

  final User user;

  @override
  ConsumerState<_Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<_Profile> {
  late final _telegram = TextEditingController(text: widget.user.telegramUsername);
  late final _address = TextEditingController(text: widget.user.address);
  bool _saving = false;

  @override
  void dispose() {
    _telegram.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save({String? telegramUsername, String? address}) async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            telegramUsername: telegramUsername,
            address: address,
          );
      _show('Сохранено');
    } on ApiException catch (error) {
      _show(error.fieldErrors['telegram_username'] ?? error.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger.withValues(alpha: 0.9) : AppColors.panelSoft,
        ),
      );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Корзина останется на устройстве.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: AppColors.violet,
      backgroundColor: AppColors.panel,
      onRefresh: () => ref.read(authProvider.notifier).reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
        children: [
          _Header(user: user),
          const SizedBox(height: 24),
          Text('TELEGRAM', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Text(
            'Статусы заказов и сообщения о поступлении карт приходят в Telegram.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telegram,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              suffixIcon: user.telegramVerified
                  ? const Icon(Icons.verified_rounded, color: AppColors.mint)
                  : null,
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(telegramUsername: _telegram.text.replaceAll('@', '').trim()),
                  child: const Text('Сохранить'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(AppConfig.supportBotUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Открыть бота'),
                ),
              ),
            ],
          ),
          if (user.telegramUsername.isNotEmpty && !user.telegramVerified) ...[
            const SizedBox(height: 10),
            Text(
              'Username сохранён. Подтвердите его в боте, чтобы получать уведомления.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.amber),
            ),
          ],
          const Divider(height: 40),
          Text('ДОСТАВКА', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Text('Адрес подставится при оформлении заказа.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Город, улица, дом, квартира'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _saving ? null : () => _save(address: _address.text.trim()),
            child: const Text('Сохранить адрес'),
          ),
          const Divider(height: 40),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Выйти из аккаунта'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Text(user.initial, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.email, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
