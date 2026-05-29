// Thème principal Material 3 pour l'identité visuelle INVYRA.
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.beigeCremeAlt,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violetRoyal,
        primary: AppColors.violetRoyal,
        secondary: AppColors.orAfricain,
        surface: AppColors.blancCasse,
      ),
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.noirDoux,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.displaySmall,
      ),
      cardTheme: CardThemeData(
        color: AppColors.blancCasse,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blancCasse,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.violetRoyalAlt, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.25), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.blancCasse,
        selectedItemColor: AppColors.violetRoyal,
        unselectedItemColor: AppColors.noirDoux.withValues(alpha: 0.65),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );

    return base.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm)),
          textStyle: WidgetStatePropertyAll(AppTypography.textTheme.labelLarge),
          foregroundColor: const WidgetStatePropertyAll(AppColors.blancCasse),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          ),
          backgroundBuilder: (context, states, child) => DecoratedBox(
            decoration: AppDecorations.buttonGradient,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.beigeCremeBase,
        selectedColor: AppColors.violetRoyal,
        labelStyle: AppTypography.textTheme.bodyMedium,
      ),
    );
  }
}
