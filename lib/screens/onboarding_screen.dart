import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.onContinue});
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: CustomPaint(
        painter: _FullScreenPainter(waveRatio: 0.58),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Column(
            children: [
              SizedBox(height: size.height * 0.58),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue',
                        style: AppTypography.textTheme.displayLarge?.copyWith(
                          color: AppColors.noirDoux,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Créez des invitations élégantes et mémorables.\nCommencez votre expérience INVYRA.',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.62),
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _GradientContinueButton(
                          onPressed: onContinue ??
                              () => Navigator.pushReplacementNamed(context, '/login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenPainter extends CustomPainter {
  const _FullScreenPainter({required this.waveRatio});
  final double waveRatio;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.orAfricain, AppColors.violetRoyalAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final waveY = size.height * waveRatio;
    final path = Path()
  ..moveTo(0, waveY)
  ..lineTo(size.width * 0.70, waveY + 5)
  
  ..lineTo(size.width, size.height)
  ..lineTo(0, size.height)
  ..close();

    canvas.drawPath(path, Paint()..color = AppColors.blancCasse);
  }

  @override
  bool shouldRepaint(covariant _FullScreenPainter old) =>
      old.waveRatio != waveRatio;
}

class _GradientContinueButton extends StatelessWidget {
  const _GradientContinueButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.violetRoyalAlt, AppColors.orAfricain],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_rounded, color: AppColors.blancCasse, size: 20),
            SizedBox(width: 8),
            Text(
              'Continuer',
              style: TextStyle(
                color: AppColors.blancCasse,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}