import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

enum _ScanResultType { success, failure }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool _flashEnabled = false;
  _ScanResultType? _resultType;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.noirDoux,
      child: SafeArea(
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
                  _ScanHeader(
                    flashEnabled: _flashEnabled,
                    onBack: () => Navigator.of(context).pop(),
                    onFlashToggle: () => setState(() => _flashEnabled = !_flashEnabled),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: _ScanFrame(animation: _scanController),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Placez le QR code dans le cadre',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.blancCasse,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _ScanHelpBubble(),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _DebugScanButtons(
                      onSuccess: _simulerSucces,
                      onFailure: _simulerEchec,
                    ),
                  ],
                  if (_resultType != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _ScanResultCard(
                      type: _resultType!,
                      onReset: () => setState(() => _resultType = null),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const _ScanHistory(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _simulerSucces() {
    setState(() => _resultType = _ScanResultType.success);
  }

  void _simulerEchec() {
    setState(() => _resultType = _ScanResultType.failure);
  }
}

class _ScanHeader extends StatelessWidget {
  final bool flashEnabled;
  final VoidCallback onBack;
  final VoidCallback onFlashToggle;

  const _ScanHeader({
    required this.flashEnabled,
    required this.onBack,
    required this.onFlashToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.xxl,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.blancCasse,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Scanner un billet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.blancCasse,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: AppSpacing.xxl,
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onFlashToggle,
              icon: Icon(flashEnabled ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded),
              color: AppColors.blancCasse,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final Animation<double> animation;

  const _ScanFrame({required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerCornerPainter(color: AppColors.violetRoyal),
            ),
          ),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg + (280 - (AppSpacing.lg * 2) - AppSpacing.sm) * animation.value,
                child: child!,
              );
            },
            child: Container(
              height: AppSpacing.sm,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrincipal,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violetRoyal.withValues(alpha: 0.50),
                    blurRadius: AppSpacing.md,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  final Color color;

  const _ScannerCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const cornerLength = 54.0;

    canvas.drawLine(Offset.zero, const Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, cornerLength), paint);

    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ScanHelpBubble extends StatelessWidget {
  const _ScanHelpBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.mascotDefault,
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.blancCasse.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.blancCasse.withValues(alpha: 0.10)),
            ),
            child: Text(
              'Scannez le QR code sur le billet de votre invité pour valider son entrée.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.blancCasse,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugScanButtons extends StatelessWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const _DebugScanButtons({
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: retirer lors de l'intégration du vrai scanner
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onSuccess,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.blancCasse,
            ),
            child: const Text('Simuler succès'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ElevatedButton(
            onPressed: onFailure,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.blancCasse,
            ),
            child: const Text('Simuler échec'),
          ),
        ),
      ],
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  final _ScanResultType type;
  final VoidCallback onReset;

  const _ScanResultCard({
    required this.type,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final success = type == _ScanResultType.success;
    final color = success ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: AppSpacing.xxl,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            success ? 'Accès autorisé' : 'Accès refusé',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (success) ...[
            _ResultLine(label: 'Invité', value: 'Aïcha Kouassi'),
            const SizedBox(height: AppSpacing.xs),
            _ResultLine(label: 'Événement', value: 'Mariage Kouassi & Amani'),
          ] else
            Text(
              'Ce billet est invalide ou a déjà été utilisé.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.blancCasse.withValues(alpha: 0.84),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _ResultBadge(
            label: success ? 'Billet valide' : 'Billet invalide',
            color: color,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blancCasse,
                side: const BorderSide(color: AppColors.blancCasse),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(success ? 'Scanner un autre billet' : 'Réessayer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String label;
  final String value;

  const _ResultLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.blancCasse.withValues(alpha: 0.82),
        ),
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ResultBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScanHistory extends StatelessWidget {
  const _ScanHistory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Derniers scans',
          style: AppTypography.textTheme.displaySmall?.copyWith(
            color: AppColors.blancCasse,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: const [
              _HistoryChip(
                icon: Icons.check_circle_rounded,
                label: 'Kofi Mensah — il y a 2 min',
                color: AppColors.success,
              ),
              SizedBox(width: AppSpacing.sm),
              _HistoryChip(
                icon: Icons.check_circle_rounded,
                label: 'Amani Kwesi — il y a 5 min',
                color: AppColors.success,
              ),
              SizedBox(width: AppSpacing.sm),
              _HistoryChip(
                icon: Icons.cancel_rounded,
                label: 'Billet invalide — il y a 8 min',
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HistoryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppSpacing.md),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.blancCasse,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
