import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/message_state.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/user.dart';
import '../../cart/application/cart_controller.dart';
import '../application/orders_providers.dart';
import '../domain/order.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _telegram = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();

  ShippingMethod _shipping = ShippingMethod.cdek;
  PaymentMethod _payment = PaymentMethod.card;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _prefill(ref.read(authProvider).valueOrNull);
  }

  /// Подставляем данные профиля, не затирая то, что пользователь уже ввёл.
  /// Сессия может восстановиться уже после открытия экрана — тогда поля
  /// заполнятся не сразу, а как только профиль приедет.
  void _prefill(User? user) {
    if (user == null) return;
    if (_name.text.isEmpty) _name.text = user.username;
    if (_email.text.isEmpty) _email.text = user.email;
    if (_telegram.text.isEmpty) _telegram.text = user.telegramUsername;
    if (_address.text.isEmpty) _address.text = user.address;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _telegram.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Кнопка внизу формы, а ошибка может оказаться выше экрана — говорим о ней явно.
      _snack('Проверьте контактные данные и адрес', isError: true);
      return;
    }
    if (!_accepted) {
      _snack('Подтвердите согласие с условиями', isError: true);
      return;
    }

    await ref.read(checkoutProvider.notifier).submit(
          CheckoutForm(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            telegram: _telegram.text.trim(),
            address: _address.text.trim(),
            shipping: _shipping,
            payment: _payment,
          ),
        );

    if (!mounted) return;
    final state = ref.read(checkoutProvider);
    if (state.hasError) {
      final error = state.error;
      _snack(error is ApiException ? error.message : 'Не удалось оформить заказ', isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger.withValues(alpha: 0.9) : AppColors.panelSoft,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) => _prefill(next.valueOrNull));

    final checkout = ref.watch(checkoutProvider);
    final summary = ref.watch(cartSummaryProvider);
    final outcome = checkout.valueOrNull;

    if (outcome != null) return _Success(outcome: outcome);

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление')),
      body: summary.isEmpty
          ? const MessageState(
              icon: Icons.shopping_bag_outlined,
              title: 'Оформлять пока нечего',
              description: 'Корзина пуста.',
            )
          : Form(
              key: _formKey,
              // Именно SingleChildScrollView, а не ListView: поля формы не должны
              // выгружаться при прокрутке, иначе проверка их пропустит.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text('КОНТАКТЫ', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Имя'),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value ?? '').trim().isEmpty ? 'Как к вам обращаться?' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value ?? '').contains('@') ? null : 'Проверьте адрес',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Телефон', hintText: '+7 999 000-00-00'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value ?? '').trim().length < 10 ? 'Нужен номер для связи' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telegram,
                    decoration: const InputDecoration(labelText: 'Telegram', prefixText: '@'),
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                  ),
                  const Divider(height: 36),
                  Text('ДОСТАВКА', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  for (final method in ShippingMethod.values) ...[
                    _Option(
                      title: method.label,
                      hint: method.hint,
                      selected: _shipping == method,
                      onTap: () => setState(() => _shipping = method),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Город, улица, дом, квартира'),
                    validator: (value) => (value ?? '').trim().length < 5 ? 'Укажите адрес доставки' : null,
                  ),
                  const Divider(height: 36),
                  Text('ОПЛАТА', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  for (final method in PaymentMethod.values) ...[
                    _Option(
                      title: method.label,
                      hint: 'После подтверждения состава заказа',
                      selected: _payment == method,
                      onTap: () => setState(() => _payment = method),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 36),
                  _Summary(summary: summary),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: (value) => setState(() => _accepted = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Принимаю условия публичной оферты и подтверждаю контактные данные',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: checkout.isLoading ? null : _submit,
                    child: checkout.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Подтвердить заказ'),
                  ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ВАШ ЗАКАЗ', style: theme.textTheme.labelSmall),
          const SizedBox(height: 12),
          for (final item in summary.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.card.name} · ${item.quality} · ${item.quantity} шт.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.priceIsPending ? 'уточняется' : formatPrice(item.subtotal),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Text('Итого', style: theme.textTheme.titleLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatPrice(summary.total, fallback: '0 ₽'),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          if (summary.types.length > 1) ...[
            const SizedBox(height: 10),
            Text(
              'Позиции разных типов уедут отдельными заказами — так устроен бэкенд магазина.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.title, required this.hint, required this.selected, required this.onTap});

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.violetStrong.withValues(alpha: 0.16) : AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: selected ? AppColors.violet : AppColors.line),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.violet : AppColors.mutedSoft,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(hint, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Success extends ConsumerWidget {
  const _Success({required this.outcome});

  final CheckoutOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = outcome.orders.map((order) => '#${order.id}').join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(outcome.isPartial ? 'Заказ создан частично' : 'Заказ оформлен')),
      body: MessageState(
        icon: outcome.isPartial ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
        accent: outcome.isPartial ? AppColors.amber : AppColors.mint,
        title: outcome.isPartial ? 'Часть заказа создана' : 'Готово',
        description: outcome.warning ?? 'Создано заказов: ${outcome.orders.length}. Номера: $numbers.',
        retryLabel: 'К моим заказам',
        onRetry: () {
          ref.read(checkoutProvider.notifier).reset();
          context.go(AppRoutes.orders);
        },
      ),
    );
  }
}
