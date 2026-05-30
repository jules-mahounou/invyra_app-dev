import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'event_detail_screen.dart';

const List<Map<String, dynamic>> mockEvents = [
  {
    'id': '1',
    'name': 'Mariage Kouassi & Amani',
    'type': 'mariage',
    'date': '12 Juillet 2025',
    'lieu': 'Abidjan, Côte d’Ivoire',
    'statut': 'a_venir',
    'invites': 120,
  },
  {
    'id': '2',
    'name': 'Anniversaire de Kofi',
    'type': 'anniversaire',
    'date': '03 Juin 2025',
    'lieu': 'Cotonou, Bénin',
    'statut': 'en_cours',
    'invites': 45,
  },
  {
    'id': '3',
    'name': 'Baptême Little Grace',
    'type': 'bapteme',
    'date': '20 Avril 2025',
    'lieu': 'Lomé, Togo',
    'statut': 'termine',
    'invites': 30,
  },
];

class EventsScreen extends StatefulWidget {
  final VoidCallback onCreate;

  const EventsScreen({
    super.key,
    required this.onCreate,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = 'tous';

  @override
  Widget build(BuildContext context) {
    final events = mockEvents.where((event) {
      return _selectedFilter == 'tous' || event['statut'] == _selectedFilter;
    }).toList();

    return Material(
      color: AppColors.blancCasse,
      child: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl + AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes événements',
                      style: AppTypography.textTheme.displayMedium?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _EventFilters(
                      selectedFilter: _selectedFilter,
                      onChanged: (value) => setState(() => _selectedFilter = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (events.isEmpty)
                      const _EmptyEvents()
                    else
                      for (final event in events) ...[
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: event),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: _EventCard(event: event),
                        ),
                        if (event != events.last) const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: FloatingActionButton.extended(
              onPressed: widget.onCreate,
              backgroundColor: AppColors.violetRoyal,
              foregroundColor: AppColors.blancCasse,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _EventFilters({
    required this.selectedFilter,
    required this.onChanged,
  });

  static const filters = [
    _EventFilterData(label: 'Tous', value: 'tous'),
    _EventFilterData(label: 'À venir', value: 'a_venir'),
    _EventFilterData(label: 'En cours', value: 'en_cours'),
    _EventFilterData(label: 'Terminé', value: 'termine'),
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

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final status = _EventStatusData.from(event['statut'] as String);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: status.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xxl + AppSpacing.lg,
            height: AppSpacing.xxl + AppSpacing.lg,
            decoration: BoxDecoration(
              gradient: _eventGradient(event['type'] as String),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.event_rounded, color: AppColors.blancCasse, size: AppSpacing.xl),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event['name'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          color: AppColors.noirDoux,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaLine(icon: Icons.calendar_today_outlined, text: event['date'] as String),
                const SizedBox(height: AppSpacing.xs),
                _MetaLine(icon: Icons.place_outlined, text: event['lieu'] as String),
                const SizedBox(height: AppSpacing.xs),
                _MetaLine(icon: Icons.people_alt_outlined, text: '${event['invites']} invités'),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.violetRoyal, size: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.noirDoux.withValues(alpha: 0.58), size: AppSpacing.md),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.70),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _EventStatusData status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.beigeCremeAlt,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Image.asset(
            AppAssets.mascotDefault,
            height: AppSpacing.xxl + AppSpacing.xl,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aucun événement pour l’instant',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventStatusData {
  final String label;
  final Color color;

  const _EventStatusData({
    required this.label,
    required this.color,
  });

  factory _EventStatusData.from(String value) {
    switch (value) {
      case 'en_cours':
        return const _EventStatusData(label: 'En cours', color: AppColors.warning);
      case 'termine':
        return const _EventStatusData(label: 'Terminé', color: AppColors.success);
      default:
        return const _EventStatusData(label: 'À venir', color: AppColors.info);
    }
  }
}

class _EventFilterData {
  final String label;
  final String value;

  const _EventFilterData({
    required this.label,
    required this.value,
  });
}

LinearGradient _eventGradient(String type) {
  switch (type) {
    case 'anniversaire':
      return const LinearGradient(
        colors: [AppColors.warning, AppColors.orAfricain],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'bapteme':
      return const LinearGradient(
        colors: [AppColors.info, AppColors.violetRoyalAlt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    default:
      return AppColors.gradientPrincipal;
  }
}
