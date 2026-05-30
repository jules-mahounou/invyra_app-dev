import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

const List<Map<String, dynamic>> mockTemplates = [
  {
    'id': '1',
    'name': 'Asante Gold Wedding',
    'description': 'Élégance africaine avec motifs Kente et typographie sur mesure.',
    'type': 'mariage',
    'tier': 'premium',
    'popular': false,
    'tags': ['Animé'],
    'asset': 'assets/images/templates/template_mariage.png',
  },
  {
    'id': '2',
    'name': 'Midnight Accra VIP',
    'description': 'Luxe sombre pour célébrations urbaines exclusives.',
    'type': 'soiree_vip',
    'tier': 'premium',
    'popular': true,
    'tags': ['Glassmorphisme', 'Animé'],
    'asset': 'assets/images/templates/template_soiree_vip.png',
  },
  {
    'id': '3',
    'name': 'Sun-Drenched Soirée',
    'description': 'Couleurs vives et motifs rythmiques.',
    'type': 'anniversaire',
    'tier': 'gratuit',
    'popular': true,
    'tags': ['Populaire'],
    'asset': 'assets/images/templates/template_anniversaire.png',
  },
  {
    'id': '4',
    'name': 'Sacred Lilies Suite',
    'description': 'Lavande douce et accents dorés.',
    'type': 'mariage',
    'tier': 'gratuit',
    'popular': false,
    'tags': [],
    'asset': 'assets/images/templates/template_mariage.png',
  },
  {
    'id': '5',
    'name': 'Douceur Pastel',
    'description': 'Tendresse et pureté pour un baptême inoubliable.',
    'type': 'bapteme',
    'tier': 'gratuit',
    'popular': false,
    'tags': [],
    'asset': 'assets/images/templates/template_bapteme.png',
  },
];

class TemplatesScreen extends StatefulWidget {
  final String accountType;

  const TemplatesScreen({
    super.key,
    this.accountType = 'premium',
  });

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'tous';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _filteredTemplates;
    final popularTemplates = filteredTemplates.where((template) => template['popular'] == true).toList();

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
                Text(
                  'Modèles d’invitation',
                  style: AppTypography.textTheme.displayMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Découvrez notre galerie exclusive',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SearchField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                _TemplateFilters(
                  selectedFilter: _selectedFilter,
                  onChanged: (value) => setState(() => _selectedFilter = value),
                ),
                if (popularTemplates.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle(title: '⭐ Populaires'),
                  const SizedBox(height: AppSpacing.md),
                  for (final template in popularTemplates) ...[
                    Builder(
                      builder: (context) {
                        // TODO: décommenter lors de l'intégration backend
                        // final bool isLocked = widget.accountType == 'gratuit' && template['tier'] == 'premium';
                        const bool isLocked = false; // retiré pour les tests frontend
                        return _TemplateLibraryCard(template: template, locked: isLocked);
                      },
                    ),
                    if (template != popularTemplates.last) const SizedBox(height: AppSpacing.md),
                  ],
                ],
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(title: 'Tous les modèles'),
                const SizedBox(height: AppSpacing.md),
                if (filteredTemplates.isEmpty)
                  Text(
                    'Aucun modèle ne correspond à votre recherche.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.70),
                    ),
                  )
                else
                  for (final template in filteredTemplates) ...[
                    Builder(
                      builder: (context) {
                        // TODO: décommenter lors de l'intégration backend
                        // final bool isLocked = widget.accountType == 'gratuit' && template['tier'] == 'premium';
                        const bool isLocked = false; // retiré pour les tests frontend
                        return _TemplateLibraryCard(template: template, locked: isLocked);
                      },
                    ),
                    if (template != filteredTemplates.last) const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredTemplates {
    final query = _searchController.text.trim().toLowerCase();
    return mockTemplates.where((template) {
      final type = template['type'] as String;
      final name = (template['name'] as String).toLowerCase();
      final description = (template['description'] as String).toLowerCase();
      final matchesFilter = _selectedFilter == 'tous' || type == _selectedFilter;
      final matchesSearch = query.isEmpty || name.contains(query) || description.contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.violetRoyal),
        hintText: 'Rechercher un modèle',
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.noirDoux.withValues(alpha: 0.42),
        ),
        fillColor: AppColors.blancCasse,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide(color: AppColors.noirDoux.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
    );
  }
}

class _TemplateFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _TemplateFilters({
    required this.selectedFilter,
    required this.onChanged,
  });

  static const filters = [
    _TemplateFilterData(label: 'Tous', value: 'tous'),
    _TemplateFilterData(label: 'Mariage', value: 'mariage'),
    _TemplateFilterData(label: 'Anniversaire', value: 'anniversaire'),
    _TemplateFilterData(label: 'Baptême', value: 'bapteme'),
    _TemplateFilterData(label: 'Soirée VIP', value: 'soiree_vip'),
    _TemplateFilterData(label: 'Autre', value: 'autre'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in filters) ...[
            _FilterPill(
              label: filter.label,
              selected: selectedFilter == filter.value,
              onTap: () => onChanged(filter.value),
            ),
            if (filter != filters.last) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.violetRoyal : AppColors.noirDoux.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: selected ? AppColors.blancCasse : AppColors.noirDoux,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.textTheme.displaySmall?.copyWith(
        color: AppColors.noirDoux,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TemplateLibraryCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final bool locked;

  const _TemplateLibraryCard({
    required this.template,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = template['tier'] == 'premium';
    final isPopular = template['popular'] == true;
    final tags = List<String>.from(template['tags'] as List);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blancCasse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    template['asset'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.beigeCremeBase,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.violetRoyal.withValues(alpha: 0.42),
                          size: AppSpacing.xl,
                        ),
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.noirDoux.withValues(alpha: 0.72),
                          AppColors.noirDoux.withValues(alpha: 0.08),
                          AppColors.noirDoux.withValues(alpha: 0.78),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (isPopular) const _ImageBadge(label: 'POPULAIRE', color: AppColors.warning),
                        if (isPremium)
                          const _ImageBadge(
                            label: 'PREMIUM',
                            color: AppColors.violetRoyal,
                            icon: Icons.star_rounded,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                template['name'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.displaySmall?.copyWith(
                                  color: AppColors.blancCasse,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                template['description'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.bodySmall?.copyWith(
                                  color: AppColors.blancCasse.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.blancCasse.withValues(alpha: 0.86),
                            foregroundColor: AppColors.violetRoyal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          ),
                          child: const Text('Aperçu'),
                        ),
                      ],
                    ),
                  ),
                  if (locked)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.noirDoux.withValues(alpha: 0.58),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, color: AppColors.blancCasse, size: AppSpacing.xl),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Débloquer avec Premium',
                                style: AppTypography.textTheme.labelLarge?.copyWith(
                                  color: AppColors.blancCasse,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed('/subscription'),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.blancCasse,
                                  foregroundColor: AppColors.violetRoyal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                ),
                                child: const Text('Voir les offres'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (tags.isEmpty)
                  const _TagChip(label: 'Classique')
                else
                  for (final tag in tags) _TagChip(label: tag),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _ImageBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.blancCasse, size: AppSpacing.md),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.blancCasse,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.noirDoux.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.noirDoux.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TemplateFilterData {
  final String label;
  final String value;

  const _TemplateFilterData({
    required this.label,
    required this.value,
  });
}
