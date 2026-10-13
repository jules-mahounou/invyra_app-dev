import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_gate.dart';
import 'core/auth/auth_session.dart';
import 'core/config/supabase_config.dart';
import 'core/services/device_link_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/subscription_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

bool get _hasActiveSession => Supabase.instance.client.auth.currentSession != null;

void _navigateTo(String routeName) {
  _navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (_) => false);
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    switch (data.event) {
      case AuthChangeEvent.initialSession:
        // Session restaurée au lancement : pas de `signedIn` dans ce cas,
        // on rattache quand même l'appareil (comptes existants avant l'anti-abus).
        if (data.session != null) {
          unawaited(linkDeviceToCurrentUser());
        }
      case AuthChangeEvent.signedIn:
        if (data.session != null) {
          unawaited(linkDeviceToCurrentUser());
          _navigateTo('/home');
        }
      case AuthChangeEvent.signedOut:
        if (!suppressSignedOutRoute) {
          _navigateTo('/login');
        }
      default:
        break;
    }
  });

  runApp(const InvyraApp());
}

class InvyraApp extends StatelessWidget {
  const InvyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = _hasActiveSession ? '/home' : '/onboarding';

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale(AppConstants.defaultLocale),
      ],
      initialRoute: initialRoute,
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final routeName = settings.name ?? '/onboarding';
  final session = Supabase.instance.client.auth.currentSession;

  const protectedRoutes = {'/home', '/create-event', '/subscription'};

  if (protectedRoutes.contains(routeName) && session == null) {
    return MaterialPageRoute<void>(
      builder: (_) => const LoginScreen(),
      settings: const RouteSettings(name: '/login'),
    );
  }

  switch (routeName) {
    case '/onboarding':
      return MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
    case '/login':
      final flashMessage = settings.arguments is String ? settings.arguments! as String : null;
      return MaterialPageRoute<void>(
        builder: (_) => LoginScreen(flashMessage: flashMessage),
        settings: settings,
      );
    case '/signup':
      return MaterialPageRoute<void>(
        builder: (_) => const SignupScreen(),
        settings: settings,
      );
    case '/home':
      return MaterialPageRoute<void>(
        builder: (_) => const AuthGate(child: MainScaffold()),
        settings: settings,
      );
    case '/create-event':
      return MaterialPageRoute<void>(
        builder: (_) => const AuthGate(
          child: MainScaffold(
            initialIndex: 1,
            initialCreateEventOpen: true,
          ),
        ),
        settings: settings,
      );
    case '/subscription':
      return MaterialPageRoute<void>(
        builder: (_) => const AuthGate(child: SubscriptionScreen()),
        settings: settings,
      );
    default:
      return MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
  }
}
