import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onContinue});
  final VoidCallback? onContinue;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: Stack(
        children: [
          // ── Cercle décoratif coin supérieur droit ──────────────────────
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.25,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violetRoyal,
              ),
            ),
          ),

          // ── Logo centré sur l'écran (vertical + horizontal) ────────────
          Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _fade,
              child: Image.asset(
                'assets/images/logos/logo.png',
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ── Textes + bouton en bas ──────────────────────────────────────
          SafeArea(
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Créez des invitations inoubliables.',
                            style: AppTypography.textTheme.displayLarge
                                ?.copyWith(
                              color: AppColors.noirDoux,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Partagez vos moments précieux avec élégance.',
                            style: AppTypography.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppColors.noirDoux.withValues(alpha: 0.55),
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Bouton CTA
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: GestureDetector(
                              onTap: widget.onContinue ??
                                  () => Navigator.pushReplacementNamed(
                                      context, '/login'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.orAfricain,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Commencer',
                                  style: AppTypography.textTheme.titleMedium
                                      ?.copyWith(
                                    color: AppColors.violetRoyal,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
