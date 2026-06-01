import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Libellés affichés dans l’UI (Basique / Standard / Premium) pour les
/// valeurs Supabase `account_type` : gratuit, essentiel, flex.
abstract final class AccountTypeUi {
  static String badgeLabel(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'essentiel':
        return 'Standard';
      case 'flex':
        return 'Premium';
      default:
        return 'Basique';
    }
  }

  static Color badgeColor(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'essentiel':
        return AppColors.violetRoyalAlt;
      case 'flex':
        return AppColors.orAfricain;
      default:
        return AppColors.noirDoux;
    }
  }

  static IconData badgeIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'essentiel':
        return Icons.verified_user_rounded;
      case 'flex':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  static bool showUpgradeBanner(String planCode) {
    final code = planCode.toLowerCase();
    return code == 'gratuit' || code == 'essentiel';
  }

  static bool isPremiumTier(String accountType) => accountType.toLowerCase() == 'flex';
}
