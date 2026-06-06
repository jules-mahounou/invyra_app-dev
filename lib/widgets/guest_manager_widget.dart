import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/import_service.dart';
import '../services/guest_service.dart';
import '../core/services/edge_function_service.dart';
import '../screens/create_event/create_event_utils.dart';

class GuestManagerWidget extends StatefulWidget {
  final String eventId;
  final VoidCallback? onChanged;

  const GuestManagerWidget({required this.eventId, this.onChanged, super.key});

  @override
  State<GuestManagerWidget> createState() => GuestManagerWidgetState();
}

class GuestManagerWidgetState extends State<GuestManagerWidget> {
  final _guestService = GuestService();
  final _importService = ImportService();

  List<Map<String, dynamic>> _guests = [];
  // Map pour stocker les liens d'invitations générés : { guestId: invitationUrl }
  Map<String, String> _generatedLinks = {};
  // Compteur local du nombre d'envois WhatsApp effectués dans cette session
  int _sentCount = 0;
  
  bool _sendViaWhatsApp = true;
  bool _sendViaEmail = false;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  Future<void> _loadGuests() async {
    setState(() => _isLoading = true);
    try {
      final guests = await _guestService.getGuestsByEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        _guests = guests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Appelé par Step3Guests pour générer les billets sur Supabase
  Future<void> triggerSendInvitations() async {
    if (_guests.isEmpty) {
      throw Exception('Veuillez ajouter au moins un invité avant de générer les billets.');
    }

    setState(() => _isBusy = true);
    try {
      // 1. On récupère la liste de tous les IDs d'invités
      final List<String> guestIds = _guests
          .map((g) => g['id']?.toString())
          .whereType<String>()
          .toList();

      // 2. On appelle ton Edge Function
      final List<InvitationResult> results = await _guestService.sendInvitations(
        eventId: widget.eventId,
        guestIds: guestIds,
      );

      // 3. On stocke les URLs générées localement pour l'affichage des boutons de partage
      if (mounted) {
        setState(() {
          _generatedLinks = {
            for (var res in results) res.guestId: res.invitationUrl
          };
        });
      }
    } on Exception catch (_) { 
      rethrow;
    } finally { // Corrigé ici : finally avec deux 'l'
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _shareOnWhatsApp(String phone, String guestName, String url) async {
    // Premier envoi → avertir que le template sera verrouillé
    final isFirstSend = _generatedLinks.isNotEmpty && _sentCount == 0;
    if (isFirstSend) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer l\'envoi'),
          content: const Text(
            'Une fois le premier billet envoyé, le template de votre invitation '
            'sera définitivement verrouillé et ne pourra plus être modifié.\n\n'
            'Assurez-vous d\'avoir bien vérifié l\'aperçu avant de continuer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Envoyer quand même'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Nettoyage : on garde seulement chiffres et +, puis on normalise le préfixe
    var cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Si le numéro commence par 00, remplacer par +
    if (cleanPhone.startsWith('00')) {
      cleanPhone = '+${cleanPhone.substring(2)}';
    }
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro WhatsApp manquant pour cet invité.')),
        );
      }
      return;
    }

    final message = Uri.encodeComponent(
      'Bonjour $guestName ! Vous êtes invité(e) à notre événement. '
      'Voici votre billet d\'accès unique à présenter à l\'entrée : $url',
    );

    // wa.me est plus fiable que le scheme whatsapp:// sur tous les appareils
    final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$message');

    try {
      await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _sentCount++);
    } catch (_) {
      try {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        if (mounted) setState(() => _sentCount++);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp. Vérifiez que l\'application est installée.')),
        );
      }
    }
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

    if (guest == null) return;

    setState(() => _isBusy = true);
    try {
      final created = await _guestService.addGuest(
        eventId: widget.eventId,
        fullName: guest['name'] as String,
        phone: guest['phone'] as String?,
        email: guest['email'] as String?,
      );
      if (!mounted) return;
      setState(() {
        _guests.add(created);
        _isBusy = false;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _removeGuest(Map<String, dynamic> guest) async {
    final guestId = guest['id'] as String?;
    if (guestId == null) {
      setState(() => _guests.remove(guest));
      return;
    }

    setState(() => _isBusy = true);
    try {
      await _guestService.deleteGuest(guestId);
      if (!mounted) return;
      setState(() {
        _guests.removeWhere((g) => g['id'] == guestId);
        _isBusy = false;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _importGuests() async {
    List<Map<String, dynamic>>? guests;
    try {
      guests = await _importService.pickAndParseFile();
    } catch (_) {
      if (!mounted) return;
      showCreateEventErrorSnackBar(
        context,
        'Format non reconnu. Utilisez .xlsx ou .csv',
      );
      return;
    }
    if (guests == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${guests!.length} invités trouvés'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final guest in guests.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      guest['full_name'] as String,
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                  ),
                if (guests.length > 5)
                  Text(
                    'et ${guests.length - 5} autres...',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.64),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          _DialogGradientButton(
            label: 'Importer',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || guests.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final imported = <Map<String, dynamic>>[];
      for (final guest in guests) {
        final created = await _guestService.addGuest(
          eventId: widget.eventId,
          fullName: guest['full_name'] as String,
          phone: guest['phone'] as String?,
          email: guest['email'] as String?,
          importSource: 'excel',
        );
        imported.add(created);
      }
      if (!mounted) return;
      setState(() {
        _guests.addAll(imported);
        _isBusy = false;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.violetRoyal),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImportGuestsBox(onTap: _importGuests),
            const SizedBox(height: AppSpacing.lg),
            _ManualGuestsBlock(
              guests: _guests,
              generatedLinks: _generatedLinks,
              onGuestAdd: _showAddGuestSheet,
              onGuestRemove: _removeGuest,
              onShareWhatsApp: _shareOnWhatsApp,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SendChannelsBlock(
              sendViaWhatsApp: _sendViaWhatsApp,
              sendViaEmail: _sendViaEmail,
              onWhatsAppChanged: (value) => setState(() => _sendViaWhatsApp = value),
              onEmailChanged: (value) => setState(() => _sendViaEmail = value),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
        if (_isBusy)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.blancCasse.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.violetRoyal),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImportGuestsBox extends StatelessWidget {
  final VoidCallback onTap;
  const _ImportGuestsBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: AppColors.violetRoyal.withValues(alpha: 0.38),
      ),
      child: InkWell(
        onTap: onTap,
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
              const Icon(
                Icons.upload_file_rounded,
                color: AppColors.violetRoyal,
                size: AppSpacing.xl,
              ),
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
  final Map<String, String> generatedLinks;
  final VoidCallback onGuestAdd;
  final ValueChanged<Map<String, dynamic>> onGuestRemove;
  final Function(String phone, String name, String url) onShareWhatsApp;

  const _ManualGuestsBlock({
    required this.guests,
    required this.generatedLinks,
    required this.onGuestAdd,
    required this.onGuestRemove,
    required this.onShareWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final hasLinks = generatedLinks.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(
          color: AppColors.violetRoyal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasLinks ? 'Billets prêts (${guests.length})' : 'Invités (${guests.length})',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Le bouton Ajouter est TOUJOURS visible
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
              _GuestTile(
                guest: guest,
                invitationUrl: generatedLinks[guest['id']?.toString()],
                onRemove: () => onGuestRemove(guest),
                onShare: (phone, name, url) => onShareWhatsApp(phone, name, url),
              ),
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
  final String? invitationUrl;
  final VoidCallback onRemove;
  final Function(String phone, String name, String url) onShare;

  const _GuestTile({
    required this.guest,
    this.invitationUrl,
    required this.onRemove,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final name = (guest['full_name'] ?? 'Invité') as String;
    final phone = (guest['phone'] ?? '') as String;
    final isReady = invitationUrl != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isReady ? AppColors.success.withValues(alpha: 0.05) : AppColors.beigeCremeAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isReady ? AppColors.success.withValues(alpha: 0.3) : AppColors.noirDoux.withValues(alpha: 0.06),
        ),
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
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
          isReady
              ? ElevatedButton.icon(
                  onPressed: () => onShare(phone, name, invitationUrl!),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  ),
                )
              : IconButton(
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
              label: 'WhatsApp (Manuel)',
              color: AppColors.success,
              selected: sendViaWhatsApp,
              onSelected: onWhatsAppChanged,
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
      side: BorderSide(
        color: selected ? color : AppColors.noirDoux.withValues(alpha: 0.10),
      ),
      labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
        color: selected ? color : AppColors.noirDoux,
        fontWeight: FontWeight.w700,
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
                helperText: 'Optionnel',
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
          borderSide: BorderSide(
            color: AppColors.orAfricain.withValues(alpha: 0.24),
          ),
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
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}