import 'package:flutter/material.dart';

import '../core/constants/app_nav_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Barre de navigation « billet » : fond blanc avec une encoche au centre
/// (comme la perforation d'un ticket) qui accueille le bouton scanner, et une
/// bulle violette qui s'anime sur l'onglet actif.
class InvyraNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onScanTap;

  const InvyraNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.onScanTap,
  });

  /// Hauteur visible de la barre (hors encart système et hors bouton qui dépasse).
  /// Hauteur visible de la barre blanche, hors encart système et hors partie
  /// du bouton scan qui dépasse au-dessus. L'écran doit réserver cette hauteur.
  static const barHeight = 66.0;
  static const _buttonSize = 58.0;
  static const _notchRadius = 36.0;
  // Partie du bouton qui dépasse au-dessus de la barre : incluse dans la
  // hauteur du widget pour que tout le bouton reste cliquable.
  static const _overflow = _buttonSize / 2 + 2;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Une moitié de barre (2 onglets). Les onglets gardent leur taille
    // naturelle ; seule la largeur max du texte de la bulle est calculée
    // d'après la place disponible, pour ne jamais déborder.
    Widget half(List<(int, IconData, String)> items) => Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labelMax = constraints.maxWidth - _NavItem.inactiveWidth - _NavItem.activeChrome - 4;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (index, icon, label) in items)
                    _NavItem(
                      icon: icon,
                      label: label,
                      selected: currentIndex == index,
                      maxLabelWidth: labelMax < 0 ? 0 : labelMax,
                      onTap: () => onChanged(index),
                    ),
                ],
              );
            },
          ),
        );

    return SizedBox(
      height: _overflow + barHeight + bottomInset,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomInset,
            child: PhysicalShape(
              clipper: const _TicketNotchClipper(radius: _notchRadius),
              color: Colors.white,
              elevation: 14,
              shadowColor: AppColors.noirDoux.withValues(alpha: 0.30),
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, bottomInset),
                child: Row(
                  children: [
                    half([(0, AppNavIcons.home, 'Accueil'), (1, AppNavIcons.events, 'Événements')]),
                    // Au-delà de ±34 du centre, l'encoche est assez peu profonde
                    // pour ne pas toucher les onglets centrés verticalement.
                    const SizedBox(width: 68),
                    half([(2, AppNavIcons.templates, 'Templates'), (3, AppNavIcons.profile, 'Profil')]),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: _overflow - _buttonSize / 2,
            left: 0,
            right: 0,
            child: Center(child: _ScannerButton(size: _buttonSize, onTap: onScanTap)),
          ),
        ],
      ),
    );
  }
}

class _TicketNotchClipper extends CustomClipper<Path> {
  const _TicketNotchClipper({required this.radius});

  final double radius;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const corner = 22.0;
    const shoulder = 8.0;
    const dip = 6.0;

    return Path()
      ..moveTo(0, corner)
      ..quadraticBezierTo(0, 0, corner, 0)
      ..lineTo(cx - radius - shoulder, 0)
      // Épaule arrondie à l'entrée de l'encoche, puis le creux du « ticket ».
      ..quadraticBezierTo(cx - radius, 0, cx - radius + 2, dip)
      ..arcToPoint(
        Offset(cx + radius - 2, dip),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..quadraticBezierTo(cx + radius, 0, cx + radius + shoulder, 0)
      ..lineTo(w - corner, 0)
      ..quadraticBezierTo(w, 0, w, corner)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant _TicketNotchClipper oldClipper) => oldClipper.radius != radius;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final double maxLabelWidth;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.maxLabelWidth,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 320);
  static const _iconSize = 22.0;
  static const _inactivePadding = 6.0;
  static const _activePadding = 10.0;
  static const _labelGap = 5.0;

  /// Largeur d'un onglet inactif (icône seule).
  static const inactiveWidth = _iconSize + 2 * _inactivePadding;

  /// Largeur de la bulle active hors texte.
  static const activeChrome = _iconSize + 2 * _activePadding + _labelGap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? _activePadding : _inactivePadding,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.violetRoyal : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: _iconSize,
                color: selected ? Colors.white : AppColors.noirDoux.withValues(alpha: 0.5),
              ),
              AnimatedSize(
                duration: _duration,
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: _labelGap),
                        // Rétrécit légèrement le texte sur les écrans étroits plutôt que de le couper.
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxLabelWidth),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _ScannerButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scanner les billets',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.violetRoyalAlt, AppColors.violetRoyal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violetRoyal.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(AppNavIcons.scanner, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

