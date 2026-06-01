import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_dashboard_data.dart';
import '../models/recent_event.dart';

class HomeDashboardService {
  HomeDashboardService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<HomeDashboardData> fetch() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Session expirée. Veuillez vous reconnecter.');
    }

    final userRow = await _client
        .from('users')
        .select('full_name, account_type, avatar_url')
        .eq('id', userId)
        .single();

    final accountType = userRow['account_type'] as String;

    final planRow = await _client
        .from('subscription_plans')
        .select('code, max_events')
        .eq('code', accountType)
        .eq('is_active', true)
        .maybeSingle();

    final planCode = planRow?['code'] as String? ?? accountType;
    final maxEvents = planRow?['max_events'] as int?;

    final eventsResponse = await _client
        .from('events')
        .select(
          'id, name, event_date, place, status, guests_confirmed, invitations_sent, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final events = (eventsResponse as List).cast<Map<String, dynamic>>();
    final eventIds = events.map((event) => event['id'] as String).toList();

    var invitesDispatched = 0;
    if (eventIds.isNotEmpty) {
      final invitationsResponse = await _client
          .from('invitations')
          .select('id')
          .inFilter('event_id', eventIds)
          .inFilter('status', ['envoyee', 'livree', 'vue', 'confirmee']);
      invitesDispatched = (invitationsResponse as List).length;
    }

    final activeEvents = events.where((event) {
      final status = event['status'] as String?;
      return status == 'a_venir' || status == 'en_cours';
    }).length;

    var guestsConfirmed = 0;
    for (final event in events) {
      guestsConfirmed += (event['guests_confirmed'] as int?) ?? 0;
    }

    if (guestsConfirmed == 0 && eventIds.isNotEmpty) {
      final confirmedResponse = await _client
          .from('invitations')
          .select('id')
          .inFilter('event_id', eventIds)
          .eq('status', 'confirmee');
      guestsConfirmed = (confirmedResponse as List).length;
    }

    if (invitesDispatched == 0) {
      for (final event in events) {
        invitesDispatched += (event['invitations_sent'] as int?) ?? 0;
      }
    }

    final recentEvents = events.take(3).map(RecentEvent.fromJson).toList();

    return HomeDashboardData(
      userName: userRow['full_name'] as String? ?? '',
      accountType: accountType,
      avatarUrl: userRow['avatar_url'] as String?,
      planCode: planCode,
      maxEvents: maxEvents,
      activeEvents: activeEvents,
      guestsConfirmed: guestsConfirmed,
      invitesDispatched: invitesDispatched,
      quotaUsed: events.length,
      recentEvents: recentEvents,
    );
  }
}
