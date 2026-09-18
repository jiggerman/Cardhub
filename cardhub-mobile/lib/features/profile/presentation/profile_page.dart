import 'package:flutter/material.dart';

import '../../../core/widgets/stage_placeholder.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: const StagePlaceholder(
        icon: Icons.person_outline_rounded,
        title: 'Вход появится позже',
        description: 'Авторизация, Telegram и адрес доставки — на этапе профиля.',
      ),
    );
  }
}
