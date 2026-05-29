import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_nav_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
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

  String _selectedType = _eventTypes.first;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _eventNameController.dispose();
    _customTypeController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: SafeArea(
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
                  const _CreateEventTopBar(),
                  const SizedBox(height: AppSpacing.xl),
                  const _CreateEventHero(),
                  const SizedBox(height: AppSpacing.xl),
                  _BaseInfoCard(
                    eventNameController: _eventNameController,
                    selectedType: _selectedType,
                    eventTypes: _eventTypes,
                    customTypeController: _customTypeController,
                    selectedDate: _selectedDate,
                    placeController: _placeController,
                    onTypeChanged: (value) => setState(() => _selectedType = value),
                    onDateTap: _pickDate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _CreateEventNavBar(),
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
}

class _CreateEventTopBar extends StatelessWidget {
  const _CreateEventTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.logoFull,
          height: AppSpacing.xxl,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        const _AccountStatusPill(),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.violetRoyal,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.blancCasse,
            side: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.12)),
          ),
        ),
      ],
    );
  }
}

class _AccountStatusPill extends StatelessWidget {
  const _AccountStatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.beigeCremeBase,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.orAfricain),
        boxShadow: [
          BoxShadow(
            color: AppColors.orAfricain.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.noirDoux, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Premium',
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateEventHero extends StatelessWidget {
  const _CreateEventHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              AppAssets.mascotCreateEvent,
              height: AppSpacing.xxl + AppSpacing.xl,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const _StepIndicator(currentStep: 1),
      ],
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
  final String selectedType;
  final List<String> eventTypes;
  final DateTime? selectedDate;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onDateTap;

  const _BaseInfoCard({
    required this.eventNameController,
    required this.customTypeController,
    required this.placeController,
    required this.selectedType,
    required this.eventTypes,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
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

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Widget? suffix;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTypography.textTheme.bodyLarge,
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

class _CreateEventNavBar extends StatelessWidget {
  const _CreateEventNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      backgroundColor: AppColors.blancCasse,
      elevation: 0,
      selectedItemColor: AppColors.violetRoyal,
      unselectedItemColor: AppColors.noirDoux.withValues(alpha: 0.72),
      selectedLabelStyle: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: AppTypography.textTheme.bodySmall,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(AppNavIcons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(AppNavIcons.events), label: 'Événements'),
        BottomNavigationBarItem(icon: Icon(AppNavIcons.guests), label: 'Invités'),
        BottomNavigationBarItem(icon: Icon(AppNavIcons.profile), label: 'Profil'),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
    );
  }
}
