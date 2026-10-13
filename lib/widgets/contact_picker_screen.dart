import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/device_contacts_service.dart';

/// Résultat renvoyé par [ContactPickerScreen] : un contact sélectionné avec
/// son premier numéro de téléphone exploitable.
class PickedContact {
  final String fullName;
  final String phone;

  const PickedContact({required this.fullName, required this.phone});
}

class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

enum _LoadState { loading, permissionDenied, ready, error }

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final _contactsService = DeviceContactsService();
  final _searchController = TextEditingController();

  _LoadState _state = _LoadState.loading;
  List<Contact> _allContacts = [];
  List<Contact> _filtered = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final granted = await _contactsService.requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _state = _LoadState.permissionDenied);
        return;
      }
      final contacts = await _contactsService.getContactsWithPhone();
      if (!mounted) return;
      setState(() {
        _allContacts = contacts;
        _filtered = contacts;
        _state = _LoadState.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _allContacts
          : _allContacts
              .where((c) => c.displayName.toLowerCase().contains(query))
              .toList();
    });
  }

  void _confirm() {
    final picked = <PickedContact>[];
    for (final contact in _allContacts) {
      if (!_selectedIds.contains(contact.id)) continue;
      final phone = contact.phones.first.number;
      picked.add(PickedContact(fullName: contact.displayName, phone: phone));
    }
    Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      appBar: AppBar(
        backgroundColor: AppColors.blancCasse,
        foregroundColor: AppColors.noirDoux,
        elevation: 0,
        title: const Text('Importer des contacts'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _state == _LoadState.ready
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violetRoyal,
                      foregroundColor: AppColors.blancCasse,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Sélectionnez des contacts'
                          : 'Importer (${_selectedIds.length})',
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator(color: AppColors.violetRoyal));
      case _LoadState.permissionDenied:
        return _MessagePane(
          icon: Icons.contacts_outlined,
          title: 'Accès aux contacts refusé',
          message:
              "Pour importer vos invités depuis vos contacts, autorisez l'accès dans les paramètres de l'application.",
          actionLabel: 'Ouvrir les paramètres',
          onAction: () => openAppSettings(),
        );
      case _LoadState.error:
        return _MessagePane(
          icon: Icons.error_outline_rounded,
          title: 'Impossible de charger vos contacts',
          message: 'Une erreur est survenue. Réessayez.',
          actionLabel: 'Réessayer',
          onAction: () {
            setState(() => _state = _LoadState.loading);
            _load();
          },
        );
      case _LoadState.ready:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un contact...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.beigeCremeAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun contact avec numéro de téléphone trouvé.',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final contact = _filtered[index];
                        final selected = _selectedIds.contains(contact.id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(contact.id);
                              } else {
                                _selectedIds.remove(contact.id);
                              }
                            });
                          },
                          activeColor: AppColors.violetRoyal,
                          title: Text(
                            contact.displayName,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(contact.phones.first.number),
                        );
                      },
                    ),
            ),
          ],
        );
    }
  }
}

class _MessagePane extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessagePane({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.noirDoux.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.noirDoux.withValues(alpha: 0.64),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violetRoyal,
                foregroundColor: AppColors.blancCasse,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
