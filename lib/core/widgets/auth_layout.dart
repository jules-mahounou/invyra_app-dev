import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_system_ui.dart';
import '../theme/app_typography.dart';

/// Forme de la vague qui sépare l'en-tête violet du panneau blanc.
///
/// 7 points en fractions de la taille de l'en-tête : départ (bord gauche),
/// 2 points de contrôle, point milieu, 2 points de contrôle, arrivée (bord droit).
class AuthWave {
  const AuthWave(this.points);
  final List<Offset> points;

  /// Le blanc remonte à gauche, le violet plonge à droite (titre à gauche).
  static const signIn = AuthWave([
    Offset(0, 0.80),
    Offset(0.20, 0.64),
    Offset(0.42, 0.68),
    Offset(0.58, 0.83),
    Offset(0.72, 0.96),
    Offset(0.88, 1.03),
    Offset(1, 0.92),
  ]);

  /// L'inverse : le violet descend à gauche, le blanc remonte à droite.
  static const welcome = AuthWave([
    Offset(0, 0.93),
    Offset(0.14, 1.02),
    Offset(0.30, 0.97),
    Offset(0.44, 0.85),
    Offset(0.60, 0.70),
    Offset(0.80, 0.64),
    Offset(1, 0.78),
  ]);
}

/// En-tête de marque : dégradé violet, lignes topographiques, petites étoiles,
/// et vague blanche en bas. Utilisé par l'accueil, la connexion et l'inscription.
class BrandHeaderPainter extends CustomPainter {
  const BrandHeaderPainter({this.wave});

  /// `null` : texture seule, sans vague blanche (ex. fond de carte).
  final AuthWave? wave;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.violetRoyal, AppColors.violetRoyalAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.11);
    // (centre, nombre de courbes, écart, déphasage) : réparti sur tout l'en-tête.
    const groups = [
      (Offset(0.12, 0.18), 6, 0.055, 0.0),
      (Offset(0.72, 0.10), 7, 0.06, 1.3),
      (Offset(0.48, 0.52), 6, 0.05, 2.1),
      (Offset(1.02, 0.55), 5, 0.06, 0.7),
      (Offset(0.05, 0.72), 4, 0.05, 2.8),
    ];
    final unit = math.min(w, h);
    for (final (c, count, step, phase) in groups) {
      final center = Offset(c.dx * w, c.dy * h);
      for (var i = 0; i < count; i++) {
        canvas.drawPath(_wobblyLoop(center, unit * (0.05 + i * step), phase + i * 0.55), contour);
      }
    }

    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.55);
    const stars = [
      (Offset(0.30, 0.14), 4.5),
      (Offset(0.86, 0.34), 3.5),
      (Offset(0.18, 0.50), 3.0),
      (Offset(0.64, 0.28), 2.8),
      (Offset(0.92, 0.70), 4.0),
    ];
    for (final (p, r) in stars) {
      canvas.drawPath(_sparkle(Offset(p.dx * w, p.dy * h), r), sparkle);
    }

    final wave = this.wave;
    if (wave == null) return;
    final pts = wave.points.map((p) => Offset(p.dx * w, p.dy * h)).toList();
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..cubicTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy, pts[3].dx, pts[3].dy)
      ..cubicTo(pts[4].dx, pts[4].dy, pts[5].dx, pts[5].dy, pts[6].dx, pts[6].dy)
      ..lineTo(w, h + 1)
      ..lineTo(0, h + 1)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  Path _wobblyLoop(Offset c, double r, double phase) {
    final path = Path();
    const steps = 80;
    for (var s = 0; s <= steps; s++) {
      final t = s / steps * 2 * math.pi;
      final rr = r * (1 + 0.12 * math.sin(3 * t + phase) + 0.06 * math.cos(5 * t - phase));
      final p = Offset(c.dx + rr * math.cos(t), c.dy + rr * 0.75 * math.sin(t));
      if (s == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  Path _sparkle(Offset c, double r) {
    final k = r * 0.28;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
  }

  @override
  bool shouldRepaint(covariant BrandHeaderPainter oldDelegate) => oldDelegate.wave != wave;
}

/// Squelette des écrans de connexion / inscription : en-tête de marque sur
/// [headerFraction] de la hauteur d'écran, formulaire en dessous. Le titre
/// remonte dans le creux blanc de la vague, comme sur la maquette.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.headerFraction = 0.45,
    this.wave = AuthWave.signIn,
    this.overlay,
  });

  final String title;
  final List<Widget> children;

  /// Calé en bas de l'écran (ex. lien vers l'autre écran d'authentification).
  final Widget? footer;
  final double headerFraction;
  final AuthWave wave;

  /// Affiché par-dessus tout l'écran (ex. loader pendant la connexion).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final headerHeight = media.size.height * headerFraction;
    // Le blanc commence vers 80 % de l'en-tête à gauche : le titre s'y loge.
    final bodyTop = headerHeight * 0.83;
    final logoZone = headerHeight * 0.64 - media.padding.top;
    final bottomPadding = 20 + media.padding.bottom;
    // Sur tablette, le formulaire reste dans une colonne lisible au centre.
    final hPad = media.size.width > 560 ? (media.size.width - 480) / 2 : 28.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.onDarkHeader,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Stack(
                children: [
                  SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: CustomPaint(painter: BrandHeaderPainter(wave: wave)),
                  ),
                  Positioned(
                    top: media.padding.top,
                    left: 0,
                    right: 0,
                    height: logoZone,
                    child: Center(
                      child: Image.asset(AppAssets.logoWhite, height: 54, fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, bodyTop, hPad, bottomPadding),
                    child: ConstrainedBox(
                      // Remplit au moins l'écran : le pied de page reste en bas.
                      constraints: BoxConstraints(minHeight: media.size.height - bodyTop - bottomPadding),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthTitle(title),
                            const SizedBox(height: 24),
                            ...children,
                            if (footer != null) ...[
                              const Spacer(),
                              const SizedBox(height: 24),
                              footer!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

/// Titre avec un trait doré sous 70 % de sa largeur.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppTypography.textTheme.displayMedium?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.7,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.orAfricain,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.noirDoux.withValues(alpha: 0.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.noirDoux.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword && obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onChanged: onChanged,
          style: AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.noirDoux),
          cursorColor: AppColors.violetRoyal,
          decoration: InputDecoration(
            // Le thème global remplit les champs en beige : ici, style ligne fine.
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            prefixIcon: Icon(icon, size: 19, color: muted),
            prefixIconConstraints: const BoxConstraints(minWidth: 30),
            hintText: hint,
            hintStyle: TextStyle(color: muted, fontSize: 14),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.noirDoux.withValues(alpha: 0.12)),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.noirDoux.withValues(alpha: 0.08)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.violetRoyal, width: 2),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: muted),
                    onPressed: onToggleObscure,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ],
    );
  }
}

/// Bouton principal + bouton Google rond sur la même ligne (gain de place).
class AuthActionsRow extends StatelessWidget {
  const AuthActionsRow({
    super.key,
    required this.label,
    required this.onPressed,
    required this.onGoogle,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onGoogle;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AuthPrimaryButton(label: label, onPressed: onPressed, loading: loading)),
        const SizedBox(width: 12),
        AuthGoogleIconButton(onPressed: onGoogle),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violetRoyal,
          disabledBackgroundColor: AppColors.violetRoyal.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class AuthGoogleIconButton extends StatelessWidget {
  const AuthGoogleIconButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Continuer avec Google',
      child: SizedBox(
        width: 52,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            side: BorderSide(color: AppColors.noirDoux.withValues(alpha: 0.14)),
          ),
          child: Image.asset(AppAssets.googleLogo, width: 22, height: 22, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Ligne « Pas encore de compte ? Créer un compte ».
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.linkLabel,
    required this.onTap,
  });

  final String text;
  final String linkLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$text ',
            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.noirDoux.withValues(alpha: 0.6)),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              linkLabel,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.violetRoyal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message d'erreur sous le formulaire.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
