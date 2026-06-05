// ============================================================
// TEMPLATE : Douceur Céleste
// CATÉGORIE : bapteme
// NIVEAU : gratuit
// ANIMÉ : oui
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Invitation de baptême bleu ciel avec nuages animés très lents et étoiles dorées.
// Le style est doux, pur et poétique, pensé pour une cérémonie familiale lumineuse.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → titre principal en typographie douce
// - date           → ligne d'information
// - lieu           → ligne d'information
// - heure          → ligne d'information si fourni
// - nomCouple      → non utilisé
// - message        → carte blanche translucide
// - logoUrl        → médaillon circulaire avec fallback colombe
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateDouceurCeleste extends StatefulWidget {
  final InvitationData data;
  const TemplateDouceurCeleste({required this.data, super.key});
  @override State<TemplateDouceurCeleste> createState() => _TemplateDouceurCelesteState();
}

class _TemplateDouceurCelesteState extends State<TemplateDouceurCeleste> with TickerProviderStateMixin {
  late final AnimationController _clouds;
  @override void initState() { super.initState(); _clouds = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat(); }
  @override void dispose() { _clouds.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    return AnimatedBuilder(animation: _clouds, builder: (_, __) => Container(
      width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0F4FF), Colors.white])),
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _SkyPainter(_clouds.value))),
        Padding(padding: const EdgeInsets.fromLTRB(26, 40, 26, 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          _Logo(logoUrl: data.logoUrl), const SizedBox(height: 26),
          Text('CÉLÉBRATION DE BAPTÊME', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, letterSpacing: 2.5, fontWeight: FontWeight.w700, color: const Color(0xFF5B21B6).withOpacity(.55))),
          const SizedBox(height: 14), Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 44, height: 1.05, fontWeight: FontWeight.w700, color: const Color(0xFF5B21B6))),
          const SizedBox(height: 26), _InfoCard(data: data),
          if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 22), Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.72), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFD4A017).withOpacity(.24))), child: Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: const Color(0xFF1F1F1F).withOpacity(.76))))],
          const SizedBox(height: 18), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
          const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF1F1F1F).withOpacity(.5)))),
        ])),
      ])),
    ));
  }
}
class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 74, height: 74, padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.82), boxShadow: [BoxShadow(color: const Color(0xFF5B21B6).withOpacity(.12), blurRadius: 22)]), child: ClipOval(child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.flutter_dash_rounded, color: Color(0xFFD4A017), size: 34)) : const Icon(Icons.flutter_dash_rounded, color: Color(0xFFD4A017), size: 34))); }}
class _InfoCard extends StatelessWidget { final InvitationData data; const _InfoCard({required this.data}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.78), borderRadius: BorderRadius.circular(26)), child: Column(children: [_Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.place_rounded, text: data.lieu)])); }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xFFD4A017), size: 18), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5B21B6))))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48))); }
class _SkyPainter extends CustomPainter { final double value; _SkyPainter(this.value); @override void paint(Canvas canvas, Size size) { final star = Paint()..color = const Color(0xFFD4A017).withOpacity(.48); for (var i = 0; i < 18; i++) { final x = ((i * 59) % 390).toDouble(); final y = 40 + ((i * 43) % 420).toDouble(); canvas.drawCircle(Offset(x, y), 1.4, star); } void cloud(double y, double speed, double scale) { final x = size.width - ((value * speed + 60) % (size.width + 170)); final p = Paint()..color = Colors.white.withOpacity(.82); canvas.drawCircle(Offset(x, y), 20 * scale, p); canvas.drawCircle(Offset(x + 22 * scale, y - 8 * scale), 28 * scale, p); canvas.drawCircle(Offset(x + 52 * scale, y), 22 * scale, p); canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20 * scale, y, 92 * scale, 22 * scale), Radius.circular(18 * scale)), p); } cloud(95, 230, 1); cloud(210, 170, .75); cloud(500, 135, .9); } @override bool shouldRepaint(covariant _SkyPainter oldDelegate) => oldDelegate.value != value; }
