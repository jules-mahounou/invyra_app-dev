import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/event_service.dart';
import '../create_event_utils.dart';

/// Étape 2 — Choix du template (liste verticale + filtres, comme l’ancien écran).
class Step2Template extends StatefulWidget {
  final String eventId;
  final String eventType;
  final String accountType;
  final void Function(String templateId) onStepCompleted;
  final VoidCallback onBack;

  const Step2Template({
    required this.eventId,
    required this.eventType,
    required this.accountType,
    required this.onStepCompleted,
    required this.onBack,
    super.key,
  });

  @override
  State<Step2Template> createState() => _Step2TemplateState();
}

class _Step2TemplateState extends State<Step2Template> {
  final _eventService = EventService();

  List<Map<String, dynamic>> _templates = [];
  String? _selectedTemplateId;
  String _templateFilter = 'tous';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.accountType == 'gratuit') {
      _templateFilter = 'gratuits';
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final templates = await _eventService.getTemplatesByEventType(
        widget.eventType,
      );
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTemplates {
    return _templates.where((template) {
      final tier = template['tier'] as String? ?? 'gratuit';
      if (_templateFilter == 'gratuits' && tier != 'gratuit') return false;
      if (_templateFilter == 'premium' && tier == 'gratuit') return false;
      return true;
    }).toList();
  }

  Future<void> _showPremiumDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Premium'),
        content: const Text(
          'Ce modèle est réservé aux offres Essentiel et Flex. Passez à une offre supérieure pour l’utiliser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('Voir les offres'),
          ),
        ],
      ),
    );
  }

  Future<void> _onTemplateTap(Map<String, dynamic> template) async {
    final tier = template['tier'] as String? ?? 'gratuit';
    if (!canAccessTemplateTier(widget.accountType, tier)) {
      await _showPremiumDialog();
      return;
    }

    final templateId = template['id'] as String;
    setState(() {
      _selectedTemplateId = templateId;
      _isSaving = true;
    });

    try {
      await _eventService.updateEventTemplate(
        eventId: widget.eventId,
        templateId: templateId,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedTemplateId = null;
        _isSaving = false;
      });
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _handleContinue() async {
    if (_selectedTemplateId == null) {
      showCreateEventErrorSnackBar(context, 'Veuillez choisir un template');
      return;
    }
    widget.onStepCompleted(_selectedTemplateId!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.violetRoyal),
        ),
      );
    }

    if (_loadError != null) {
      return Column(
        children: [
          Text(_loadError!, style: AppTypography.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: _loadTemplates,
            child: const Text('Réessayer'),
          ),
        ],
      );
    }

    final templates = _filteredTemplates;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.cardDecoration.copyWith(
            color: AppColors.blancCasse,
            border: Border.all(
              color: AppColors.violetRoyal.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez le style qui fera briller votre invitation.',
                style: AppTypography.textTheme.displaySmall?.copyWith(
                  color: AppColors.violetRoyal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _TemplateFilterChip(
                      label: 'Tous',
                      selected: _templateFilter == 'tous',
                      onTap: () => setState(() => _templateFilter = 'tous'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TemplateFilterChip(
                      label: 'Gratuits',
                      selected: _templateFilter == 'gratuits',
                      onTap: () => setState(() => _templateFilter = 'gratuits'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TemplateFilterChip(
                      label: 'Premium',
                      selected: _templateFilter == 'premium',
                      onTap: () => setState(() => _templateFilter = 'premium'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (templates.isEmpty)
                Text(
                  'Aucun template disponible pour ce filtre.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.70),
                  ),
                )
              else
                for (final template in templates) ...[
                  _TemplateCard(
                    template: template,
                    locked: !canAccessTemplateTier(
                      widget.accountType,
                      template['tier'] as String? ?? 'gratuit',
                    ),
                    selected: _selectedTemplateId == template['id'],
                    onTap: () => _onTemplateTap(template),
                  ),
                  if (template != templates.last)
                    const SizedBox(height: AppSpacing.md),
                ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: AppSpacing.lg,
                      ),
                      label: const Text('Retour'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.violetRoyal,
                        side: BorderSide(
                          color: AppColors.violetRoyal.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violetRoyal,
                        foregroundColor: AppColors.blancCasse,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Suivant'),
                          SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: AppSpacing.lg,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.blancCasse.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.violetRoyal),
              ),
            ),
          ),
      ],
    );
  }
}

class _TemplateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: const StadiumBorder(),
      selectedColor: AppColors.violetRoyal.withValues(alpha: 0.12),
      backgroundColor: AppColors.beigeCremeAlt,
      labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
        color: selected ? AppColors.violetRoyal : AppColors.noirDoux,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.violetRoyal
            : AppColors.noirDoux.withValues(alpha: 0.10),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tier = template['tier'] as String? ?? 'gratuit';
    final isFree = tier == 'gratuit';
    final badgeColor = isFree ? AppColors.success : AppColors.violetRoyal;
    final name = template['name'] as String? ?? 'Template';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppDecorations.cardDecoration.copyWith(
              color: AppColors.beigeCremeAlt,
              border: Border.all(
                color: selected
                    ? AppColors.violetRoyal
                    : badgeColor.withValues(alpha: 0.16),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: _TemplatePreviewImage(
                    template: template,
                    fallbackName: name,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.noirDoux,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (template['description'] != null &&
                          (template['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          template['description'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.noirDoux.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TemplateTierBadge(tier: tier),
                          if (template['is_popular'] == true)
                            const _TemplateTierBadge(tier: 'populaire'),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.violetRoyal,
                              size: AppSpacing.lg,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.noirDoux.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blancCasse,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          color: AppColors.violetRoyal,
                          size: AppSpacing.md,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Voir les offres',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.violetRoyal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplatePreviewImage extends StatelessWidget {
  final Map<String, dynamic> template;
  final String fallbackName;

  const _TemplatePreviewImage({
    required this.template,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final previewUrl = template['preview_url'] as String?;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, _) => _assetOrPlaceholder(),
        errorWidget: (_, _, _) => _assetOrPlaceholder(),
      );
    }
    return _assetOrPlaceholder();
  }

  Widget _assetOrPlaceholder() {
    final assetPath = template['asset_path'] as String?;
    if (assetPath != null && assetPath.startsWith('assets/')) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.beigeCremeBase,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        fallbackName,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.textTheme.titleMedium?.copyWith(
          color: AppColors.violetRoyal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TemplateTierBadge extends StatelessWidget {
  final String tier;

  const _TemplateTierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    if (tier == 'populaire') {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.orAfricain.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          'Populaire',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.orAfricain,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isFree = tier == 'gratuit';
    final color = isFree ? AppColors.success : AppColors.violetRoyal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFree
                ? Icons.check_circle_rounded
                : Icons.workspace_premium_rounded,
            color: color,
            size: AppSpacing.md,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isFree ? 'Gratuit' : 'Premium',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
