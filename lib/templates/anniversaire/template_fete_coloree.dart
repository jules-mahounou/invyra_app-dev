// ============================================================
// TEMPLATE : Fête Colorée
// CATÉGORIE : anniversaire
// NIVEAU : gratuit
// ANIMÉ : non
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Carte d'anniversaire vibrante avec dégradé orange-bordeaux, motifs wax stylisés et ballons décoratifs.
// Idéale pour une célébration chaleureuse, joyeuse et africaine contemporaine.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → titre de l'anniversaire
// - date           → ligne d'information avec icône calendrier
// - lieu           → ligne d'information avec icône localisation
// - heure          → ligne d'information avec icône horloge si fourni
// - nomCouple      → non utilisé
// - message        → message dans un ruban blanc translucide
// - logoUrl        → photo/logo circulaire avec fallback gâteau
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateFeteColoree extends StatefulWidget {
  final InvitationData data;
  const TemplateFeteColoree({required this.data, super.key});

  @override
  State<TemplateFeteColoree> createState() => _TemplateFeteColoreeState();
}

class _TemplateFeteColoreeState extends State<TemplateFeteColoree>
    with TickerProviderStateMixin {
  @override
  void initState() { super.initState(); }
  @override
  void dispose() { super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final age = data.customField1Value != null && RegExp(r'^\d{1,3}$').hasMatch(data.customField1Value!.trim()) ? data.customField1Value!.trim() : null;
    return Container(
      width: 390,
      constraints: const BoxConstraints(minHeight: 700),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6B35), Color(0xFF8B1A1A)])),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _WaxPainter())),
            const Positioned(left: -25, bottom: 20, child: _Balloon(color: Color(0xFFFFC857), size: 78)),
            const Positioned(right: -18, bottom: 60, child: _Balloon(color: Color(0xFF5B21B6), size: 70)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _Logo(logoUrl: data.logoUrl),
                const SizedBox(height: 24),
                Text('INVITATION ANNIVERSAIRE', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(.82))),
                if (age != null) ...[
                  const SizedBox(height: 8),
                  Text('$age ans', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 82, height: .95, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black.withOpacity(.16), blurRadius: 16, offset: const Offset(0, 8))])),
                ] else const SizedBox(height: 38),
                Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 34, height: 1.08, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 24),
                _InfoCard(data: data),
                if (data.message != null && data.message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(.22))), child: Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: Colors.white, fontWeight: FontWeight.w600))),
                ],
                const SizedBox(height: 18),
                if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()),
                const Spacer(),
                Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(.5)))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 78, height: 78, padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.94), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 9))]), child: ClipOval(child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.cake_rounded, color: Color(0xFFFF6B35), size: 36)) : const Icon(Icons.cake_rounded, color: Color(0xFFFF6B35), size: 36))); }}
class _InfoCard extends StatelessWidget { final InvitationData data; const _InfoCard({required this.data}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(26)), child: Column(children: [_Line(icon: Icons.calendar_month_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.access_time_filled_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.place_rounded, text: data.lieu)])); }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 19, color: const Color(0xFF8B1A1A)), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF8B1A1A))))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF8B1A1A), size: 48))); }
class _Balloon extends StatelessWidget { final Color color; final double size; const _Balloon({required this.color, required this.size}); @override Widget build(BuildContext context) => CustomPaint(size: Size(size, size * 1.4), painter: _BalloonPainter(color)); }
class _BalloonPainter extends CustomPainter { final Color color; _BalloonPainter(this.color); @override void paint(Canvas canvas, Size size) { canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height * .78), Paint()..color = color.withOpacity(.7)); final path = Path()..moveTo(size.width * .43, size.height * .77)..lineTo(size.width * .57, size.height * .77)..lineTo(size.width * .50, size.height * .88)..close(); canvas.drawPath(path, Paint()..color = color.withOpacity(.8)); canvas.drawLine(Offset(size.width / 2, size.height * .88), Offset(size.width * .46, size.height), Paint()..color = Colors.white.withOpacity(.4)..strokeWidth = 1.2); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
class _WaxPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = Colors.white.withOpacity(.10); for (double y = 30; y < size.height; y += 86) { for (double x = -20; x < size.width; x += 74) { canvas.drawCircle(Offset(x, y), 18, p); canvas.drawLine(Offset(x - 20, y), Offset(x + 20, y), p); canvas.drawLine(Offset(x, y - 20), Offset(x, y + 20), p); } } } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
