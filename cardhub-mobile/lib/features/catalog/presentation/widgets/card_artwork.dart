import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Картинка карты со скруглением и рубашкой вместо отсутствующего изображения:
/// у двусторонних карт бэкенд оставляет ссылки пустыми.
class CardArtwork extends StatelessWidget {
  const CardArtwork({required this.imageUrl, this.radius = 14, this.fit = BoxFit.cover, super.key});

  final String imageUrl;
  final double radius;
  final BoxFit fit;

  /// Пропорции карты Magic (63 × 88 мм).
  static const aspectRatio = 63 / 88;

  static const _cardBack = 'assets/images/card_back.webp';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: imageUrl.isEmpty
            ? const _CardBack()
            : Image.network(
                imageUrl,
                fit: fit,
                errorBuilder: (context, error, stack) => const _CardBack(),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const ColoredBox(
                        color: AppColors.panelSoft,
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
              ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) => Image.asset(CardArtwork._cardBack, fit: BoxFit.cover);
}
