import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduit les erreurs Supabase Auth en messages français pour l'UI.
String authErrorMessage(Object error) {
  if (_isNetworkError(error)) {
    return 'Vérifiez votre connexion internet';
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (message.contains('email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter';
    }
    if (message.contains('email rate limit') ||
        message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Trop de tentatives, réessayez dans quelques minutes';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (message.contains('password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (message.contains('unable to validate email')) {
      return 'Adresse email invalide.';
    }
    if (message.contains('signup is disabled')) {
      return "L'inscription est temporairement désactivée.";
    }
    if (message.contains('provider is not enabled')) {
      return "La connexion Google n'est pas activée sur ce projet.";
    }

    return error.message;
  }

  if (error is PostgrestException) {
    return 'Erreur serveur : ${error.message}';
  }

  return 'Une erreur est survenue. Réessayez.';
}

bool _isNetworkError(Object error) {
  if (error is SocketException || error is HandshakeException || error is IOException) {
    return true;
  }
  if (error is TimeoutException) {
    return true;
  }
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed host lookup')) {
      return true;
    }
  }
  return false;
}
