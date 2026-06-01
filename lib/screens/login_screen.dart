import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_error_message.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class LoginScreen extends StatefulWidget {
  final String? flashMessage;

  const LoginScreen({super.key, this.flashMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool rememberMe = false;
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.blancCasse,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const _FullScreenPainter(waveRatio: 0.32),
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
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connexion',
                      style: AppTypography.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.noirDoux,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 28),
                      height: 3,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.orAfricain,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text('Email', style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'demo@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    Text('Mot de passe', style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Entrez votre mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: _isLoading
                                ? null
                                : (v) => setState(() => rememberMe = v ?? false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: AppColors.orAfricain,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Text('Se souvenir de moi', style: AppTypography.textTheme.bodySmall),
                        const Spacer(),
                        TextButton(
                          onPressed: _isLoading ? null : () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.orAfricain,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ],
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
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _isLoading ? null : _signInWithEmail,
                      child: Opacity(
                        opacity: _isLoading ? 0.6 : 1,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.orAfricain, AppColors.violetRoyalAlt],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
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
                                  'Se connecter',
                                  style: TextStyle(
                                    color: AppColors.blancCasse,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGoogleButton(),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Vous n'avez pas de compte ?", style: AppTypography.textTheme.bodySmall),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => Navigator.pushNamed(context, '/signup'),
                          child: Text(
                            'Créer un compte',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.orAfricain,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
          width: 20,
          height: 20,
          fit: BoxFit.contain,
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
                onPressed: () => setState(() => obscure = !obscure),
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
      ..moveTo(0, waveY + 20)
      ..cubicTo(
        size.width * 0,
        waveY - 80,
        size.width * 0.50,
        waveY - 50,
        size.width * 0.50,
        waveY + 90,
      )
      ..cubicTo(
        size.width * 0.90,
        waveY + 140,
        size.width * 1,
        waveY + 70,
        size.width,
        waveY,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.blancCasse);
  }

  @override
  bool shouldRepaint(covariant _FullScreenPainter old) => old.waveRatio != waveRatio;
}
