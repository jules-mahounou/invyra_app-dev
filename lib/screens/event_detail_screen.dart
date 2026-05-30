import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../widgets/guest_manager_widget.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    final status = _EventStatusData.from(event['statut'] as String?);
    final guests = List<Map<String, dynamic>>.from(event['guests'] ?? []);
    var localGuests = guests;

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
                _InternalHeader(title: _eventName, onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: AppSpacing.lg),
                _HeroBlock(event: event, status: status),
                const SizedBox(height: AppSpacing.lg),
                _StatisticsBlock(event: event),
                const SizedBox(height: AppSpacing.lg),
                _InformationBlock(event: event),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Invités',
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StatefulBuilder(
                  builder: (context, setGuestsState) {
                    return GuestManagerWidget(
                      initialGuests: localGuests,
                      onGuestsChanged: (updatedGuests) {
                        setGuestsState(() => localGuests = updatedGuests);
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _GradientActionButton(
                  label: 'Envoyer les invitations',
                  icon: Icons.send_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                _OutlineActionButton(
                  label: "Partager l'événement",
                  icon: Icons.share_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text("Clôturer l'événement"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _eventName {
    final value = event['name'] as String?;
    return value == null || value.trim().isEmpty ? 'Événement' : value;
  }
}

class _InternalHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _InternalHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.violetRoyal,
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.violetRoyal),
          color: AppColors.blancCasse,
          itemBuilder: (context) => const [],
        ),
      ],
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final Map<String, dynamic> event;
  final _EventStatusData status;

  const _HeroBlock({
    required this.event,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: _eventGradient(event['type'] as String?),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _StatusBadge(status: status),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              (event['name'] as String?) ?? 'Événement',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.displayMedium?.copyWith(
                color: AppColors.blancCasse,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsBlock extends StatelessWidget {
  final Map<String, dynamic> event;

  const _StatisticsBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    final total = event['invites'] ?? (event['guests'] as List?)?.length ?? 0;

    return Row(
      children: [
        _StatCard(icon: Icons.people_alt_outlined, color: AppColors.violetRoyal, value: '$total', label: 'Total invités'),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(icon: Icons.check_circle_outline_rounded, color: AppColors.info, value: '${event['sent'] ?? 0}', label: 'Envoyées'),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(icon: Icons.visibility_outlined, color: AppColors.warning, value: '${event['views'] ?? 0}', label: 'Vues'),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(icon: Icons.done_all_rounded, color: AppColors.success, value: '${event['confirmed'] ?? 0}', label: 'Confirmées'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.beigeCremeAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppSpacing.lg),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.textTheme.displaySmall?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.noirDoux.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationBlock extends StatelessWidget {
  final Map<String, dynamic> event;

  const _InformationBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTile(icon: Icons.category_outlined, label: 'Type', value: _formatType(event['type'] as String?)),
          _InfoTile(icon: Icons.calendar_today_outlined, label: 'Date', value: (event['date'] as String?) ?? 'Date non définie'),
          _InfoTile(icon: Icons.place_outlined, label: 'Lieu', value: (event['lieu'] as String?) ?? 'Lieu non défini'),
          _InfoTile(icon: Icons.notes_rounded, label: 'Description', value: (event['description'] as String?) ?? 'Aucune description pour le moment.'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: AppSpacing.xxl + AppSpacing.md,
                height: AppSpacing.xxl + AppSpacing.md,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.beigeCremeBase,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
                ),
                child: Image.asset(
                  (event['templateAsset'] as String?) ?? AppAssets.tplMariage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_outlined, color: AppColors.violetRoyal);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Template utilisé',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatType(String? type) {
    switch (type) {
      case 'mariage':
        return 'Mariage';
      case 'anniversaire':
        return 'Anniversaire';
      case 'bapteme':
        return 'Baptême';
      case 'soiree_vip':
        return 'Soirée VIP';
      default:
        return type ?? 'Type non défini';
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.violetRoyal, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrincipal,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: AppSpacing.lg),
          label: Text(label, textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blancCasse,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppSpacing.lg),
        label: Text(label, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violetRoyal,
          side: const BorderSide(color: AppColors.violetRoyal),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _EventStatusData status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EventStatusData {
  final String label;
  final Color color;

  const _EventStatusData({
    required this.label,
    required this.color,
  });

  factory _EventStatusData.from(String? value) {
    switch (value) {
      case 'en_cours':
        return const _EventStatusData(label: 'En cours', color: AppColors.warning);
      case 'termine':
        return const _EventStatusData(label: 'Terminé', color: AppColors.success);
      default:
        return const _EventStatusData(label: 'À venir', color: AppColors.info);
    }
  }
}

LinearGradient _eventGradient(String? type) {
  switch (type) {
    case 'anniversaire':
      return const LinearGradient(
        colors: [AppColors.warning, AppColors.orAfricain],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'bapteme':
      return const LinearGradient(
        colors: [AppColors.info, AppColors.violetRoyalAlt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    default:
      return AppColors.gradientPrincipal;
  }
}
