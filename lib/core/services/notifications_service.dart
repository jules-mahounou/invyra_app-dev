import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';

class NotificationsService {
  NotificationsService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<AppNotification>> fetchAll() async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Session expirée. Veuillez vous reconnecter.');
    }

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => AppNotification.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final userId = _userId;
    if (userId == null) {
      return 0;
    }

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  Stream<List<Map<String, dynamic>>> watchUserNotifications() {
    final userId = _userId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _client.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId);
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
