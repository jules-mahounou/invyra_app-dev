import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/account_type_ui.dart';
import '../core/auth/auth_gate.dart';
import '../core/constants/app_assets.dart';
import '../core/services/notifications_service.dart';
import '../core/services/user_profile_service.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_nav_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'create_event_screen.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'templates_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final bool initialCreateEventOpen;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
    this.initialCreateEventOpen = false,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _profileService = UserProfileService();
  final _notificationsService = NotificationsService();
  final _homeKey = GlobalKey<HomeTabContentState>();
  final _eventsKey = GlobalKey<EventsScreenState>();

  late int _currentIndex;
  late bool _createEventOpen;
  String _accountType = 'gratuit';
  int _unreadCount = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _createEventOpen = widget.initialCreateEventOpen && _currentIndex == 1;
    _loadProfile();
    _loadUnreadCount();
    _subscribeToNotifications();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _loadUnreadCount();
      _subscribeToNotifications();
    });
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationsService.watchUserNotifications().listen(
      (data) {
        final unread = data.where((notification) => notification['is_read'] == false).length;
        if (mounted) {
          setState(() => _unreadCount = unread);
        }
      },
      onError: (_) => _loadUnreadCount(),
    );
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationsService.fetchUnreadCount();
      if (!mounted) {
        return;
      }
      setState(() => _unreadCount = count);
    } catch (_) {
      // Le badge reste masqué en cas d'échec silencieux.
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetch();
      if (!mounted) {
        return;
      }
      setState(() => _accountType = profile.accountType);
    } catch (_) {
      // Le badge reste sur « Basique » (gratuit) en cas d'échec silencieux.
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _ShellAccountPlan.from(_accountType);

    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                  child: _PersistentHeader(
                    plan: plan,
                    unreadCount: _unreadCount,
                    onNotificationsTap: () async {
                      await pushProtectedRoute(context, const NotificationsScreen());
                      if (mounted) {
                        await _loadUnreadCount();
                      }
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeTabContent(
                    key: _homeKey,
                    onSeeAllEvents: _openEventsList,
                  ),
                  _createEventOpen
                      ? CreateEventTabContent(
                          accountType: _accountType,
                          onBack: _closeCreateEvent,
                        )
                      : EventsScreen(
                          key: _eventsKey,
                          onCreate: _openCreateEvent,
                        ),
                  TemplatesScreen(accountType: _accountType),
                  ProfileScreen(accountType: _accountType),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PersistentNavBar(
        currentIndex: _currentIndex,
        onChanged: _onNavChanged,
        onScanTap: () => pushProtectedRoute(context, const ScanScreen()),
      ),
    );
  }

  void _openCreateEvent() {
    setState(() {
      _currentIndex = 1;
      _createEventOpen = true;
    });
  }

  void _closeCreateEvent() {
    setState(() => _createEventOpen = false);
    _refreshHomeAndEvents();
  }

  void _openEventsList() {
    setState(() {
      _currentIndex = 1;
      _createEventOpen = false;
    });
    _eventsKey.currentState?.refresh();
  }

  void _refreshHomeAndEvents() {
    _homeKey.currentState?.refresh();
    _eventsKey.currentState?.refresh();
  }

  void _onNavChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 1) {
        _createEventOpen = false;
      }
    });
    if (index == 0) {
      _homeKey.currentState?.refresh();
    } else if (index == 1 && !_createEventOpen) {
      _eventsKey.currentState?.refresh();
    }
  }
}

class _PersistentHeader extends StatelessWidget {
  final _ShellAccountPlan plan;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  const _PersistentHeader({
    required this.plan,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(AppAssets.logoFull, height: AppSpacing.xxl, fit: BoxFit.contain),
        const Spacer(),
        _AccountStatusPill(plan: plan),
        const SizedBox(width: AppSpacing.sm),
        _NotificationIconButton(unreadCount: unreadCount, onTap: onNotificationsTap),
      ],
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationIconButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeLabel = unreadCount > 9 ? '9+' : '$unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.violetRoyal,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.blancCasse,
            side: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.12)),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: AppSpacing.xs,
            top: AppSpacing.xs,
            child: Container(
              constraints: const BoxConstraints(minWidth: AppSpacing.lg, minHeight: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badgeLabel,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.blancCasse,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountStatusPill extends StatelessWidget {
  final _ShellAccountPlan plan;

  const _AccountStatusPill({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.beigeCremeBase,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: plan.color),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(plan.icon, color: AppColors.noirDoux, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.sm),
          Text(
            plan.label,
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersistentNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onScanTap;

  const _PersistentNavBar({
    required this.currentIndex,
    required this.onChanged,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.blancCasse,
          boxShadow: [
            BoxShadow(
              color: AppColors.noirDoux.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: AppNavIcons.home,
                label: 'Accueil',
                selected: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: AppNavIcons.events,
                label: 'Événements',
                selected: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
            ),
            Expanded(child: _ScannerNavItem(onTap: onScanTap)),
            Expanded(
              child: _NavItem(
                icon: AppNavIcons.templates,
                label: 'Templates',
                selected: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: AppNavIcons.profile,
                label: 'Profil',
                selected: currentIndex == 3,
                onTap: () => onChanged(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.violetRoyal : AppColors.noirDoux.withValues(alpha: 0.72);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSpacing.lg),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _ScannerNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Scanner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: AppSpacing.xxl + AppSpacing.sm,
                height: AppSpacing.xxl + AppSpacing.sm,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrincipal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violetRoyal.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  AppNavIcons.scanner,
                  color: AppColors.blancCasse,
                  size: AppSpacing.lg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ShellAccountPlan {
  final String label;
  final Color color;
  final IconData icon;

  const _ShellAccountPlan({
    required this.label,
    required this.color,
    required this.icon,
  });

  factory _ShellAccountPlan.from(String value) {
    return _ShellAccountPlan(
      label: AccountTypeUi.badgeLabel(value),
      color: AccountTypeUi.badgeColor(value),
      icon: AccountTypeUi.badgeIcon(value),
    );
  }
}
