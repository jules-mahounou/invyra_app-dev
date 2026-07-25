import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

export '../../core/constants/supabase_schema.dart'
    show
        kEventTypeUiToDb,
        kEventTypeDbToUi,
        kEventTypeDisplayValues,
        eventTypeDbKey,
        eventTypeDisplayLabel;

/// Compte gratuit → templates `gratuit` uniquement ; essentiel / flex → tous les tiers.
bool canAccessTemplateTier(String accountType, String templateTier) {
  if (templateTier == 'gratuit') return true;
  return accountType == 'essentiel' || accountType == 'flex';
}

void showCreateEventErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: AppColors.blancCasse),
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showCreateEventSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: AppColors.blancCasse),
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String formatEventDate(DateTime date) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class CreateEventHero extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onBack;

  const CreateEventHero({required this.currentStep, this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: AppSpacing.lg),
            label: const Text('Retour aux événements'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.violetRoyal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              textStyle: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créer un événement',
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      color: AppColors.noirDoux,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Trois étapes pour lancer votre invitation.',
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Image.asset(
              _mascotForStep(currentStep),
              height: AppSpacing.xxl + AppSpacing.xl,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ],
    );
  }

  String _mascotForStep(int step) {
    if (step == 2) return AppAssets.mascotTemplateChoice;
    if (step == 3) return AppAssets.mascotInviteManager;
    return AppAssets.mascotCreateEvent;
  }
}

class CreateEventStepIndicator extends StatelessWidget {
  final int currentStep;

  const CreateEventStepIndicator({required this.currentStep, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepCircle(number: 1, active: currentStep == 1),
        const Expanded(child: _StepLine()),
        _StepCircle(number: 2, active: currentStep == 2),
        const Expanded(child: _StepLine()),
        _StepCircle(number: 3, active: currentStep == 3),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final bool active;

  const _StepCircle({required this.number, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: active ? null : null,
        color: active ? AppColors.violetRoyal : AppColors.beigeCremeBase,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.violetRoyal.withValues(alpha: 0.18),
                  blurRadius: AppSpacing.lg,
                  offset: const Offset(0, AppSpacing.sm),
                ),
              ]
            : null,
      ),
      child: Text(
        number.toString(),
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: active ? AppColors.blancCasse : AppColors.noirDoux,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.beigeCremeBase,
    );
  }
}

class CreateEventGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const CreateEventGradientButton({
    required this.label,
    required this.icon,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: AppSpacing.lg),
          label: Text(label, textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blancCasse,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
          ),
        ),
      ),
    );
  }
}

class CreateEventOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const CreateEventOutlineButton({
    required this.label,
    required this.icon,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppSpacing.lg),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.violetRoyal),
          foregroundColor: AppColors.violetRoyal,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
        ),
      ),
    );
  }
}
