import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Vignette événement : logo uploadé si disponible, sinon icône calendrier.
class EventThumbnail extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final BorderRadius? borderRadius;

  const EventThumbnail({
    super.key,
    this.logoUrl,
    this.size = AppSpacing.xxl,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: logoUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => _fallbackBox(radius),
            errorWidget: (_, _, _) => _fallbackBox(radius),
          ),
        ),
      );
    }

    return _fallbackBox(radius);
  }

  Widget _fallbackBox(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.beigeCremeBase,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.violetRoyal.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.calendar_today_outlined,
        color: AppColors.violetRoyal.withValues(alpha: 0.75),
        size: size * 0.42,
      ),
    );
  }
}
