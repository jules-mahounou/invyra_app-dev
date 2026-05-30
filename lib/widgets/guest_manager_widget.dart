import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class GuestManagerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> initialGuests;
  final Function(List<Map<String, dynamic>>) onGuestsChanged;

  const GuestManagerWidget({
    required this.initialGuests,
    required this.onGuestsChanged,
    super.key,
  });

  @override
  State<GuestManagerWidget> createState() => _GuestManagerWidgetState();
}

class _GuestManagerWidgetState extends State<GuestManagerWidget> {
  late List<Map<String, dynamic>> _guests;
  bool _sendViaWhatsApp = true;
  bool _sendViaEmail = false;

  @override
  void initState() {
    super.initState();
    _guests = widget.initialGuests.map((guest) => Map<String, dynamic>.from(guest)).toList();
  }

  @override
  void didUpdateWidget(covariant GuestManagerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGuests != widget.initialGuests) {
      _guests = widget.initialGuests.map((guest) => Map<String, dynamic>.from(guest)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ImportGuestsBox(),
        const SizedBox(height: AppSpacing.lg),
        _ManualGuestsBlock(
          guests: _guests,
          onGuestAdd: _showAddGuestSheet,
          onGuestRemove: _removeGuest,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SendChannelsBlock(
          sendViaWhatsApp: _sendViaWhatsApp,
          sendViaEmail: _sendViaEmail,
          onWhatsAppChanged: (value) => setState(() => _sendViaWhatsApp = value),
          onEmailChanged: (value) => setState(() => _sendViaEmail = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _InvitationInfoCard(),
      ],
    );
  }

  Future<void> _showAddGuestSheet() async {
    final guest = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => const _AddGuestSheet(),
    );

    if (guest == null) {
      return;
    }

    setState(() => _guests.add(guest));
    widget.onGuestsChanged(List<Map<String, dynamic>>.from(_guests));
  }

  void _removeGuest(Map<String, dynamic> guest) {
    setState(() => _guests.remove(guest));
    widget.onGuestsChanged(List<Map<String, dynamic>>.from(_guests));
  }
}

class _ImportGuestsBox extends StatelessWidget {
  const _ImportGuestsBox();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(color: AppColors.violetRoyal.withValues(alpha: 0.38)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
      ),
    );
  }
}

class _ManualGuestsBlock extends StatelessWidget {
  final List<Map<String, dynamic>> guests;
  final VoidCallback onGuestAdd;
  final ValueChanged<Map<String, dynamic>> onGuestRemove;

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
  final Map<String, dynamic> guest;
  final VoidCallback onRemove;

  const _GuestTile({
    required this.guest,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = (guest['name'] ?? guest['nom'] ?? 'Invité') as String;
    final phone = (guest['phone'] ?? guest['whatsapp'] ?? guest['telephone'] ?? '') as String;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ],
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
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'phone': '+${_phoneController.text.trim()}',
      'email': _emailController.text.trim(),
    });
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
