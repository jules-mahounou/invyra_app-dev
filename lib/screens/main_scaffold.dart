import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_gate.dart';
import '../core/services/notifications_service.dart';
import '../core/services/user_profile_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_loader.dart';
import '../core/widgets/app_update_dialog.dart';
import '../services/event_service.dart';
import 'create_event_screen.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'templates_screen.dart';
import '../widgets/invyra_nav_bar.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final bool initialCreateEventOpen;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
    this.initialCreateEventOpen = false,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  final _profileService = UserProfileService();
  final _notificationsService = NotificationsService();
  final _eventService = EventService();
  final _homeKey = GlobalKey<HomeTabContentState>();
  final _eventsKey = GlobalKey<EventsScreenState>();

  late int _currentIndex;
  late bool _createEventOpen;
  String _accountType = 'gratuit';
  int _unreadCount = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _createEventOpen = widget.initialCreateEventOpen && _currentIndex == 1;
    _loadProfile();
    _loadUnreadCount();
    _subscribeToNotifications();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      _loadUnreadCount();
      _subscribeToNotifications();
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkAndPromptAppUpdate(context);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android garde souvent l'app en mémoire : on revérifie à chaque retour.
    if (state == AppLifecycleState.resumed && mounted) {
      checkAndPromptAppUpdate(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationsService
        .watchUserNotifications()
        .listen((data) {
          final unread = data
              .where((notification) => notification['is_read'] == false)
              .length;
          if (mounted) {
            setState(() => _unreadCount = unread);
          }
        }, onError: (_) => _loadUnreadCount());
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationsService.fetchUnreadCount();
      if (!mounted) {
        return;
      }
      setState(() => _unreadCount = count);
    } catch (_) {
      // Le badge reste masqué en cas d'échec silencieux.
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetch();
      if (!mounted) {
        return;
      }
      setState(() => _accountType = profile.accountType);
    } catch (_) {
      // Le badge reste sur « Basique » (gratuit) en cas d'échec silencieux.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seule la barre blanche est réservée : la bande au-dessus (où dépasse le
    // bouton scan) est transparente et le contenu reste visible dessous.
    final navReserved =
        InvyraNavBar.barHeight + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: navReserved),
          child: Builder(
            // extendBody ajoute la hauteur de la barre au padding bas : déjà
            // géré ci-dessus, on le retire pour que les écrans ne le comptent pas deux fois.
            builder: (inner) => MediaQuery.removePadding(
              context: inner,
              removeBottom: true,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeTabContent(
                    key: _homeKey,
                    onSeeAllEvents: _openEventsList,
                    onCreateEvent: _openCreateEvent,
                    onProfileTap: () => _onNavChanged(3),
                    unreadCount: _unreadCount,
                    onNotificationsTap: () async {
                      await pushProtectedRoute(
                        context,
                        const NotificationsScreen(),
                      );
                      if (mounted) await _loadUnreadCount();
                    },
                  ),
                  _createEventOpen
                      ? CreateEventTabContent(
                          accountType: _accountType,
                          onBack: _closeCreateEvent,
                        )
                      : EventsScreen(
                          key: _eventsKey,
                          onCreate: _openCreateEvent,
                        ),
                  TemplatesScreen(accountType: _accountType),
                  ProfileScreen(accountType: _accountType),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: InvyraNavBar(
        currentIndex: _currentIndex,
        onChanged: _onNavChanged,
        onScanTap: () => _openScanEventPicker(context),
      ),
    );
  }

  void _openCreateEvent() {
    setState(() {
      _currentIndex = 1;
      _createEventOpen = true;
    });
  }

  void _closeCreateEvent() {
    setState(() => _createEventOpen = false);
    _refreshHomeAndEvents();
  }

  void _openEventsList() {
    setState(() {
      _currentIndex = 1;
      _createEventOpen = false;
    });
    _eventsKey.currentState?.refresh();
  }

  void _refreshHomeAndEvents() {
    _homeKey.currentState?.refresh();
    _eventsKey.currentState?.refresh();
  }

  void _onNavChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 1) {
        _createEventOpen = false;
      }
    });
    if (index == 0) {
      _homeKey.currentState?.refresh();
    } else if (index == 1 && !_createEventOpen) {
      _eventsKey.currentState?.refresh();
    }
  }

  Future<void> _openScanEventPicker(BuildContext context) async {
    List<Map<String, dynamic>> events = [];
    bool isLoading = true;
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (isLoading && events.isEmpty && errorMessage == null) {
              _eventService
                  .getMyEvents()
                  .then((result) {
                    if (!ctx.mounted) return;
                    setSheetState(() {
                      events = result;
                      isLoading = false;
                    });
                  })
                  .catchError((e) {
                    if (!ctx.mounted) return;
                    setSheetState(() {
                      errorMessage = e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      );
                      isLoading = false;
                    });
                  });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.noirDoux.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Scanner les billets',
                      style: AppTypography.textTheme.displaySmall?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Sélectionnez l'événement dont vous voulez scanner les billets.",
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: AppLoader()),
                      )
                    else if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          errorMessage!,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      )
                    else if (events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Center(
                          child: Text(
                            'Aucun événement trouvé.\nCréez un événement pour scanner des billets.',
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.noirDoux.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: events.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final ev = events[i];
                            final name = ev['name'] as String? ?? 'Événement';
                            final eventId = ev['id'] as String;
                            final status = ev['status'] as String? ?? 'a_venir';
                            final eventDate = ev['event_date'] as String?;

                            return InkWell(
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                pushProtectedRoute(
                                  context,
                                  ScanScreen(eventId: eventId, eventName: name),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.beigeCremeAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                  border: Border.all(
                                    color: AppColors.violetRoyal.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.violetRoyal,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.event_rounded,
                                        color: AppColors.blancCasse,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.noirDoux,
                                                ),
                                          ),
                                          if (eventDate != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            Text(
                                              _formatEventDate(eventDate),
                                              style: AppTypography
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.noirDoux
                                                        .withValues(
                                                          alpha: 0.58,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    _StatusDot(status: status),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: AppColors.violetRoyal,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatEventDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const months = [
        'jan',
        'fév',
        'mar',
        'avr',
        'mai',
        'jun',
        'jul',
        'aoû',
        'sep',
        'oct',
        'nov',
        'déc',
      ];
      return '${date.day} ${months[date.month - 1]}. ${date.year}';
    } catch (_) {
      return '';
    }
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'en_cours' => AppColors.warning,
      'termine' => AppColors.success,
      'cloture' => AppColors.noirDoux,
      _ => AppColors.info,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
