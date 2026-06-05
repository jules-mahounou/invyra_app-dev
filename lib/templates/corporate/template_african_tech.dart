// ============================================================
// TEMPLATE : African Tech
// CATÉGORIE : corporate
// NIVEAU : premium
// ANIMÉ : oui
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Template tech premium violet profond avec circuits inspirés du kente et silhouette d'Afrique subtile.
// Les lignes de données s'illuminent en boucle pour créer un effet innovation et réseau.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → titre principal technologique
// - date           → bloc d'information
// - lieu           → bloc d'information
// - heure          → bloc d'information si fourni
// - nomCouple      → non utilisé
// - message        → pitch de l'événement
// - logoUrl        → logo circulaire en haut avec fallback hub
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateAfricanTech extends StatefulWidget {
  final InvitationData data;
  const TemplateAfricanTech({required this.data, super.key});
  @override State<TemplateAfricanTech> createState() => _TemplateAfricanTechState();
}

class _TemplateAfricanTechState extends State<TemplateAfricanTech> with TickerProviderStateMixin {
  late final AnimationController _flow;
  @override void initState() { super.initState(); _flow = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(); }
  @override void dispose() { _flow.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    return AnimatedBuilder(animation: _flow, builder: (_, __) => Container(width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(color: const Color(0xFF1A0533), borderRadius: BorderRadius.circular(30)), child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _TechPainter(_flow.value))),
      Padding(padding: const EdgeInsets.fromLTRB(24, 36, 24, 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        _Logo(logoUrl: data.logoUrl), const SizedBox(height: 30),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFD4A017).withOpacity(.35)), color: Colors.white.withOpacity(.06)), child: Text('AFRICAN TECH EXPERIENCE', style: GoogleFonts.poppins(fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: const Color(0xFFD4A017)))),
        const SizedBox(height: 22), Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 35, height: 1.08, color: Colors.white, fontWeight: FontWeight.w900)),
        if (data.customField1Label != null && data.customField1Value != null && data.customField1Value!.trim().isNotEmpty) ...[const SizedBox(height: 12), Text(data.customField1Value!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: Colors.white.withOpacity(.7), fontWeight: FontWeight.w600))],
        const SizedBox(height: 28), _DataPanel(data: data),
        if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 22), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.08))), child: Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(.82))))],
        const SizedBox(height: 18), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
        const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(.5)))),
      ])),
    ]))));
  }
}
class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 76, height: 76, padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFFD4A017)]), boxShadow: [BoxShadow(color: const Color(0xFFD4A017).withOpacity(.24), blurRadius: 20)]), child: ClipOval(child: Container(color: const Color(0xFF1A0533), child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, color: Color(0xFFD4A017), size: 36)) : const Icon(Icons.hub_rounded, color: Color(0xFFD4A017), size: 36)))); }}
class _DataPanel extends StatelessWidget { final InvitationData data; const _DataPanel({required this.data}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [Colors.white.withOpacity(.08), Colors.white.withOpacity(.035)]), border: Border.all(color: const Color(0xFFD4A017).withOpacity(.24))), child: Column(children: [_Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.place_rounded, text: data.lieu), if (data.customField2Label != null && data.customField2Value != null && data.customField2Value!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.record_voice_over_rounded, text: '${data.customField2Label}: ${data.customField2Value}')]])); }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: const Color(0xFFD4A017)), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48))); }
class _TechPainter extends CustomPainter { final double value; _TechPainter(this.value); @override void paint(Canvas canvas, Size size) { final africa = Paint()..color = Colors.white.withOpacity(.035)..style = PaintingStyle.fill; final path = Path()..moveTo(size.width * .55, 95)..cubicTo(310, 130, 282, 190, 302, 230)..cubicTo(330, 282, 260, 315, 248, 388)..cubicTo(238, 446, 190, 404, 176, 334)..cubicTo(162, 262, 110, 224, 150, 164)..cubicTo(185, 112, 240, 84, size.width * .55, 95)..close(); canvas.drawPath(path, africa); final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.35..color = const Color(0xFFD4A017).withOpacity(.20); final glow = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = const Color(0xFFE6B800).withOpacity(.65)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6); for (var i = 0; i < 9; i++) { final y = 80 + i * 58.0; final start = Offset(22, y); final mid = Offset(120 + (i % 3) * 50, y + (i.isEven ? 28 : -24)); final end = Offset(size.width - 24, y + (i.isEven ? 8 : 34)); final p = Path()..moveTo(start.dx, start.dy)..lineTo(mid.dx, mid.dy)..lineTo(end.dx, end.dy); canvas.drawPath(p, base); final local = (value + i * .08) % 1; final metric = p.computeMetrics().first; final seg = metric.extractPath(0, metric.length * local); canvas.drawPath(seg, glow); canvas.drawCircle(end, 3, Paint()..color = const Color(0xFFD4A017).withOpacity(.42)); } for (var i = 0; i < 24; i++) { final x = ((i * 37) % 390).toDouble(); final y = ((i * 61) % 700).toDouble(); canvas.drawCircle(Offset(x, y), 1.1 + math.sin(value * math.pi * 2 + i).abs(), Paint()..color = const Color(0xFF5B21B6).withOpacity(.22)); } } @override bool shouldRepaint(covariant _TechPainter oldDelegate) => oldDelegate.value != value; }
