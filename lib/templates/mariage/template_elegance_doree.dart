// ============================================================
// TEMPLATE : Élégance Dorée
// CATÉGORIE : mariage
// NIVEAU : gratuit
// ANIMÉ : non
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Invitation mariage intemporelle sur fond crème, bordure or fine et ornements de coins dessinés.
// Style luxueux, calme et raffiné pour les cérémonies élégantes.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → label supérieur discret
// - date           → ligne d'information avec icône calendrier
// - lieu           → ligne d'information avec icône localisation
// - heure          → ligne d'information avec icône horloge si fourni
// - nomCouple      → titre principal en Playfair Display, fallback vers nomEvenement
// - message        → encadré central crème/or
// - logoUrl        → cercle doré supérieur avec fallback floral
// - qrCodeUrl      → QR code en bas si disponible
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateEleganceDoree extends StatefulWidget {
  final InvitationData data;
  const TemplateEleganceDoree({required this.data, super.key});

  @override
  State<TemplateEleganceDoree> createState() => _TemplateEleganceDoreeState();
}

class _TemplateEleganceDoreeState extends State<TemplateEleganceDoree>
    with TickerProviderStateMixin {
  static const cream = Color(0xFFFFF8ED);
  static const gold = Color(0xFFD4A017);
  static const violet = Color(0xFF5B21B6);
  static const ink = Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final title = data.nomCouple != null && data.nomCouple!.trim().isNotEmpty
        ? data.nomCouple!.trim()
        : data.nomEvenement;
    return Container(
      width: 390,
      constraints: const BoxConstraints(minHeight: 700),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: gold.withOpacity(.2), blurRadius: 28, offset: const Offset(0, 16))],
      ),
      child: CustomPaint(
        painter: _CornerOrnamentsPainter(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            constraints: const BoxConstraints(minHeight: 656),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gold.withOpacity(.62), width: 1.2),
            ),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LogoSeal(logoUrl: data.logoUrl),
                const SizedBox(height: 18),
                Text(data.nomEvenement.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, letterSpacing: 2.4, color: violet.withOpacity(.72), fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                Text(title, textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: title.length > 22 ? 38 : 46, height: 1.02, color: violet, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 62, height: 1, color: gold.withOpacity(.55)), const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.auto_awesome, color: gold, size: 18)), Container(width: 62, height: 1, color: gold.withOpacity(.55))]),
                const SizedBox(height: 24),
                _InfoLine(icon: Icons.calendar_today_rounded, text: data.date),
                if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 10), _InfoLine(icon: Icons.schedule_rounded, text: data.heure!.trim())],
                const SizedBox(height: 10),
                _InfoLine(icon: Icons.location_on_rounded, text: data.lieu),
                if (data.message != null && data.message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.55), borderRadius: BorderRadius.circular(18), border: Border.all(color: gold.withOpacity(.3))),
                    child: Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.55, color: ink.withOpacity(.8))),
                  ),
                ],
                const SizedBox(height: 20),
                if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _QrCode(url: data.qrCodeUrl!.trim()),
                const SizedBox(height: 18),
                Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: ink.withOpacity(.5)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSeal extends StatelessWidget {
  final String? logoUrl;
  const _LogoSeal({this.logoUrl});
  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;
    return Container(
      width: 74,
      height: 74,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFE6B800), Color(0xFFD4A017)])),
      child: ClipOval(child: Container(color: const Color(0xFFFFF8ED), child: hasLogo ? Image.network(logoUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist_rounded, color: Color(0xFFD4A017), size: 32)) : const Icon(Icons.local_florist_rounded, color: Color(0xFFD4A017), size: 32))),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xFFD4A017), size: 18), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600, color: const Color(0xFF1F1F1F))))]);
}

class _QrCode extends StatelessWidget {
  final String url;
  const _QrCode({required this.url});
  @override
  Widget build(BuildContext context) => Container(width: 82, height: 82, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD4A017).withOpacity(.35))), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 48)));
}

class _CornerOrnamentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFD4A017).withOpacity(.48)..style = PaintingStyle.stroke..strokeWidth = 1.25..strokeCap = StrokeCap.round;
    void c(double x, double y, double sx, double sy) {
      final path = Path()
        ..moveTo(x + sx * 18, y)
        ..cubicTo(x + sx * 44, y + sy * 6, x + sx * 42, y + sy * 32, x + sx * 17, y + sy * 38)
        ..moveTo(x, y + sy * 22)
        ..cubicTo(x + sx * 12, y + sy * 42, x + sx * 40, y + sy * 42, x + sx * 50, y + sy * 18);
      canvas.drawPath(path, p);
    }
    c(24, 24, 1, 1); c(size.width - 24, 24, -1, 1); c(24, size.height - 24, 1, -1); c(size.width - 24, size.height - 24, -1, -1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
