// Couleurs et dégradés d'identité visuelle INVYRA.
import 'package:flutter/material.dart';

class AppColors {
  // ─── Couleurs principales ──────────────────────────────────────────────────
  /// Violet profond — couleur primaire des boutons et éléments d'action
  static const Color violetRoyal = Color(0xFF420F75);

  /// Violet légèrement plus clair — hover, états secondaires
  static const Color violetRoyalAlt = Color(0xFF5A1E9A);

  /// Or ambré — couleur accent pour les touches spéciales
  static const Color orAfricain = Color(0xFFF9B233);

  /// Or ambré clair — variante de l'accent
  static const Color orAfricainAlt = Color(0xFFFAC040);

  // ─── Couleurs de fond ──────────────────────────────────────────────────────
  static const Color beigeCremeBase = Color(0xFFF6F6F6);
  static const Color beigeCremeAlt = Color(0xFFF0EDE8);
  static const Color noirDoux = Color(0xFF1F1F1F);
  static const Color blancCasse = Color(0xFFF6F6F6);

  // ─── Couleurs fonctionnelles ───────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // ─── Dégradés ─────────────────────────────────────────────────────────────
  /// Dégradé principal — violet vers or (utilisé uniquement pour décorations)
  static const LinearGradient gradientPrincipal = LinearGradient(
    colors: [violetRoyal, orAfricain],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé violet — deux teintes de violet
  static const LinearGradient gradientViolet = LinearGradient(
    colors: [violetRoyal, violetRoyalAlt],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dégradé luxe — noir vers violet
  static const LinearGradient gradientLuxe = LinearGradient(
    colors: [Color(0xFF1F1F1F), violetRoyal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
