// Thème principal Material 3 pour l'identité visuelle INVYRA.
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_spacing.dart';
import 'app_system_ui.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // Police par défaut de tout texte non stylé (boutons, champs, menus…).
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.beigeCremeAlt,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violetRoyal,
        primary: AppColors.violetRoyal,
        secondary: AppColors.orAfricain,
        surface: AppColors.blancCasse,
      ),
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: AppSystemUi.standard,
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
        fillColor: AppColors.beigeCremeAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppColors.noirDoux.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppColors.noirDoux.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: AppColors.noirDoux.withValues(alpha: 0.40),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: AppColors.noirDoux.withValues(alpha: 0.55),
        ),
        prefixIconColor: AppColors.violetRoyal,
        suffixIconColor: WidgetStateColor.fromMap({
          WidgetState.focused: AppColors.violetRoyal,
          WidgetState.any: AppColors.noirDoux,
        }),
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
