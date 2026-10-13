import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/guest_text_parser.dart';

class PastedGuest {
  final String fullName;
  final String? phone;

  const PastedGuest({required this.fullName, this.phone});
}

/// Écran en deux temps : collage d'une liste en texte libre, puis aperçu
/// modifiable des invités détectés avant import — l'analyse automatique
/// n'est jamais appliquée à l'aveugle.
class PasteGuestListScreen extends StatefulWidget {
  const PasteGuestListScreen({super.key});

  @override
  State<PasteGuestListScreen> createState() => _PasteGuestListScreenState();
}

class _PasteGuestListScreenState extends State<PasteGuestListScreen> {
  final _pasteController = TextEditingController();
  final List<_EditableRow> _rows = [];
  bool _showPreview = false;

  @override
  void dispose() {
    _pasteController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _analyze() {
    final parsed = parseGuestListText(_pasteController.text);
    setState(() {
      for (final row in _rows) {
        row.dispose();
      }
      _rows
        ..clear()
        ..addAll(parsed.map((e) => _EditableRow(name: e.fullName, phone: e.phone ?? '')));
      _showPreview = true;
    });
  }

  void _addEmptyRow() {
    setState(() => _rows.add(_EditableRow(name: '', phone: '')));
  }

  void _removeRow(_EditableRow row) {
    setState(() {
      _rows.remove(row);
      row.dispose();
    });
  }

  void _confirm() {
    final guests = _rows
        .map((row) => PastedGuest(
              fullName: row.nameController.text.trim(),
              phone: row.phoneController.text.trim().isEmpty ? null : row.phoneController.text.trim(),
            ))
        .where((g) => g.fullName.isNotEmpty)
        .toList();
    Navigator.of(context).pop(guests);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      appBar: AppBar(
        backgroundColor: AppColors.blancCasse,
        foregroundColor: AppColors.noirDoux,
        elevation: 0,
        title: Text(_showPreview ? 'Vérifiez la liste' : 'Coller une liste'),
      ),
      body: _showPreview ? _buildPreview() : _buildPasteInput(),
      bottomNavigationBar: _showPreview
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rows.isEmpty ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violetRoyal,
                      foregroundColor: AppColors.blancCasse,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    child: Text('Ajouter (${_rows.length}) invités'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPasteInput() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Collez votre liste d'invités ci-dessous — un invité par ligne. "
            "Vous pouvez mettre le nom et le numéro ensemble (\"Jean Dupont, 97123456\") "
            "ou le nom puis le numéro sur la ligne suivante.",
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: _pasteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Jean Dupont, 97123456\nAwa Koffi - 97654321\n...',
                filled: true,
                fillColor: AppColors.beigeCremeAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pasteController.text.trim().isEmpty ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violetRoyal,
                foregroundColor: AppColors.blancCasse,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: const Text('Analyser la liste'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            "Aucun invité détecté. Revenez en arrière et vérifiez le format de votre liste.",
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.noirDoux.withValues(alpha: 0.64),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      children: [
        Text(
          '${_rows.length} invité(s) détecté(s) — vérifiez et corrigez si besoin avant import.',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.noirDoux.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final row in _rows) ...[
          _PreviewRowCard(row: row, onRemove: () => _removeRow(row)),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextButton.icon(
          onPressed: _addEmptyRow,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter une ligne'),
          style: TextButton.styleFrom(foregroundColor: AppColors.violetRoyal),
        ),
      ],
    );
  }
}

class _EditableRow {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  _EditableRow({required String name, required String phone})
      : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

class _PreviewRowCard extends StatelessWidget {
  final _EditableRow row;
  final VoidCallback onRemove;

  const _PreviewRowCard({required this.row, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.beigeCremeAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: row.nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nom complet',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextField(
                  controller: row.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Numéro (optionnel)',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.noirDoux.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
