import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../widgets/guest_manager_widget.dart';

class CreateEventTabContent extends StatefulWidget {
  final String accountType;
  final VoidCallback? onBack;

  const CreateEventTabContent({
    super.key,
    this.accountType = 'premium',
    this.onBack,
  });

  @override
  State<CreateEventTabContent> createState() => _CreateEventTabContentState();
}

class CreateEventScreen extends CreateEventTabContent {
  const CreateEventScreen({super.key, super.accountType, super.onBack});
}

const List<Map<String, dynamic>> mockTemplates = [
  {
    'id': '1',
    'name': 'Élégance Dorée',
    'type': 'mariage',
    'tier': 'premium',
    'asset': 'assets/images/templates/template_mariage.png',
  },
  {
    'id': '2',
    'name': 'Simple & Sobre',
    'type': 'mariage',
    'tier': 'gratuit',
    'asset': 'assets/images/templates/template_mariage.png',
  },
  {
    'id': '3',
    'name': 'Fête Colorée',
    'type': 'anniversaire',
    'tier': 'gratuit',
    'asset': 'assets/images/templates/template_anniversaire.png',
  },
  {
    'id': '4',
    'name': 'Soirée VIP',
    'type': 'soiree_vip',
    'tier': 'premium',
    'asset': 'assets/images/templates/template_soiree_vip.png',
  },
  {
    'id': '5',
    'name': 'Douceur Pastel',
    'type': 'bapteme',
    'tier': 'gratuit',
    'asset': 'assets/images/templates/template_bapteme.png',
  },
];

class _CreateEventTabContentState extends State<CreateEventTabContent> {
  static const List<String> _eventTypes = [
    'Mariage',
    'Anniversaire',
    'Baptême',
    'Soirée VIP',
    'Conférence',
    'Autre',
  ];

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = _eventTypes.first;
  DateTime? _selectedDate;
  String? _eventImageAsset;
  Map<String, dynamic>? _selectedTemplate;
  int _currentStep = 1;
  String _templateFilter = 'tous';
  bool _showGuestForm = false;
  List<Map<String, dynamic>> _guests = [];

  @override
  void dispose() {
    _eventNameController.dispose();
    _customTypeController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _CreateEventHero(currentStep: _currentStep, onBack: widget.onBack),
                const SizedBox(height: AppSpacing.xl),
                _StepIndicator(currentStep: _currentStep),
                const SizedBox(height: AppSpacing.xl),
                if (_currentStep == 1)
                  _BaseInfoCard(
                    eventNameController: _eventNameController,
                    selectedType: _selectedType,
                    eventTypes: _eventTypes,
                    customTypeController: _customTypeController,
                    selectedDate: _selectedDate,
                    placeController: _placeController,
                    descriptionController: _descriptionController,
                    eventImageAsset: _eventImageAsset,
                    onTypeChanged: (value) => setState(() => _selectedType = value),
                    onDateTap: _pickDate,
                    onImageTap: _pickEventImage,
                    onImageRemove: () => setState(() => _eventImageAsset = null),
                    onContinue: _handleBaseInfoContinue,
                  )
                else if (_currentStep == 2)
                  _TemplateChoiceStep(
                    accountType: widget.accountType,
                    selectedEventType: _selectedType,
                    selectedFilter: _templateFilter,
                    selectedTemplate: _selectedTemplate,
                    onFilterChanged: (value) => setState(() => _templateFilter = value),
                    onTemplateSelected: (template) => setState(() => _selectedTemplate = template),
                    onBack: () => setState(() => _currentStep = 1),
                    onContinue: _goToGuestStep,
                  )
                else if (_showGuestForm)
                  _GuestManagementStep(
                    guests: _guests,
                    onGuestsChanged: (guests) => setState(() => _guests = guests),
                    onCreateAndSend: _finishEvent,
                    onFinishWithoutSending: _finishEvent,
                  )
                else
                  _EventReadyStep(
                    eventName: _eventName,
                    templateName: _selectedTemplateName,
                    onAddGuestsNow: () => setState(() => _showGuestForm = true),
                    onLater: _finishEvent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      locale: const Locale(AppConstants.defaultLocale),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.violetRoyal,
                  secondary: AppColors.orAfricain,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickEventImage() {
    setState(() => _eventImageAsset = AppAssets.logoMark);
  }

  void _handleBaseInfoContinue() {
    // TODO: décommenter lors de l'intégration backend
    // if (userPlan == 'gratuit' && eventCount >= 3)
    final bool hasReachedEventLimit = _isLimitEnabledForFrontendTests(); // retiré pour les tests frontend

    if (hasReachedEventLimit) {
      _showSubscriptionLimitDialog(
        message: 'Vous avez atteint la limite de 3 événements. Passez à Essentiel pour continuer.',
      );
      return;
    }

    setState(() => _currentStep = 2);
  }

  String get _eventName {
    final value = _eventNameController.text.trim();
    return value.isEmpty ? 'Nouvel événement' : value;
  }

  String get _selectedTemplateName {
    return (_selectedTemplate?['name'] as String?) ?? 'Template sélectionné';
  }

  void _goToGuestStep() {
    setState(() {
      _selectedTemplate ??= _firstTemplateForSelectedType();
      _currentStep = 3;
      _showGuestForm = false;
    });
  }

  Map<String, dynamic>? _firstTemplateForSelectedType() {
    final selectedTypeKey = _eventTypeKey(_selectedType);
    for (final template in mockTemplates) {
      if (template['type'] == selectedTypeKey) {
        return template;
      }
    }
    return mockTemplates.isEmpty ? null : mockTemplates.first;
  }

  // ignore: unused_element
  Future<void> _showAddGuestSheet() async {
    // TODO: décommenter lors de l'intégration backend
    // if (userPlan == 'gratuit' && inviteCount >= 50)
    final bool hasReachedInviteLimit = _isLimitEnabledForFrontendTests(); // retiré pour les tests frontend

    if (hasReachedInviteLimit) {
      _showSubscriptionLimitDialog(
        message: 'Limite de 50 invités atteinte. Choisissez un pack Flex ou passez à Essentiel.',
      );
      return;
    }

    final guest = await showModalBottomSheet<_GuestDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => const _AddGuestSheet(),
    );

    if (guest != null) {
      setState(() => _guests.add(guest.toMap()));
    }
  }

  void _finishEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Votre événement a bien été sauvegardé.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
    widget.onBack?.call();
  }

  Future<void> _showSubscriptionLimitDialog({required String message}) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.blancCasse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text(
            'Limite atteinte',
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.noirDoux),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.noirDoux),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violetRoyal,
                foregroundColor: AppColors.blancCasse,
              ),
              child: const Text('Voir les offres'),
            ),
          ],
        );
      },
    );
  }

  bool _isLimitEnabledForFrontendTests() {
    return false;
  }
}

class _CreateEventHero extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onBack;

  const _CreateEventHero({
    required this.currentStep,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          _BackToEventsButton(onBack: onBack!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créer un événement',
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      color: AppColors.noirDoux,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Trois étapes pour lancer votre invitation.',
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Image.asset(
              _heroMascot,
              height: AppSpacing.xxl + AppSpacing.xl,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String get _heroMascot {
    if (currentStep == 2) {
      return AppAssets.mascotTemplateChoice;
    }
    if (currentStep == 3) {
      return AppAssets.mascotInviteManager;
    }
    return AppAssets.mascotCreateEvent;
  }
}

class _BackToEventsButton extends StatelessWidget {
  final VoidCallback onBack;

  const _BackToEventsButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_rounded, size: AppSpacing.lg),
      label: const Text('Retour aux événements'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.violetRoyal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepCircle(number: 1, active: currentStep == 1),
        const Expanded(child: _StepLine()),
        _StepCircle(number: 2, active: currentStep == 2),
        const Expanded(child: _StepLine()),
        _StepCircle(number: 3, active: currentStep == 3),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final bool active;

  const _StepCircle({required this.number, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: active ? AppColors.gradientPrincipal : null,
        color: active ? null : AppColors.beigeCremeBase,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.violetRoyal.withValues(alpha: 0.18),
                  blurRadius: AppSpacing.lg,
                  offset: const Offset(0, AppSpacing.sm),
                ),
              ]
            : null,
      ),
      child: Text(
        number.toString(),
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: active ? AppColors.blancCasse : AppColors.noirDoux,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.beigeCremeBase,
    );
  }
}

class _BaseInfoCard extends StatelessWidget {
  final TextEditingController eventNameController;
  final TextEditingController customTypeController;
  final TextEditingController placeController;
  final TextEditingController descriptionController;
  final String selectedType;
  final List<String> eventTypes;
  final DateTime? selectedDate;
  final String? eventImageAsset;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onDateTap;
  final VoidCallback onImageTap;
  final VoidCallback onImageRemove;
  final VoidCallback onContinue;

  const _BaseInfoCard({
    required this.eventNameController,
    required this.customTypeController,
    required this.placeController,
    required this.descriptionController,
    required this.selectedType,
    required this.eventTypes,
    required this.selectedDate,
    required this.eventImageAsset,
    required this.onTypeChanged,
    required this.onDateTap,
    required this.onImageTap,
    required this.onImageRemove,
    required this.onContinue,
  });

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
          const _FieldLabel(text: 'Nom de l’événement'),
          const SizedBox(height: AppSpacing.sm),
          _StyledTextField(
            controller: eventNameController,
            hintText: 'Mariage Aïcha & Kofi',
            icon: Icons.celebration_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel(text: 'Logo ou image de l’événement'),
          const SizedBox(height: AppSpacing.sm),
          _EventImagePicker(
            imageAsset: eventImageAsset,
            onTap: onImageTap,
            onRemove: onImageRemove,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel(text: 'Type d’événement'),
          const SizedBox(height: AppSpacing.sm),
          _EventTypeSelector(
            value: selectedType,
            items: eventTypes,
            onChanged: onTypeChanged,
          ),
          if (selectedType == 'Autre') ...[
            const SizedBox(height: AppSpacing.md),
            _StyledTextField(
              controller: customTypeController,
              hintText: 'Saisir votre type d’événement',
              icon: Icons.edit_note_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel(text: 'Date'),
          const SizedBox(height: AppSpacing.sm),
          _DateField(date: selectedDate, onTap: onDateTap),
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel(text: 'Lieu'),
          const SizedBox(height: AppSpacing.sm),
          _StyledTextField(
            controller: placeController,
            hintText: 'Nom du lieu ou adresse',
            icon: Icons.place_outlined,
            suffix: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map_outlined, size: AppSpacing.md),
              label: const Text('Carte'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.violetRoyal,
                textStyle: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel(text: 'Description courte'),
          const SizedBox(height: AppSpacing.sm),
          _StyledTextField(
            controller: descriptionController,
            hintText: 'Ajoutez quelques mots pour présenter votre événement',
            icon: Icons.notes_rounded,
            maxLines: 4,
            minLines: 3,
            maxLength: 200,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continuer'),
                  SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward_rounded, size: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventReadyStep extends StatelessWidget {
  final String eventName;
  final String templateName;
  final VoidCallback onAddGuestsNow;
  final VoidCallback onLater;

  const _EventReadyStep({
    required this.eventName,
    required this.templateName,
    required this.onAddGuestsNow,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.beigeCremeAlt,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            'Votre événement est prêt !',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.violetRoyal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _EventSummaryLine(label: 'Événement', value: eventName),
          const SizedBox(height: AppSpacing.xs),
          _EventSummaryLine(label: 'Template', value: templateName),
          const SizedBox(height: AppSpacing.xl),
          _GradientActionButton(
            label: 'Ajouter mes invités maintenant',
            icon: Icons.people_alt_rounded,
            onPressed: onAddGuestsNow,
          ),
          const SizedBox(height: AppSpacing.md),
          _OutlineActionButton(
            label: 'Je le ferai plus tard',
            icon: Icons.schedule_rounded,
            onPressed: onLater,
          ),
        ],
      ),
    );
  }
}

class _EventSummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _EventSummaryLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.blancCasse,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.56),
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestManagementStep extends StatelessWidget {
  final List<Map<String, dynamic>> guests;
  final ValueChanged<List<Map<String, dynamic>>> onGuestsChanged;
  final VoidCallback onCreateAndSend;
  final VoidCallback onFinishWithoutSending;

  const _GuestManagementStep({
    required this.guests,
    required this.onGuestsChanged,
    required this.onCreateAndSend,
    required this.onFinishWithoutSending,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuestManagerWidget(
          initialGuests: guests,
          onGuestsChanged: onGuestsChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        _GradientActionButton(
          label: 'Créer et envoyer maintenant',
          icon: Icons.send_rounded,
          onPressed: onCreateAndSend,
        ),
        const SizedBox(height: AppSpacing.md),
        _OutlineActionButton(
          label: 'Terminer sans envoyer',
          icon: Icons.check_rounded,
          onPressed: onFinishWithoutSending,
        ),
        const SizedBox.shrink(),
        const SizedBox(
          height: 0,
          width: 0,
          child: Offstage(
            // ignore: unnecessary_const
            child: const Text('← Retour à mes événements'),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _ImportGuestsBox extends StatelessWidget {
  const _ImportGuestsBox();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(color: AppColors.violetRoyal.withValues(alpha: 0.38)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.beigeCremeBase,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_file_rounded, color: AppColors.violetRoyal, size: AppSpacing.xl),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Importer une liste Excel (.xlsx, .csv)',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ManualGuestsBlock extends StatelessWidget {
  final List<_GuestDraft> guests;
  final VoidCallback onGuestAdd;
  final ValueChanged<_GuestDraft> onGuestRemove;

  const _ManualGuestsBlock({
    required this.guests,
    required this.onGuestAdd,
    required this.onGuestRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ajout manuel (${guests.length})',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onGuestAdd,
                icon: const Icon(Icons.add_rounded, size: AppSpacing.md),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violetRoyal,
                  foregroundColor: AppColors.blancCasse,
                ),
              ),
            ],
          ),
          if (guests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final guest in guests) ...[
              _GuestTile(guest: guest, onRemove: () => onGuestRemove(guest)),
              if (guest != guests.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  final _GuestDraft guest;
  final VoidCallback onRemove;

  const _GuestTile({
    required this.guest,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.beigeCremeAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              guest.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SendChannelsBlock extends StatelessWidget {
  final bool sendViaWhatsApp;
  final bool sendViaEmail;
  final ValueChanged<bool> onWhatsAppChanged;
  final ValueChanged<bool> onEmailChanged;

  const _SendChannelsBlock({
    required this.sendViaWhatsApp,
    required this.sendViaEmail,
    required this.onWhatsAppChanged,
    required this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Envoyer via',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            color: AppColors.noirDoux,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SendChannelChip(
              label: 'WhatsApp',
              color: AppColors.success,
              selected: sendViaWhatsApp,
              onSelected: onWhatsAppChanged,
            ),
            _SendChannelChip(
              label: 'Email',
              color: AppColors.info,
              selected: sendViaEmail,
              onSelected: onEmailChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _SendChannelChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _SendChannelChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.12),
      backgroundColor: AppColors.noirDoux.withValues(alpha: 0.06),
      checkmarkColor: color,
      side: BorderSide(color: selected ? color : AppColors.noirDoux.withValues(alpha: 0.10)),
      labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
        color: selected ? color : AppColors.noirDoux,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ignore: unused_element
class _InvitationInfoCard extends StatelessWidget {
  const _InvitationInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.beigeCremeAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.orAfricain, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Vos invitations seront prêtes à être envoyées sur WhatsApp dès la création.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.noirDoux),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGuestSheet extends StatefulWidget {
  const _AddGuestSheet();

  @override
  State<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends State<_AddGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter un invité',
                style: AppTypography.textTheme.displaySmall?.copyWith(
                  color: AppColors.noirDoux,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetTextField(
                controller: _nameController,
                label: 'Nom complet',
                icon: Icons.person_outline_rounded,
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              _SheetTextField(
                controller: _phoneController,
                label: 'Numéro WhatsApp',
                icon: Icons.phone_outlined,
                prefixText: '+',
                keyboardType: TextInputType.phone,
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              _SheetTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                helperText: 'Pour envoi par email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xl),
              _GradientActionButton(
                label: "Ajouter l'invité",
                icon: Icons.person_add_alt_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      _GuestDraft(
        name: _nameController.text.trim(),
        phone: '+${_phoneController.text.trim()}',
        email: _emailController.text.trim(),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? prefixText;
  final String? helperText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.prefixText,
    this.helperText,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: AppTypography.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: AppColors.violetRoyal),
        prefixText: prefixText,
        fillColor: AppColors.beigeCremeAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
    );
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
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedRoundedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.lg),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashWidth = 8.0;
      const dashGap = 6.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GuestDraft {
  final String name;
  final String phone;
  final String email;

  const _GuestDraft({
    required this.name,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

class _TemplateChoiceStep extends StatelessWidget {
  final String accountType;
  final String selectedEventType;
  final String selectedFilter;
  final Map<String, dynamic>? selectedTemplate;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<Map<String, dynamic>> onTemplateSelected;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _TemplateChoiceStep({
    required this.accountType,
    required this.selectedEventType,
    required this.selectedFilter,
    required this.selectedTemplate,
    required this.onFilterChanged,
    required this.onTemplateSelected,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTypeKey = _eventTypeKey(selectedEventType);
    final templates = mockTemplates.where((template) {
      final tier = template['tier'] as String;
      final type = template['type'] as String;

      if (type != selectedTypeKey) {
        return false;
      }
      if (selectedFilter == 'gratuits' && tier != 'gratuit') {
        return false;
      }
      if (selectedFilter == 'premium' && tier == 'gratuit') {
        return false;
      }
      return true;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
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
                  selected: selectedFilter == 'tous',
                  onTap: () => onFilterChanged('tous'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _TemplateFilterChip(
                  label: 'Gratuits',
                  selected: selectedFilter == 'gratuits',
                  onTap: () => onFilterChanged('gratuits'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _TemplateFilterChip(
                  label: 'Premium',
                  selected: selectedFilter == 'premium',
                  onTap: () => onFilterChanged('premium'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final template in templates) ...[
            _TemplateCard(
              template: template,
              locked: !_canAccessTemplate(accountType, template['tier'] as String),
              selected: selectedTemplate?['id'] == template['id'],
              onTap: () => onTemplateSelected(template),
            ),
            if (template != templates.last) const SizedBox(height: AppSpacing.md),
          ],
          if (templates.isEmpty)
            Text(
              'Aucun template disponible pour ce filtre.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.noirDoux.withValues(alpha: 0.70),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: AppSpacing.lg),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.violetRoyal,
                    side: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.28)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Suivant'),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward_rounded, size: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      shape: const StadiumBorder(),
      selectedColor: AppColors.violetRoyal.withValues(alpha: 0.12),
      backgroundColor: AppColors.beigeCremeAlt,
      labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
        color: selected ? AppColors.violetRoyal : AppColors.noirDoux,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? AppColors.violetRoyal : AppColors.noirDoux.withValues(alpha: 0.10),
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
    final tier = template['tier'] as String;
    final isFree = tier == 'gratuit';
    final badgeColor = isFree ? AppColors.success : AppColors.violetRoyal;

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppDecorations.cardDecoration.copyWith(
              color: AppColors.beigeCremeAlt,
              border: Border.all(
                color: selected ? AppColors.violetRoyal : badgeColor.withValues(alpha: 0.16),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  color: AppColors.beigeCremeBase,
                  child: Image.asset(
                    template['asset'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.violetRoyal.withValues(alpha: 0.42),
                          size: AppSpacing.xl,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.noirDoux,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          _TemplateTierBadge(tier: tier),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.violetRoyal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              minimumSize: const Size(0, AppSpacing.xl),
                            ),
                            child: const Text('Aperçu'),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.violetRoyal, size: AppSpacing.lg),
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
                color: AppColors.noirDoux.withValues(alpha: 0.48),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.blancCasse,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.violetRoyal, size: AppSpacing.md),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Passer en Premium',
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

/*
                  children: [
                    Text(
                      template['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.noirDoux,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _TemplateTierBadge(tier: tier),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.violetRoyal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            minimumSize: const Size(0, AppSpacing.xl),
                          ),
                          child: const Text('Aperçu'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                color: AppColors.noirDoux.withValues(alpha: 0.48),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.blancCasse,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.violetRoyal, size: AppSpacing.md),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Passer en Premium',
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

*/
class _TemplateTierBadge extends StatelessWidget {
  final String tier;

  const _TemplateTierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final isFree = tier == 'gratuit';
    final color = isFree ? AppColors.success : AppColors.violetRoyal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFree ? Icons.check_circle_rounded : Icons.workspace_premium_rounded, color: color, size: AppSpacing.md),
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

String _eventTypeKey(String value) {
  switch (value.toLowerCase()) {
    case 'mariage':
      return 'mariage';
    case 'anniversaire':
      return 'anniversaire';
    case 'baptême':
    case 'baptÃªme':
      return 'bapteme';
    case 'soirée vip':
    case 'soirÃ©e vip':
      return 'soiree_vip';
    default:
      return value.toLowerCase().replaceAll(' ', '_');
  }
}

bool _canAccessTemplate(String accountType, String tier) {
  final account = accountType.toLowerCase();
  if (tier == 'gratuit') {
    return true;
  }
  if (account == 'premium') {
    return true;
  }
  if (account == 'standard') {
    return tier == 'premium_standard';
  }
  return false;
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.textTheme.labelLarge?.copyWith(
        color: AppColors.noirDoux,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EventImagePicker extends StatelessWidget {
  final String? imageAsset;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _EventImagePicker({
    required this.imageAsset,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageAsset != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.beigeCremeAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xxl + AppSpacing.md,
            height: AppSpacing.xxl + AppSpacing.md,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blancCasse,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(imageAsset!, fit: BoxFit.contain),
                  )
                : Icon(Icons.image_outlined, color: AppColors.violetRoyal, size: AppSpacing.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasImage ? 'Image choisie' : 'Aucune image choisie',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasImage ? 'Aperçu disponible pour votre événement.' : 'Ajoutez un logo ou une image principale.',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.upload_rounded, size: AppSpacing.md),
                      label: Text(hasImage ? 'Remplacer' : 'Choisir une image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.violetRoyal,
                        side: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.28)),
                      ),
                    ),
                    if (hasImage)
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: AppSpacing.md),
                        label: const Text('Retirer'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Widget? suffix;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTypography.textTheme.bodyLarge,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.violetRoyal),
        suffixIcon: suffix,
        hintText: hintText,
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.noirDoux.withValues(alpha: 0.42),
        ),
        fillColor: AppColors.beigeCremeAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
    );
  }
}

class _EventTypeSelector extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _EventTypeSelector({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: AppTypography.textTheme.bodyLarge),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.violetRoyal),
        fillColor: AppColors.beigeCremeAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.violetRoyal),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          fillColor: AppColors.beigeCremeAlt,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.24)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
          ),
        ),
        child: Text(
          date == null ? 'Choisir une date' : _formatDate(date!),
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: date == null ? AppColors.noirDoux.withValues(alpha: 0.42) : AppColors.noirDoux,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
