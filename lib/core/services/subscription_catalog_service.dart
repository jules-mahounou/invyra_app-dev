import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flex_pack.dart';
import '../models/subscription_plan.dart';

class SubscriptionCatalog {
  final List<SubscriptionPlan> plans;
  final List<FlexPack> flexPacks;
  final String currentPlanCode;

  const SubscriptionCatalog({
    required this.plans,
    required this.flexPacks,
    required this.currentPlanCode,
  });
}

class SubscriptionCatalogService {
  SubscriptionCatalogService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _planOrder = ['gratuit', 'essentiel', 'flex'];

  Future<SubscriptionCatalog> fetch() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Session expirée. Veuillez vous reconnecter.');
    }

    final userRow = await _client.from('users').select('account_type').eq('id', userId).single();

    final plansResponse = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true);

    final plans = (plansResponse as List)
        .map((row) => SubscriptionPlan.fromJson(row as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        final indexA = _planOrder.indexOf(a.code);
        final indexB = _planOrder.indexOf(b.code);
        return (indexA == -1 ? 99 : indexA).compareTo(indexB == -1 ? 99 : indexB);
      });

    final flexResponse = await _client.from('flex_packs').select().order('guest_limit');

    final flexPacks =
        (flexResponse as List).map((row) => FlexPack.fromJson(row as Map<String, dynamic>)).toList();

    return SubscriptionCatalog(
      plans: plans,
      flexPacks: flexPacks,
      currentPlanCode: userRow['account_type'] as String,
    );
  }
}
