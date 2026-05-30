import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class HomeTabContent extends StatelessWidget {
  final String userName;
  final String accountType;
  final int activeEvents;
  final int guestsConfirmed;
  final int invitesDispatched;
  final int quotaUsed;
  final int quotaTotal;

  const HomeTabContent({
    super.key,
    this.userName = 'Amani',
    this.accountType = 'premium',
    this.activeEvents = 12,
    this.guestsConfirmed = 482,
    this.invitesDispatched = 1240,
    this.quotaUsed = 1240,
    this.quotaTotal = 2000,
  });

  @override
  Widget build(BuildContext context) {
    final plan = _AccountPlan.from(accountType);

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
                _AccountBanner(plan: plan, quotaUsed: quotaUsed, quotaTotal: quotaTotal),
                const SizedBox(height: AppSpacing.lg),
                // TODO: décommenter lors de l'intégration backend
                // if (userPlan != 'premium')
                const _SubscriptionUpgradeBanner(),
                const SizedBox(height: AppSpacing.lg),
                _WelcomeCard(userName: userName),
                const SizedBox(height: AppSpacing.lg),
                _StatsSection(
                  activeEvents: activeEvents,
                  guestsConfirmed: guestsConfirmed,
                  invitesDispatched: invitesDispatched,
                ),
                const SizedBox(height: AppSpacing.lg),
                _QuotaCard(used: quotaUsed, total: quotaTotal, plan: plan),
                const SizedBox(height: AppSpacing.lg),
                const _EventListSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionUpgradeBanner extends StatelessWidget {
  const _SubscriptionUpgradeBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/subscription'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.violetRoyal.withValues(alpha: 0.82),
              AppColors.orAfricain.withValues(alpha: 0.82),
            ],
            begin: AppColors.gradientPrincipal.begin,
            end: AppColors.gradientPrincipal.end,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.blancCasse, size: AppSpacing.lg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "Vous utilisez 2/3 événements — Passez à Essentiel pour l'illimité",
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.blancCasse,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/subscription'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blancCasse,
                foregroundColor: AppColors.violetRoyal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                minimumSize: const Size(0, AppSpacing.xl),
              ),
              child: const Text('Voir les offres'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends HomeTabContent {
  const HomeScreen({
    super.key,
    super.userName,
    super.accountType,
    super.activeEvents,
    super.guestsConfirmed,
    super.invitesDispatched,
    super.quotaUsed,
    super.quotaTotal,
  });
}

class _AccountBanner extends StatelessWidget {
  final _AccountPlan plan;
  final int quotaUsed;
  final int quotaTotal;

  const _AccountBanner({
    required this.plan,
    required this.quotaUsed,
    required this.quotaTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: plan.gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: 0.16),
            blurRadius: AppSpacing.xl,
            offset: const Offset(0, AppSpacing.md),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.isPremium ? 'Compte ${AppConstants.appName}' : 'Compte ${plan.label}',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.blancCasse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.description,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.blancCasse,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MiniQuotaProgress(
                  used: quotaUsed,
                  total: quotaTotal,
                  foregroundColor: AppColors.blancCasse,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: AppSpacing.xxl + AppSpacing.lg,
            height: AppSpacing.xxl + AppSpacing.lg,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.blancCasse,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: plan.isPremium
                ? Image.asset(AppAssets.logoMark, fit: BoxFit.contain)
                : Icon(plan.icon, color: plan.color, size: AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;

  const _WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.mascotWelcome,
            height: AppSpacing.xxl + AppSpacing.lg,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, $userName',
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.violetRoyal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Vos invitations, invités et événements sont prêts à être pilotés avec élégance.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.noirDoux),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int activeEvents;
  final int guestsConfirmed;
  final int invitesDispatched;

  const _StatsSection({
    required this.activeEvents,
    required this.guestsConfirmed,
    required this.invitesDispatched,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        icon: Icons.event_available_rounded,
        label: 'Événements actifs',
        value: activeEvents.toString(),
        color: AppColors.violetRoyal,
      ),
      _StatData(
        icon: Icons.people_alt_rounded,
        label: 'Invités confirmés',
        value: guestsConfirmed.toString(),
        color: AppColors.orAfricain,
      ),
      _StatData(
        icon: Icons.send_rounded,
        label: 'Invitations envoyées',
        value: invitesDispatched.toString(),
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppConstants.maxContentWidth / 2;

        if (compact) {
          return Column(
            children: [
              for (final stat in stats) ...[
                SizedBox(width: double.infinity, child: _StatCard(data: stat)),
                if (stat != stats.last) const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        final cardWidth = (constraints.maxWidth - AppSpacing.lg * (stats.length - 1)) / stats.length;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            for (final stat in stats)
              SizedBox(width: cardWidth, child: _StatCard(data: stat)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        border: Border.all(color: data.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(data.icon, color: AppColors.blancCasse, size: AppSpacing.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.label,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
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

class _QuotaCard extends StatelessWidget {
  final int used;
  final int total;
  final _AccountPlan plan;

  const _QuotaCard({required this.used, required this.total, required this.plan});

  @override
  Widget build(BuildContext context) {
    final remaining = (total - used).clamp(0, total);
    final percent = total <= 0 ? 0 : ((used / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.beigeCremeAlt,
        border: Border.all(color: plan.color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: plan.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.auto_graph_rounded, color: plan.color, size: AppSpacing.lg),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Utilisation du quota',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$percent% de votre pack consommé',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: plan.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$used / $total',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: plan.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MiniQuotaProgress(used: used, total: total, foregroundColor: plan.color),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan ${plan.label}',
                  style: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$remaining restants',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.noirDoux.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventListSection extends StatelessWidget {
  const _EventListSection();

  @override
  Widget build(BuildContext context) {
    final events = [
      _EventListItem(
        title: 'Soirée d’ouverture',
        date: 'Aujourd’hui • 18h30',
        place: 'Hôtel Ivoire, Abidjan',
        status: _EventStatus.upcoming,
      ),
      _EventListItem(
        title: 'Carnet d’invités',
        date: 'Hier • 14h00',
        place: 'Salle Ébène, Dakar',
        status: _EventStatus.done,
      ),
      _EventListItem(
        title: 'Thème premium',
        date: 'Mar 27 • 10h15',
        place: 'Studio INVYRA',
        status: _EventStatus.running,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Événements récents',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.violetRoyal),
                child: const Text('Voir plus'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final event in events) ...[
            _EventListTile(event: event),
            if (event != events.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  final _EventListItem event;

  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.beigeCremeAlt,
        border: Border.all(color: event.status.backgroundColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.beigeCremeBase,
              child: Image.asset(AppAssets.logoMark, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  event.date,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.place_outlined, color: AppColors.violetRoyal, size: AppSpacing.md),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        event.place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: event.status.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              event.status.label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: event.status.foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniQuotaProgress extends StatelessWidget {
  final int used;
  final int total;
  final Color foregroundColor;

  const _MiniQuotaProgress({
    required this.used,
    required this.total,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = total <= 0 ? 0 : (used / total).clamp(0, 1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value.toDouble(),
        minHeight: AppSpacing.sm,
        backgroundColor: AppColors.beigeCremeBase,
        valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
      ),
    );
  }
}

class _AccountPlan {
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final LinearGradient gradient;
  final bool isPremium;

  const _AccountPlan({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.gradient,
    this.isPremium = false,
  });

  factory _AccountPlan.from(String value) {
    switch (value.toLowerCase()) {
      case 'premium':
        return const _AccountPlan(
          label: 'Premium',
          description: 'Accès complet aux expériences INVYRA.',
          color: AppColors.orAfricain,
          icon: Icons.workspace_premium_rounded,
          gradient: AppColors.gradientLuxe,
          isPremium: true,
        );
      case 'standard':
        return const _AccountPlan(
          label: 'Standard',
          description: 'Les essentiels pour vos événements réguliers.',
          color: AppColors.violetRoyalAlt,
          icon: Icons.verified_user_rounded,
          gradient: AppColors.gradientViolet,
        );
      default:
        return const _AccountPlan(
          label: 'Basique',
          description: 'Un démarrage simple pour créer vos invitations.',
          color: AppColors.noirDoux,
          icon: Icons.person_outline_rounded,
          gradient: AppColors.gradientPrincipal,
        );
    }
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _EventListItem {
  final String title;
  final String date;
  final String place;
  final _EventStatus status;

  const _EventListItem({
    required this.title,
    required this.date,
    required this.place,
    required this.status,
  });
}

enum _EventStatus {
  upcoming('À venir'),
  running('En cours'),
  done('Terminé');

  final String label;

  const _EventStatus(this.label);

  Color get backgroundColor {
    switch (this) {
      case _EventStatus.upcoming:
        return AppColors.info.withValues(alpha: 0.12);
      case _EventStatus.running:
        return AppColors.warning.withValues(alpha: 0.12);
      case _EventStatus.done:
        return AppColors.success.withValues(alpha: 0.12);
    }
  }

  Color get foregroundColor {
    switch (this) {
      case _EventStatus.upcoming:
        return AppColors.info;
      case _EventStatus.running:
        return AppColors.warning;
      case _EventStatus.done:
        return AppColors.success;
    }
  }
}
