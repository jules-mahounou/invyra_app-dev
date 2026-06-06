import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_schema.dart';
import '../core/services/edge_function_service.dart';

class GuestService {
  final _client = Supabase.instance.client;
  final _edgeService = const EdgeFunctionService();

  Future<Map<String, dynamic>> addGuest({
    required String eventId,
    required String fullName,
    String? phone,
    String? email,
    String importSource = 'manual',
  }) async {
    try {
      final response = await _client
          .from('guests')
          .insert(
            supabaseRow({
              'event_id': eventId,
              'full_name': fullName.trim(),
              'phone': normalizeOptionalText(phone),
              'email': normalizeOptionalText(email),
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

  Future<void> deleteGuest(String guestId) async {
    try {
      await _client.from('guests').delete().eq('id', guestId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  Future<List<Map<String, dynamic>>> getGuestsByEvent(String eventId) async {
    try {
      final response = await _client.from('guests').select().eq('event_id', eventId);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
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
}
