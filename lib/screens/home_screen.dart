import 'package:flutter/material.dart';

import '../core/auth/auth_gate.dart';
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
import 'event_detail_screen.dart';

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
                  _WelcomeCard(userName: data.firstName),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsSection(
                    activeEvents: data.activeEvents,
                    invitesDispatched: data.invitesDispatched,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PlansButton(),
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

class _PlansButton extends StatelessWidget {
  const _PlansButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pushNamed('/subscription'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orAfricain,
          side: const BorderSide(color: AppColors.orAfricain, width: 1.5),
          backgroundColor: AppColors.orAfricain.withValues(alpha: 0.04),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Voir les offres d\'abonnement',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.orAfricain,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
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

    return InkWell(
      onTap: () => pushProtectedRoute(
        context,
        EventDetailScreen(eventId: event.id),
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.noirDoux.withValues(alpha: 0.35),
                  size: AppSpacing.lg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
