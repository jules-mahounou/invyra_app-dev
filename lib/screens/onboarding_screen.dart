import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_system_ui.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/auth_layout.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onContinue});
  final VoidCallback? onContinue;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _continue() {
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue();
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final headerHeight = media.size.height * 0.58;
    // Sur tablette, le texte reste dans une colonne lisible au centre.
    final hPad = media.size.width > 560 ? (media.size.width - 480) / 2 : 28.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.onDarkHeader,
      child: Scaffold(
        backgroundColor: Colors.white,
        // Remplit l'écran quand il y a la place, défile sinon (paysage,
        // petit téléphone, texte agrandi dans les réglages).
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: media.size.height),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: CustomPaint(
                            painter: BrandHeaderPainter(wave: AuthWave.welcome),
                          ),
                        ),
                        Positioned(
                          top: media.padding.top,
                          left: 0,
                          right: 0,
                          height: headerHeight * 0.62 - media.padding.top,
                          child: Center(
                            child: FadeTransition(
                              opacity: _fade,
                              child: Image.asset(
                                AppAssets.logoWhite,
                                height: 72,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SlideTransition(
                      position: _slide,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            12,
                            hPad,
                            28 + media.padding.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue',
                                style: AppTypography.textTheme.displayLarge
                                    ?.copyWith(
                                      color: AppColors.noirDoux,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Créez des invitations inoubliables et partagez vos moments précieux avec élégance.',
                                style: AppTypography.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.noirDoux.withValues(
                                        alpha: 0.55,
                                      ),
                                      height: 1.5,
                                    ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _continue,
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Commencer',
                                        style: AppTypography.textTheme.bodyLarge
                                            ?.copyWith(
                                              color: AppColors.noirDoux,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 14),
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: const BoxDecoration(
                                          color: AppColors.violetRoyal,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
