import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/guest_manager_widget.dart';
import '../create_event_utils.dart';

/// Étape 3 — Gestion des invités.
class Step3Guests extends StatefulWidget {
  final String eventId;
  final VoidCallback onCreateAndSend; // Callback optionnel si tu as une redirection d'écran après succès
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
  State<Step3Guests> createState() => _Step3GuestsState();
}

class _Step3GuestsState extends State<Step3Guests> {
  
  final GlobalKey<GuestManagerWidgetState> _guestManagerKey = GlobalKey<GuestManagerWidgetState>();
  bool _isSending = false;

  Future<void> _handleCreateAndSend() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // On demande au widget enfant de lancer l'Edge Function avec ses paramètres locaux (WhatsApp/Email)
      await _guestManagerKey.currentState?.triggerSendInvitations();
      
      if (!mounted) return;
      
      // Message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Invitations générées avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );

      // Exécute la suite de ton workflow (ex: redirection vers l'accueil ou le récapitulatif)
      widget.onCreateAndSend();
    } catch (e) {
      if (!mounted) return;
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

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
        
        // On attache la clé ici pour piloter l'état de l'envoi et des canaux
        GuestManagerWidget(
          key: _guestManagerKey,
          eventId: widget.eventId,
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        _isSending 
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: CircularProgressIndicator(color: AppColors.violetRoyal),
              ),
            )
          : CreateEventGradientButton(
              label: 'Générer les invitations',
              icon: Icons.send_rounded,
              onPressed: _handleCreateAndSend, // Utilise la nouvelle fonction connectée à l'Edge Function
            ),
            
        const SizedBox(height: AppSpacing.md),
        CreateEventOutlineButton(
          label: 'Terminer sans envoyer',
          icon: Icons.check_rounded,
          onPressed: widget.onFinishWithoutSending,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: widget.onBackToEvents,
            child: const Text('← Retour à mes événements'),
          ),
        ),
      ],
    );
  }
}