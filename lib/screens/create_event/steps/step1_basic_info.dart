import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_schema.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/event_service.dart';
import '../../../services/storage_service.dart';
import '../create_event_utils.dart';

/// Étape 1 — Informations de base et création de l'événement.
class Step1BasicInfo extends StatefulWidget {
  final void Function(String eventId, String eventType, Map<String, dynamic> customFields) onStepCompleted;

  const Step1BasicInfo({required this.onStepCompleted, super.key});

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _eventService = EventService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customField1LabelController = TextEditingController();
  final _customField1ValueController = TextEditingController();
  final _customField2LabelController = TextEditingController();
  final _customField2ValueController = TextEditingController();
  final _guestQuotaController = TextEditingController();

  String _selectedTypeLabel = kEventTypeDisplayValues.first;
  String _selectedSendChannel = kDefaultSendChannel;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Uint8List? _logoBytes;
  String? _logoFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customTypeController.dispose();
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
      setState(() => _selectedTime = picked);
    }
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
      _logoBytes = bytes;
      _logoFileName = file.name;
    });
  }

  Future<void> _showQuotaDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limite atteinte'),
        content: const Text(
          'Vous avez atteint le nombre maximum d’événements pour votre offre actuelle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('Voir les offres'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    final place = _placeController.text.trim();
    final eventTypeKey = eventTypeDbKey(_selectedTypeLabel);
    final selectedDate = _selectedDate;
    final selectedTime = _selectedTime;

    if (name.isEmpty) {
      showCreateEventErrorSnackBar(
        context,
        'Le nom de l’événement est obligatoire.',
      );
      return;
    }
    if (eventTypeKey.isEmpty) {
      showCreateEventErrorSnackBar(
        context,
        'Le type d’événement est obligatoire.',
      );
      return;
    }
    if (selectedDate == null) {
      showCreateEventErrorSnackBar(context, 'Veuillez choisir une date');
      return;
    }
    if (selectedTime == null) {
      showCreateEventErrorSnackBar(context, 'Veuillez choisir une heure');
      return;
    }
    if (place.isEmpty) {
      showCreateEventErrorSnackBar(
        context,
        'Le lieu de l’événement est obligatoire.',
      );
      return;
    }
    if (eventTypeKey == 'autre' && _customTypeController.text.trim().isEmpty) {
      showCreateEventErrorSnackBar(
        context,
        'Veuillez préciser votre type d’événement.',
      );
      return;
    }

    final customField1Label = _customField1LabelController.text.trim();
    final customField1Value = _customField1ValueController.text.trim();
    final customField2Label = _customField2LabelController.text.trim();
    final customField2Value = _customField2ValueController.text.trim();

    if ((customField1Label.isNotEmpty && customField1Value.isEmpty) ||
        (customField1Label.isEmpty && customField1Value.isNotEmpty)) {
      showCreateEventErrorSnackBar(
        context,
        'Les champs “Informations supplémentaires 1” doivent être remplis ensemble.',
      );
      return;
    }
    if ((customField2Label.isNotEmpty && customField2Value.isEmpty) ||
        (customField2Label.isEmpty && customField2Value.isNotEmpty)) {
      showCreateEventErrorSnackBar(
        context,
        'Les champs “Informations supplémentaires 2” doivent être remplis ensemble.',
      );
      return;
    }

    int? guestQuota;
    final quotaText = _guestQuotaController.text.trim();
    if (quotaText.isNotEmpty) {
      guestQuota = int.tryParse(quotaText);
      if (guestQuota == null || guestQuota < 0) {
        showCreateEventErrorSnackBar(
          context,
          'Le quota invité doit être un nombre entier positif.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final quota = await _eventService.checkEventCreationQuota();
      if (!(quota['canCreate'] as bool)) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await _showQuotaDialog();
        return;
      }

      final eventDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final metadata = {
        'customField1Label': customField1Label.isEmpty ? null : customField1Label,
        'customField1Value': customField1Value.isEmpty ? null : customField1Value,
        'customField2Label': customField2Label.isEmpty ? null : customField2Label,
        'customField2Value': customField2Value.isEmpty ? null : customField2Value,
      };

      final eventId = await _eventService.createEvent(
        name: name,
        eventType: eventTypeKey,
        customType: eventTypeKey == 'autre'
            ? _customTypeController.text.trim()
            : null,
        eventDate: eventDateTime,
        place: place,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sendChannel: _selectedSendChannel,
        guestQuota: guestQuota,
        metadata: metadata,
      );

      if (_logoBytes != null && _logoFileName != null) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final logoUrl = await _storageService.uploadEventLogo(
          userId: userId,
          eventId: eventId,
          fileBytes: _logoBytes!,
          fileName: _logoFileName!,
        );
        if (logoUrl != null) {
          await _eventService.updateEventLogo(
            eventId: eventId,
            logoUrl: logoUrl,
          );
        }
      }

      if (!mounted) return;
      widget.onStepCompleted(eventId, eventTypeKey, {
        'customField1Label': customField1Label,
        'customField1Value': customField1Value,
        'customField2Label': customField2Label,
        'customField2Value': customField2Value,
      });
    } catch (e) {
      if (!mounted) return;
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              _fieldLabel('Nom de l’événement'),
              const SizedBox(height: AppSpacing.sm),
              _styledField(
                controller: _nameController,
                hint: 'Mariage Aïcha & Kofi',
                icon: Icons.celebration_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel('Logo ou image de l’événement'),
              const SizedBox(height: AppSpacing.sm),
              _LogoPicker(
                logoBytes: _logoBytes,
                onPick: _pickLogo,
                onRemove: () => setState(() {
                  _logoBytes = null;
                  _logoFileName = null;
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel('Type d’événement'),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedTypeLabel,
                decoration: _inputDecoration(Icons.category_outlined),
                items: kEventTypeDisplayValues
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedTypeLabel = value);
                },
              ),
              if (_selectedTypeLabel == 'Autre') ...[
                const SizedBox(height: AppSpacing.md),
                _styledField(
                  controller: _customTypeController,
                  hint: 'Saisir votre type d’événement',
                  icon: Icons.edit_note_rounded,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Date'),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: _inputDecoration(
                              Icons.calendar_today_outlined,
                            ),
                            child: Text(
                              _selectedDate != null
                                  ? DateFormat(
                                      'dd MMMM yyyy',
                                      'fr',
                                    ).format(_selectedDate!)
                                  : 'Choisir une date',
                              style: AppTypography.textTheme.bodyLarge
                                  ?.copyWith(
                                    color: _selectedDate != null
                                        ? AppColors.noirDoux
                                        : AppColors.noirDoux.withValues(
                                            alpha: 0.45,
                                          ),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Heure'),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: _inputDecoration(
                              Icons.schedule_rounded,
                            ),
                            child: Text(
                              _selectedTime != null
                                  ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Choisir une heure',
                              style: AppTypography.textTheme.bodyLarge
                                  ?.copyWith(
                                    color: _selectedTime != null
                                        ? AppColors.noirDoux
                                        : AppColors.noirDoux.withValues(
                                            alpha: 0.45,
                                          ),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel('Lieu'),
              const SizedBox(height: AppSpacing.sm),
              _styledField(
                controller: _placeController,
                hint: 'Nom du lieu ou adresse',
                icon: Icons.place_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel('Description courte'),
              const SizedBox(height: AppSpacing.sm),
              _styledField(
                controller: _descriptionController,
                hint: 'Ajoutez quelques mots pour présenter votre événement',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Options de diffusion'),
              const SizedBox(height: AppSpacing.sm),
              _sendChannelChips(),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel('Quota invités (optionnel)'),
              const SizedBox(height: AppSpacing.sm),
              _styledField(
                controller: _guestQuotaController,
                hint: 'Ex: 120',
                icon: Icons.people_outline,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Informations supplémentaires (optionnel)'),
              const SizedBox(height: AppSpacing.sm),
              _customInfoCard(),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violetRoyal,
                    foregroundColor: AppColors.blancCasse,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Créer l\'événement'),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.check_rounded, size: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (_isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.blancCasse.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.violetRoyal),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppTypography.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.textTheme.titleMedium?.copyWith(
        color: AppColors.noirDoux,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _sendChannelChips() {
    final options = <String, String>{
      'whatsapp': 'WhatsApp',
      'email': 'Email',
      'les_deux': 'Les deux',
    };

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.entries.map((entry) {
        final selected = _selectedSendChannel == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => setState(() => _selectedSendChannel = entry.key),
          selectedColor: AppColors.violetRoyal.withValues(alpha: 0.14),
          labelStyle: AppTypography.textTheme.bodyMedium?.copyWith(
            color: selected ? AppColors.violetRoyal : AppColors.noirDoux,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: selected ? AppColors.violetRoyal : AppColors.orAfricain.withValues(alpha: 0.22),
          ),
          backgroundColor: AppColors.beigeCremeAlt,
        );
      }).toList(),
    );
  }

  Widget _customInfoCard() {
    return Column(
      children: [
        _styledField(
          controller: _customField1LabelController,
          hint: 'Ex: Thème, Dress code, Âge...',
          icon: Icons.label_outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        _styledField(
          controller: _customField1ValueController,
          hint: 'Ex: Soirée blanche, Black tie, 30 ans...',
          icon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _styledField(
          controller: _customField2LabelController,
          hint: 'Ex: Intervenant, RSVP avant le...',
          icon: Icons.label_outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        _styledField(
          controller: _customField2ValueController,
          hint: 'Ex: Dr. Amina Koné, 10 juin 2025...',
          icon: Icons.edit_note_rounded,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.violetRoyal),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTypography.textTheme.bodyLarge,
      decoration: _inputDecoration(icon).copyWith(hintText: hint),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  final Uint8List? logoBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _LogoPicker({
    required this.logoBytes,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.beigeCremeAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.violetRoyal.withValues(alpha: 0.2),
          ),
        ),
        child: logoBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.memory(logoBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.violetRoyal,
                    size: 36,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ajouter un logo',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
