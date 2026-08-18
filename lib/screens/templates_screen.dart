import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'web_preview_screen.dart';

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
  late Future<List<Map<String, dynamic>>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    // Récupération dynamique et automatique de tes modèles depuis Supabase
    _templatesFuture = Supabase.instance.client
        .from('event_templates')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openWebPreview(Map<String, dynamic> template) {
    final webKey = template['web_template_key'] as String?;
    if (webKey != null && webKey.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => WebPreviewScreen(
          webTemplateKey: webKey,
          templateName: template['name'] ?? 'Invitation',
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blancCasse,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.violetRoyal),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement des modèles',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.noirDoux,
                ),
              ),
            );
          }

          final allTemplates = snapshot.data ?? [];
          final filteredTemplates = _filteredTemplates(allTemplates);
          final popularTemplates = filteredTemplates.where((template) => template['is_popular'] == true).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- En-tete fixe
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mod\u00e8les d\u2019invitation',
                          style: AppTypography.textTheme.displayMedium?.copyWith(
                            color: AppColors.noirDoux,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'D\u00e9couvrez notre galerie exclusive',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.noirDoux.withValues(alpha: 0.62),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SearchField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _TemplateFilters(
                          selectedFilter: _selectedFilter,
                          onChanged: (value) => setState(() => _selectedFilter = value),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                  // -- Liste scrollable
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
                      ),
                      children: [
                        if (popularTemplates.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          const _SectionTitle(title: '\u2b50 Populaires'),
                          const SizedBox(height: AppSpacing.md),
                          for (final template in popularTemplates) ...[
                            _TemplateLibraryCard(
                              template: template,
                              locked: false,
                              onPreviewTap: () => _openWebPreview(template),
                            ),
                            if (template != popularTemplates.last)
                              const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionTitle(title: 'Tous les mod\u00e8les'),
                        const SizedBox(height: AppSpacing.md),
                        if (filteredTemplates.isEmpty)
                          Text(
                            'Aucun mod\u00e8le ne correspond \u00e0 votre recherche.',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.noirDoux.withValues(alpha: 0.70),
                            ),
                          )
                        else
                          for (final template in filteredTemplates) ...[
                            _TemplateLibraryCard(
                              template: template,
                              locked: false,
                              onPreviewTap: () => _openWebPreview(template),
                            ),
                            if (template != filteredTemplates.last)
                              const SizedBox(height: AppSpacing.md),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filteredTemplates(List<Map<String, dynamic>> templates) {
    final query = _searchController.text.trim().toLowerCase();
    return templates.where((template) {
      final type = template['event_type'] as String? ?? '';
      final name = (template['name'] as String? ?? '').toLowerCase();
      final description = (template['description'] as String? ?? '').toLowerCase();
      
      final rawTags = template['tags'];
      final String tagsString = rawTags is List ? rawTags.join(' ').toLowerCase() : '';

      final matchesFilter = _selectedFilter == 'tous' || type == _selectedFilter;
      final matchesSearch = query.isEmpty || 
                            name.contains(query) || 
                            description.contains(query) || 
                            tagsString.contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

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
      ),
    );
  }
}

class _TemplateFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _TemplateFilters({required this.selectedFilter, required this.onChanged});

  static const filters = [
    _EventFilterData(label: 'Tous', value: 'tous'),
    _EventFilterData(label: 'Mariage', value: 'mariage'),
    _EventFilterData(label: 'Anniversaire', value: 'anniversaire'),
    _EventFilterData(label: 'Baptême', value: 'bapteme'),
    _EventFilterData(label: 'Soirée VIP', value: 'soiree_vip'),
    _EventFilterData(label: 'Autre', value: 'autre'),
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

  const _FilterPill({required this.label, required this.selected, required this.onTap});

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
  final VoidCallback onPreviewTap;

  const _TemplateLibraryCard({
    required this.template,
    required this.locked,
    required this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = template['tier'] == 'premium';
    final isPopular = template['is_popular'] == true;
    
    // Récupération dynamique de la colonne d'image présente dans ta base Supabase
    // Si la colonne s'appelle 'image_url' au lieu de 'thumbnail_url', change simplement le mot ici.
    final String? imageUrl = template['thumbnail_url'] as String? ?? template['image_url'] as String?;

    final rawTags = template['tags'];
    final List<String> tags = rawTags is List 
        ? List<String>.from(rawTags.map((e) => e.toString()))
        : [];

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
                  // Rendu instantané et mis en cache globale (Zéro WebView locale, performance maximale)
                  imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          placeholder: (context, url) => Container(
                            color: AppColors.beigeCremeBase,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.violetRoyal, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const _DefaultCardBackground(),
                        )
                      : const _DefaultCardBackground(),
                      
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.noirDoux.withValues(alpha: 0.35),
                          AppColors.noirDoux.withValues(alpha: 0.02),
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
                                (template['name'] as String? ?? ''),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.displaySmall?.copyWith(
                                  color: AppColors.blancCasse,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                (template['description'] as String? ?? ''),
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
                          onPressed: onPreviewTap,
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

class _DefaultCardBackground extends StatelessWidget {
  const _DefaultCardBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.beigeCremeBase, AppColors.blancCasse],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.insert_invitation_rounded,
          size: 48,
          color: AppColors.violetRoyal.withValues(alpha: 0.20),
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _ImageBadge({required this.label, required this.color, this.icon});

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

class _EventFilterData {
  final String label;
  final String value;
  const _EventFilterData({required this.label, required this.value});
}
