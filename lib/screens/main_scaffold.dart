import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
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
  final String accountType;
  final bool initialCreateEventOpen;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
    this.accountType = 'premium',
    this.initialCreateEventOpen = false,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late bool _createEventOpen;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _createEventOpen = widget.initialCreateEventOpen && _currentIndex == 1;
  }

  @override
  Widget build(BuildContext context) {
    final plan = _ShellAccountPlan.from(widget.accountType);

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
                  child: _PersistentHeader(plan: plan),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  const HomeTabContent(),
                  _createEventOpen
                      ? CreateEventTabContent(
                          accountType: widget.accountType,
                          onBack: _closeCreateEvent,
                        )
                      : EventsScreen(onCreate: _openCreateEvent),
                  TemplatesScreen(accountType: widget.accountType),
                  ProfileScreen(accountType: widget.accountType),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PersistentNavBar(
        currentIndex: _currentIndex,
        onChanged: _onNavChanged,
        onScanTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ScanScreen()),
        ),
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
  }

  void _onNavChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 1) {
        _createEventOpen = false;
      }
    });
  }
}

class _PersistentHeader extends StatelessWidget {
  final _ShellAccountPlan plan;

  const _PersistentHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(AppAssets.logoFull, height: AppSpacing.xxl, fit: BoxFit.contain),
        const Spacer(),
        _AccountStatusPill(plan: plan),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.violetRoyal,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.blancCasse,
            side: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.12)),
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
    return Transform.translate(
      offset: const Offset(0, -AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: AppSpacing.xxl + AppSpacing.sm,
              height: AppSpacing.xxl + AppSpacing.sm,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrincipal,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppNavIcons.scanner, color: AppColors.blancCasse, size: AppSpacing.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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
    switch (value.toLowerCase()) {
      case 'premium':
        return const _ShellAccountPlan(
          label: 'Premium',
          color: AppColors.orAfricain,
          icon: Icons.workspace_premium_rounded,
        );
      case 'standard':
        return const _ShellAccountPlan(
          label: 'Standard',
          color: AppColors.violetRoyalAlt,
          icon: Icons.verified_user_rounded,
        );
      default:
        return const _ShellAccountPlan(
          label: 'Basique',
          color: AppColors.noirDoux,
          icon: Icons.person_outline_rounded,
        );
    }
  }
}
