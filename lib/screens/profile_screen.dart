import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_gate.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'notifications_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String accountType;

  const ProfileScreen({
    super.key,
    this.accountType = 'gratuit',
  });

  @override
  Widget build(BuildContext context) {
    final plan = _ProfilePlan.from(accountType);

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
                _ProfileHeaderCard(plan: plan),
                const SizedBox(height: AppSpacing.lg),
                _SubscriptionSummary(plan: plan),
                const SizedBox(height: AppSpacing.lg),
                const _SettingsMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final _ProfilePlan plan;

  const _ProfileHeaderCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.violetRoyal.withValues(alpha: 0.18),
            AppColors.violetRoyalAlt.withValues(alpha: 0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.cardDecoration.copyWith(
          color: AppColors.blancCasse,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            _ProfileAvatar(plan: plan),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Amani Kouassi',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.displayMedium?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AccountBadge(label: plan.memberLabel),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Créatrice d’expériences élégantes pour des événements qui rassemblent.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.noirDoux.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violetRoyal,
                      foregroundColor: AppColors.blancCasse,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    child: const Text('Modifier le profil'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_rounded),
                  color: AppColors.violetRoyal,
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppColors.violetRoyal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final _ProfilePlan plan;

  const _ProfileAvatar({required this.plan});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.beigeCremeBase,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.16), width: 2),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.violetRoyal.withValues(alpha: 0.72),
              size: AppSpacing.xxl,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              decoration: BoxDecoration(
                color: AppColors.orAfricain,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blancCasse, width: 3),
              ),
              child: Icon(plan.icon, color: AppColors.blancCasse, size: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final String label;

  const _AccountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.violetRoyal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: AppColors.violetRoyal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  final _ProfilePlan plan;

  const _SubscriptionSummary({required this.plan});

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Mon abonnement',
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.orAfricain.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.orAfricain, size: AppSpacing.lg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Plan ${plan.planLabel}',
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (plan.key == 'flex')
            const _PremiumMemberBadge()
          else ...[
            if (plan.key == 'gratuit') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: const LinearProgressIndicator(
                  value: 2 / 3,
                  minHeight: AppSpacing.sm,
                  backgroundColor: AppColors.beigeCremeBase,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.violetRoyal),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '2 / 3 événements utilisés',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.violetRoyal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _GradientButton(
              label: '⚡ Voir les offres',
              onPressed: () => Navigator.of(context).pushNamed('/subscription'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumMemberBadge extends StatelessWidget {
  const _PremiumMemberBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.orAfricain.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.28)),
      ),
      child: Text(
        '✨ Membre Premium',
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: AppColors.orAfricain,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SettingsItemData(
        icon: Icons.notifications_none_rounded,
        label: 'Notifications',
        color: AppColors.warning,
        routeKey: 'notifications',
      ),
      const _SettingsItemData(
        icon: Icons.lock_outline_rounded,
        label: 'Sécurité & Mot de passe',
        color: AppColors.violetRoyal,
      ),
      const _SettingsItemData(
        icon: Icons.language_rounded,
        label: 'Langue',
        color: AppColors.info,
      ),
      const _SettingsItemData(
        icon: Icons.help_outline_rounded,
        label: 'Aide & Support',
        color: AppColors.success,
      ),
      const _SettingsItemData(
        icon: Icons.logout_rounded,
        label: 'Se déconnecter',
        color: AppColors.error,
        destructive: true,
        showChevron: false,
      ),
    ];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (final item in items) ...[
            _SettingsTile(data: item),
            if (item != items.last)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.noirDoux.withValues(alpha: 0.06),
                indent: AppSpacing.lg + AppSpacing.xl,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItemData data;

  const _SettingsTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.color, size: AppSpacing.md),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _displayLabel,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: data.destructive ? AppColors.error : AppColors.noirDoux,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (data.showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.noirDoux.withValues(alpha: 0.38),
                size: AppSpacing.lg,
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (data.icon == Icons.logout_rounded) {
      _signOut(context);
      return;
    }

    if (data.routeKey == 'notifications') {
      pushProtectedRoute(context, const NotificationsScreen());
      return;
    }

    if (data.icon == Icons.lock_outline_rounded) {
      pushProtectedRoute(context, const SecurityScreen());
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  String get _displayLabel {
    if (data.icon == Icons.lock_outline_rounded) {
      return 'Sécurité & Mot de passe';
    }
    return data.label;
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
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
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blancCasse,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _ProfilePlan {
  final String key;
  final String memberLabel;
  final String planLabel;
  final IconData icon;

  const _ProfilePlan({
    required this.key,
    required this.memberLabel,
    required this.planLabel,
    required this.icon,
  });

  factory _ProfilePlan.from(String value) {
    switch (value.toLowerCase()) {
      case 'flex':
        return const _ProfilePlan(
          key: 'flex',
          memberLabel: 'Membre Premium',
          planLabel: 'Flex',
          icon: Icons.star_rounded,
        );
      case 'essentiel':
        return const _ProfilePlan(
          key: 'essentiel',
          memberLabel: 'Membre Standard',
          planLabel: 'Essentiel',
          icon: Icons.star_rounded,
        );
      default:
        return const _ProfilePlan(
          key: 'gratuit',
          memberLabel: 'Membre Gratuit',
          planLabel: 'Découverte',
          icon: Icons.star_rounded,
        );
    }
  }
}

class _SettingsItemData {
  final IconData icon;
  final String label;
  final Color color;
  final bool destructive;
  final bool showChevron;
  final String? routeKey;

  const _SettingsItemData({
    required this.icon,
    required this.label,
    required this.color,
    this.destructive = false,
    this.showChevron = true,
    this.routeKey,
  });
}
