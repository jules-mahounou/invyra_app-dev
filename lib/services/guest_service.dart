import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_schema.dart';
import '../core/services/edge_function_service.dart';

class GuestService {
  final _client = Supabase.instance.client;
  final _edgeService = const EdgeFunctionService();

  /// Vérifie que l'événement appartient bien à l'utilisateur connecté.
  /// Les tables `guests`/`invitations` n'ont pas de colonne `user_id` propre :
  /// on passe donc par l'événement parent pour éviter qu'un utilisateur
  /// ne manipule les invités d'un événement qui n'est pas le sien.
  Future<void> _assertEventOwnership(String eventId) async {
    final row = await _client
        .from('events')
        .select('id')
        .eq('id', eventId)
        .eq('user_id', _client.auth.currentUser!.id)
        .maybeSingle();
    if (row == null) {
      throw Exception('Événement introuvable ou accès refusé.');
    }
  }

  Future<Map<String, dynamic>> addGuest({
    required String eventId,
    required String fullName,
    String? phone,
    String? email,
    String importSource = 'manual',
  }) async {
    try {
      await _assertEventOwnership(eventId);
      final response = await _client
          .from('guests')
          .insert(
            supabaseRow({
              'event_id': eventId,
              'full_name': fullName.trim(),
              'phone': normalizeOptionalText(phone),
              'email': normalizeOptionalEmail(email),
              'import_source': importSource.isEmpty ? kDefaultGuestImportSource : importSource,
            }),
          )
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      // Code 23505 = violation de contrainte unique (doublon)
      if (e.code == '23505') {
        final field = e.message.contains('phone') ? 'numéro de téléphone' : 'email';
        throw Exception(
          'Un invité avec ce $field est déjà dans la liste. '
          'Chaque invité doit avoir un $field unique.',
        );
      }
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  /// Ajoute plusieurs invités en une seule requête (import contacts, liste
  /// collée, CSV/Excel) — bien plus rapide qu'un `addGuest` par invité.
  Future<List<Map<String, dynamic>>> addGuestsBulk({
    required String eventId,
    required List<({String fullName, String? phone, String? email})> guests,
    String importSource = 'manual',
  }) async {
    if (guests.isEmpty) return [];
    try {
      await _assertEventOwnership(eventId);
      final rows = guests
          .map((g) => supabaseRow({
                'event_id': eventId,
                'full_name': g.fullName.trim(),
                'phone': normalizeOptionalText(g.phone),
                'email': normalizeOptionalEmail(g.email),
                'import_source': importSource.isEmpty ? kDefaultGuestImportSource : importSource,
              }))
          .toList();
      final response = await _client.from('guests').insert(rows).select();
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          "Au moins un invité de cette liste a un numéro ou un email déjà utilisé "
          "(soit dans la liste elle-même, soit déjà présent dans l'événement). "
          "Retirez les doublons et réessayez.",
        );
      }
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  /// Corrige un invité déjà ajouté (faute de frappe sur le nom, le numéro...).
  Future<Map<String, dynamic>> updateGuest({
    required String guestId,
    required String eventId,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    try {
      await _assertEventOwnership(eventId);
      final response = await _client
          .from('guests')
          .update({
            'full_name': fullName.trim(),
            'phone': normalizeOptionalText(phone),
            'email': normalizeOptionalEmail(email),
          })
          .eq('id', guestId)
          .eq('event_id', eventId)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final field = e.message.contains('phone') ? 'numéro de téléphone' : 'email';
        throw Exception('Un autre invité utilise déjà ce $field.');
      }
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  Future<void> deleteGuest({
    required String guestId,
    required String eventId,
  }) async {
    try {
      await _assertEventOwnership(eventId);
      await _client
          .from('guests')
          .delete()
          .eq('id', guestId)
          .eq('event_id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  Future<List<Map<String, dynamic>>> getGuestsByEvent(String eventId) async {
    try {
      await _assertEventOwnership(eventId);
      final response = await _client.from('guests').select().eq('event_id', eventId);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

 

  Future<List<InvitationResult>> sendInvitations({
    required String eventId,
    required List<String> guestIds,
  }) async {
    try {

      return await _edgeService.sendInvitations(
        eventId: eventId,
        guestIds: guestIds,
        channel: 'whatsapp',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Envoie automatiquement, côté serveur, un email d'invitation à tous les
  /// invités de l'événement qui ont une adresse email renseignée — contrairement
  /// à WhatsApp, aucune action manuelle n'est nécessaire après cet appel.
  Future<({int sent, int failed, int skippedInvalid})> sendInvitationEmails({
    required String eventId,
  }) async {
    try {
      return await _edgeService.sendInvitationEmails(eventId: eventId);
    } catch (e) {
      // EdgeFunctionService traduit déjà les erreurs techniques en messages
      // compréhensibles — on les relaie tels quels plutôt que de les masquer.
      if (e is Exception) rethrow;
      throw Exception("L'envoi des emails a échoué. Vérifiez votre connexion et réessayez.");
    }
  }
}
