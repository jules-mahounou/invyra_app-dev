import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // Récupère l'utilisateur connecté
  User? get currentUser => _client.auth.currentUser;

  // Vérifie si l'utilisateur est authentifié
  bool get isLoggedIn => currentUser != null;

  // Flux des changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}