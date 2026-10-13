import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../widgets/guest_manager_widget.dart';

/// Écran dédié à la gestion des invités d'un événement — séparé de la fiche
/// événement pour que la liste (qui peut compter des dizaines/centaines
/// d'invités) ait toute la place de l'écran, plutôt que de s'ajouter à la
/// suite d'une page déjà longue (stats, infos, aperçu du template...).
class GuestManagerScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final VoidCallback? onChanged;

  const GuestManagerScreen({
    required this.eventId,
    required this.eventName,
    this.onChanged,
    super.key,
  });

  @override
  State<GuestManagerScreen> createState() => _GuestManagerScreenState();
}

class _GuestManagerScreenState extends State<GuestManagerScreen> {
  final _guestManagerKey = GlobalKey<GuestManagerWidgetState>();
  bool _isSending = false;

  Future<void> _generateTickets() async {
    setState(() => _isSending = true);
    try {
      await _guestManagerKey.currentState?.triggerSendInvitations();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Billets générés avec succès ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      appBar: AppBar(
        backgroundColor: AppColors.blancCasse,
        foregroundColor: AppColors.noirDoux,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invités',
              style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              widget.eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.noirDoux.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          child: GuestManagerWidget(
            key: _guestManagerKey,
            eventId: widget.eventId,
            onChanged: widget.onChanged,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.violetRoyal,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _generateTickets,
                icon: const Icon(Icons.send_rounded),
                label: Text(_isSending ? 'Génération...' : 'Générer les billets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.blancCasse,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
