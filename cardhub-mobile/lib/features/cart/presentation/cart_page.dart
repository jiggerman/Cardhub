import 'package:flutter/material.dart';

import '../../../core/widgets/stage_placeholder.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: const StagePlaceholder(
        icon: Icons.shopping_bag_outlined,
        title: 'Корзина пока пуста',
        description: 'Добавление карт и лимиты появятся на этапе корзины.',
      ),
    );
  }
}
