import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barres système (heure/réseau/batterie en haut, navigation Android en bas)
/// transparentes : chaque écran s'affiche bord à bord, sa couleur de fond
/// remonte sous la barre d'état.
class AppSystemUi {
  /// Icônes foncées : écrans à fond clair (cas général).
  static const standard = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// Icônes blanches en haut : écrans à en-tête violet (accueil, connexion…).
  /// Le bas de ces écrans reste clair, d'où des icônes foncées en bas.
  static const onDarkHeader = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static Future<void> enableEdgeToEdge() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(standard);
  }
}
