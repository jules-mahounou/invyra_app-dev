import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration Supabase chargée depuis `.env` (voir `.env.example`).
abstract final class SupabaseConfig {
  static String get url => _require('SUPABASE_URL');

  /// Clé publishable (client Flutter) — ne pas utiliser la service_role ici.
  static String get anonKey => _require('SUPABASE_ANON_KEY');

  /// Deep link de retour auth (OAuth Google + confirmation email).
  /// À enregistrer dans Supabase : Authentication → URL Configuration → Redirect URLs.
  static String get authRedirectUrl => _require('AUTH_REDIRECT_URL');

  static String _require(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Variable d\'environnement manquante : $key. '
        'Copiez .env.example vers .env et renseignez les valeurs.',
      );
    }
    return value;
  }
}
