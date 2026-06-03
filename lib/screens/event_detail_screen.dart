import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/supabase_schema.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../services/event_service.dart';
import '../services/invitation_service.dart';
import '../widgets/guest_manager_widget.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  final _invitationService = InvitationService();

  Map<String, dynamic>? _event;
  bool _isLoading = true;
  bool _isSendingInvitations = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final event = await _eventService.getEventById(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.blancCasse),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.blancCasse),
        ),
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
      builder: (context) => _EditEventSheet(event: event),
    );
    if (saved != true) return;
    _showSuccess('Événement modifié avec succès');
    await _loadEvent();
  }

  Future<void> _openStatusDialog() async {
    final event = _event;
    if (event == null) return;
    final currentStatus = readEventStatus(event);
    var selectedStatus = currentStatus;
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
                    onTap: () =>
                        setDialogState(() => selectedStatus = status.value),
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
        SnackBar(
          content: const Text(
            'Événement supprimé',
            style: TextStyle(color: AppColors.blancCasse),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _sendInvitations() async {
    final event = _event;
    if (event == null) return;
    final guestCount = _guestCount(event);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Envoyer les invitations'),
        content: Text('$guestCount invités vont recevoir leur invitation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          _DialogGradientButton(
            label: 'Envoyer',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSendingInvitations = true);
    try {
      final channel = (event['send_channel'] as String?) ?? kDefaultSendChannel;
      await _invitationService.createInvitationsForEvent(
        eventId: widget.eventId,
        channel: channel,
      );
      await _invitationService.markInvitationsAsSent(widget.eventId);
      if (!mounted) return;
      _showSuccess('Invitations envoyées avec succès !');
      await _loadEvent();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingInvitations = false);
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
    final status = _EventStatusData.from(readEventStatus(event));
    final name = (event['name'] as String?)?.trim().isNotEmpty == true
        ? event['name'] as String
        : 'Événement';

    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _InternalHeader(
                      title: name,
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
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroBlock(event: event, status: status),
                            const SizedBox(height: AppSpacing.lg),
                            _StatisticsBlock(event: event),
                            const SizedBox(height: AppSpacing.lg),
                            _InformationBlock(event: event),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Invités',
                              style: AppTypography.textTheme.displaySmall
                                  ?.copyWith(
                                    color: AppColors.noirDoux,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            GuestManagerWidget(
                              eventId: widget.eventId,
                              onChanged: _loadEvent,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _GradientActionButton(
                              label: 'Envoyer les invitations',
                              icon: Icons.send_rounded,
                              onPressed: _sendInvitations,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _OutlineActionButton(
                              label: "Partager l'événement",
                              icon: Icons.share_rounded,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSendingInvitations)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.blancCasse.withValues(alpha: 0.62),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.violetRoyal,
                      ),
                    ),
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
  final Map<String, dynamic> event;
  final _EventStatusData status;

  const _HeroBlock({required this.event, required this.status});

  @override
  Widget build(BuildContext context) {
    final logoUrl = event['logo_url'] as String?;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: hasLogo ? null : _eventGradient(readEventType(event)),
          image: hasLogo
              ? DecorationImage(
                  image: CachedNetworkImageProvider(logoUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (hasLogo)
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
              child: _StatusBadge(status: status, light: hasLogo),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                (event['name'] as String?) ?? 'Événement',
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
  final Map<String, dynamic> event;

  const _StatisticsBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.people_alt_outlined,
          color: AppColors.violetRoyal,
          value: '${_intValue(event['guests_count'])}',
          label: 'Total invités',
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatCard(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.info,
          value: '${_intValue(event['invitations_sent'])}',
          label: 'Envoyées',
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatCard(
          icon: Icons.visibility_outlined,
          color: AppColors.warning,
          value: '${_intValue(event['invitations_viewed'])}',
          label: 'Vues',
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatCard(
          icon: Icons.done_all_rounded,
          color: AppColors.success,
          value: '${_intValue(event['guests_confirmed'])}',
          label: 'Confirmés',
        ),
      ],
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
              maxLines: 2,
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
  final Map<String, dynamic> event;

  const _InformationBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    final template = event['event_templates'];
    final templateMap = template is Map<String, dynamic> ? template : null;

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
            value: eventTypeDisplayLabel(readEventType(event)),
          ),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formatEventDate(event['event_date']),
          ),
          _InfoTile(
            icon: Icons.place_outlined,
            label: 'Lieu',
            value: (event['place'] as String?) ?? 'Lieu non défini',
          ),
          _InfoTile(
            icon: Icons.notes_rounded,
            label: 'Description',
            value:
                (event['description'] as String?) ??
                'Aucune description pour le moment.',
          ),
          if (templateMap != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _TemplatePreview(template: templateMap),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template utilisé',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (templateMap['name'] as String?) ?? 'Template',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.noirDoux,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  final Map<String, dynamic> template;

  const _TemplatePreview({required this.template});

  @override
  Widget build(BuildContext context) {
    final previewUrl = template['preview_url'] as String?;
    final assetPath = template['asset_path'] as String?;
    final image = previewUrl != null && previewUrl.isNotEmpty
        ? Image.network(previewUrl, fit: BoxFit.cover)
        : assetPath != null && assetPath.isNotEmpty
        ? Image.asset(assetPath, fit: BoxFit.cover)
        : const Icon(Icons.image_outlined, color: AppColors.violetRoyal);

    return Container(
      width: AppSpacing.xxl + AppSpacing.md,
      height: AppSpacing.xxl + AppSpacing.md,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.beigeCremeBase,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.violetRoyal.withValues(alpha: 0.10),
        ),
      ),
      child: image,
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

class _EditEventSheet extends StatefulWidget {
  final Map<String, dynamic> event;

  const _EditEventSheet({required this.event});

  @override
  State<_EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<_EditEventSheet> {
  final _eventService = EventService();
  late final TextEditingController _nameController;
  late final TextEditingController _placeController;
  late final TextEditingController _descriptionController;
  late DateTime _initialDateTime;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rawDate = widget.event['event_date'] as String?;
    _initialDateTime = rawDate == null
        ? DateTime.now()
        : DateTime.parse(rawDate).toLocal();
    _selectedDate = _initialDateTime;
    _selectedTime = TimeOfDay(
      hour: _initialDateTime.hour,
      minute: _initialDateTime.minute,
    );
    _nameController = TextEditingController(
      text: widget.event['name'] as String? ?? '',
    );
    _placeController = TextEditingController(
      text: widget.event['place'] as String? ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.event['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(DateTime.now().year + 3),
      locale: const Locale('fr'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final newDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final currentName = widget.event['name'] as String? ?? '';
    final currentPlace = widget.event['place'] as String? ?? '';
    final currentDescription = widget.event['description'] as String? ?? '';
    final eventId = widget.event['id'] as String;

    setState(() => _isSaving = true);
    try {
      await _eventService.updateEvent(
        eventId: eventId,
        name: name == currentName ? null : name,
        eventDate: newDateTime.isAtSameMomentAs(_initialDateTime)
            ? null
            : newDateTime,
        place: _placeController.text.trim() == currentPlace
            ? null
            : _placeController.text.trim(),
        description: _descriptionController.text.trim() == currentDescription
            ? null
            : _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: AppColors.blancCasse),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Modifier l'événement",
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SheetTextField(
                  controller: _nameController,
                  label: 'Nom',
                  icon: Icons.celebration_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Date',
                        icon: Icons.calendar_today_outlined,
                        value: formatEventDateShort(_selectedDate),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PickerField(
                        label: 'Heure',
                        icon: Icons.schedule_rounded,
                        value:
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SheetTextField(
                  controller: _placeController,
                  label: 'Lieu',
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                _SheetTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.xl),
                _GradientActionButton(
                  label: 'Enregistrer les modifications',
                  icon: Icons.save_outlined,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.blancCasse.withValues(alpha: 0.55),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.violetRoyal),
              ),
            ),
          ),
      ],
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.textTheme.bodyLarge,
      decoration: _sheetDecoration(icon).copyWith(labelText: label),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InputDecorator(
        decoration: _sheetDecoration(icon).copyWith(labelText: label),
        child: Text(value, style: AppTypography.textTheme.bodyLarge),
      ),
    );
  }
}

InputDecoration _sheetDecoration(IconData icon) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: AppColors.violetRoyal),
    fillColor: AppColors.beigeCremeAlt,
    filled: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(
        color: AppColors.orAfricain.withValues(alpha: 0.24),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
    ),
  );
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

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

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
          gradient: onPressed == null ? null : AppColors.gradientPrincipal,
          color: onPressed == null
              ? AppColors.noirDoux.withValues(alpha: 0.18)
              : null,
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

class _DialogGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DialogGradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrincipal,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blancCasse,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppSpacing.lg),
        label: Text(label, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violetRoyal,
          side: const BorderSide(color: AppColors.violetRoyal),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
        ),
      ),
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
        color: light
            ? AppColors.blancCasse.withValues(alpha: 0.18)
            : status.color.withValues(alpha: 0.12),
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

class _StatusChoice {
  final String label;
  final String value;

  const _StatusChoice(this.label, this.value);
}

const _statusChoices = [
  _StatusChoice('À venir', 'a_venir'),
  _StatusChoice('En cours', 'en_cours'),
  _StatusChoice('Terminé', 'termine'),
  _StatusChoice('Clôturé', 'cloture'),
];

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _guestCount(Map<String, dynamic> event) {
  final guestsCount = _intValue(event['guests_count']);
  if (guestsCount > 0) return guestsCount;
  final guests = event['guests'];
  if (guests is List) return guests.length;
  return 0;
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
