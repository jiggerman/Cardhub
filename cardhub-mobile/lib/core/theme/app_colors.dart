import 'package:flutter/material.dart';

/// Токены дизайна перенесены один в один из веб-клиента
/// (`cardhub-frontend/src/App.css`, блок `:root`).
abstract final class AppColors {
  static const ink = Color(0xFFF5F2EE);
  static const muted = Color(0xFFAAA4AF);
  static const mutedSoft = Color(0xFF77727D);

  static const bg = Color(0xFF100F13);
  static const bgRaised = Color(0xFF17161B);
  static const panel = Color(0xFF1E1C22);
  static const panelSoft = Color(0xFF242129);

  static const line = Color(0x17FFFFFF);
  static const lineStrong = Color(0x29FFFFFF);

  static const violet = Color(0xFF9B87F5);
  static const violetStrong = Color(0xFF7357ED);
  static const coral = Color(0xFFFF8D6C);
  static const mint = Color(0xFF77D8AD);
  static const amber = Color(0xFFF6BD60);
  static const danger = Color(0xFFFF7A88);

  /// Заливка кнопки `.button--primary`.
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violetStrong, Color(0xFF8E68EF)],
  );
}

/// Скругления из веб-клиента: карточки 22, элементы управления 13, поиск 18.
abstract final class AppRadius {
  static const control = 13.0;
  static const field = 18.0;
  static const card = 22.0;
}

abstract final class AppSpacing {
  static const gutter = 20.0;
}
