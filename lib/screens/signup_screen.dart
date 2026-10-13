import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_error_message.dart';
import '../core/config/supabase_config.dart';
import '../core/widgets/auth_layout.dart';
import '../core/services/device_link_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _deviceHasFreeAccount = false;

  @override
  void initState() {
    super.initState();
    deviceHasFreeAccount().then((value) {
      if (mounted && value) setState(() => _deviceHasFreeAccount = true);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _verifyUserProfile(String userId) async {
    final client = Supabase.instance.client;

    for (var attempt = 0; attempt < 5; attempt++) {
      final row = await client.from('users').select('id').eq('id', userId).maybeSingle();
      if (row != null) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  Future<void> _signUpWithEmail() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb ? null : SupabaseConfig.authRedirectUrl,
        data: {
          'username': username,
          'full_name': username,
        },
      );

      final user = response.user;
      if (user == null) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Impossible de créer le compte. Réessayez.');
        return;
      }

      if (response.session != null) {
        final profileReady = await _verifyUserProfile(user.id);
        if (!mounted) {
          return;
        }
        if (!profileReady) {
          setState(() {
            _errorMessage =
                'Compte créé, mais le profil n\'a pas encore été synchronisé. Réessayez de vous connecter.';
          });
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Compte créé. Vérifiez votre boîte mail pour confirmer votre inscription, puis connectez-vous.';
      });
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


  void _clearError(String _) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Inscription',
      headerFraction: 0.32,
      footer: AuthFooterLink(
        text: 'Vous avez déjà un compte ?',
        linkLabel: 'Se connecter',
        onTap: _isLoading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      children: [
        if (_deviceHasFreeAccount) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orAfricain.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.orAfricain),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Un compte gratuit existe déjà sur cet appareil. Un nouveau compte n’aura pas d’événements gratuits : connectez-vous plutôt avec votre compte existant, ou continuez pour souscrire une offre payante.',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        AuthTextField(
          label: 'Nom d’utilisateur',
          controller: _usernameController,
          hint: 'Choisissez un nom d’utilisateur',
          icon: Icons.person_outline_rounded,
          autofillHints: const [AutofillHints.username],
          enabled: !_isLoading,
          onChanged: _clearError,
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Mot de passe',
          controller: _passwordController,
          hint: 'Au moins 6 caractères',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: obscurePassword,
          onToggleObscure: () => setState(() => obscurePassword = !obscurePassword),
          autofillHints: const [AutofillHints.newPassword],
          enabled: !_isLoading,
          onChanged: _clearError,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirmer le mot de passe',
          controller: _confirmPasswordController,
          hint: 'Répétez votre mot de passe',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: obscureConfirm,
          onToggleObscure: () => setState(() => obscureConfirm = !obscureConfirm),
          enabled: !_isLoading,
          onChanged: _clearError,
        ),
        const SizedBox(height: 22),
        if (_errorMessage != null) ...[
          AuthErrorText(_errorMessage!),
          const SizedBox(height: 16),
        ],
        AuthActionsRow(
          label: 'Créer mon compte',
          loading: _isLoading,
          onPressed: _signUpWithEmail,
          onGoogle: _isLoading ? null : _signInWithGoogle,
        ),
      ],
    );
  }
}
