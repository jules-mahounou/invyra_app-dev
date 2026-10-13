import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_schema.dart';

class InvitationService {
  final _client = Supabase.instance.client;

  /// Vérifie que l'événement appartient bien à l'utilisateur connecté.
  /// La table `invitations` n'a pas de colonne `user_id` propre : on passe
  /// donc par l'événement parent pour éviter qu'un utilisateur ne manipule
  /// les invitations d'un événement qui n'est pas le sien.
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

  Future<void> createInvitationsForEvent({
    required String eventId,
    required String channel,
  }) async {
    try {
      await _assertEventOwnership(eventId);
      final validatedChannel = sendChannelOrDefault(channel);
      final guests = await _client
          .from('guests')
          .select('id')
          .eq('event_id', eventId);
      final rows = List<Map<String, dynamic>>.from(guests)
          .map(
            (guest) => {
              'event_id': eventId,
              'guest_id': guest['id'],
              'channel': validatedChannel,
              'status': 'brouillon',
            },
          )
          .toList();
      if (rows.isEmpty) return;
      await _client.from('invitations').insert(rows);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> markInvitationsAsSent(String eventId) async {
    try {
      await _assertEventOwnership(eventId);
      final now = DateTime.now().toUtc().toIso8601String();
      final sent = await _client
          .from('invitations')
          .update({'status': 'envoye', 'sent_at': now})
          .eq('event_id', eventId)
          .select('id');
      final sentCount = (sent as List).length;
      await _client
          .from('events')
          .update({'invitations_sent': sentCount})
          .eq('id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getInvitationsByEvent(
    String eventId,
  ) async {
    try {
      await _assertEventOwnership(eventId);
      final response = await _client
          .from('invitations')
          .select('''
            id,
            event_id,
            guest_id,
            channel,
            status,
            public_token,
            sent_at,
            delivered_at,
            viewed_at,
            confirmed_at,
            failure_reason,
            created_at,
            updated_at,
            guests(id, full_name, phone, email)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  /// Marque l'invitation d'un invité comme envoyée (ex: après un partage
  /// WhatsApp réussi), sans écraser un statut déjà plus avancé (vue/confirmé/
  /// décliné) — seul un "brouillon" peut passer à "envoyé" par cette méthode.
  Future<void> markGuestInvitationSent({
    required String eventId,
    required String guestId,
  }) async {
    try {
      await _assertEventOwnership(eventId);
      await _client
          .from('invitations')
          .update({
            'status': 'envoye',
            'sent_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('guest_id', guestId)
          .eq('status', 'brouillon');
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }
}
