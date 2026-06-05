// ============================================================
// TEMPLATE : Midnight Accra
// CATÉGORIE : soiree_vip
// NIVEAU : premium
// ANIMÉ : oui
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Invitation VIP noire et dorée avec badge central, halo animé et motifs géométriques africains.
// Les lignes lumineuses diagonales renforcent le caractère exclusif et nocturne.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → nom de la soirée sous le badge VIP
// - date           → information principale
// - lieu           → information principale
// - heure          → information principale si fourni
// - nomCouple      → non utilisé
// - message        → note d'accès VIP
// - logoUrl        → médaillon supérieur avec fallback étoile
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateMidnightAccra extends StatefulWidget {
  final InvitationData data;
  const TemplateMidnightAccra({required this.data, super.key});
  @override State<TemplateMidnightAccra> createState() => _TemplateMidnightAccraState();
}

class _TemplateMidnightAccraState extends State<TemplateMidnightAccra> with TickerProviderStateMixin {
  late final AnimationController _halo;
  late final AnimationController _sweep;
  @override void initState() { super.initState(); _halo = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true); _sweep = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(); }
  @override void dispose() { _halo.dispose(); _sweep.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    return AnimatedBuilder(animation: Listenable.merge([_halo, _sweep]), builder: (_, __) => Container(
      width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(30)),
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _AccraPainter(halo: _halo.value, sweep: _sweep.value))),
        Padding(padding: const EdgeInsets.fromLTRB(24, 34, 24, 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          _Logo(logoUrl: data.logoUrl), const SizedBox(height: 34),
          Transform.rotate(angle: _halo.value * math.pi * .08, child: Container(width: 132, height: 132, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4A017), width: 2), boxShadow: [BoxShadow(color: const Color(0xFFD4A017).withOpacity(.25 + .35 * _halo.value), blurRadius: 24 + 22 * _halo.value, spreadRadius: 3)]), child: Center(child: Text('VIP', style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2, color: const Color(0xFFD4A017))))),
          ),
          const SizedBox(height: 28), Text(data.nomEvenement.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 36, height: 1.05, fontWeight: FontWeight.w700, color: Colors.white)),
          if (data.customField1Label != null && data.customField1Value != null && data.customField1Value!.trim().isNotEmpty) ...[const SizedBox(height: 8), Text('${data.customField1Label}: ${data.customField1Value}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD4A017), fontWeight: FontWeight.w700, letterSpacing: 1.2))],
          const SizedBox(height: 26), _InfoPanel(data: data),
          if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 22), Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(.78)))],
          const SizedBox(height: 18), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
          const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(.5)))),
        ])),
      ])),
    ));
  }
}
class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 64, height: 64, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD4A017)), child: ClipOval(child: Container(color: const Color(0xFF0A0A0A), child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.star_rounded, color: Color(0xFFD4A017), size: 32)) : const Icon(Icons.star_rounded, color: Color(0xFFD4A017), size: 32)))); }}
class _InfoPanel extends StatelessWidget { final InvitationData data; const _InfoPanel({required this.data}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFD4A017).withOpacity(.35))), child: Column(children: [_Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.location_on_rounded, text: data.lieu)])); }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: const Color(0xFFD4A017)), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFFD4A017), size: 48))); }
class _AccraPainter extends CustomPainter { final double halo; final double sweep; _AccraPainter({required this.halo, required this.sweep}); @override void paint(Canvas canvas, Size size) { final geo = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = const Color(0xFFD4A017).withOpacity(.15); for (double y = 20; y < size.height; y += 54) { for (double x = 0; x < size.width; x += 54) { final path = Path()..moveTo(x, y + 27)..lineTo(x + 27, y)..lineTo(x + 54, y + 27)..lineTo(x + 27, y + 54)..close(); canvas.drawPath(path, geo); } } final p = Paint()..color = const Color(0xFFD4A017).withOpacity(.55)..strokeWidth = 2.2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8); for (var i = 0; i < 2; i++) { final dx = -size.width + (sweep + i * .5) % 1 * size.width * 2.4; canvas.drawLine(Offset(dx, size.height + 20), Offset(dx + 180, -20), p); } } @override bool shouldRepaint(covariant _AccraPainter oldDelegate) => oldDelegate.halo != halo || oldDelegate.sweep != sweep; }
