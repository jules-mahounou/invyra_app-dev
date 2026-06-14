import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_schema.dart';

class EventService {
  final _client = Supabase.instance.client;

  /// Récupère tous les événements créés par l'utilisateur connecté
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

  /// Vérifie le quota de création d'événements selon le type de compte de l'utilisateur
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

  /// Crée un nouvel événement initial
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
    int? guestQuota,
    Map<String, dynamic>? metadata,
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
        'guest_quota': guestQuota,
        'metadata': metadata != null && metadata.isNotEmpty ? metadata : {'customField1Label': null, 'customField1Value': null, 'customField2Label': null, 'customField2Value': null},
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

  /// Met à jour le logo d'un événement
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

  /// Récupère les détails complets d'un événement par son ID
  Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final response = await _client
          .from('events')
          .select('''
            *,
            guests(id, full_name, phone, email, import_source, created_at),
            event_templates(id, name, tier, asset_path, preview_url, class_name, web_template_key),
            invitations(status)
          ''')
          .eq('id', eventId)
          .eq('user_id', _client.auth.currentUser!.id)
          .single();

      final data = Map<String, dynamic>.from(response);

      // Calculer guests_declined depuis les invitations avec status = 'decline'
      final invitations = data['invitations'] as List? ?? [];
      data['guests_declined'] = invitations
          .where((i) => i['status'] == 'decline')
          .length;

      return data;
    } on PostgrestException catch (e) {
      throw Exception('Erreur base de données : ${e.message}');
    } catch (e) {
      throw Exception(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  /// Met à jour les informations globales d'un événement
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
    int? guestQuota,
    Map<String, dynamic>? metadata,
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
        'guest_quota': guestQuota,
        'metadata': metadata,
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

  /// Supprime un événement
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

  /// Met à jour le statut d'un événement (ex: à venir, terminé)
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

  /// Associe un template graphique à l'événement
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

  /// Récupère la liste des templates actifs filtrés par type d'événement
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

  /// Récupère l'intégralité des templates actifs
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