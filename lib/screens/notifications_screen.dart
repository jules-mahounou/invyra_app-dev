import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/models/app_notification.dart';
import '../core/services/notifications_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/notification_time_formatter.dart';
import '../core/utils/notification_visuals.dart';
import '../core/widgets/app_shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();

  String _selectedFilter = 'toutes';
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await _service.fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les notifications';
      });
    }
  }

  List<AppNotification> get _filteredNotifications {
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

  bool get _hasUnread => _notifications.any((notification) => !notification.isRead);

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) {
      _handleNotificationAction(notification);
      return;
    }

    setState(() {
      final index = _notifications.indexWhere((item) => item.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });

    try {
      await _service.markAsRead(notification.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _loadNotifications();
    }

    if (mounted) {
      _handleNotificationAction(notification);
    }
  }

  void _handleNotificationAction(AppNotification notification) {
    final actionUrl = notification.metadata['action_url'] as String?;
    if (actionUrl == '/subscription') {
      Navigator.of(context).pushNamed('/subscription');
    }
  }

  Future<void> _markAllAsRead() async {
    if (!_hasUnread) {
      return;
    }

    setState(() {
      _notifications = [
        for (final notification in _notifications) notification.copyWith(isRead: true),
      ];
    });

    try {
      await _service.markAllAsRead();
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filteredNotifications;

    return Material(
      color: AppColors.blancCasse,
      child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: _isLoading
              ? const _NotificationsLoadingView()
              : _errorMessage != null
                  ? _NotificationsErrorView(message: _errorMessage!, onRetry: _loadNotifications)
                  : SingleChildScrollView(
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
                              _NotificationCard(
                                notification: notification,
                                onTap: () => _markAsRead(notification),
                              ),
                              if (notification != filteredNotifications.last)
                                const SizedBox(height: AppSpacing.md),
                            ],
                          if (_hasUnread) ...[
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
    ),
    );
  }
}

class _NotificationsLoadingView extends StatelessWidget {
  const _NotificationsLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          const ShimmerBox(height: 40),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                const Expanded(child: ShimmerBox(height: 36)),
                if (i < 3) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 4; i++) ...[
            const ShimmerBox(height: 96),
            if (i < 3) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _NotificationsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotificationsErrorView({required this.message, required this.onRetry});

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
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = NotificationVisualsResolver.fromType(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.cardDecoration.copyWith(
          color: notification.isRead ? AppColors.blancCasse : AppColors.beigeCremeAlt,
          border: Border.all(color: visuals.color.withValues(alpha: 0.12)),
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
                    color: visuals.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visuals.icon, color: visuals.color, size: AppSpacing.md),
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
                        notification.body,
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
                    NotificationTimeFormatter.format(notification.createdAt),
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

class _FilterData {
  final String label;
  final String value;

  const _FilterData({
    required this.label,
    required this.value,
  });
}
