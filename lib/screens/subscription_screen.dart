import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class SubscriptionScreen extends StatefulWidget {
  final String accountType;

  const SubscriptionScreen({
    super.key,
    this.accountType = 'premium',
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedFlexOption = '300 invités — 3 500 F';

  @override
  Widget build(BuildContext context) {
    final currentPlan = _SubscriptionPlan.from(widget.accountType);

    return Material(
      color: AppColors.blancCasse,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.violetRoyal,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.blancCasse,
                      side: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.12)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Nos offres',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.displayLarge?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choisissez le plan qui vous correspond',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _DiscoveryPlanCard(current: currentPlan.key == 'gratuit'),
                const SizedBox(height: AppSpacing.md),
                const _EssentialPlanCard(),
                const SizedBox(height: AppSpacing.md),
                _FlexPlanCard(
                  selectedOption: _selectedFlexOption,
                  onOptionChanged: (value) => setState(() => _selectedFlexOption = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryPlanCard extends StatelessWidget {
  final bool current;

  const _DiscoveryPlanCard({required this.current});

  @override
  Widget build(BuildContext context) {
    return _SubscriptionCard(
      title: 'Découverte',
      price: 'Gratuit',
      points: const [
        '3 événements max',
        '50 invités max par événement',
        'Templates gratuits uniquement',
      ],
      badge: current ? 'Actuel' : null,
      badgeColor: AppColors.info,
      action: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: current ? null : () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.noirDoux.withValues(alpha: 0.08),
            foregroundColor: AppColors.noirDoux.withValues(alpha: 0.56),
          ),
          child: Text(current ? 'Plan actuel' : 'Choisir Découverte'),
        ),
      ),
    );
  }
}

class _EssentialPlanCard extends StatelessWidget {
  const _EssentialPlanCard();

  @override
  Widget build(BuildContext context) {
    return _SubscriptionCard(
      title: 'Essentiel',
      price: '5 000 F / mois',
      priceColor: AppColors.violetRoyal,
      highlighted: true,
      points: const [
        'Événements illimités',
        'Invités illimités',
        'Tous les templates premium',
        'Support prioritaire',
      ],
      badge: 'Populaire',
      badgeColor: AppColors.warning,
      action: const _GradientButton(label: 'Passer à Essentiel'),
    );
  }
}

class _FlexPlanCard extends StatelessWidget {
  final String selectedOption;
  final ValueChanged<String> onOptionChanged;

  const _FlexPlanCard({
    required this.selectedOption,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      const _FlexOption(label: '100 invités — 1 500 F'),
      const _FlexOption(label: '300 invités — 3 500 F', badge: 'Meilleure valeur'),
      const _FlexOption(label: '1 000 invités — 8 000 F'),
    ];

    return _SubscriptionCard(
      title: 'Flex',
      subtitle: 'Payez uniquement pour un événement',
      price: 'One-Shot',
      points: const [],
      badge: 'Sans abonnement',
      badgeColor: AppColors.info,
      middle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              _FlexChoiceChip(
                option: option,
                selected: selectedOption == option.label,
                onTap: () => onOptionChanged(option.label),
              ),
          ],
        ),
      ),
      action: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.violetRoyal,
            side: const BorderSide(color: AppColors.violetRoyal),
          ),
          child: const Text('Choisir Flex'),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String price;
  final Color? priceColor;
  final bool highlighted;
  final List<String> points;
  final String? badge;
  final Color badgeColor;
  final Widget? middle;
  final Widget action;

  const _SubscriptionCard({
    required this.title,
    required this.price,
    required this.points,
    required this.action,
    this.subtitle,
    this.priceColor,
    this.highlighted = false,
    this.badge,
    this.badgeColor = AppColors.violetRoyal,
    this.middle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(
          color: highlighted ? AppColors.violetRoyal : badgeColor.withValues(alpha: 0.14),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.violetRoyal.withValues(alpha: 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.textTheme.displaySmall?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) _PlanBadge(label: badge!, color: badgeColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            price,
            style: AppTypography.textTheme.displayMedium?.copyWith(
              color: priceColor ?? AppColors.noirDoux,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final point in points) ...[
              _PlanPoint(text: point),
              if (point != points.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
          ?middle,
          const SizedBox(height: AppSpacing.lg),
          action,
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PlanBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanPoint extends StatelessWidget {
  final String text;

  const _PlanPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: AppSpacing.md),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlexChoiceChip extends StatelessWidget {
  final _FlexOption option;
  final bool selected;
  final VoidCallback onTap;

  const _FlexChoiceChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.violetRoyal.withValues(alpha: 0.10) : AppColors.beigeCremeAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.violetRoyal : AppColors.noirDoux.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.violetRoyal : AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (option.badge != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _PlanBadge(label: option.badge!, color: AppColors.success),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;

  const _GradientButton({required this.label});

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
          onPressed: () {},
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

class _SubscriptionPlan {
  final String key;

  const _SubscriptionPlan({required this.key});

  factory _SubscriptionPlan.from(String value) {
    switch (value.toLowerCase()) {
      case 'premium':
        return const _SubscriptionPlan(key: 'premium');
      case 'standard':
        return const _SubscriptionPlan(key: 'standard');
      default:
        return const _SubscriptionPlan(key: 'gratuit');
    }
  }
}

class _FlexOption {
  final String label;
  final String? badge;

  const _FlexOption({
    required this.label,
    this.badge,
  });
}
