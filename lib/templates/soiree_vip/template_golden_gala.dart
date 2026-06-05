// ============================================================
// TEMPLATE : Golden Gala
// CATÉGORIE : soiree_vip
// NIVEAU : premium
// ANIMÉ : non
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Invitation gala avec fond violet-or et carte centrale glassmorphism.
// Design prestigieux, élégant et lisible pour événements exclusifs.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → titre principal en Playfair blanc
// - date           → ligne d'information dans la carte centrale
// - lieu           → ligne d'information dans la carte centrale
// - heure          → ligne d'information si fourni
// - nomCouple      → non utilisé
// - message        → message dans la carte centrale
// - logoUrl        → hexagone doré en haut avec fallback diamant
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateGoldenGala extends StatefulWidget {
  final InvitationData data;
  const TemplateGoldenGala({required this.data, super.key});
  @override State<TemplateGoldenGala> createState() => _TemplateGoldenGalaState();
}

class _TemplateGoldenGalaState extends State<TemplateGoldenGala> with TickerProviderStateMixin {
  @override void initState() { super.initState(); }
  @override void dispose() { super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    return Container(width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2D0A5E), Color(0xFF5B21B6), Color(0xFFD4A017)])), child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GalaPainter())),
      Padding(padding: const EdgeInsets.fromLTRB(24, 40, 24, 20), child: ClipRRect(borderRadius: BorderRadius.circular(30), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: Container(
        constraints: const BoxConstraints(minHeight: 640), padding: const EdgeInsets.fromLTRB(24, 30, 24, 18), decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(.32))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _HexLogo(logoUrl: data.logoUrl), const SizedBox(height: 28),
          Text('GOLDEN INVITATION', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, letterSpacing: 2.7, color: Colors.white.withOpacity(.72), fontWeight: FontWeight.w700)),
          const SizedBox(height: 18), Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 42, height: 1.05, color: Colors.white, fontWeight: FontWeight.w700)),
          if (data.customField1Label != null && data.customField1Value != null && data.customField1Value!.trim().isNotEmpty) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFD4A017).withOpacity(.22), borderRadius: BorderRadius.circular(20)), child: Text('${data.customField1Label}: ${data.customField1Value}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)))],
          const SizedBox(height: 30), _Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 13), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 13), _Line(icon: Icons.place_rounded, text: data.lieu),
          if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 26), Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(.82)))],
          const SizedBox(height: 18), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
          const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(.5)))),
        ]),
      )))),
    ])));
  }
}
class _HexLogo extends StatelessWidget { final String? logoUrl; const _HexLogo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return ClipPath(clipper: _HexClipper(), child: Container(width: 84, height: 84, padding: const EdgeInsets.all(5), color: const Color(0xFFD4A017), child: ClipPath(clipper: _HexClipper(), child: Container(color: const Color(0xFF2D0A5E), child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.diamond_rounded, color: Color(0xFFD4A017), size: 38)) : const Icon(Icons.diamond_rounded, color: Color(0xFFD4A017), size: 38))))); }}
class _HexClipper extends CustomClipper<Path> { @override Path getClip(Size s) => Path()..moveTo(s.width * .5, 0)..lineTo(s.width, s.height * .25)..lineTo(s.width, s.height * .75)..lineTo(s.width * .5, s.height)..lineTo(0, s.height * .75)..lineTo(0, s.height * .25)..close(); @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false; }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: const Color(0xFFD4A017)), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(.9), fontWeight: FontWeight.w700)))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48))); }
class _GalaPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final p = Paint()..color = Colors.white.withOpacity(.08)..style = PaintingStyle.stroke..strokeWidth = 1.4; for (double r = 60; r < 380; r += 58) { canvas.drawCircle(Offset(size.width * .82, size.height * .12), r, p); } } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
