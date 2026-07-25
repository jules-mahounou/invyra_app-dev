// Décorations réutilisables pour cartes, boutons et surfaces INVYRA.
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppDecorations {
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.blancCasse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.noirDoux.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get cardBeige => BoxDecoration(
        color: AppColors.beigeCremeBase,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetRoyal.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get buttonGradient => BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetRoyal.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: AppColors.blancCasse.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.blancCasse.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.noirDoux.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get invitationDecoration => BoxDecoration(
        color: AppColors.beigeCremeAlt,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.orAfricain.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get scanFrameDecoration => BoxDecoration(
        color: AppColors.noirDoux,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.violetRoyalAlt.withValues(alpha: 0.95), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetRoyal.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );
}
