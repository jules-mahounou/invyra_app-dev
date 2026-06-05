// ============================================================
// TEMPLATE : Neon Birthday
// CATÉGORIE : anniversaire
// NIVEAU : premium
// ANIMÉ : oui
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Carte noire avec cadre néon violet pulsant, particules lumineuses et micro-effet glitch du titre.
// Pensée pour les anniversaires urbains, modernes et nocturnes.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → titre principal sous le headline néon
// - date           → ligne d'information
// - lieu           → ligne d'information
// - heure          → ligne d'information si fourni
// - nomCouple      → non utilisé
// - message        → bloc lumineux sous les détails
// - logoUrl        → avatar/logo rond avec fallback cadeau
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateNeonBirthday extends StatefulWidget {
  final InvitationData data;
  const TemplateNeonBirthday({required this.data, super.key});
  @override State<TemplateNeonBirthday> createState() => _TemplateNeonBirthdayState();
}

class _TemplateNeonBirthdayState extends State<TemplateNeonBirthday> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _particles;
  late final AnimationController _glitch;
  @override void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true); _particles = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(); _glitch = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(); }
  @override void dispose() { _pulse.dispose(); _particles.dispose(); _glitch.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    final glitchOffset = _glitch.value > .94 ? math.sin(_glitch.value * 120) * 2.5 : 0.0;
    return AnimatedBuilder(animation: Listenable.merge([_pulse, _particles, _glitch]), builder: (_, __) => Container(
      width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(30)),
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _NeonParticlesPainter(_particles.value))),
        Padding(padding: const EdgeInsets.all(20), child: Container(
          constraints: const BoxConstraints(minHeight: 660), padding: const EdgeInsets.fromLTRB(22, 30, 22, 18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFF5B21B6).withOpacity(.6 + .4 * _pulse.value), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF5B21B6).withOpacity(.28 + .35 * _pulse.value), blurRadius: 24 + 18 * _pulse.value, spreadRadius: 1)]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Logo(logoUrl: data.logoUrl), const SizedBox(height: 28),
            Transform.translate(offset: Offset(glitchOffset, 0), child: Text('VOUS ÊTES INVITÉ(E)', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, height: 1, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: const Color(0xFF5B21B6).withOpacity(.95), blurRadius: 18), Shadow(color: const Color(0xFFE6B800).withOpacity(.45), blurRadius: 32)]))),
            const SizedBox(height: 18),
            Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 38, height: 1.05, fontWeight: FontWeight.w900, color: const Color(0xFFE6B800))),
            const SizedBox(height: 28), _InfoBox(data: data),
            if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 22), Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(.84), fontWeight: FontWeight.w500))],
            const SizedBox(height: 18), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
            const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(.5)))),
          ]),
        )),
      ])),
    ));
  }
}
class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 74, height: 74, padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF5B21B6), boxShadow: [BoxShadow(color: const Color(0xFF5B21B6).withOpacity(.7), blurRadius: 20)]), child: ClipOval(child: Container(color: const Color(0xFF0D0D0D), child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE6B800), size: 34)) : const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE6B800), size: 34)))); }}
class _InfoBox extends StatelessWidget { final InvitationData data; const _InfoBox({required this.data}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE6B800).withOpacity(.35))), child: Column(children: [_Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.place_rounded, text: data.lieu)])); }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: const Color(0xFFE6B800)), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48))); }
class _NeonParticlesPainter extends CustomPainter { final double value; _NeonParticlesPainter(this.value); @override void paint(Canvas canvas, Size size) { for (var i = 0; i < 34; i++) { final d = (value + i * .071) % 1; final x = ((i * 53) % 390) + math.sin(d * math.pi * 2 + i) * 15; final y = size.height - d * (size.height + 80); final color = i.isEven ? const Color(0xFF5B21B6) : const Color(0xFFE6B800); canvas.drawCircle(Offset(x.toDouble(), y), 1.5 + (i % 4) * .7, Paint()..color = color.withOpacity(.24 + .36 * math.sin(d * math.pi))); } } @override bool shouldRepaint(covariant _NeonParticlesPainter oldDelegate) => oldDelegate.value != value; }
