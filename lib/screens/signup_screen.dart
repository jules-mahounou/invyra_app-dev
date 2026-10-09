import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_error_message.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const _FullScreenPainter(waveRatio: 0.30),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.18),
                    Center(
                      child: Image.asset(
                        AppAssets.logoFull,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Créer un compte',
                      style: AppTypography.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.noirDoux,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 18),
                      height: 3,
                      width: 58,
                      decoration: BoxDecoration(
                        color: AppColors.orAfricain,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text('Nom d’utilisateur', style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'Choisissez un nom d’utilisateur',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    Text('Email', style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Text('Mot de passe', style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Créez un mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscure: obscurePassword,
                      onToggle: () => setState(() => obscurePassword = !obscurePassword),
                    ),
                    const SizedBox(height: 16),
                    Text('Confirmer le mot de passe', style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Répétez votre mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscure: obscureConfirm,
                      onToggle: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildPrimaryButton(),
                    const SizedBox(height: 16),
                    _buildGoogleButton(),
                    const SizedBox(height: 18),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Vous avez déjà un compte ?', style: AppTypography.textTheme.bodySmall),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(context, '/login'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.orAfricain),
                            child: const Text('Se connecter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signUpWithEmail,
      child: Opacity(
        opacity: _isLoading ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.violetRoyal,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blancCasse,
                  ),
                )
              : const Text(
                  'Créer un compte',
                  style: TextStyle(color: AppColors.blancCasse, fontWeight: FontWeight.w600, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blancCasse,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.12)),
      ),
      child: TextButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: Image.asset(
          AppAssets.googleLogo,
          width: 18,
          height: 18,
        ),
        label: const Text('Continuer avec Google'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.noirDoux,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() => _errorMessage = null);
        }
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: AppColors.noirDoux.withValues(alpha: 0.55)),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.noirDoux.withValues(alpha: 0.45), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.noirDoux.withValues(alpha: 0.12)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.orAfricain, width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.noirDoux.withValues(alpha: 0.55),
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }
}

class _FullScreenPainter extends CustomPainter {
  const _FullScreenPainter({required this.waveRatio});
  final double waveRatio;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.orAfricain, AppColors.violetRoyalAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final waveY = size.height * waveRatio;
    final path = Path()
      ..moveTo(0, waveY + 18)
      ..cubicTo(size.width * 0.05, waveY - 60, size.width * 0.35, waveY - 35, size.width * 0.50, waveY + 70)
      ..cubicTo(size.width * 0.72, waveY + 130, size.width * 1.0, waveY + 70, size.width, waveY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.blancCasse);
  }

  @override
  bool shouldRepaint(covariant _FullScreenPainter old) => old.waveRatio != waveRatio;
}
