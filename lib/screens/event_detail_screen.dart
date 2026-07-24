import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/user_profile_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'create_event/steps/step2_template.dart';
import 'scan_screen.dart';
import 'template_customization_screen.dart';
import 'web_preview_screen.dart';
import '../widgets/guest_manager_widget.dart';
import '../widgets/edit_event_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  final _profileService = UserProfileService();
  
  final GlobalKey<GuestManagerWidgetState> _guestManagerKey = GlobalKey<GuestManagerWidgetState>();

  EventModel? _event;
  bool _isLoading = true;
  String? _errorMessage;
  String _accountType = 'gratuit';
  String? _webTemplateKey;           // déplacé dans le state
  Map<String, dynamic> _templateConfig = {};

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetch();
      if (mounted) setState(() => _accountType = profile.accountType);
    } catch (_) {
      // garde la valeur par défaut 'gratuit' en cas d'erreur
    }
  }

  Future<void> _loadEvent() async {
    try {
      setState(() => _isLoading = true);
      
      final data = await _eventService.getEventById(widget.eventId);
      
      setState(() {
        // Réinitialiser avant chaque chargement
        _webTemplateKey = null;
        _templateConfig = {};
        if (data['event_templates'] != null) {
          final tpl = data['event_templates'] as Map<String, dynamic>;
          _webTemplateKey = tpl['web_template_key'] as String?;
          _templateConfig = tpl['config'] is Map
              ? Map<String, dynamic>.from(tpl['config'] as Map)
              : {};
        }
        _event = EventModel.fromMap(data); 
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.blancCasse)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.blancCasse)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionTile(
                icon: Icons.edit_outlined,
                label: "Modifier l'événement",
                onTap: () {
                  Navigator.of(context).pop();
                  _openEditSheet();
                },
              ),
              _ActionTile(
                icon: Icons.sync_rounded,
                label: 'Changer le statut',
                onTap: () {
                  Navigator.of(context).pop();
                  _openStatusDialog();
                },
              ),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: "Supprimer l'événement",
                color: AppColors.error,
                onTap: () {
                  Navigator.of(context).pop();
                  _openDeleteDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditSheet() async {
    final event = _event;
    if (event == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => EditEventSheet(event: event, invitationsSent: event.invitationsSent, accountType: _accountType),
    );
    if (saved != true) return;
    _showSuccess('Événement modifié avec succès');
    await _loadEvent();
  }

  Future<void> _openStatusDialog() async {
    final event = _event;
    if (event == null) return;
    var selectedStatus = event.status;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Changer le statut'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final status in _statusChoices)
                  ListTile(
                    leading: Icon(
                      selectedStatus == status.value
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selectedStatus == status.value
                          ? AppColors.violetRoyal
                          : AppColors.noirDoux.withValues(alpha: 0.46),
                    ),
                    title: Text(status.label),
                    onTap: () => setDialogState(() => selectedStatus = status.value),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true) return;
    try {
      await _eventService.updateEventStatus(
        eventId: widget.eventId,
        status: selectedStatus,
      );
      if (!mounted) return;
      _showSuccess('Statut modifié avec succès');
      await _loadEvent();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer l'événement ?"),
        content: const Text(
          'Cette action est irréversible. Tous les invités et invitations liés seront également supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _eventService.deleteEvent(widget.eventId);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Événement supprimé', style: TextStyle(color: AppColors.blancCasse)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(
        color: AppColors.blancCasse,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.violetRoyal),
        ),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Material(
        color: AppColors.blancCasse,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage ?? "Impossible de charger l'événement.",
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _loadEvent,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final event = _event!;
    final status = _EventStatusData.from(event.status);

    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                        child: _InternalHeader(
                          title: event.name,
                          onBack: () => Navigator.of(context).pop(),
                          onMenu: _openActions,
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.violetRoyal,
                          onRefresh: _loadEvent,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroBlock(event: event, status: status),
                                const SizedBox(height: AppSpacing.lg),
                                _StatisticsBlock(event: event),
                                const SizedBox(height: AppSpacing.lg),
                                _InformationBlock(event: event),
                                const SizedBox(height: AppSpacing.lg),
                                
                                _InvitationPreviewCard(
                                  webTemplateKey: _webTemplateKey,
                                  eventName: event.name,
                                  hasTemplateChosen: _webTemplateKey != null && _webTemplateKey!.isNotEmpty,
                                  event: event,
                                  accountType: _accountType,
                                  templateConfig: _templateConfig,
                                  onTemplateChosen: () async {
                                    await _loadEvent();
                                  },
                                ),
                                
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Invités',
                                  style: AppTypography.textTheme.displaySmall?.copyWith(
                                    color: AppColors.noirDoux,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                GuestManagerWidget(
                                  key: _guestManagerKey,
                                  eventId: widget.eventId,
                                  onChanged: _loadEvent,
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
            );
          },
        ),
      ),
      // DEUX BOUTONS EN BAS : générer les invitations + scanner
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            children: [
              // Bouton Scanner (secondaire)
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScanScreen(
                          eventId: widget.eventId,
                          eventName: event.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scanner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.violetRoyal,
                    side: const BorderSide(color: AppColors.violetRoyal),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Bouton Générer les invitations (principal)
              Expanded(
                flex: 2,
                child: _GradientActionButton(
                  label: 'Générer les billets',
                  icon: Icons.send_rounded,
                  onPressed: () async {
                    try {
                      await _guestManagerKey.currentState?.triggerSendInvitations();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Billets générés avec succès ✓'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        _showError(e.toString().replaceFirst('Exception: ', ''));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternalHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const _InternalHeader({
    required this.title,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.violetRoyal,
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onMenu,
          icon: const Icon(Icons.more_vert_rounded),
          color: AppColors.violetRoyal,
        ),
      ],
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final EventModel event;
  final _EventStatusData status;

  const _HeroBlock({required this.event, required this.status});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: event.hasLogo ? null : _eventGradient(event.eventType),
          image: event.hasLogo
              ? DecorationImage(
                  image: CachedNetworkImageProvider(event.logoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (event.hasLogo)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topRight,
              child: _StatusBadge(status: status, light: event.hasLogo),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                event.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.displayMedium?.copyWith(
                  color: AppColors.blancCasse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsBlock extends StatelessWidget {
  final EventModel event;

  const _StatisticsBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.blancCasse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(
                icon: Icons.people_alt_outlined,
                color: AppColors.violetRoyal,
                value: '${event.guestsCount}',
                label: 'Total invités',
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                icon: Icons.remove_red_eye_outlined,
                color: AppColors.orAfricain,
                value: '${event.invitationsViewed}',
                label: 'Vues',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatCard(
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                value: '${event.guestsConfirmed}',
                label: 'Présents',
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                value: '${event.guestsDeclined}',
                label: 'Absents',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.beigeCremeAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.displaySmall?.copyWith(
                fontSize: 18,
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.noirDoux.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationBlock extends StatelessWidget {
  final EventModel event;

  const _InformationBlock({required this.event});

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'anniversaire':
        return 'Anniversaire';
      case 'bapteme':
        return 'Baptême';
      case 'mariage':
        return 'Mariage';
      case 'fete':
        return 'Fête / Réception';
      default:
        return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTile(
            icon: Icons.category_outlined,
            label: 'Type',
            value: _getTypeLabel(event.eventType),
          ),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: event.eventDate != null ? formatEventDate(event.eventDate!.toIso8601String()) : 'Date non définie',
          ),
          _InfoTile(
            icon: Icons.place_outlined,
            label: 'Lieu',
            value: event.place,
          ),
          _InfoTile(
            icon: Icons.notes_rounded,
            label: 'Description',
            value: event.description,
          ),
          if (event.hasCustomField1) ...[
            const Divider(height: AppSpacing.lg, color: AppColors.beigeCremeAlt),
            _InfoTile(
              icon: Icons.star_border_rounded,
              label: event.customField1Label!,
              value: event.customField1Value!,
            ),
          ],
          if (event.hasCustomField2) ...[
            if (!event.hasCustomField1) const Divider(height: AppSpacing.lg, color: AppColors.beigeCremeAlt),
            _InfoTile(
              icon: Icons.star_border_rounded,
              label: event.customField2Label!,
              value: event.customField2Value!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InvitationPreviewCard extends StatelessWidget {
  final String? webTemplateKey;
  final String eventName;
  final bool hasTemplateChosen;
  final EventModel event;
  final String accountType;
  final Map<String, dynamic> templateConfig;
  final VoidCallback onTemplateChosen;

  const _InvitationPreviewCard({
    required this.webTemplateKey,
    required this.eventName,
    required this.hasTemplateChosen,
    required this.event,
    required this.accountType,
    required this.templateConfig,
    required this.onTemplateChosen,
  });

  void _openTemplateSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.blancCasse,
          appBar: AppBar(
            backgroundColor: AppColors.blancCasse,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.violetRoyal),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Choisir un template',
              style: AppTypography.textTheme.displaySmall?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Step2Template(
              eventId: event.id,
              eventType: event.eventType,
              accountType: accountType,
              onStepCompleted: (templateId) async {
                Navigator.of(context).pop();
                onTemplateChosen(); // VoidCallback — pas d'await
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Template enregistré ✓'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Ouvrir la personnalisation si la config a des champs
                if (context.mounted && templateConfig.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TemplateCustomizationScreen(
                        eventId: event.id,
                        templateName: eventName,
                        templateConfig: templateConfig,
                        initialValues: event.customization,
                        onSaved: onTemplateChosen,
                      ),
                    ),
                  );
                }
              },
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Votre modèle de carte",
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasTemplateChosen
                          ? "Visualisez le rendu avec les vraies données de l'événement."
                          : "Choisissez un template pour votre invitation.",
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.noirDoux.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  if (!hasTemplateChosen) {
                    _openTemplateSelection(context);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WebPreviewScreen(
                        webTemplateKey: webTemplateKey!,
                        templateName: eventName,
                        event: event,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  hasTemplateChosen ? Icons.visibility_rounded : Icons.palette_outlined,
                  size: 18,
                ),
                label: Text(hasTemplateChosen ? 'Aperçu' : 'Choisir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasTemplateChosen ? AppColors.violetRoyal : AppColors.orAfricain,
                  foregroundColor: AppColors.blancCasse,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
              ),
            ],
          ),
          // Bouton Personnaliser si template choisi et config disponible
          if (hasTemplateChosen && templateConfig.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TemplateCustomizationScreen(
                      eventId: event.id,
                      templateName: eventName,
                      templateConfig: templateConfig,
                      initialValues: event.customization,
                      onSaved: onTemplateChosen,
                    ),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Personnaliser les couleurs et options'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orAfricain,
                  side: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.violetRoyal, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.violetRoyal,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _EventStatusData status;
  final bool light;

  const _StatusBadge({required this.status, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: light ? AppColors.blancCasse.withValues(alpha: 0.18) : status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: light ? AppColors.blancCasse : status.color,
          fontWeight: FontWeight.w700,
        ),
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
        return const _EventStatusData(label: 'En cours', color: AppColors.warning);
      case 'termine':
        return const _EventStatusData(label: 'Terminé', color: AppColors.success);
      case 'cloture':
        return const _EventStatusData(label: 'Clôturé', color: AppColors.noirDoux);
      default:
        return const _EventStatusData(label: 'À venir', color: AppColors.info);
    }
  }
}

const _statusChoices = [
  _StatusChoice('À venir', 'a_venir'),
  _StatusChoice('En cours', 'en_cours'),
  _StatusChoice('Terminé', 'termine'),
  _StatusChoice('Clôturé', 'cloture'),
];

class _StatusChoice {
  final String label;
  final String value;

  const _StatusChoice(this.label, this.value);
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

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrincipal,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: AppSpacing.lg),
          label: Text(label, textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blancCasse,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
          ),
        ),
      ),
    );
  }
}