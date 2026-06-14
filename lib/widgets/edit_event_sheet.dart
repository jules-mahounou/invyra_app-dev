import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../models/event_model.dart';
import '../screens/create_event/steps/step2_template.dart';
import '../services/event_service.dart';
import '../services/storage_service.dart';

class EditEventSheet extends StatefulWidget {
  final EventModel event;
  final int invitationsSent;
  final String accountType;

  const EditEventSheet({
    required this.event,
    this.invitationsSent = 0,
    this.accountType = 'gratuit',
    super.key,
  });

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  final _eventService = EventService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _placeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customField1LabelController;
  late final TextEditingController _customField1ValueController;
  late final TextEditingController _customField2LabelController;
  late final TextEditingController _customField2ValueController;
  late final TextEditingController _guestQuotaController;
  late DateTime _initialDateTime;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedSendChannel;

  // Image
  Uint8List? _newLogoBytes;
  String? _newLogoFileName;
  bool _removeExistingLogo = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialDateTime = widget.event.eventDate ?? DateTime.now();
    _selectedDate = _initialDateTime;
    _selectedTime = TimeOfDay(
      hour: _initialDateTime.hour,
      minute: _initialDateTime.minute,
    );
    _nameController = TextEditingController(text: widget.event.name);
    _placeController = TextEditingController(text: widget.event.place);
    _descriptionController = TextEditingController(text: widget.event.description);
    _customField1LabelController = TextEditingController(text: widget.event.customField1Label ?? '');
    _customField1ValueController = TextEditingController(text: widget.event.customField1Value ?? '');
    _customField2LabelController = TextEditingController(text: widget.event.customField2Label ?? '');
    _customField2ValueController = TextEditingController(text: widget.event.customField2Value ?? '');
    _guestQuotaController = TextEditingController(text: widget.event.guestQuota?.toString() ?? '');
    _selectedSendChannel = widget.event.sendChannel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    _customField1LabelController.dispose();
    _customField1ValueController.dispose();
    _customField2LabelController.dispose();
    _customField2ValueController.dispose();
    _guestQuotaController.dispose();
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

  Future<void> _pickLogo() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _newLogoBytes = bytes;
      _newLogoFileName = file.name;
      _removeExistingLogo = false;
    });
  }

  void _openTemplateSelection() {
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
              'Changer de template',
              style: AppTypography.textTheme.displaySmall?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Step2Template(
              eventId: widget.event.id,
              eventType: widget.event.eventType,
              accountType: widget.accountType,  // ← vrai account type
              onStepCompleted: (_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Template mis à jour'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Fermer aussi le sheet d'édition et recharger
                Navigator.of(context).pop(true);
              },
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final customField1Label = _customField1LabelController.text.trim();
    final customField1Value = _customField1ValueController.text.trim();
    final customField2Label = _customField2LabelController.text.trim();
    final customField2Value = _customField2ValueController.text.trim();

    if ((customField1Label.isNotEmpty && customField1Value.isEmpty) ||
        (customField1Label.isEmpty && customField1Value.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les champs 1 doivent être remplis ensemble.')),
      );
      return;
    }
    if ((customField2Label.isNotEmpty && customField2Value.isEmpty) ||
        (customField2Label.isEmpty && customField2Value.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les champs 2 doivent être remplis ensemble.')),
      );
      return;
    }

    int? guestQuota;
    final quotaText = _guestQuotaController.text.trim();
    if (quotaText.isNotEmpty) {
      guestQuota = int.tryParse(quotaText);
      if (guestQuota == null || guestQuota < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le quota doit être un nombre entier positif.')),
        );
        return;
      }
    }

    final newDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    setState(() => _isSaving = true);
    try {
      // 1. Gérer le logo si changé
      String? newLogoUrl;
      if (_newLogoBytes != null && _newLogoFileName != null) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        newLogoUrl = await _storageService.uploadEventLogo(
          userId: userId,
          eventId: widget.event.id,
          fileBytes: _newLogoBytes!,
          fileName: _newLogoFileName!,
        );
      } else if (_removeExistingLogo) {
        newLogoUrl = '';
      }

      // 2. Mettre à jour l'événement
      await _eventService.updateEvent(
        eventId: widget.event.id,
        name: name == widget.event.name ? null : name,
        eventDate: newDateTime.isAtSameMomentAs(_initialDateTime) ? null : newDateTime,
        place: _placeController.text.trim() == widget.event.place ? null : _placeController.text.trim(),
        description: _descriptionController.text.trim() == widget.event.description ? null : _descriptionController.text.trim(),
        sendChannel: _selectedSendChannel,
        guestQuota: guestQuota,
        logoUrl: newLogoUrl,
        metadata: {
          'customField1Label': customField1Label.isEmpty ? null : customField1Label,
          'customField1Value': customField1Value.isEmpty ? null : customField1Value,
          'customField2Label': customField2Label.isEmpty ? null : customField2Label,
          'customField2Value': customField2Value.isEmpty ? null : customField2Value,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.noirDoux.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  "Modifier l'événement",
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // IMAGE / LOGO
                _sectionLabel('Image de l\'événement'),
                const SizedBox(height: AppSpacing.sm),
                _LogoEditor(
                  existingLogoUrl: _removeExistingLogo ? null : widget.event.logoUrl,
                  newLogoBytes: _newLogoBytes,
                  onPick: _pickLogo,
                  onRemove: () => setState(() {
                    _newLogoBytes = null;
                    _newLogoFileName = null;
                    _removeExistingLogo = true;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),

                // TEMPLATE — masqué si des invitations ont déjà été envoyées
                if (widget.invitationsSent == 0) ...[
                  _sectionLabel('Template d\'invitation'),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _openTemplateSelection,
                    icon: const Icon(Icons.palette_outlined),
                    label: Text(
                      widget.event.templateId != null
                          ? 'Changer de template'
                          : 'Choisir un template',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.violetRoyal,
                      side: const BorderSide(color: AppColors.violetRoyal),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ] else ...[
                  // Template verrouillé — afficher un message informatif
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.orAfricain.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.orAfricain, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Le template est verrouillé car des billets ont déjà été envoyés.',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.orAfricain,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _SheetTextField(controller: _nameController, label: 'Nom', icon: Icons.celebration_outlined),
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
                        value: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SheetTextField(controller: _placeController, label: 'Lieu', icon: Icons.place_outlined),
                const SizedBox(height: AppSpacing.md),
                _SheetTextField(controller: _descriptionController, label: 'Description', icon: Icons.notes_rounded, maxLines: 4),
                const SizedBox(height: AppSpacing.md),
                _sectionLabel('Canal d\'envoi'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ['whatsapp', 'email', 'les_deux'].map((channel) {
                    final label = channel == 'whatsapp' ? 'WhatsApp' : channel == 'email' ? 'Email' : 'Les deux';
                    final selected = _selectedSendChannel == channel;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSendChannel = channel),
                      selectedColor: AppColors.violetRoyal.withValues(alpha: 0.14),
                      backgroundColor: AppColors.beigeCremeAlt,
                      side: BorderSide(color: selected ? AppColors.violetRoyal : AppColors.orAfricain.withValues(alpha: 0.22)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                _SheetTextField(
                  controller: _guestQuotaController,
                  label: 'Quota invités (optionnel)',
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.beigeCremeAlt.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informations supplémentaires (optionnel)',
                        style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.noirDoux, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.md),
                      _SheetTextField(controller: _customField1LabelController, label: 'Label 1', icon: Icons.label_outline),
                      const SizedBox(height: AppSpacing.sm),
                      _SheetTextField(controller: _customField1ValueController, label: 'Valeur 1', icon: Icons.edit_note_rounded),
                      const SizedBox(height: AppSpacing.md),
                      _SheetTextField(controller: _customField2LabelController, label: 'Label 2', icon: Icons.label_outline),
                      const SizedBox(height: AppSpacing.sm),
                      _SheetTextField(controller: _customField2ValueController, label: 'Valeur 2', icon: Icons.edit_note_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _GradientActionButton(
                  label: 'Enregistrer les modifications',
                  icon: Icons.save_outlined,
                  onPressed: _isSaving ? null : _save,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.blancCasse.withValues(alpha: 0.55),
              child: const Center(child: CircularProgressIndicator(color: AppColors.violetRoyal)),
            ),
          ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.noirDoux,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─── Widgets privés ──────────────────────────────────────────────────────────

class _LogoEditor extends StatelessWidget {
  final String? existingLogoUrl;
  final Uint8List? newLogoBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _LogoEditor({
    required this.existingLogoUrl,
    required this.newLogoBytes,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasNewImage = newLogoBytes != null;
    final hasExistingImage = existingLogoUrl != null && existingLogoUrl!.isNotEmpty;
    final showImage = hasNewImage || hasExistingImage;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.beigeCremeAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.2)),
        ),
        child: showImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: hasNewImage
                        ? Image.memory(newLogoBytes!, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: existingLogoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                  ),
                  // Overlay boutons
                  Positioned(
                    top: 8, right: 8,
                    child: Row(
                      children: [
                        _ImageActionButton(
                          icon: Icons.edit_rounded,
                          onTap: onPick,
                          color: AppColors.violetRoyal,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _ImageActionButton(
                          icon: Icons.delete_rounded,
                          onTap: onRemove,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: AppColors.violetRoyal, size: 36),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ajouter une image',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'Appuyez pour choisir',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ImageActionButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.blancCasse.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
      borderSide: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.24)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
    ),
  );
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _GradientActionButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : AppColors.gradientPrincipal,
          color: onPressed == null ? AppColors.noirDoux.withValues(alpha: 0.18) : null,
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
