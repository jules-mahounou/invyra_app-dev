import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_id_service.dart';

/// Rattache l'identifiant d'appareil local au compte qui vient de se connecter.
///
/// Appelé depuis l'écouteur `onAuthStateChange` (un seul point d'entrée pour
/// les 3 chemins : inscription email, connexion email, Google OAuth). En cas
/// de conflit (un autre compte gratuit est déjà lié à cet appareil — violation
/// de la contrainte unique partielle `users_device_id_gratuit_unique`), on ne
/// fait rien de plus ici : `device_id` reste `null` pour ce compte, et
/// `EventService.checkEventCreationQuota()` affichera le message adapté au
/// moment de créer un événement.
/// `true` si un compte gratuit est déjà lié à cet appareil. Utilisable sans
/// être connecté (écran d'inscription). En cas d'erreur réseau, renvoie
/// `false` : l'avertissement est un confort, pas une barrière.
Future<bool> deviceHasFreeAccount() async {
  try {
    final deviceId = await DeviceIdService.instance.getOrCreateDeviceId();
    final result = await Supabase.instance.client.rpc(
      'device_has_free_account',
      params: {'p_device_id': deviceId},
    );
    return result == true;
  } catch (e) {
    debugPrint('deviceHasFreeAccount: $e');
    return false;
  }
}

Future<void> linkDeviceToCurrentUser() async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return;

  try {
    final deviceId = await DeviceIdService.instance.getOrCreateDeviceId();
    final updated = await client
        .from('users')
        .update({'device_id': deviceId})
        .eq('id', userId)
        .select('id');
    // RLS qui refuse l'UPDATE ne lève pas d'erreur : 0 ligne modifiée.
    if (updated.isEmpty) {
      debugPrint('linkDeviceToCurrentUser: aucune ligne mise à jour (policy RLS ?)');
    }
  } on PostgrestException catch (e) {
    if (e.code == '23505') {
      // Device déjà lié à un autre compte gratuit : comportement attendu, rien à faire.
      return;
    }
    debugPrint('linkDeviceToCurrentUser: $e');
  } catch (e) {
    debugPrint('linkDeviceToCurrentUser: $e');
  }
}
