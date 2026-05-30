import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'toutes';
  late List<_NotificationData> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List<_NotificationData>.from(_mockNotifications);
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filteredNotifications;
    final hasUnread = _notifications.any((notification) => !notification.isRead);

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
                _NotificationsHeader(
                  onBack: () => Navigator.of(context).pop(),
                  onReadAll: _markAllAsRead,
                ),
                const SizedBox(height: AppSpacing.lg),
                _NotificationFilters(
                  selectedFilter: _selectedFilter,
                  onChanged: (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (filteredNotifications.isEmpty)
                  const _EmptyNotifications()
                else
                  for (final notification in filteredNotifications) ...[
                    _NotificationCard(notification: notification),
                    if (notification != filteredNotifications.last) const SizedBox(height: AppSpacing.md),
                  ],
                if (hasUnread) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all_rounded, size: AppSpacing.lg),
                      label: const Text('Marquer tout comme lu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.violetRoyal,
                        side: const BorderSide(color: AppColors.violetRoyal),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_NotificationData> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'non_lues':
        return _notifications.where((notification) => !notification.isRead).toList();
      case 'systeme':
        return _notifications.where((notification) => notification.category == 'systeme').toList();
      case 'offres':
        return _notifications.where((notification) => notification.category == 'offres').toList();
      default:
        return _notifications;
    }
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = [
        for (final notification in _notifications) notification.copyWith(isRead: true),
      ];
    });
  }
}

class _NotificationsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReadAll;

  const _NotificationsHeader({
    required this.onBack,
    required this.onReadAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.violetRoyal,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Notifications',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 82,
          child: TextButton(
            onPressed: onReadAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.violetRoyal,
              padding: EdgeInsets.zero,
              textStyle: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: const Text('Tout lire'),
          ),
        ),
      ],
    );
  }
}

class _NotificationFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _NotificationFilters({
    required this.selectedFilter,
    required this.onChanged,
  });

  static const filters = [
    _FilterData(label: 'Toutes', value: 'toutes'),
    _FilterData(label: 'Non lues', value: 'non_lues'),
    _FilterData(label: 'Système', value: 'systeme'),
    _FilterData(label: 'Offres', value: 'offres'),
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
          color: selected ? AppColors.violetRoyal : AppColors.beigeCremeBase,
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

class _NotificationCard extends StatelessWidget {
  final _NotificationData notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: notification.isRead ? AppColors.blancCasse : AppColors.beigeCremeAlt,
        border: Border.all(color: notification.color.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(notification.icon, color: notification.color, size: AppSpacing.md),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTypography.textTheme.headlineLarge?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.description,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: EdgeInsets.only(top: notification.isRead ? 0 : AppSpacing.md),
                child: Text(
                  notification.time,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.48),
                  ),
                ),
              ),
            ],
          ),
          if (!notification.isRead)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: const BoxDecoration(
                  color: AppColors.violetRoyal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final gray = AppColors.noirDoux.withValues(alpha: 0.38);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, color: gray, size: AppSpacing.xxl),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Aucune notification pour l'instant",
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: gray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationData {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  final String category;
  final bool isRead;

  const _NotificationData({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    required this.category,
    required this.isRead,
  });

  _NotificationData copyWith({bool? isRead}) {
    return _NotificationData(
      title: title,
      description: description,
      time: time,
      icon: icon,
      color: color,
      category: category,
      isRead: isRead ?? this.isRead,
    );
  }
}

class _FilterData {
  final String label;
  final String value;

  const _FilterData({
    required this.label,
    required this.value,
  });
}

const _mockNotifications = [
  _NotificationData(
    title: 'Limite proche',
    description: 'Il ne vous reste que 3 invités dans votre quota. Passez à Essentiel pour continuer sans limite.',
    time: 'Il y a 5 min',
    icon: Icons.warning_amber_rounded,
    color: AppColors.warning,
    category: 'systeme',
    isRead: false,
  ),
  _NotificationData(
    title: 'Offre spéciale',
    description: 'Profitez de -20% sur le plan Essentiel ce mois-ci. Offre limitée !',
    time: 'Il y a 1 h',
    icon: Icons.star_rounded,
    color: AppColors.violetRoyal,
    category: 'offres',
    isRead: false,
  ),
  _NotificationData(
    title: 'Événement créé',
    description: 'Votre événement "Mariage Kouassi & Amani" a été créé avec succès.',
    time: 'Hier',
    icon: Icons.check_circle_rounded,
    color: AppColors.success,
    category: 'systeme',
    isRead: true,
  ),
  _NotificationData(
    title: 'Invitations envoyées',
    description: '45 invitations ont été envoyées pour l\'événement "Anniversaire de Kofi".',
    time: '12 mai',
    icon: Icons.email_outlined,
    color: AppColors.info,
    category: 'systeme',
    isRead: true,
  ),
  _NotificationData(
    title: 'Sécurité',
    description: 'Une connexion depuis un nouvel appareil a été détectée sur votre compte.',
    time: '10 mai',
    icon: Icons.lock_outline_rounded,
    color: AppColors.noirDoux,
    category: 'systeme',
    isRead: false,
  ),
  _NotificationData(
    title: 'Quota atteint',
    description: 'Vous avez atteint la limite de 3 événements de votre plan Gratuit. Passez à Essentiel pour continuer.',
    time: '08 mai',
    icon: Icons.block_rounded,
    color: AppColors.error,
    category: 'systeme',
    isRead: true,
  ),
];
