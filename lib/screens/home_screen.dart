import 'package:flutter/material.dart';

import '../core/auth/auth_gate.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/models/home_dashboard_data.dart';
import '../core/models/recent_event.dart';
import '../core/services/home_dashboard_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../core/widgets/app_shimmer.dart';
import '../widgets/event_thumbnail.dart';
import 'event_detail_screen.dart';

class HomeTabContent extends StatefulWidget {
  final VoidCallback? onSeeAllEvents;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;

  const HomeTabContent({
    super.key,
    this.onSeeAllEvents,
    this.unreadCount = 0,
    this.onNotificationsTap,
  });

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
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: RefreshIndicator(
            color: AppColors.violetRoyal,
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header propre à la page ──
                  _HomeHeader(
                    userName: data.firstName,
                    avatarUrl: data.avatarUrl,
                    unreadCount: widget.unreadCount,
                    onNotificationsTap: widget.onNotificationsTap,
                    onSeeAllEvents: widget.onSeeAllEvents,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Carte Créer un événement ──
                        _CreateEventCard(onTap: widget.onSeeAllEvents),
                        const SizedBox(height: AppSpacing.lg),
                        // ── Stats ──
                        _StatsSection(
                          activeEvents: data.activeEvents,
                          invitesDispatched: data.invitesDispatched,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // ── Événements récents ──
                        _EventListSection(
                          events: data.recentEvents,
                          onSeeAll: widget.onSeeAllEvents,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // ── Bouton abonnements ──
                        _PlansButton(),
                      ],
                    ),
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

// ─── Header propre à la page Home ────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSeeAllEvents;

  const _HomeHeader({
    required this.userName,
    required this.avatarUrl,
    required this.unreadCount,
    this.onNotificationsTap,
    this.onSeeAllEvents,
  });

  @override
  Widget build(BuildContext context) {
    final badgeLabel = unreadCount > 9 ? '9+' : '$unreadCount';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.beigeCremeAlt,
              border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.2), width: 2),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppColors.violetRoyal, size: 24))
                  : const Icon(Icons.person_rounded, color: AppColors.violetRoyal, size: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  userName.isNotEmpty ? userName.split(' ').first : 'Utilisateur',
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Cloche notifications
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotificationsTap,
                icon: const Icon(Icons.notifications_rounded),
                color: AppColors.violetRoyal,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.violetRoyal.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4, top: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(color: AppColors.orAfricain, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(badgeLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Carte Créer un événement ─────────────────────────────────────────────────
class _CreateEventCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _CreateEventCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.violetRoyal,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Texte + bouton à gauche
            Positioned(
              left: AppSpacing.lg,
              bottom: AppSpacing.lg,
              right: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Créer un\névénement',
                    style: AppTypography.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'Commencer',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.violetRoyal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Badge "Nouveau"
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.orAfricain,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Nouveau',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Illustration à droite
            Positioned(
              right: -8,
              bottom: 0,
              child: Image.asset(
                'assets/images/illustrations/invyra_event_asset.png',
                height: 170,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _StatsSection extends StatelessWidget {
  final int activeEvents;
  final int invitesDispatched;

  const _StatsSection({
    required this.activeEvents,
    required this.invitesDispatched,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.event_available_rounded,
            label: 'Événements actifs',
            value: activeEvents.toString(),
            color: AppColors.violetRoyal,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.send_rounded,
            label: 'Invitations envoyées',
            value: invitesDispatched.toString(),
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.55),
                    fontSize: 11,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section — titre + lien "Voir plus"
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
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            if (event != events.last) const SizedBox(height: AppSpacing.xs),
          ],
      ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            EventThumbnail(logoUrl: event.logoUrl, size: 48),
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
                      color: AppColors.noirDoux,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.noirDoux.withValues(alpha: 0.45),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatEventDateShort(event.eventDate),
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.place_outlined,
                        color: AppColors.noirDoux.withValues(alpha: 0.45),
                        size: 11,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.noirDoux.withValues(alpha: 0.55),
                            fontSize: 11,
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
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                status.label,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: status.foregroundColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.noirDoux.withValues(alpha: 0.25),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
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
