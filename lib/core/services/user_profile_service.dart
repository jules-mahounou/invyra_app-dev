import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String accountType;

  const UserProfile({required this.accountType});
}

class UserProfileService {
  UserProfileService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UserProfile> fetch() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Session expirée. Veuillez vous reconnecter.');
    }

    final row = await _client.from('users').select('account_type').eq('id', userId).single();

    return UserProfile(accountType: row['account_type'] as String);
  }
}
