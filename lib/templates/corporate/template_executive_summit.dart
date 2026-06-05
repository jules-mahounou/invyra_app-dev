// ============================================================
// TEMPLATE : Executive Summit
// CATÉGORIE : corporate
// NIVEAU : gratuit
// ANIMÉ : non
//
// PACKAGES REQUIS (à ajouter dans pubspec.yaml si absents) :
// - google_fonts: ^6.1.0         (polices Poppins, Inter, Playfair Display)
//
// DESCRIPTION :
// Template corporate sobre, blanc cassé, structuré et professionnel avec accents violets.
// La hiérarchie est claire pour conférences, séminaires et sommets d'entreprise.
//
// CHAMPS DYNAMIQUES UTILISÉS :
// - nomEvenement   → titre principal corporate
// - date           → ligne d'information
// - lieu           → ligne d'information
// - heure          → ligne d'information si fourni
// - nomCouple      → non utilisé
// - message        → résumé ou description de l'événement
// - logoUrl        → logo entreprise centré en haut avec fallback business
// - qrCodeUrl      → QR code visible en bas si disponible
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invitation_data.dart';

class TemplateExecutiveSummit extends StatefulWidget {
  final InvitationData data;
  const TemplateExecutiveSummit({required this.data, super.key});
  @override State<TemplateExecutiveSummit> createState() => _TemplateExecutiveSummitState();
}

class _TemplateExecutiveSummitState extends State<TemplateExecutiveSummit> with TickerProviderStateMixin {
  static const violet = Color(0xFF5B21B6);
  static const gold = Color(0xFFD4A017);
  static const ink = Color(0xFF1F1F1F);
  @override void initState() { super.initState(); }
  @override void dispose() { super.dispose(); }
  @override Widget build(BuildContext context) {
    final data = widget.data;
    return Container(width: 390, constraints: const BoxConstraints(minHeight: 700), decoration: BoxDecoration(color: const Color(0xFFFCFCFC), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.grey.withOpacity(.28)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 24, offset: const Offset(0, 12))]), child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        _Logo(logoUrl: data.logoUrl), const SizedBox(height: 28),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE6E6E6)), bottom: BorderSide(color: Color(0xFFE6E6E6)))), child: Text('CORPORATE INVITATION', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, letterSpacing: 2.2, color: ink.withOpacity(.55), fontWeight: FontWeight.w700))),
        const SizedBox(height: 28), Text(data.nomEvenement, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 34, height: 1.12, color: violet, fontWeight: FontWeight.w800)),
        if (data.customField1Label != null && data.customField1Value != null && data.customField1Value!.trim().isNotEmpty) ...[const SizedBox(height: 12), Text(data.customField1Value!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 15, height: 1.4, color: ink.withOpacity(.66), fontWeight: FontWeight.w600))],
        const SizedBox(height: 30), _InfoBlock(data: data),
        if (data.customField2Label != null && data.customField2Value != null && data.customField2Value!.trim().isNotEmpty) ...[const SizedBox(height: 18), Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: violet.withOpacity(.06), borderRadius: BorderRadius.circular(16)), child: Text('${data.customField2Label}: ${data.customField2Value}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: violet, fontWeight: FontWeight.w800)))],
        if (data.message != null && data.message!.trim().isNotEmpty) ...[const SizedBox(height: 22), Text(data.message!.trim(), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: ink.withOpacity(.72)))],
        const SizedBox(height: 22), if (data.qrCodeUrl != null && data.qrCodeUrl!.trim().isNotEmpty) _Qr(url: data.qrCodeUrl!.trim()) else const Icon(Icons.qr_code_2_rounded, size: 82, color: violet),
        const Spacer(), Padding(padding: const EdgeInsets.only(top: 18), child: Text('Créé avec INVYRA', style: GoogleFonts.inter(fontSize: 10, color: ink.withOpacity(.5)))),
      ]),
    ));
  }
}
class _Logo extends StatelessWidget { final String? logoUrl; const _Logo({this.logoUrl}); @override Widget build(BuildContext context) { final has = logoUrl != null && logoUrl!.trim().isNotEmpty; return Container(width: 88, height: 88, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF5B21B6).withOpacity(.15))), child: has ? Image.network(logoUrl!.trim(), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.business_center_rounded, color: Color(0xFF5B21B6), size: 40)) : const Icon(Icons.business_center_rounded, color: Color(0xFF5B21B6), size: 40)); }}
class _InfoBlock extends StatelessWidget { final InvitationData data; const _InfoBlock({required this.data}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(.18))), child: Column(children: [_Line(icon: Icons.calendar_today_rounded, text: data.date), if (data.heure != null && data.heure!.trim().isNotEmpty) ...[const SizedBox(height: 12), _Line(icon: Icons.schedule_rounded, text: data.heure!.trim())], const SizedBox(height: 12), _Line(icon: Icons.place_rounded, text: data.lieu)])); }
class _Line extends StatelessWidget { final IconData icon; final String text; const _Line({required this.icon, required this.text}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: const Color(0xFFD4A017)), const SizedBox(width: 10), Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F))))]); }
class _Qr extends StatelessWidget { final String url; const _Qr({required this.url}); @override Widget build(BuildContext context) => Container(width: 92, height: 92, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF5B21B6).withOpacity(.25))), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5B21B6), size: 56))); }
