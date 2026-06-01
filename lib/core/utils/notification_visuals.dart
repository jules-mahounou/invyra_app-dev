import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NotificationVisuals {
  final IconData icon;
  final Color color;

  const NotificationVisuals({required this.icon, required this.color});
}

abstract final class NotificationVisualsResolver {
  static NotificationVisuals fromType(String type) {
    switch (type) {
      case 'limite_proche':
        return const NotificationVisuals(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        );
      case 'offre_speciale':
        return const NotificationVisuals(
          icon: Icons.star_rounded,
          color: AppColors.violetRoyal,
        );
      case 'evenement_cree':
        return const NotificationVisuals(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      case 'invitations_envoyees':
        return const NotificationVisuals(
          icon: Icons.email_outlined,
          color: AppColors.info,
        );
      case 'securite':
        return const NotificationVisuals(
          icon: Icons.lock_outline_rounded,
          color: AppColors.noirDoux,
        );
      case 'quota_atteint':
        return const NotificationVisuals(
          icon: Icons.block_rounded,
          color: AppColors.error,
        );
      default:
        return const NotificationVisuals(
          icon: Icons.notifications_rounded,
          color: AppColors.violetRoyal,
        );
    }
  }
}
