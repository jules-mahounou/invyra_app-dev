import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

/// Protège un écran : redirige vers `/login` si aucune session active.
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({required this.child, super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool get _hasSession => Supabase.instance.client.auth.currentSession != null;

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    });
  }

  @override
  void initState() {
    super.initState();
    if (!_hasSession) {
      _redirectToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSession) {
      return const Material(
        color: AppColors.blancCasse,
        child: Center(child: CircularProgressIndicator(color: AppColors.violetRoyal)),
      );
    }
    return widget.child;
  }
}

/// Navigation vers un écran interne réservé aux utilisateurs connectés.
Future<void>? pushProtectedRoute(BuildContext context, Widget page) {
  if (Supabase.instance.client.auth.currentSession == null) {
    return Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AuthGate(child: page)),
  );
}
