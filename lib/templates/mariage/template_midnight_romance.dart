// ============================================================
// TEMPLATE : Midnight Romance
// CATÉGORIE : mariage
// NIVEAU : premium
// ANIMÉ : oui
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Invitation mariage nocturne avec étoiles scintillantes, pétales tombants et halo violet pulsant.
// Le design donne un rendu romantique, cinématique et premium.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → label supérieur en petites capitales
// - date           → panneau d'informations
// - lieu           → panneau d'informations
// - heure          → panneau d'informations si fourni
// - nomCouple      → grand titre blanc avec halo violet, fallback vers nomEvenement
// - message        → citation dans une carte sombre translucide
// - logoUrl        → médaillon supérieur avec fallback anneaux
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateMidnightRomance extends StatefulWidget {
  final InvitationData data;
  const TemplateMidnightRomance({required this.data, super.key});

  @override
  State<TemplateMidnightRomance> createState() => _TemplateMidnightRomanceState();
}

class _TemplateMidnightRomanceState extends State<TemplateMidnightRomance>
    with TickerProviderStateMixin {
  late final AnimationController _skyController;
  late final AnimationController _haloController;
  late final AnimationController _petalController;

  @override
  void initState() {
    super.initState();
    _skyController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _haloController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _petalController = AnimationController(vsync: this, duration: const Duration(seconds: 13))..repeat();
  }

  @override
  void dispose() {
    _skyController.dispose();
    _haloController.dispose();
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final title = data.nomCouple != null && data.nomCouple!.trim().isNotEmpty ? data.nomCouple!.trim() : data.nomEvenement;
    return AnimatedBuilder(
      animation: Listenable.merge([_skyController, _haloController, _petalController]),
      builder: (context, _) => Container(
        width: 390,
        constraints: const BoxConstraints(minHeight: 700),
        decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFF5B21B6).withOpacity(.42), blurRadius: 32, offset: const Offset(0, 18))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _RomancePainter(stars: _skyController.value, petals: _petalController.value))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Logo(logoUrl: data.logoUrl),
                    const SizedBox(height: 24),
                    Text('VOUS ÊTES INVITÉ(E)', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: const Color(0xFFE6B800).withOpacity(.92), fontSize: 11, letterSpacing: 2.8, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(data.nomEvenement.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white.withOpacity(.54), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withOpacity(.22 + _haloController.value * .34), blurRadius: 28 + _haloController.value * 22, spreadRadius: 1 + _haloController.value * 5)]),
                      child: Text(title, textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: title.length > 22 ? 39 : 48, height: 1.03, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    const SizedBox(height: 24),
                    Container(width: 160, height: 2, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [const Color(0xFFE6B800).withOpacity(.25 + _haloController.value * .35), const Color(0xFFB76E79), const Color(0xFFE6B800).withOpacity(.25 + _haloController.value * .35)]))),
                    const SizedBox(height: 26),
                    _InfoPanel(data: data),
                    if (data.message != null && data.message!.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.07), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.12))), child: Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(color: Colors.white.withOpacity(.86), fontStyle: FontStyle.italic, fontSize: 16, height: 1.45))),
                    ],
                    const SizedBox(height: 18),
                    if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
                    const Spacer(),
                    Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(.5)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logoUrl;
  const _Logo({this.logoUrl});
  @override
  Widget build(BuildContext context) {
    final has = logoUrl != null && logoUrl!.trim().isNotEmpty;
    return Container(width: 70, height: 70, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFE6B800), Color(0xFFB76E79), Color(0xFF5B21B6)])), child: ClipOval(child: Container(color: const Color(0xFF111111), child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.diversity_1_rounded, color: Color(0xFFE6B800), size: 32)) : const Icon(Icons.diversity_1_rounded, color: Color(0xFFE6B800), size: 32))));
  }
}

class _InfoPanel extends StatelessWidget {
  final InvitationData data;
  const _InfoPanel({required this.data});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE6B800).withOpacity(.2))), child: Column(children: [_Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.place_rounded, text: data.lieu)]));
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xFFE6B800), size: 18), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white.withOpacity(.88), fontWeight: FontWeight.w600, fontSize: 14)))]);
}

class _Qr extends StatelessWidget {
  final String url;
  const _Qr({required this.url});
  @override
  Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48)));
}

class _RomancePainter extends CustomPainter {
  final double stars;
  final double petals;
  _RomancePainter({required this.stars, required this.petals});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A0A0A), Color(0xFF160821), Color(0xFF0A0A0A)]).createShader(rect));
    for (var i = 0; i < 44; i++) {
      final x = ((i * 73) % 390).toDouble();
      final y = ((i * 47) % 700).toDouble();
      final tw = .5 + .5 * math.sin(stars * math.pi * 2 + i);
      canvas.drawCircle(Offset(x, y), .8 + (i % 3) * .5, Paint()..color = Colors.white.withOpacity(.18 + tw * .5));
    }
    for (var i = 0; i < 10; i++) {
      final d = (petals + i * .11) % 1;
      final x = ((i * 41) % 360) + 18 + math.sin(d * math.pi * 2 + i) * 18;
      final y = d * (size.height + 90) - 45;
      canvas.save(); canvas.translate(x, y); canvas.rotate(d * math.pi * 2); canvas.drawOval(const Rect.fromLTWH(-4, -7, 8, 14), Paint()..color = const Color(0xFFB76E79).withOpacity(.28)); canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _RomancePainter oldDelegate) => oldDelegate.stars != stars || oldDelegate.petals != petals;
}
