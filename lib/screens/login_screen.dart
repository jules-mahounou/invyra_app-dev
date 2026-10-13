import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_error_message.dart';
import '../core/config/supabase_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_loader.dart';
import '../core/widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  final String? flashMessage;

  const LoginScreen({super.key, this.flashMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final message = widget.flashMessage;
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.violetRoyal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError(String _) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez renseigner votre email et votre mot de passe.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : SupabaseConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Connexion',
      footer: AuthFooterLink(
        text: 'Pas encore de compte ?',
        linkLabel: 'Créer un compte',
        onTap: _isLoading ? null : () => Navigator.pushNamed(context, '/signup'),
      ),
      overlay: _isLoading
          ? Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.85),
                child: const AppLoader(size: 80),
              ),
            )
          : null,
      children: [
        AuthTextField(
          label: 'Email',
          controller: _emailController,
          hint: 'vous@exemple.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !_isLoading,
          onChanged: _clearError,
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Mot de passe',
          controller: _passwordController,
          hint: 'Votre mot de passe',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: obscure,
          onToggleObscure: () => setState(() => obscure = !obscure),
          autofillHints: const [AutofillHints.password],
          enabled: !_isLoading,
          onChanged: _clearError,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : () {},
            style: TextButton.styleFrom(foregroundColor: AppColors.violetRoyal),
            child: Text(
              'Mot de passe oublié ?',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.violetRoyal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          AuthErrorText(_errorMessage!),
          const SizedBox(height: 14),
        ] else
          const SizedBox(height: 6),
        AuthActionsRow(
          label: 'Se connecter',
          loading: _isLoading,
          onPressed: _signInWithEmail,
          onGoogle: _isLoading ? null : _signInWithGoogle,
        ),
      ],
    );
  }
}
