// ============================================================
// TEMPLATE : Sacred Lilies
// CATÉGORIE : bapteme
// NIVEAU : gratuit
// ANIMÉ : non
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Invitation de baptême blanche et lavande avec lys dessinés aux coins et croix dorée centrale.
// Une esthétique sacrée, douce et lumineuse pour les cérémonies familiales.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → prénom ou nom de cérémonie en titre principal
// - date           → ligne d'information avec icône calendrier
// - lieu           → ligne d'information avec icône localisation
// - heure          → ligne d'information avec icône horloge si fourni
// - nomCouple      → non utilisé
// - message        → message de bénédiction au centre
// - logoUrl        → photo/logo dans médaillon lavande, fallback colombe
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateSacredLilies extends StatefulWidget {
  final InvitationData data;
  const TemplateSacredLilies({required this.data, super.key});
  @override State<TemplateSacredLilies> createState() => _TemplateSacredLiliesState();
}

class _TemplateSacredLiliesState extends State<TemplateSacredLilies> with TickerProviderStateMixin {
  static const lavender = Color(0xFFE8D5F5);
  static const gold = Color(0xFFD4A017);
  static const ink = Color(0xFF1F1F1F);
  @override void initState() { super.initState(); }
  @override void dispose() { super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    return Container(
      width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: lavender.withOpacity(.55), blurRadius: 26, offset: const Offset(0, 14))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: CustomPaint(painter: _LiliesPainter(), child: Padding(
        padding: const EdgeInsets.all(22), child: Container(
          constraints: const BoxConstraints(minHeight: 656), padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: lavender, width: 2)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Logo(logoUrl: data.logoUrl), const SizedBox(height: 18),
            const Icon(Icons.church_rounded, color: gold, size: 30), const SizedBox(height: 10),
            Text('BAPTÊME', style: GoogleFonts.poppins(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700, color: ink.withOpacity(.45))),
            const SizedBox(height: 16),
            Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 44, height: 1.05, fontWeight: FontWeight.w700, color: const Color(0xFF5B21B6))),
            const SizedBox(height: 14), Container(width: 94, height: 1, color: gold.withOpacity(.7)),
            const SizedBox(height: 24), _Line(icon: Icons.calendar_today_rounded, text: data.date),
            if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 10), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())],
            const SizedBox(height: 10), _Line(icon: Icons.place_rounded, text: data.lieu),
            if (data.customField1Label != null && data.customField1Value != null && data.customField1Value!.trim().isNotEmpty) ...[const SizedBox(height: 18), Text('${data.customField1Label}: ${data.customField1Value}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: ink.withOpacity(.65), fontWeight: FontWeight.w600))],
            if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 24), Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: lavender.withOpacity(.24), borderRadius: BorderRadius.circular(20), border: Border.all(color: lavender)), child: Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 17, height: 1.45, fontStyle: FontStyle.italic, color: ink.withOpacity(.82))))],
            const SizedBox(height: 18), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
            const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: ink.withOpacity(.5)))),
          ]),
        ),
      ))),
    );
  }
}
class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 72, height: 72, padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE8D5F5).withOpacity(.7)), child: ClipOval(child: Container(color: Colors.white, child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.flutter_dash_rounded, color: Color(0xFFD4A017), size: 34)) : const Icon(Icons.flutter_dash_rounded, color: Color(0xFFD4A017), size: 34)))); }}
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xFFD4A017), size: 18), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F).withOpacity(.78))))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8D5F5))), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48))); }
class _LiliesPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final p = Paint()..color = Colors.white.withOpacity(.0); canvas.drawRect(Offset.zero & size, p); final stem = Paint()..color = const Color(0xFFE8D5F5).withOpacity(.7)..strokeWidth = 1.2..style = PaintingStyle.stroke; final petal = Paint()..color = const Color(0xFFE8D5F5).withOpacity(.32)..style = PaintingStyle.fill; void lily(Offset o, double s) { canvas.drawLine(o, o + Offset(0, 54 * s), stem); for (var i = 0; i < 3; i++) { canvas.save(); canvas.translate(o.dx, o.dy); canvas.rotate((-0.55 + i * 0.55)); canvas.drawOval(Rect.fromCenter(center: Offset(0, -16 * s), width: 13 * s, height: 34 * s), petal); canvas.restore(); } } lily(const Offset(48, 88), 1); lily(Offset(size.width - 48, 88), -1); lily(Offset(48, size.height - 88), -1); lily(Offset(size.width - 48, size.height - 88), 1); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
