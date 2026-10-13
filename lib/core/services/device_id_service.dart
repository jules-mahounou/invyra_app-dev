import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Identifiant d'appareil persistant, généré localement une seule fois.
///
/// Signal faible (contournable par désinstallation/réinstallation) utilisé
/// uniquement pour limiter l'abus occasionnel des comptes gratuits — voir
/// `device_link_service.dart`. Ce n'est pas un identifiant matériel (l'adresse
/// MAC est randomisée par l'OS depuis Android 10 / iOS 14 et inaccessible).
class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService instance = DeviceIdService._();

  static const _prefsKey = 'device_id';

  String? _cached;

  Future<String> getOrCreateDeviceId() async {
    final cached = _cached;
    if (cached != null) return cached;

    final prefs = SharedPreferencesAsync();
    final existing = await prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final generated = _generateId();
    await prefs.setString(_prefsKey, generated);
    _cached = generated;
    return generated;
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
