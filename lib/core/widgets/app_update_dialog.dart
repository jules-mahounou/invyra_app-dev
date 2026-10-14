// Fenêtre « Mise à jour disponible » : télécharge et installe le nouvel APK.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/app_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Vérifie s'il existe une nouvelle version et, si oui, affiche la fenêtre.
/// À appeler une fois l'écran principal affiché ; silencieux en cas d'échec.
Future<void> checkAndPromptAppUpdate(BuildContext context) async {
  final info = await AppUpdateService().checkForUpdate();
  if (info == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: !info.mandatory,
    builder: (_) => AppUpdateDialog(info: info),
  );
}

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;

  const AppUpdateDialog({super.key, required this.info});

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  StreamSubscription<OtaEvent>? _subscription;
  bool _downloading = false;
  double? _progress;
  String? _error;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _downloading = true;
      _progress = null;
      _error = null;
    });
    _subscription = AppUpdateService().downloadAndInstall(widget.info).listen(
      (event) {
        if (!mounted) return;
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final percent = double.tryParse(event.value ?? '');
            setState(() => _progress = percent == null ? null : percent / 100);
          case OtaStatus.INSTALLING:
          case OtaStatus.INSTALLATION_DONE:
            Navigator.of(context).maybePop();
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            _fail('Autorisez Invyra à installer des applications, puis réessayez.');
          default:
            _fail('Le téléchargement a échoué. Vérifiez votre connexion et réessayez.');
        }
      },
      onError: (_) => _fail('Le téléchargement a échoué. Vérifiez votre connexion et réessayez.'),
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !info.mandatory && !_downloading,
      child: Dialog(
        backgroundColor: AppColors.blancCasse,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.violetRoyal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppColors.violetRoyal),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Mise à jour disponible', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Version ${info.versionName} (${info.versionCode}) · vous avez ${info.currentVersionName}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.6)),
              ),
              if (info.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(info.notes, style: textTheme.bodyMedium),
              ],
              if (_downloading) ...[
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    color: AppColors.violetRoyal,
                    backgroundColor: AppColors.violetRoyal.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _progress == null ? 'Téléchargement…' : 'Téléchargement… ${(_progress! * 100).round()} %',
                  style: textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: textTheme.bodySmall?.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!info.mandatory)
                    TextButton(
                      onPressed: _downloading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Plus tard'),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _downloading ? null : _startUpdate,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.violetRoyal),
                    child: Text(_error == null ? 'Mettre à jour' : 'Réessayer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
