import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_schema.dart';

class EventService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyEvents() async {
    try {
      final response = await _client
          .from('events')
          .select('*, guests(count)')
          .eq('user_id', _client.auth.currentUser!.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<Map<String, dynamic>> checkEventCreationQuota() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final userResponse = await _client
          .from('users')
          .select('account_type')
          .eq('id', userId)
          .single();
      final accountType = userResponse['account_type'] as String;

      final planRow = await _client
          .from('subscription_plans')
          .select('max_events')
          .eq('code', accountType)
          .eq('is_active', true)
          .maybeSingle();

      final maxAllowed = planRow?['max_events'] as int?;
      // Secours si le plan gratuit n'est pas configuré en base.
      final effectiveMax = maxAllowed ?? (accountType == 'gratuit' ? 3 : null);

      final events = await _client
          .from('events')
          .select('id')
          .eq('user_id', userId);
      final currentCount = (events as List).length;

      return {
        'canCreate': effectiveMax == null || currentCount < effectiveMax,
        'currentCount': currentCount,
        'maxAllowed': effectiveMax,
        'accountType': accountType,
      };
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<String> createEvent({
    required String name,
    required String eventType,
    String? customType,
    DateTime? eventDate,
    String? place,
    double? placeLat,
    double? placeLng,
    String? description,
    String? logoUrl,
    String? sendChannel,
  }) async {
    try {
      final validatedType = eventTypeOrThrow(eventType);
      final validatedChannel = sendChannelOrDefault(sendChannel);

      final data = supabaseRow({
        'name': name.trim(),
        'event_type': validatedType,
        'user_id': _client.auth.currentUser!.id,
        'send_channel': validatedChannel,
        'custom_type': validatedType == 'autre'
            ? normalizeOptionalText(customType)
            : null,
        'event_date': eventDate?.toIso8601String(),
        'place': normalizeOptionalText(place),
        'place_lat': placeLat,
        'place_lng': placeLng,
        'description': normalizeOptionalText(description),
        'logo_url': normalizeOptionalText(logoUrl),
      });

      if (validatedType == 'autre' && !data.containsKey('custom_type')) {
        throw Exception('Le type personnalisé est obligatoire pour « Autre ».');
      }

      final response = await _client
          .from('events')
          .insert(data)
          .select()
          .single();
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> updateEventLogo({
    required String eventId,
    required String logoUrl,
  }) async {
    try {
      await _client
          .from('events')
          .update({'logo_url': logoUrl})
          .eq('id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final response = await _client
          .from('events')
          .select('''
            *,
            guests(id, full_name, phone, email, import_source, created_at),
            event_templates(id, name, tier, asset_path, preview_url)
          ''')
          .eq('id', eventId)
          .eq('user_id', _client.auth.currentUser!.id)
          .single();
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> updateEvent({
    required String eventId,
    String? name,
    String? eventType,
    String? customType,
    DateTime? eventDate,
    String? place,
    double? placeLat,
    double? placeLng,
    String? description,
    String? logoUrl,
    String? sendChannel,
  }) async {
    try {
      final validatedType = eventType == null
          ? null
          : eventTypeOrThrow(eventType);
      final validatedChannel = sendChannel == null
          ? null
          : sendChannelOrDefault(sendChannel);
      final data = supabaseRow({
        'name': normalizeOptionalText(name),
        'event_type': validatedType,
        'custom_type': validatedType == 'autre'
            ? normalizeOptionalText(customType)
            : null,
        'event_date': eventDate?.toIso8601String(),
        'place': normalizeOptionalText(place),
        'place_lat': placeLat,
        'place_lng': placeLng,
        'description': normalizeOptionalText(description),
        'logo_url': normalizeOptionalText(logoUrl),
        'send_channel': validatedChannel,
      });
      if (data.isEmpty) return;
      await _client
          .from('events')
          .update(data)
          .eq('id', eventId)
          .eq('user_id', _client.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _client
          .from('events')
          .delete()
          .eq('id', eventId)
          .eq('user_id', _client.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> updateEventStatus({
    required String eventId,
    required String status,
  }) async {
    try {
      final validatedStatus = requireDbEnum(status, kDbEventStatuses, 'status');
      await _client
          .from('events')
          .update({'status': validatedStatus})
          .eq('id', eventId)
          .eq('user_id', _client.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> updateEventTemplate({
    required String eventId,
    required String templateId,
  }) async {
    try {
      await _client
          .from('events')
          .update({'template_id': templateId})
          .eq('id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTemplatesByEventType(
    String eventType,
  ) async {
    try {
      final validatedType = eventTypeOrThrow(eventType);
      final response = await _client
          .from('event_templates')
          .select()
          .eq('event_type', validatedType)
          .eq('is_active', true)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    try {
      final response = await _client
          .from('event_templates')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }
}
