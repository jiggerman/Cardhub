import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _register = false;
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final auth = ref.read(authProvider.notifier);
    if (_register) {
      await auth.signUp(
        email: _email.text,
        username: _username.text,
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );
    } else {
      await auth.signIn(email: _email.text, password: _password.text);
    }
    if (!mounted) return;

    final state = ref.read(authProvider);
    setState(() => _submitting = false);

    if (state.hasError) {
      final error = state.error;
      setState(() {
        _error = error is ApiException ? error.message : 'Не удалось выполнить вход';
        _fieldErrors = error is ApiException ? error.fieldErrors : const {};
      });
      return;
    }
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Регистрация' : 'Вход')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Вход')),
                ButtonSegment(value: true, label: Text('Регистрация')),
              ],
              selected: {_register},
              onSelectionChanged: (value) => setState(() {
                _register = value.first;
                _error = null;
                _fieldErrors = const {};
              }),
            ),
            const SizedBox(height: 24),
            Text(
              _register ? 'Создать аккаунт' : 'С возвращением',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _register ? 'Понадобится меньше минуты.' : 'Введите данные, чтобы продолжить.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            if (_register) ...[
              TextFormField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Имя пользователя',
                  errorText: _fieldErrors['username'],
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => (value ?? '').trim().isEmpty ? 'Как к вам обращаться?' : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: 'Email', errorText: _fieldErrors['email']),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Введите email';
                if (!email.contains('@') || !email.contains('.')) return 'Проверьте адрес';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(labelText: 'Пароль', errorText: _fieldErrors['password']),
              obscureText: true,
              textInputAction: _register ? TextInputAction.next : TextInputAction.done,
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Введите пароль';
                if (_register && password.length < 8) return 'Не меньше 8 символов';
                return null;
              },
            ),
            if (_register) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmation,
                decoration: const InputDecoration(labelText: 'Повторите пароль'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) => value == _password.text ? null : 'Пароли не совпадают',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_register ? 'Создать аккаунт' : 'Войти'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.mutedSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Пароль сохраняется в Keychain устройства, чтобы не входить заново: '
                    'сервер выдаёт токен всего на 5 минут.',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
