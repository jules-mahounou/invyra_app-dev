import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/event_service.dart';

/// Écran de personnalisation d'un template.
/// Lit la config depuis event_templates.config et génère les champs dynamiquement.
class TemplateCustomizationScreen extends StatefulWidget {
  final String eventId;
  final String templateName;
  final Map<String, dynamic> templateConfig;   // config du template (depuis BDD)
  final Map<String, dynamic> initialValues;    // customization existante de l'event
  final VoidCallback onSaved;

  const TemplateCustomizationScreen({
    required this.eventId,
    required this.templateName,
    required this.templateConfig,
    required this.initialValues,
    required this.onSaved,
    super.key,
  });

  @override
  State<TemplateCustomizationScreen> createState() => _TemplateCustomizationScreenState();
}

class _TemplateCustomizationScreenState extends State<TemplateCustomizationScreen> {
  final _eventService = EventService();
  late Map<String, dynamic> _values;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Partir des valeurs existantes, compléter avec les défauts du template
    _values = Map<String, dynamic>.from(widget.initialValues);

    // Couleur primaire par défaut depuis le template
    final defaultColors = widget.templateConfig['defaultColors'] as Map? ?? {};
    if (!_values.containsKey('primaryColor')) {
      _values['primaryColor'] = defaultColors['primary'] ?? '#5B21B6';
    }

    // Initialiser les champs custom avec leurs valeurs par défaut si absent
    final customFields = widget.templateConfig['customFields'] as List? ?? [];
    for (final field in customFields) {
      final f = field as Map;
      final key = f['key'] as String?;
      if (key != null && !_values.containsKey(key)) {
        final def = f['default'];
        if (def != null) _values[key] = def;
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _eventService.updateEventCustomization(
        eventId: widget.eventId,
        customization: _values,
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personnalisation enregistrée ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  // ─── Color picker popup ────────────────────────────────────────────────────
  Future<void> _pickColor(String key, Color current) async {
    Color picked = current;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            pickerAreaHeightPercent: 0.8,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _values[key] = '#${picked.toARGB32().toRadixString(16).substring(2).toUpperCase()}');
              Navigator.of(ctx).pop();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(dynamic value, String fallback) {
    final hex = (value as String? ?? fallback).replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.violetRoyal;
    }
  }

  // ─── Widgets par type de champ ─────────────────────────────────────────────

  Widget _buildColorField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final defaultColors = widget.templateConfig['defaultColors'] as Map? ?? {};
    final fallback = defaultColors['primary'] as String? ?? '#5B21B6';
    final colorHex = _values[key] as String? ?? fallback;
    final color = _parseColor(colorHex, fallback);

    return _FieldCard(
      label: label,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickColor(key, color),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.15), width: 2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(colorHex, style: AppTypography.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: AppColors.noirDoux)),
                const SizedBox(height: AppSpacing.xs),
                Text('Appuyez sur le cercle pour changer', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorListField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final max = (field['max'] as int?) ?? 4;
    final defaultList = (field['default'] as List?)?.cast<String>() ?? ['#e879a0', '#f0a0c0', '#f9c8d9'];
    final colors = (_values[key] as List?)?.cast<String>() ?? List<String>.from(defaultList);
    final showKey = '${key}_visible';
    final isVisible = _values[showKey] as bool? ?? true;

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: isVisible,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[showKey] = v),
      ),
      child: isVisible ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (int i = 0; i < colors.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final cur = _parseColor(colors[i], '#e879a0');
                        Color picked = cur;
                        await showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Couleur ${i + 1}'),
                            content: SingleChildScrollView(
                              child: ColorPicker(pickerColor: cur, onColorChanged: (c) => picked = c, enableAlpha: false, hexInputBar: true),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
                              FilledButton(
                                onPressed: () {
                                  final newList = List<String>.from(colors);
                                  newList[i] = '#${picked.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                                  setState(() => _values[key] = newList);
                                  Navigator.of(ctx).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(colors[i], '#e879a0'),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                    // Bouton supprimer le cercle
                    if (colors.length > 1)
                      Positioned(
                        top: -4, right: -4,
                        child: GestureDetector(
                          onTap: () {
                            final newList = List<String>.from(colors)..removeAt(i);
                            setState(() => _values[key] = newList);
                          },
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              if (colors.length < max)
                GestureDetector(
                  onTap: () => setState(() => _values[key] = [...colors, '#AAAAAA']),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.violetRoyal, size: 20),
                  ),
                ),
            ],
          ),
        ],
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildTextField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final placeholder = field['placeholder'] as String? ?? '';
    final controller = TextEditingController(text: _values[key] as String? ?? '');
    final showKey = '${key}_visible';
    final isVisible = _values[showKey] as bool? ?? true;

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: isVisible,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[showKey] = v),
      ),
      child: isVisible ? TextField(
        controller: controller,
        onChanged: (v) => _values[key] = v,
        style: AppTypography.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: placeholder,
          fillColor: AppColors.beigeCremeAlt,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.violetRoyal, width: 1.5)),
        ),
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildTextareaField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final placeholder = field['placeholder'] as String? ?? '';
    final controller = TextEditingController(text: _values[key] as String? ?? '');
    final showKey = '${key}_visible';
    final isVisible = _values[showKey] as bool? ?? true;

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: isVisible,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[showKey] = v),
      ),
      child: isVisible ? TextField(
        controller: controller,
        onChanged: (v) => _values[key] = v,
        maxLines: 4,
        style: AppTypography.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: placeholder,
          fillColor: AppColors.beigeCremeAlt,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.violetRoyal, width: 1.5)),
        ),
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildUrlField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final placeholder = field['placeholder'] as String? ?? 'https://...';
    final controller = TextEditingController(text: _values[key] as String? ?? '');
    final showKey = '${key}_visible';
    final isVisible = _values[showKey] as bool? ?? true;

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: isVisible,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[showKey] = v),
      ),
      child: isVisible ? TextField(
        controller: controller,
        onChanged: (v) => _values[key] = v,
        keyboardType: TextInputType.url,
        style: AppTypography.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: const Icon(Icons.link_rounded, color: AppColors.violetRoyal, size: 18),
          fillColor: AppColors.beigeCremeAlt,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.violetRoyal, width: 1.5)),
        ),
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildToggleField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final value = _values[key] as bool? ?? (field['default'] as bool? ?? true);

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[key] = v),
      ),
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildImageListField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final max = (field['max'] as int?) ?? 5;
    // Images actuelles ou images démo par défaut (noms de fichiers du registre)
    final demoImages = (field['demoImages'] as List?)?.cast<String>() ?? <String>[];
    final images = (_values[key] as List?)?.cast<String>() ?? <String>[];
    final showKey = '${key}_visible';
    final isVisible = _values[showKey] as bool? ?? true;

    // Construire la liste à afficher : images uploadées ou placeholders démo
    final _ = demoImages; // demoImages disponibles pour référence future

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: isVisible,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[showKey] = v),
      ),
      child: isVisible ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appuyez sur une photo pour la remplacer. Max $max photos.',
            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Grille galerie 2×2 style moodboard
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: images.length < max ? images.length + 1 : images.length,
            itemBuilder: (_, i) {
              // Dernière case = bouton ajouter
              if (i == images.length && images.length < max) {
                return GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1200,
                      imageQuality: 85,
                    );
                    if (picked == null || !mounted) return;
                    setState(() => _isSaving = true);
                    try {
                      final bytes = await picked.readAsBytes();
                      final userId = Supabase.instance.client.auth.currentUser!.id;
                      final path = '$userId/events/${widget.eventId}/template/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
                      await Supabase.instance.client.storage
                          .from('event-logos')
                          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
                      final url = Supabase.instance.client.storage
                          .from('event-logos')
                          .getPublicUrl(path);
                      if (mounted) {
                        setState(() {
                          final newList = List<String>.from(images)..add(url);
                          _values[key] = newList;
                          _isSaving = false;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.beigeCremeAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.3), style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_rounded, color: AppColors.violetRoyal, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'Ajouter',
                          style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.violetRoyal, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Photo existante — tap pour remplacer, long press pour supprimer
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                      if (picked == null || !mounted) return;
                      setState(() => _isSaving = true);
                      try {
                        final bytes = await picked.readAsBytes();
                        final userId = Supabase.instance.client.auth.currentUser!.id;
                        final path = '$userId/events/${widget.eventId}/template/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
                        await Supabase.instance.client.storage.from('event-logos').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
                        final url = Supabase.instance.client.storage.from('event-logos').getPublicUrl(path);
                        if (mounted) {
                          setState(() {
                            final newList = List<String>.from(images);
                            newList[i] = url;
                            _values[key] = newList;
                            _isSaving = false;
                          });
                        }
                      } catch (_) { if (mounted) setState(() => _isSaving = false); }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.08)),
                        image: DecorationImage(
                          image: NetworkImage(images[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Overlay "Modifier"
                  Positioned(
                    bottom: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Modifier', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // Bouton supprimer
                  Positioned(
                    top: -6, right: -6,
                    child: GestureDetector(
                      onTap: () {
                        final newList = List<String>.from(images)..removeAt(i);
                        setState(() => _values[key] = newList);
                      },
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Aucune photo ajoutée — les images de démo seront utilisées.',
                style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.4), fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildTimelineField(Map field) {
    final key = field['key'] as String;
    final label = field['label'] as String? ?? key;
    final rawDefault = field['default'] as List? ?? [];
    final items = (_values[key] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ?? rawDefault.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Toggle pour masquer/afficher ce bloc entier
    final showKey = '${key}_visible';
    final isVisible = _values[showKey] as bool? ?? true;

    return _FieldCard(
      label: label,
      trailing: Switch(
        value: isVisible,
        activeThumbColor: AppColors.violetRoyal,
        activeTrackColor: AppColors.violetRoyal.withValues(alpha: 0.3),
        onChanged: (v) => setState(() => _values[showKey] = v),
      ),
      child: isVisible ? Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  // Bouton heure — ouvre TimePicker
                  GestureDetector(
                    onTap: () async {
                      final current = items[i]['time'] as String? ?? '';
                      final parts = current.split(':');
                      final initial = TimeOfDay(
                        hour: parts.length > 0 ? int.tryParse(parts[0]) ?? 0 : 0,
                        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                      );
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initial,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.violetRoyal),
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          items[i]['time'] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          _values[key] = items;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.beigeCremeAlt,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: AppColors.violetRoyal),
                          const SizedBox(width: 4),
                          Text(
                            items[i]['time'] as String? ?? '--:--',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.violetRoyal, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: items[i]['label'] as String? ?? ''),
                      onChanged: (v) {
                        items[i]['label'] = v;
                        _values[key] = items;
                      },
                      style: AppTypography.textTheme.bodySmall,
                      decoration: _smallInput('Programme...'),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      items.removeAt(i);
                      _values[key] = items;
                    }),
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() {
              items.add({'time': '', 'label': ''});
              _values[key] = items;
            }),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter une étape'),
            style: TextButton.styleFrom(foregroundColor: AppColors.violetRoyal),
          ),
        ],
      ) : const SizedBox.shrink(),
    );
  }

  InputDecoration _smallInput(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 11),
    fillColor: AppColors.beigeCremeAlt,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.violetRoyal)),
  );

  Widget _buildFieldWidget(Map field) {
    final type = field['type'] as String? ?? 'text';
    switch (type) {
      case 'color': return _buildColorField(field);
      case 'colorList': return _buildColorListField(field);
      case 'textarea': return _buildTextareaField(field);
      case 'toggle': return _buildToggleField(field);
      case 'url': return _buildUrlField(field);
      case 'timeline': return _buildTimelineField(field);
      case 'imageList': return _buildImageListField(field);
      default: return _buildTextField(field);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = widget.templateConfig['defaultColors'] as Map? ?? {};
    final primaryFallback = defaultColors['primary'] as String? ?? '#5B21B6';
    final primaryHex = _values['primaryColor'] as String? ?? primaryFallback;
    final primaryColor = _parseColor(primaryHex, primaryFallback);
    final customFields = (widget.templateConfig['customFields'] as List? ?? []).cast<Map>();

    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      appBar: AppBar(
        backgroundColor: AppColors.blancCasse,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.violetRoyal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Personnaliser',
          style: AppTypography.textTheme.displaySmall?.copyWith(color: AppColors.noirDoux, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.violetRoyal))
                : TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(foregroundColor: AppColors.violetRoyal),
                    child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Couleur principale ──
            Text('Couleur principale', style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.noirDoux, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Touchez le cercle pour personnaliser la couleur du template.', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.6))),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => _pickColor('primaryColor', primaryColor),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.12), width: 2),
                      boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.colorize_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(primaryHex, style: AppTypography.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                      Text('Couleur du template ${widget.templateName}', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
            ),

            if (customFields.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Options spécifiques', style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.noirDoux, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text('Ces champs sont optionnels. Laissez vides pour utiliser les valeurs par défaut.', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.6))),
              const SizedBox(height: AppSpacing.lg),
              for (final field in customFields) ...[
                _buildFieldWidget(field),
                const SizedBox(height: AppSpacing.md),
              ],
            ],

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.gradientPrincipal, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Enregistrer la personnalisation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    foregroundColor: AppColors.blancCasse,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  const _FieldCard({required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blancCasse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.orAfricain.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.violetRoyal, fontWeight: FontWeight.w700)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (child is! SizedBox || (child as SizedBox).height != 0) ...[
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ],
      ),
    );
  }
}
