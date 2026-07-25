import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/models/flex_pack.dart';
import '../core/models/subscription_plan.dart';
import '../core/services/subscription_catalog_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_shimmer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _service = SubscriptionCatalogService();

  SubscriptionCatalog? _catalog;
  String? _selectedFlexPackId;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _processingPlanCode;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catalog = await _service.fetch();
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _isLoading = false;
        _selectedFlexPackId ??= catalog.flexPacks.isNotEmpty ? catalog.flexPacks.first.id : null;
        if (_selectedFlexPackId != null &&
            !catalog.flexPacks.any((pack) => pack.id == _selectedFlexPackId)) {
          _selectedFlexPackId = catalog.flexPacks.first.id;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les offres';
      });
    }
  }

  Future<void> _onSubscribe(String planCode) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingPlanCode = planCode;
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fonctionnalité de paiement bientôt disponible'),
        backgroundColor: AppColors.violetRoyal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );

    setState(() {
      _isProcessing = false;
      _processingPlanCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blancCasse,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: _isLoading
                ? const _SubscriptionLoadingView()
                : _errorMessage != null
                    ? _SubscriptionErrorView(message: _errorMessage!, onRetry: _loadCatalog)
                    : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final catalog = _catalog!;
    final flexPlan = catalog.plans.where((plan) => plan.code == 'flex').firstOrNull;
    final standardPlans = catalog.plans.where((plan) => plan.code != 'flex').toList();

    return ListView(
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
        for (final plan in standardPlans) ...[
          _PlanCard(
            plan: plan,
            isCurrent: catalog.currentPlanCode == plan.code,
            isProcessing: _isProcessing && _processingPlanCode == plan.code,
            onSubscribe: () => _onSubscribe(plan.code),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (flexPlan != null) ...[
          _FlexPlanCard(
            plan: flexPlan,
            flexPacks: catalog.flexPacks,
            selectedPackId: _selectedFlexPackId,
            isCurrent: catalog.currentPlanCode == flexPlan.code,
            isProcessing: _isProcessing && _processingPlanCode == flexPlan.code,
            onPackSelected: (packId) => setState(() => _selectedFlexPackId = packId),
            onSubscribe: () => _onSubscribe(flexPlan.code),
          ),
        ],
      ],
    );
  }
}

class _SubscriptionLoadingView extends StatelessWidget {
  const _SubscriptionLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        ShimmerBox(height: 48, width: 48),
        SizedBox(height: AppSpacing.lg),
        ShimmerBox(height: 36),
        SizedBox(height: AppSpacing.sm),
        ShimmerBox(height: 20),
        SizedBox(height: AppSpacing.xl),
        ShimmerBox(height: 260),
        SizedBox(height: AppSpacing.md),
        ShimmerBox(height: 280),
        SizedBox(height: AppSpacing.md),
        ShimmerBox(height: 300),
      ],
    );
  }
}

class _SubscriptionErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SubscriptionErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isProcessing;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isProcessing,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return _SubscriptionCard(
      title: plan.name,
      subtitle: plan.description,
      price: plan.priceLabel,
      priceColor: plan.code == 'essentiel' ? AppColors.violetRoyal : null,
      highlighted: plan.isPopular,
      points: plan.features,
      badge: isCurrent
          ? 'Actuel'
          : plan.isPopular
              ? 'Populaire'
              : null,
      badgeColor: isCurrent
          ? AppColors.info
          : plan.isPopular
              ? AppColors.warning
              : AppColors.violetRoyal,
      action: SizedBox(
        width: double.infinity,
        child: isCurrent
            ? ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.noirDoux.withValues(alpha: 0.08),
                  foregroundColor: AppColors.noirDoux.withValues(alpha: 0.56),
                ),
                child: const Text('Plan actuel'),
              )
            : plan.code == 'essentiel'
                ? _GradientButton(
                    label: isProcessing ? 'Traitement en cours...' : 'Passer à Essentiel',
                    onPressed: isProcessing ? null : onSubscribe,
                  )
                : ElevatedButton(
                    onPressed: isProcessing ? null : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.noirDoux.withValues(alpha: 0.08),
                      foregroundColor: AppColors.noirDoux,
                    ),
                    child: Text(
                      isProcessing ? 'Traitement en cours...' : 'Choisir ${plan.name}',
                    ),
                  ),
      ),
    );
  }
}

bool _isMiddleFlexPack(FlexPack pack, List<FlexPack> flexPacks) {
  if (flexPacks.isEmpty) {
    return false;
  }
  final sorted = [...flexPacks]..sort((a, b) => a.guestLimit.compareTo(b.guestLimit));
  return pack.id == sorted[sorted.length ~/ 2].id;
}

class _FlexPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final List<FlexPack> flexPacks;
  final String? selectedPackId;
  final bool isCurrent;
  final bool isProcessing;
  final ValueChanged<String> onPackSelected;
  final VoidCallback onSubscribe;

  const _FlexPlanCard({
    required this.plan,
    required this.flexPacks,
    required this.selectedPackId,
    required this.isCurrent,
    required this.isProcessing,
    required this.onPackSelected,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return _SubscriptionCard(
      title: plan.name,
      subtitle: plan.description,
      price: plan.priceLabel,
      points: plan.features,
      badge: isCurrent ? 'Actuel' : 'Sans abonnement',
      badgeColor: isCurrent ? AppColors.info : AppColors.info,
      middle: flexPacks.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final pack in flexPacks)
                    _FlexChoiceChip(
                      pack: pack,
                      selected: selectedPackId == pack.id,
                      showBestValueBadge: _isMiddleFlexPack(pack, flexPacks),
                      onTap: () => onPackSelected(pack.id),
                    ),
                ],
              ),
            ),
      action: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isCurrent || isProcessing ? null : onSubscribe,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.violetRoyal,
            side: const BorderSide(color: AppColors.violetRoyal),
          ),
          child: Text(
            isCurrent
                ? 'Plan actuel'
                : isProcessing
                    ? 'Traitement en cours...'
                    : 'Choisir Flex',
          ),
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

  const _PlanBadge({required this.label, required this.color});

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
  final FlexPack pack;
  final bool selected;
  final bool showBestValueBadge;
  final VoidCallback onTap;

  const _FlexChoiceChip({
    required this.pack,
    required this.selected,
    required this.showBestValueBadge,
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
              pack.label,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.violetRoyal : AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showBestValueBadge) ...[
              const SizedBox(height: AppSpacing.xs),
              const _PlanBadge(label: 'Meilleure valeur', color: AppColors.success),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GradientButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
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
