import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'create_event_utils.dart';
import 'steps/step1_basic_info.dart';

/// Écran de création d'événement — une seule étape (infos de base).
/// Après création, l'utilisateur est redirigé vers EventDetailScreen.
class CreateEventScreen extends StatelessWidget {
  final String accountType;
  final VoidCallback? onBack;

  const CreateEventScreen({
    super.key,
    this.accountType = 'gratuit',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CreateEventHeader(onBack: onBack),
                const SizedBox(height: AppSpacing.xl),
                Step1BasicInfo(
                  onStepCompleted: (eventId, eventType, _) {
                    // Redirection directe vers EventDetailScreen
                    onBack?.call();
                    showCreateEventSuccessSnackBar(
                      context,
                      'Événement créé ! Ajoutez vos invités et choisissez un template.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Version tab (utilisée dans MainScaffold via IndexedStack)
class CreateEventTabContent extends StatelessWidget {
  final String accountType;
  final VoidCallback? onBack;

  const CreateEventTabContent({
    super.key,
    this.accountType = 'gratuit',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return CreateEventScreen(accountType: accountType, onBack: onBack);
  }
}

class _CreateEventHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const _CreateEventHeader({this.onBack});

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
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Créer un événement',
          style: AppTypography.textTheme.displayLarge?.copyWith(
            color: AppColors.noirDoux,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Renseignez les informations de votre événement. Vous pourrez choisir un template et ajouter vos invités depuis l\'écran de l\'événement.',
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.noirDoux.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
