import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/auth/auth_gate.dart';
import '../core/constants/app_assets.dart';
import '../core/models/home_dashboard_data.dart';
import '../core/models/recent_event.dart';
import '../core/services/home_dashboard_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../core/widgets/app_loader.dart';
import '../core/widgets/auth_layout.dart';
import 'event_detail_screen.dart';

class HomeTabContent extends StatefulWidget {
  final VoidCallback? onSeeAllEvents;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onProfileTap;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;

  const HomeTabContent({
    super.key,
    this.onSeeAllEvents,
    this.onCreateEvent,
    this.onProfileTap,
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
      _isLoading = _data == null;
      _errorMessage = null;
    });

    try {
      final data = await _service.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger vos données. Vérifiez votre connexion internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoaderScreen();

    final data = _data;
    if (data == null) {
      return _HomeErrorView(
        message: _errorMessage ?? 'Impossible de charger vos données.',
        onRetry: _loadDashboard,
      );
    }

    return HomeView(
      data: data,
      unreadCount: widget.unreadCount,
      onRefresh: _loadDashboard,
      onNotificationsTap: widget.onNotificationsTap,
      onSeeAllEvents: widget.onSeeAllEvents,
      onCreateEvent: widget.onCreateEvent ?? widget.onSeeAllEvents,
      onOpenEvent: (event) => pushProtectedRoute(context, EventDetailScreen(eventId: event.id)),
      onProfileTap: widget.onProfileTap,
    );
  }
}

class HomeScreen extends HomeTabContent {
  const HomeScreen({super.key});
}

/// Affichage de l'accueil, à partir de données déjà chargées.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.data,
    required this.onRefresh,
    this.unreadCount = 0,
    this.onNotificationsTap,
    this.onSeeAllEvents,
    this.onCreateEvent,
    this.onOpenEvent,
    this.onProfileTap,
  });

  final HomeDashboardData data;
  final int unreadCount;
  final Future<void> Function() onRefresh;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSeeAllEvents;
  final VoidCallback? onCreateEvent;
  final ValueChanged<RecentEvent>? onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Sur tablette, le contenu reste dans une colonne confortable au centre.
    final hPad = width > 720 ? (width - 640) / 2 : AppSpacing.lg;

    return Material(
      color: AppColors.blancCasse,
      child: RefreshIndicator(
        color: AppColors.violetRoyal,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.md, hPad, 0),
              child: _TopBar(
                avatarUrl: data.avatarUrl,
                unreadCount: unreadCount,
                onNotificationsTap: onNotificationsTap,
                onProfileTap: onProfileTap,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.lg, hPad, 0),
              child: _Greeting(firstName: data.firstName),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _SectionTitle(
                title: 'Vos événements',
                actionLabel: data.recentEvents.isEmpty ? null : 'Voir tout',
                onAction: onSeeAllEvents,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (data.recentEvents.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _FirstEventCard(onCreate: onCreateEvent),
              )
            else
              _EventsCarousel(
                events: data.recentEvents,
                horizontalPadding: hPad,
                onOpen: onOpenEvent,
                onCreate: onCreateEvent,
              ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _StatsCard(data: data),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _PlanCard(data: data),
            ),
            if (data.accountType != 'essentiel' && data.flexPacks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _PacksSection(packs: data.flexPacks, horizontalPadding: hPad),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Barre du haut : avatar + notifications ──────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.avatarUrl,
    required this.unreadCount,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Row(
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(AppAssets.logoColor, height: 34, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: onNotificationsTap,
          badge: unreadCount > 0 ? (unreadCount > 9 ? '9+' : '$unreadCount') : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Tooltip(
          message: 'Mon profil',
          child: GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: url != null && url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const _AvatarFallback(),
                      )
                    : const _AvatarFallback(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.violetRoyal.withValues(alpha: 0.10),
      child: const Icon(Icons.person_rounded, color: AppColors.violetRoyal, size: 24),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, this.onTap, this.badge});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(icon, color: AppColors.noirDoux, size: 24),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.orAfricain,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.blancCasse, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Salutation ──────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final salutation = hour >= 5 && hour < 18 ? 'Bonjour' : 'Bonsoir';
    final muted = AppColors.noirDoux.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$salutation,', style: AppTypography.textTheme.titleLarge?.copyWith(color: muted)),
        const SizedBox(height: 2),
        // Prénom souligné en doré sur 70 % de sa largeur, comme les titres des écrans de connexion.
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.displayLarge?.copyWith(fontSize: 34, letterSpacing: -0.8),
              ),
              const SizedBox(height: 2),
              FractionallySizedBox(
                widthFactor: 0.7,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.orAfricain,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Prêt à célébrer ?', style: AppTypography.textTheme.bodyLarge?.copyWith(color: muted)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(
                actionLabel!,
                style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.violetRoyal),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Carrousel d'événements ──────────────────────────────────────────────────

class _EventsCarousel extends StatefulWidget {
  const _EventsCarousel({
    required this.events,
    required this.horizontalPadding,
    this.onOpen,
    this.onCreate,
  });

  final List<RecentEvent> events;
  final double horizontalPadding;
  final ValueChanged<RecentEvent>? onOpen;
  final VoidCallback? onCreate;

  @override
  State<_EventsCarousel> createState() => _EventsCarouselState();
}

class _EventsCarouselState extends State<_EventsCarousel> {
  PageController? _controller;
  double _fraction = 0;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double fraction) {
    if (_controller == null || _fraction != fraction) {
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(viewportFraction: fraction, initialPage: _page);
    }
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.events.length + 1; // + carte « Nouvel événement »

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Une carte principale bien visible + un aperçu de la suivante.
        final cardWidth = math.min(width - 2 * widget.horizontalPadding - 40, 420.0);
        final fraction = (cardWidth / width).clamp(0.4, 0.92);
        final height = (cardWidth * 1.05).clamp(250.0, 400.0);
        final controller = _controllerFor(fraction);

        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: controller,
                padEnds: false,
                itemCount: count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final card = index < widget.events.length
                      ? _EventCard(
                          event: widget.events[index],
                          onTap: () => widget.onOpen?.call(widget.events[index]),
                        )
                      : _NewEventCard(onTap: widget.onCreate);
                  // Les cartes voisines sont légèrement réduites : effet de profondeur.
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      var delta = (index - _page).toDouble();
                      if (controller.hasClients && controller.position.haveDimensions) {
                        delta = index - (controller.page ?? _page.toDouble());
                      }
                      final scale = 1 - (delta.abs() * 0.06).clamp(0.0, 0.06);
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? widget.horizontalPadding : 6,
                          right: index == count - 1 ? widget.horizontalPadding : 6,
                        ),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: card,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PageDots(count: count, current: _page),
          ],
        );
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == current ? AppColors.orAfricain : AppColors.noirDoux.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.onTap});

  final RecentEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _EventStatus.fromDb(event.status);
    final logo = event.logoUrl;
    final date = event.eventDate;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (logo != null && logo.isNotEmpty)
              CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const _CardPattern(),
              )
            else
              const _CardPattern(),
            // Dégradé sombre en bas pour garder le texte lisible sur n'importe quelle photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 1],
                  colors: [Colors.transparent, Color(0xD9140A24)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _GlassChip(label: status.label, dotColor: status.color),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (date != null) _InfoTag(icon: Icons.event_rounded, label: formatEventDateShort(date)),
                      if (event.place.isNotEmpty) _InfoTag(icon: Icons.place_rounded, label: event.place),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fond violet texturé (lignes topographiques) pour les événements sans photo.
class _CardPattern extends StatelessWidget {
  const _CardPattern();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: BrandHeaderPainter());
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, required this.dotColor});

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.noirDoux),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewEventCard extends StatelessWidget {
  const _NewEventCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // Le texte garde toute la largeur ; si la carte manque de hauteur
          // (petit écran, texte agrandi), l'ensemble se réduit au lieu de déborder.
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppColors.violetRoyal, shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Nouvel événement',
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créez une invitation en quelques minutes',
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grande carte d'accueil quand l'utilisateur n'a encore aucun événement.
class _FirstEventCard extends StatelessWidget {
  const _FirstEventCard({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          const Positioned.fill(child: _CardPattern()),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créez votre premier événement',
                        style: AppTypography.textTheme.displayMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: onCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.violetRoyal,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Commencer'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Image.asset(AppAssets.mascotCreateEvent, height: 130, fit: BoxFit.contain),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chiffres clés ───────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final unlimited = data.hasUnlimitedEvents;
    final max = data.maxEvents ?? 0;
    final progress = unlimited || max == 0 ? 1.0 : (data.quotaUsed / max).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: _RingPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unlimited ? '∞' : '${data.quotaUsed}/$max',
                      style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'quota',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatLine(value: data.invitesDispatched, label: 'invitations envoyées'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.noirDoux.withValues(alpha: 0.07)),
                ),
                _StatLine(value: data.guestsConfirmed, label: 'invités confirmés'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$value', style: AppTypography.textTheme.displayMedium?.copyWith(fontSize: 26)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.violetRoyal.withValues(alpha: 0.10),
    );
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          // Du violet vers l'or, en partant du haut de l'anneau.
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: 3 * math.pi / 2,
            colors: const [AppColors.violetRoyal, AppColors.violetRoyalAlt, AppColors.orAfricain],
            stops: [0, (progress * 0.55).clamp(0.01, 0.99), progress.clamp(0.02, 1.0)],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

String _formatFcfa(int amount) => '${NumberFormat.decimalPattern('fr').format(amount)} F';

void _openOffers(BuildContext context) => Navigator.of(context).pushNamed('/subscription');

/// Offre actuelle. Compte gratuit : grande carte violette avec l'incitation à
/// passer à Essentiel. Compte payant : rappel discret de l'offre.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final planName = data.planName ?? 'Découverte';
    if (data.accountType == 'gratuit') {
      final price = data.essentielPriceFcfa;
      final max = data.maxEvents;
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(child: _CardPattern()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _CrownBadge(),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offre $planName',
                              style: AppTypography.textTheme.titleLarge?.copyWith(color: Colors.white),
                            ),
                            if (max != null)
                              Text(
                                '${data.quotaUsed} sur $max événements utilisés',
                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Événements illimités, plus d’invités et toutes les fonctionnalités avec Essentiel.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openOffers(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orAfricain,
                        foregroundColor: AppColors.noirDoux,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        textStyle: AppTypography.textTheme.titleSmall,
                      ),
                      child: Text(
                        price != null ? 'Passer à Essentiel · ${_formatFcfa(price)}' : 'Passer à Essentiel',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final subtitle = data.accountType == 'flex'
        ? 'Vous ne payez que les invités dont vous avez besoin'
        : 'Événements illimités';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openOffers(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const _CrownBadge(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Offre $planName', style: AppTypography.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Gérer',
                style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.violetRoyal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrownBadge extends StatelessWidget {
  const _CrownBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(color: AppColors.orAfricain, shape: BoxShape.circle),
      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.violetRoyal, size: 24),
    );
  }
}

/// Packs d'invités à l'unité, prix en étiquette dorée.
class _PacksSection extends StatelessWidget {
  const _PacksSection({required this.packs, required this.horizontalPadding});

  final List<HomeFlexPack> packs;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: const _SectionTitle(title: 'Besoin de plus d’invités ?'),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            'Ajoutez un pack à n’importe quel événement, sans abonnement.',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              for (final pack in packs) ...[
                _PackCard(pack: pack),
                if (pack != packs.last) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack});

  final HomeFlexPack pack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openOffers(context),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.groups_rounded, color: AppColors.violetRoyal),
              const SizedBox(height: AppSpacing.sm),
              Text(
                NumberFormat.decimalPattern('fr').format(pack.guestLimit),
                style: AppTypography.textTheme.displayMedium,
              ),
              Text(
                'invités',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.noirDoux.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orAfricain.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(_formatFcfa(pack.priceFcfa), style: AppTypography.textTheme.labelMedium),
              ),
            ],
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

enum _EventStatus {
  upcoming('À venir', AppColors.info),
  running('En cours', AppColors.warning),
  done('Terminé', AppColors.success);

  final String label;
  final Color color;

  const _EventStatus(this.label, this.color);

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
}
