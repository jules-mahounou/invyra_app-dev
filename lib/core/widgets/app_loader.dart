import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Loader INVYRA — logo avec barre de scan lumineuse qui balaye de haut en bas.
class AppLoader extends StatefulWidget {
  /// Taille du carré contenant le logo (défaut 80)
  final double size;

  /// Fond de la page (pour centrer proprement)
  final Color? backgroundColor;

  const AppLoader({super.key, this.size = 80, this.backgroundColor});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scan = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    return ColoredBox(
      color: bg,
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Logo INVYRA
              Positioned.fill(
                child: Image.asset(
                  'assets/images/logos/logo_.png',
                  fit: BoxFit.contain,
                ),
              ),
              // Barre de scan lumineuse
              AnimatedBuilder(
                animation: _scan,
                builder: (_, __) {
                  final top = _scan.value * widget.size - 3;
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: top.clamp(0.0, widget.size - 3),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violetRoyal.withValues(alpha: 0),
                            AppColors.violetRoyal.withValues(alpha: 0.9),
                            AppColors.orAfricain.withValues(alpha: 0.95),
                            AppColors.violetRoyal.withValues(alpha: 0.9),
                            AppColors.violetRoyal.withValues(alpha: 0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violetRoyal.withValues(alpha: 0.55),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Version plein écran — à utiliser comme page de chargement complète
class AppLoaderScreen extends StatelessWidget {
  final Color? backgroundColor;
  const AppLoaderScreen({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.blancCasse,
      child: AppLoader(size: 80, backgroundColor: backgroundColor ?? AppColors.blancCasse),
    );
  }
}
