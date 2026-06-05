import 'package:flutter/material.dart';

import '../core/auth/account_type_ui.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/models/home_dashboard_data.dart';
import '../core/models/recent_event.dart';
import '../core/services/home_dashboard_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../core/widgets/app_shimmer.dart';
import '../widgets/event_thumbnail.dart';

class HomeTabContent extends StatefulWidget {
  final VoidCallback? onSeeAllEvents;

  const HomeTabContent({super.key, this.onSeeAllEvents});

  @override
  State<HomeTabContent> createState() => HomeTabContentState();
}

class HomeTabContentState extends State<HomeTabContent> {
  final _service = HomeDashboardService();

  HomeDashboardData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  /// Recharge le tableau de bord (après création d’un événement, etc.).
  void refresh() => _loadDashboard();

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.fetch();
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger vos données.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _HomeLoadingView();
    }

    if (_errorMessage != null) {
      return _HomeErrorView(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final data = _data!;
    final plan = _AccountPlan.from(data.accountType);

    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: RefreshIndicator(
            color: AppColors.violetRoyal,
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccountBanner(
                    plan: plan,
                    quotaUsed: data.quotaUsed,
                    quotaTotal: data.hasUnlimitedEvents
                        ? null
                        : data.quotaTotal,
                  ),
                  if (AccountTypeUi.showUpgradeBanner(data.planCode)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SubscriptionUpgradeBanner(
                      quotaUsed: data.quotaUsed,
                      quotaMax: data.maxEvents,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _WelcomeCard(userName: data.firstName),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsSection(
                    activeEvents: data.activeEvents,
                    invitesDispatched: data.invitesDispatched,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _QuotaCard(
                    used: data.quotaUsed,
                    total: data.maxEvents,
                    plan: plan,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _EventListSection(
                    events: data.recentEvents,
                    onSeeAll: widget.onSeeAllEvents,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends HomeTabContent {
  const HomeScreen({super.key});
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                const ShimmerBox(
                  height: 140,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
                ),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerBox(height: 72),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerBox(height: 120),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 88)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: ShimmerBox(height: 88)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: ShimmerBox(height: 88)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerBox(height: 160),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerBox(height: 220),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.noirDoux.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionUpgradeBanner extends StatelessWidget {
  final int quotaUsed;
  final int? quotaMax;

  const _SubscriptionUpgradeBanner({
    required this.quotaUsed,
    required this.quotaMax,
  });

  @override
  Widget build(BuildContext context) {
    final quotaLabel = quotaMax != null ? '$quotaUsed/$quotaMax' : '$quotaUsed';

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
            const Icon(
              Icons.bolt_rounded,
              color: AppColors.blancCasse,
              size: AppSpacing.lg,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "Vous utilisez $quotaLabel événements — Passez à Essentiel pour l'illimité",
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
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

class _AccountBanner extends StatelessWidget {
  final _AccountPlan plan;
  final int quotaUsed;
  final int? quotaTotal;

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
                  plan.isPremium
                      ? 'Compte ${AppConstants.appName}'
                      : 'Compte ${plan.label}',
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
                if (quotaTotal != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MiniQuotaProgress(
                    used: quotaUsed,
                    total: quotaTotal!,
                    foregroundColor: AppColors.blancCasse,
                  ),
                ],
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
        border: Border.all(
          color: AppColors.violetRoyal.withValues(alpha: 0.10),
        ),
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
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux,
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

class _StatsSection extends StatelessWidget {
  final int activeEvents;
  final int invitesDispatched;

  const _StatsSection({
    required this.activeEvents,
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
                SizedBox(
                  width: double.infinity,
                  child: _StatCard(data: stat),
                ),
                if (stat != stats.last) const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        final cardWidth =
            (constraints.maxWidth - AppSpacing.lg * (stats.length - 1)) /
            stats.length;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            for (final stat in stats)
              SizedBox(
                width: cardWidth,
                child: _StatCard(data: stat),
              ),
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
            child: Icon(
              data.icon,
              color: AppColors.blancCasse,
              size: AppSpacing.lg,
            ),
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
  final int? total;
  final _AccountPlan plan;

  const _QuotaCard({
    required this.used,
    required this.total,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlimited = total == null;
    final safeTotal = total ?? (used == 0 ? 1 : used);
    final remaining = isUnlimited
        ? null
        : (safeTotal - used).clamp(0, safeTotal);
    final percent = isUnlimited
        ? 0
        : (safeTotal <= 0 ? 0 : ((used / safeTotal) * 100).round());

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
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: plan.color,
                  size: AppSpacing.lg,
                ),
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
                      isUnlimited
                          ? 'Événements illimités sur votre plan'
                          : '$percent% de votre pack consommé',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: plan.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isUnlimited ? '$used / Illimité' : '$used / $safeTotal',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: plan.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!isUnlimited) ...[
            const SizedBox(height: AppSpacing.md),
            _MiniQuotaProgress(
              used: used,
              total: safeTotal,
              foregroundColor: plan.color,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan ${plan.label}',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                isUnlimited ? 'Quota illimité' : '$remaining restants',
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
  final List<RecentEvent> events;
  final VoidCallback? onSeeAll;

  const _EventListSection({required this.events, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(
          color: AppColors.violetRoyal.withValues(alpha: 0.10),
        ),
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
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.violetRoyal,
                ),
                child: const Text('Voir plus'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (events.isEmpty)
            const _EmptyEventsPlaceholder()
          else
            for (final event in events) ...[
              _EventListTile(event: event),
              if (event != events.last) const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _EmptyEventsPlaceholder extends StatelessWidget {
  const _EmptyEventsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Image.asset(
            AppAssets.mascotWelcome,
            height: AppSpacing.xxl + AppSpacing.lg,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Créez votre premier événement !',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  final RecentEvent event;

  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final status = _EventStatus.fromDb(event.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.beigeCremeAlt,
        border: Border.all(
          color: status.backgroundColor.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          EventThumbnail(logoUrl: event.logoUrl, size: AppSpacing.xxl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatEventDateShort(event.eventDate),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      color: AppColors.violetRoyal,
                      size: AppSpacing.md,
                    ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: status.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              status.label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: status.foregroundColor,
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
    final value = total <= 0 ? 0.0 : (used / total).clamp(0, 1).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value,
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
      case 'flex':
        return const _AccountPlan(
          label: 'Premium',
          description: 'Accès complet aux expériences INVYRA.',
          color: AppColors.orAfricain,
          icon: Icons.workspace_premium_rounded,
          gradient: AppColors.gradientLuxe,
          isPremium: true,
        );
      case 'essentiel':
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

enum _EventStatus {
  upcoming('À venir'),
  running('En cours'),
  done('Terminé');

  final String label;

  const _EventStatus(this.label);

  factory _EventStatus.fromDb(String value) {
    switch (value.toLowerCase()) {
      case 'en_cours':
        return _EventStatus.running;
      case 'termine':
      case 'cloture':
        return _EventStatus.done;
      default:
        return _EventStatus.upcoming;
    }
  }

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
