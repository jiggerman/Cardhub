import 'package:flutter/material.dart';

import '../../../core/widgets/stage_placeholder.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: const StagePlaceholder(
        icon: Icons.receipt_long_outlined,
        title: 'Заказов пока нет',
        description: 'История заказов появится вместе с оформлением.',
      ),
    );
  }
}
