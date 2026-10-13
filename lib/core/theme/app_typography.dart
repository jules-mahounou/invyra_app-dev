// Styles typographiques et familles de polices INVYRA.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  /// Police de toute l'interface, embarquée dans l'app (assets/fonts/Manrope).
  static const String fontFamily = 'Manrope';

  static TextStyle _manrope(double size, FontWeight weight, {double? height}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: AppColors.noirDoux,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: _manrope(32, FontWeight.w800, height: 1.15),
        displayMedium: _manrope(24, FontWeight.w800, height: 1.2),
        displaySmall: _manrope(20, FontWeight.w700, height: 1.25),
        headlineLarge: _manrope(18, FontWeight.w700),
        titleLarge: _manrope(18, FontWeight.w700),
        titleMedium: _manrope(16, FontWeight.w700),
        titleSmall: _manrope(14, FontWeight.w700),
        bodyLarge: _manrope(16, FontWeight.w500),
        bodyMedium: _manrope(14, FontWeight.w500),
        bodySmall: _manrope(12, FontWeight.w500),
        labelLarge: _manrope(14, FontWeight.w600),
        labelMedium: _manrope(12, FontWeight.w600),
        labelSmall: _manrope(11, FontWeight.w600),
      );

  static TextStyle elegantTitle = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontStyle: FontStyle.italic,
    color: AppColors.noirDoux,
  );

  static TextStyle elegantBody = GoogleFonts.playfairDisplay(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.noirDoux,
  );
}
