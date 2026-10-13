import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/supabase_schema.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/import_service.dart';
import '../services/guest_service.dart';
import '../services/invitation_service.dart';
import '../core/services/edge_function_service.dart';
import '../screens/create_event/create_event_utils.dart';
import 'contact_picker_screen.dart';
import 'paste_guest_list_screen.dart';

class GuestManagerWidget extends StatefulWidget {
  final String eventId;
  final VoidCallback? onChanged;

  const GuestManagerWidget({required this.eventId, this.onChanged, super.key});

  @override
  State<GuestManagerWidget> createState() => GuestManagerWidgetState();
}

const String _invitationBaseUrl = 'https://invyra-web.vercel.app/i/';

class GuestManagerWidgetState extends State<GuestManagerWidget> {
  final _guestService = GuestService();
  final _importService = ImportService();
  final _invitationService = InvitationService();

  List<Map<String, dynamic>> _guests = [];
  // Map pour stocker les liens d'invitations générés : { guestId: invitationUrl }
  Map<String, String> _generatedLinks = {};
  // Compteur local du nombre d'envois WhatsApp effectués dans cette session
  int _sentCount = 0;
  // IDs des invités déjà envoyés via WhatsApp dans cette session — permet au
  // bouton "file d'envoi" de savoir à qui proposer l'envoi suivant.
  final Set<String> _sentGuestIds = {};

  bool _isLoading = true;
  bool _isBusy = false;
  bool _isSendingEmails = false;
  ({int sent, int failed, int skippedInvalid})? _lastEmailResult;

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  Future<void> _loadGuests() async {
    setState(() => _isLoading = true);
    try {
      final guests = await _guestService.getGuestsByEvent(widget.eventId);

      // Recharger les billets déjà générés précédemment (et qui ont déjà été
      // envoyés) — sans ça, quitter puis revenir sur cet écran faisait
      // croire qu'il fallait tout régénérer, alors que c'était déjà fait.
      final invitations = await _invitationService.getInvitationsByEvent(widget.eventId);
      final generatedLinks = <String, String>{};
      final sentGuestIds = <String>{};
      for (final inv in invitations) {
        final guestId = inv['guest_id']?.toString();
        final token = inv['public_token'] as String?;
        if (guestId == null || token == null || token.isEmpty) continue;
        generatedLinks[guestId] = '$_invitationBaseUrl$token';
        final status = inv['status'] as String?;
        if (status != null && status != 'brouillon') {
          sentGuestIds.add(guestId);
        }
      }

      if (!mounted) return;
      setState(() {
        _guests = guests;
        _generatedLinks = generatedLinks;
        _sentGuestIds
          ..clear()
          ..addAll(sentGuestIds);
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
    if (_isBusy) return;
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

  Future<void> _shareOnWhatsApp(String guestId, String phone, String guestName, String url) async {
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
      await _markGuestSent(guestId);
    } catch (_) {
      try {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        await _markGuestSent(guestId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp. Vérifiez que l\'application est installée.')),
        );
      }
    }
  }

  /// Met à jour l'état local ET persiste en base qu'une invitation a été
  /// envoyée — pour que revenir sur cet écran plus tard (ou un autre jour)
  /// retrouve le bon statut au lieu de tout considérer "non envoyé".
  Future<void> _markGuestSent(String guestId) async {
    if (mounted) {
      setState(() {
        _sentCount++;
        _sentGuestIds.add(guestId);
      });
    }
    try {
      await _invitationService.markGuestInvitationSent(
        eventId: widget.eventId,
        guestId: guestId,
      );
    } catch (_) {
      // L'ouverture de WhatsApp a déjà réussi du point de vue de l'utilisateur ;
      // un échec de cette écriture de suivi ne doit pas lui afficher une erreur.
    }
  }

  /// Envoie au prochain invité (ayant un billet généré) qui n'a pas encore
  /// reçu son invitation dans cette session — évite d'avoir à chercher
  /// manuellement qui reste à faire dans une longue liste.
  Future<void> _sendToNextGuest() async {
    Map<String, dynamic>? next;
    for (final guest in _guests) {
      final id = guest['id']?.toString();
      if (id == null) continue;
      if (_generatedLinks.containsKey(id) && !_sentGuestIds.contains(id)) {
        next = guest;
        break;
      }
    }
    if (next == null) return;

    final guestId = next['id'].toString();
    final name = (next['full_name'] ?? 'Invité') as String;
    final phone = (next['phone'] ?? '') as String;
    final url = _generatedLinks[guestId]!;
    await _shareOnWhatsApp(guestId, phone, name, url);
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

  Future<void> _showEditGuestSheet(Map<String, dynamic> guest) async {
    final edited = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _AddGuestSheet(existingGuest: guest),
    );

    if (edited == null) return;
    final guestId = guest['id'] as String?;
    if (guestId == null) return;

    setState(() => _isBusy = true);
    try {
      final updated = await _guestService.updateGuest(
        guestId: guestId,
        eventId: widget.eventId,
        fullName: edited['name'] as String,
        phone: edited['phone'] as String?,
        email: edited['email'] as String?,
      );
      if (!mounted) return;
      setState(() {
        final index = _guests.indexWhere((g) => g['id'] == guestId);
        if (index != -1) _guests[index] = updated;
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
      await _guestService.deleteGuest(guestId: guestId, eventId: widget.eventId);
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

  /// Numéros déjà présents dans l'événement (normalisés), pour écarter les
  /// doublons évidents avant un ajout en masse — y compris les doublons
  /// internes au nouveau lot lui-même.
  Set<String> _existingPhoneKeys() {
    return _guests
        .map((g) => _normalizePhoneKey(g['phone'] as String?))
        .whereType<String>()
        .toSet();
  }

  String? _normalizePhoneKey(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.isEmpty ? null : digits;
  }

  /// Ajoute un lot d'invités (contacts importés, liste collée, fichier) en
  /// écartant les doublons de téléphone, puis rafraîchit l'affichage.
  Future<void> _bulkAddAndRefresh(
    List<({String fullName, String? phone, String? email})> candidates, {
    required String importSource,
  }) async {
    if (candidates.isEmpty) return;

    final seenPhones = _existingPhoneKeys();
    var skippedDuplicates = 0;
    final toAdd = <({String fullName, String? phone, String? email})>[];
    for (final candidate in candidates) {
      final key = _normalizePhoneKey(candidate.phone);
      if (key != null) {
        if (seenPhones.contains(key)) {
          skippedDuplicates++;
          continue;
        }
        seenPhones.add(key);
      }
      toAdd.add(candidate);
    }

    if (toAdd.isEmpty) {
      if (!mounted) return;
      showCreateEventErrorSnackBar(context, 'Tous ces invités sont déjà dans la liste.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final created = await _guestService.addGuestsBulk(
        eventId: widget.eventId,
        guests: toAdd,
        importSource: importSource,
      );
      if (!mounted) return;
      setState(() {
        _guests.addAll(created);
        _isBusy = false;
      });
      widget.onChanged?.call();
      final message = skippedDuplicates > 0
          ? '${created.length} invité(s) ajouté(s), $skippedDuplicates doublon(s) ignoré(s).'
          : '${created.length} invité(s) ajouté(s).';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _importFromContacts() async {
    final picked = await Navigator.of(context).push<List<PickedContact>>(
      MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
    );
    if (picked == null || picked.isEmpty) return;
    await _bulkAddAndRefresh(
      [for (final c in picked) (fullName: c.fullName, phone: c.phone, email: null)],
      importSource: 'contacts',
    );
  }

  Future<void> _importFromPastedList() async {
    final pasted = await Navigator.of(context).push<List<PastedGuest>>(
      MaterialPageRoute(builder: (_) => const PasteGuestListScreen()),
    );
    if (pasted == null || pasted.isEmpty) return;
    await _bulkAddAndRefresh(
      [for (final g in pasted) (fullName: g.fullName, phone: g.phone, email: null)],
      importSource: 'paste',
    );
  }

  int get _guestsWithEmailCount =>
      _guests.where((g) => (g['email'] as String?)?.trim().isNotEmpty == true).length;

  Future<void> _sendEmails() async {
    if (_isSendingEmails) return;
    setState(() => _isSendingEmails = true);
    try {
      final result = await _guestService.sendInvitationEmails(eventId: widget.eventId);
      if (!mounted) return;
      setState(() {
        _lastEmailResult = result;
        _isSendingEmails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingEmails = false);
      showCreateEventErrorSnackBar(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      await _importService.shareTemplateFile();
    } catch (e) {
      if (!mounted) return;
      showCreateEventErrorSnackBar(context, 'Impossible de générer le modèle.');
    }
  }

  Future<void> _importGuests() async {
    List<Map<String, dynamic>>? guests;
    try {
      guests = await _importService.pickAndParseFile();
    } catch (e) {
      if (!mounted) return;
      showCreateEventErrorSnackBar(
        context,
        e.toString().replaceFirst('FormatException: ', ''),
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

    await _bulkAddAndRefresh(
      [
        for (final g in guests)
          (
            fullName: g['full_name'] as String,
            phone: g['phone'] as String?,
            email: g['email'] as String?,
          ),
      ],
      importSource: 'excel',
    );
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
            _ImportOptionsRow(
              onImportContacts: _importFromContacts,
              onPasteList: _importFromPastedList,
              onImportFile: _importGuests,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Télécharger un modèle de fichier'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.violetRoyal,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_generatedLinks.isNotEmpty) ...[
              _SendQueueBanner(
                total: _generatedLinks.length,
                sent: _sentGuestIds.length,
                onSendNext: _sendToNextGuest,
              ),
              const SizedBox(height: AppSpacing.md),
              _EmailSendBlock(
                guestsWithEmailCount: _guestsWithEmailCount,
                isSending: _isSendingEmails,
                lastResult: _lastEmailResult,
                onSend: _sendEmails,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _ManualGuestsBlock(
              guests: _guests,
              generatedLinks: _generatedLinks,
              sentGuestIds: _sentGuestIds,
              onGuestAdd: _showAddGuestSheet,
              onGuestEdit: _showEditGuestSheet,
              onGuestRemove: _removeGuest,
              onShareWhatsApp: _shareOnWhatsApp,
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

class _ImportOptionsRow extends StatelessWidget {
  final VoidCallback onImportContacts;
  final VoidCallback onPasteList;
  final VoidCallback onImportFile;

  const _ImportOptionsRow({
    required this.onImportContacts,
    required this.onPasteList,
    required this.onImportFile,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: AppColors.violetRoyal.withValues(alpha: 0.38),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.beigeCremeBase,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            _ImportOptionTile(
              icon: Icons.contacts_rounded,
              label: 'Importer depuis mes contacts',
              subtitle: 'Choisissez parmi vos contacts du téléphone',
              onTap: onImportContacts,
            ),
            const _ImportOptionDivider(),
            _ImportOptionTile(
              icon: Icons.content_paste_rounded,
              label: 'Coller une liste',
              subtitle: 'Collez des noms et numéros en texte libre',
              onTap: onPasteList,
            ),
            const _ImportOptionDivider(),
            _ImportOptionTile(
              icon: Icons.upload_file_rounded,
              label: 'Fichier Excel ou CSV',
              subtitle: 'Importez un fichier .xlsx ou .csv',
              onTap: onImportFile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportOptionDivider extends StatelessWidget {
  const _ImportOptionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
      color: AppColors.violetRoyal.withValues(alpha: 0.08),
    );
  }
}

class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.violetRoyal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.violetRoyal, size: AppSpacing.lg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.noirDoux,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.noirDoux),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'envoi rapide : évite d'avoir à chercher manuellement qui reste
/// à envoyer dans la liste — un seul bouton répété avance toujours vers le
/// prochain invité non envoyé.
class _SendQueueBanner extends StatelessWidget {
  final int total;
  final int sent;
  final VoidCallback onSendNext;

  const _SendQueueBanner({
    required this.total,
    required this.sent,
    required this.onSendNext,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - sent;
    final isDone = remaining <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDone ? AppColors.success.withValues(alpha: 0.08) : AppColors.violetRoyal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDone ? AppColors.success : AppColors.violetRoyal).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.send_rounded,
            color: isDone ? AppColors.success : AppColors.violetRoyal,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isDone
                  ? 'Toutes les invitations ont été envoyées ✓'
                  : '$sent/$total invitations envoyées sur WhatsApp',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isDone)
            ElevatedButton(
              onPressed: onSendNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violetRoyal,
                foregroundColor: AppColors.blancCasse,
              ),
              child: const Text('Envoyer'),
            ),
        ],
      ),
    );
  }
}

class _ManualGuestsBlock extends StatefulWidget {
  final List<Map<String, dynamic>> guests;
  final Map<String, String> generatedLinks;
  final Set<String> sentGuestIds;
  final VoidCallback onGuestAdd;
  final ValueChanged<Map<String, dynamic>> onGuestEdit;
  final ValueChanged<Map<String, dynamic>> onGuestRemove;
  final Function(String guestId, String phone, String name, String url) onShareWhatsApp;

  const _ManualGuestsBlock({
    required this.guests,
    required this.generatedLinks,
    required this.sentGuestIds,
    required this.onGuestAdd,
    required this.onGuestEdit,
    required this.onGuestRemove,
    required this.onShareWhatsApp,
  });

  @override
  State<_ManualGuestsBlock> createState() => _ManualGuestsBlockState();
}

// Au-delà de ce nombre d'invités, une barre de recherche s'affiche —
// inutile pour une petite liste, indispensable passé quelques dizaines.
const int _searchThreshold = 8;

class _ManualGuestsBlockState extends State<_ManualGuestsBlock> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLinks = widget.generatedLinks.isNotEmpty;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.guests
        : widget.guests
            .where((g) => (g['full_name'] as String? ?? '').toLowerCase().contains(query))
            .toList();

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
                  hasLinks ? 'Billets prêts (${widget.guests.length})' : 'Invités (${widget.guests.length})',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Le bouton Ajouter est TOUJOURS visible
              ElevatedButton.icon(
                onPressed: widget.onGuestAdd,
                icon: const Icon(Icons.add_rounded, size: AppSpacing.md),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violetRoyal,
                  foregroundColor: AppColors.blancCasse,
                ),
              ),
            ],
          ),
          if (widget.guests.length > _searchThreshold) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un invité...',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.beigeCremeAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          if (widget.guests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Aucun invité ne correspond à "$query".',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              // shrinkWrap + physics désactivée : cette liste vit dans la page
              // défilante de son propre écran dédié, elle ne doit pas essayer
              // de défiler elle-même en plus du reste de la page.
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final guest = filtered[index];
                  final guestId = guest['id']?.toString();
                  return _GuestTile(
                    guest: guest,
                    invitationUrl: widget.generatedLinks[guestId],
                    alreadySent: guestId != null && widget.sentGuestIds.contains(guestId),
                    onEdit: () => widget.onGuestEdit(guest),
                    onRemove: () => widget.onGuestRemove(guest),
                    onShare: (guestId, phone, name, url) =>
                        widget.onShareWhatsApp(guestId, phone, name, url),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  final Map<String, dynamic> guest;
  final String? invitationUrl;
  final bool alreadySent;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final Function(String guestId, String phone, String name, String url) onShare;

  const _GuestTile({
    required this.guest,
    this.invitationUrl,
    this.alreadySent = false,
    required this.onEdit,
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
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.noirDoux.withValues(alpha: 0.6),
            tooltip: 'Modifier',
          ),
          isReady
              ? (alreadySent
                  ? IconButton(
                      onPressed: () {
                        final guestId = guest['id']?.toString();
                        if (guestId == null) return;
                        onShare(guestId, phone, name, invitationUrl!);
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      color: AppColors.success,
                      tooltip: 'Envoyé — renvoyer',
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        final guestId = guest['id']?.toString();
                        if (guestId == null) return;
                        onShare(guestId, phone, name, invitationUrl!);
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      ),
                    ))
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

/// Envoi automatique par email — contrairement à WhatsApp, aucune action
/// manuelle n'est nécessaire après avoir appuyé sur le bouton : tous les
/// invités ayant une adresse email reçoivent leur billet d'un coup.
class _EmailSendBlock extends StatelessWidget {
  final int guestsWithEmailCount;
  final bool isSending;
  final ({int sent, int failed, int skippedInvalid})? lastResult;
  final VoidCallback onSend;

  const _EmailSendBlock({
    required this.guestsWithEmailCount,
    required this.isSending,
    required this.lastResult,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmails = guestsWithEmailCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: AppColors.violetRoyal),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envoi automatique par email',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  lastResult != null
                      ? '${lastResult!.sent} email(s) envoyé(s)'
                          '${lastResult!.failed > 0 ? ', ${lastResult!.failed} échec(s)' : ''}'
                          '${lastResult!.skippedInvalid > 0 ? ', ${lastResult!.skippedInvalid} adresse(s) invalide(s) ignorée(s)' : ''}'
                      : hasEmails
                          ? '$guestsWithEmailCount invité(s) avec email'
                          : "Aucun invité n'a d'email renseigné",
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: (!hasEmails || isSending) ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violetRoyal,
              foregroundColor: AppColors.blancCasse,
            ),
            child: Text(isSending ? 'Envoi...' : 'Envoyer'),
          ),
        ],
      ),
    );
  }
}



class _AddGuestSheet extends StatefulWidget {
  final Map<String, dynamic>? existingGuest;

  const _AddGuestSheet({this.existingGuest});

  @override
  State<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends State<_AddGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  bool get _isEditing => widget.existingGuest != null;

  @override
  void initState() {
    super.initState();
    final guest = widget.existingGuest;
    final existingPhone = (guest?['phone'] as String?) ?? '';
    _nameController = TextEditingController(text: guest?['full_name'] as String? ?? '');
    _phoneController = TextEditingController(
      text: existingPhone.startsWith('+') ? existingPhone.substring(1) : existingPhone,
    );
    _emailController = TextEditingController(text: guest?['email'] as String? ?? '');
  }

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
                _isEditing ? "Modifier l'invité" : 'Ajouter un invité',
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
                validator: _emailValidator,
              ),
              const SizedBox(height: AppSpacing.xl),
              _GradientActionButton(
                label: _isEditing ? 'Enregistrer' : "Ajouter l'invité",
                icon: _isEditing ? Icons.check_rounded : Icons.person_add_alt_rounded,
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

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optionnel
    if (!isValidEmail(value)) {
      return 'Email invalide (ex: nom@exemple.com)';
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
        decoration: BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
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
      decoration: BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
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