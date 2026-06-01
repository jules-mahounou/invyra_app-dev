import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_error_message.dart';
import '../core/auth/auth_session.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  String? _formError;
  String? _lengthError;
  String? _confirmMismatchError;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onFieldsChanged);
    _confirmPasswordController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    setState(() {
      if (_newPasswordController.text.length >= 8) {
        _lengthError = null;
      }
      if (_newPasswordController.text == _confirmPasswordController.text) {
        _confirmMismatchError = null;
      }
      if (_formError != null) {
        _formError = null;
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onFieldsChanged);
    _confirmPasswordController.removeListener(_onFieldsChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _formError = null;
      _lengthError = null;
      _confirmMismatchError = null;
    });

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _formError = 'Veuillez remplir tous les champs.');
      return;
    }

    if (newPassword.length < 8) {
      setState(() => _lengthError = 'Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _confirmMismatchError = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mot de passe mis à jour avec succès'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );

      suppressSignedOutRoute = true;
      try {
        await Supabase.instance.client.auth.signOut();
      } finally {
        suppressSignedOutRoute = false;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
        arguments: 'Veuillez vous reconnecter',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _PasswordStrength.from(_newPasswordController.text);

    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SecurityHeader(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        AppAssets.mascotDefault,
                        height: AppSpacing.xxl + AppSpacing.lg,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gardez votre compte en sécurité',
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.noirDoux.withValues(alpha: 0.56),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.cardDecoration.copyWith(
                    color: AppColors.beigeCremeAlt,
                    border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PasswordField(
                        controller: _currentPasswordController,
                        label: 'Mot de passe actuel',
                        obscureText: !_showCurrentPassword,
                        enabled: !_isLoading,
                        onVisibilityTap: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PasswordField(
                        controller: _newPasswordController,
                        label: 'Nouveau mot de passe',
                        obscureText: !_showNewPassword,
                        enabled: !_isLoading,
                        onVisibilityTap: () => setState(() => _showNewPassword = !_showNewPassword),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PasswordStrengthIndicator(strength: strength),
                      if (_lengthError != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _lengthError!,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _PasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirmer le nouveau mot de passe',
                        obscureText: !_showConfirmPassword,
                        enabled: !_isLoading,
                        onVisibilityTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      if (_confirmMismatchError != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _confirmMismatchError!,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _formError!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _GradientActionButton(
                  label: 'Mettre à jour le mot de passe',
                  icon: Icons.lock_reset_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _updatePassword,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    'Pour votre sécurité, vous serez déconnecté après le changement de mot de passe.',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.noirDoux.withValues(alpha: 0.52),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _SecurityHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.xxl,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.violetRoyal,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Sécurité & Mot de passe',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool enabled;
  final VoidCallback onVisibilityTap;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onVisibilityTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      style: AppTypography.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.violetRoyal),
        suffixIcon: IconButton(
          onPressed: enabled ? onVisibilityTap : null,
          icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          color: AppColors.noirDoux.withValues(alpha: 0.58),
        ),
        fillColor: AppColors.blancCasse,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.violetRoyal.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final _PasswordStrength strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: strength.progress,
            minHeight: AppSpacing.sm,
            backgroundColor: AppColors.noirDoux.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(strength.color),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strength.label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: strength.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrincipal,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blancCasse,
                  ),
                )
              : Icon(icon, size: AppSpacing.lg),
          label: Text(label, textAlign: TextAlign.center),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blancCasse,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength {
  final String label;
  final double progress;
  final Color color;

  const _PasswordStrength({
    required this.label,
    required this.progress,
    required this.color,
  });

  factory _PasswordStrength.from(String value) {
    final hasLetters = RegExp('[A-Za-z]').hasMatch(value);
    final hasDigits = RegExp(r'\d').hasMatch(value);
    final hasSymbols = RegExp(r'[^A-Za-z0-9]').hasMatch(value);

    if (value.length >= 10 && hasLetters && hasDigits && hasSymbols) {
      return const _PasswordStrength(label: 'Fort', progress: 1, color: AppColors.success);
    }
    if (value.length >= 6 && hasLetters && hasDigits) {
      return const _PasswordStrength(label: 'Moyen', progress: 0.62, color: AppColors.warning);
    }
    return const _PasswordStrength(label: 'Faible', progress: 0.28, color: AppColors.error);
  }
}
