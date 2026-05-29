// Couleurs et dégradés d'identité visuelle INVYRA.
import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color violetRoyal = Color(0xFF5B21B6);
  static const Color violetRoyalAlt = Color(0xFF6D28D9);
  static const Color orAfricain = Color(0xFFD4A017);
  static const Color orAfricainAlt = Color(0xFFE6B800);
  static const Color beigeCremeBase = Color(0xFFF7EEDD);
  static const Color beigeCremeAlt = Color(0xFFFFF8ED);
  static const Color noirDoux = Color(0xFF1F1F1F);
  static const Color blancCasse = Color(0xFFFCFCFC);

  // Couleurs fonctionnelles
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Dégradés
  static const LinearGradient gradientPrincipal = LinearGradient(
    colors: [violetRoyal, orAfricain],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientViolet = LinearGradient(
    colors: [violetRoyal, violetRoyalAlt],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientLuxe = LinearGradient(
    colors: [Color(0xFF1F1F1F), violetRoyal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
