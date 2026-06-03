import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/guest_manager_widget.dart';
import '../create_event_utils.dart';

/// Étape 3 — Gestion des invités.
class Step3Guests extends StatelessWidget {
  final String eventId;
  final VoidCallback onCreateAndSend;
  final VoidCallback onFinishWithoutSending;
  final VoidCallback onBackToEvents;

  const Step3Guests({
    required this.eventId,
    required this.onCreateAndSend,
    required this.onFinishWithoutSending,
    required this.onBackToEvents,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos invités',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            color: AppColors.noirDoux,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ajoutez vos invités manuellement ou importez une liste.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.noirDoux.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GuestManagerWidget(eventId: eventId),
        const SizedBox(height: AppSpacing.xl),
        CreateEventGradientButton(
          label: 'Créer et envoyer maintenant',
          icon: Icons.send_rounded,
          onPressed: onCreateAndSend,
        ),
        const SizedBox(height: AppSpacing.md),
        CreateEventOutlineButton(
          label: 'Terminer sans envoyer',
          icon: Icons.check_rounded,
          onPressed: onFinishWithoutSending,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: onBackToEvents,
            child: const Text('← Retour à mes événements'),
          ),
        ),
      ],
    );
  }
}
