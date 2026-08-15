import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../widgets/event_thumbnail.dart';
import '../core/constants/supabase_schema.dart';
import '../core/utils/date_utils.dart';
import '../services/event_service.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'event_detail_screen.dart';

/* TODO: données mockées — décommenter pour tester sans backend
const List<Map<String, dynamic>> mockEvents = [
  {
    'id': '1',
    'name': 'Mariage Kouassi & Amani',
    'type': 'mariage',
    'date': '12 Juillet 2025',
    'lieu': 'Abidjan, Côte d’Ivoire',
    'status': 'a_venir',
    'invites': 120,
  },
  {
    'id': '2',
    'name': 'Anniversaire de Kofi',
    'type': 'anniversaire',
    'date': '03 Juin 2025',
    'lieu': 'Cotonou, Bénin',
    'status': 'en_cours',
    'invites': 45,
  },
  {
    'id': '3',
    'name': 'Baptême Little Grace',
    'type': 'bapteme',
    'date': '20 Avril 2025',
    'lieu': 'Lomé, Togo',
    'status': 'termine',
    'invites': 30,
  },
];
*/

class EventsScreen extends StatefulWidget {
  final VoidCallback onCreate;

  const EventsScreen({super.key, required this.onCreate});

  @override
  State<EventsScreen> createState() => EventsScreenState();
}

class EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = 'tous';
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventService().getMyEvents();
  }

  void refresh() {
    setState(() {
      _eventsFuture = EventService().getMyEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.violetRoyal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Erreur de chargement des événements.'),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: refresh,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final allEvents = snapshot.data ?? [];
        final events = allEvents.where((event) {
          final status = _eventStatus(event);
          return _selectedFilter == 'tous' || status == _selectedFilter;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            refresh();
            await _eventsFuture;
          },
          child: Material(
            color: AppColors.blancCasse,
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── En-tête fixe ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: Text(
                            'Mes événements',
                            style: AppTypography.textTheme.displayMedium
                                ?.copyWith(
                                  color: AppColors.noirDoux,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        // ── Filtres fixes ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: _EventFilters(
                            selectedFilter: _selectedFilter,
                            onChanged: (value) =>
                                setState(() => _selectedFilter = value),
                          ),
                        ),
                        // ── Liste scrollable ──────────────────────────────
                        Expanded(
                          child: events.isEmpty
                              ? const SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                  child: _EmptyEvents(),
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    0,
                                    AppSpacing.lg,
                                    AppSpacing.xxl + AppSpacing.xl,
                                  ),
                                  itemCount: events.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (_, i) {
                                    final event = events[i];
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EventDetailScreen(
                                              eventId:
                                                  event['id'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.lg,
                                      ),
                                      child: _EventCard(event: event),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: FloatingActionButton(
                    onPressed: widget.onCreate,
                    backgroundColor: AppColors.violetRoyal,
                    foregroundColor: AppColors.blancCasse,
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _EventFilters({required this.selectedFilter, required this.onChanged});

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violetRoyal
              : AppColors.noirDoux.withValues(alpha: 0.06),
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

int _guestCount(Map<String, dynamic> event) {
  final guests = event['guests'];
  if (guests is List && guests.isNotEmpty) {
    final count = guests.first['count'];
    if (count is int) return count;
  }
  return event['invites'] as int? ?? 0;
}

String _eventStatus(Map<String, dynamic> event) => readEventStatus(event);

String _eventDateLabel(Map<String, dynamic> event) {
  if (event['date'] is String) return event['date'] as String;
  return formatEventDateShort(event['event_date']);
}

String _eventPlace(Map<String, dynamic> event) {
  return (event['place'] ?? event['lieu'] ?? '—') as String;
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final status = _EventStatusData.from(_eventStatus(event));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: status.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          EventThumbnail(
            logoUrl: event['logo_url'] as String?,
            size: AppSpacing.xxl + AppSpacing.lg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                _MetaLine(
                  icon: Icons.calendar_today_outlined,
                  text: _eventDateLabel(event),
                ),
                const SizedBox(height: AppSpacing.xs),
                _MetaLine(icon: Icons.place_outlined, text: _eventPlace(event)),
                const SizedBox(height: AppSpacing.xs),
                _MetaLine(
                  icon: Icons.people_alt_outlined,
                  text: '${_guestCount(event)} invités',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.violetRoyal,
            size: AppSpacing.lg,
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.noirDoux.withValues(alpha: 0.58),
          size: AppSpacing.md,
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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
        border: Border.all(
          color: AppColors.violetRoyal.withValues(alpha: 0.10),
        ),
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

  const _EventStatusData({required this.label, required this.color});

  factory _EventStatusData.from(String value) {
    switch (value) {
      case 'en_cours':
        return const _EventStatusData(
          label: 'En cours',
          color: AppColors.warning,
        );
      case 'termine':
        return const _EventStatusData(
          label: 'Terminé',
          color: AppColors.success,
        );
      case 'cloture':
        return const _EventStatusData(
          label: 'Clôturé',
          color: AppColors.noirDoux,
        );
      default:
        return const _EventStatusData(label: 'À venir', color: AppColors.info);
    }
  }
}

class _EventFilterData {
  final String label;
  final String value;

  const _EventFilterData({required this.label, required this.value});
}
