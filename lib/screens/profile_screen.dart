import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_gate.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/event_service.dart';
import 'notifications_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String accountType;

  const ProfileScreen({
    super.key,
    this.accountType = 'gratuit',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = Supabase.instance.client;
  final _eventService = EventService();

  bool _isLoading = true;
  String _fullName = '';
  String _username = '';
  String _bio = '';
  String? _avatarUrl;
  String _accountType = 'gratuit';
  int _eventsCount = 0;
  int? _maxEvents;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser!.id;
      
      // Charger profil et événements en parallèle
      final userDataFuture = _client.from('users').select('full_name, username, bio, avatar_url, account_type').eq('id', userId).single();
      final eventsFuture = _eventService.getMyEvents();
      
      final userData = await userDataFuture;
      final events = await eventsFuture;

      // Quota selon le plan
      final quota = await _eventService.checkEventCreationQuota();

      if (!mounted) return;
      setState(() {
        _fullName = userData['full_name'] as String? ?? '';
        _username = userData['username'] as String? ?? '';
        _bio = userData['bio'] as String? ?? '';
        _avatarUrl = userData['avatar_url'] as String?;
        _accountType = userData['account_type'] as String? ?? 'gratuit';
        _eventsCount = events.length;
        _maxEvents = quota['maxAllowed'] as int?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditProfile() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.blancCasse,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _EditProfileSheet(
        fullName: _fullName,
        username: _username,
        bio: _bio,
        avatarUrl: _avatarUrl,
      ),
    );
    if (saved == true) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(
        color: AppColors.blancCasse,
        child: Center(child: CircularProgressIndicator(color: AppColors.violetRoyal)),
      );
    }

    final plan = _ProfilePlan.from(_accountType);

    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: RefreshIndicator(
            color: AppColors.violetRoyal,
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeaderCard(
                    fullName: _fullName.isNotEmpty ? _fullName : 'Utilisateur',
                    username: _username,
                    bio: _bio,
                    avatarUrl: _avatarUrl,
                    plan: plan,
                    onEditTap: _openEditProfile,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SubscriptionSummary(
                    plan: plan,
                    eventsCount: _eventsCount,
                    maxEvents: _maxEvents,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SettingsMenu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String fullName;
  final String username;
  final String bio;
  final String? avatarUrl;
  final _ProfilePlan plan;
  final VoidCallback onEditTap;

  const _ProfileHeaderCard({
    required this.fullName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.plan,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.violetRoyal.withValues(alpha: 0.18),
            AppColors.violetRoyalAlt.withValues(alpha: 0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.cardDecoration.copyWith(
          color: AppColors.blancCasse,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            _ProfileAvatar(avatarUrl: avatarUrl, plan: plan),
            const SizedBox(height: AppSpacing.md),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.displayMedium?.copyWith(
                color: AppColors.noirDoux,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (username.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '@$username',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.noirDoux.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _AccountBadge(label: plan.memberLabel),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.noirDoux.withValues(alpha: 0.62),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEditTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violetRoyal,
                  foregroundColor: AppColors.blancCasse,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: const Text('Modifier le profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final _ProfilePlan plan;

  const _ProfileAvatar({required this.avatarUrl, required this.plan});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.beigeCremeBase,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.16), width: 2),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, _, _) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              decoration: BoxDecoration(
                color: AppColors.orAfricain,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blancCasse, width: 3),
              ),
              child: Icon(plan.icon, color: AppColors.blancCasse, size: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Icon(Icons.person_rounded, color: AppColors.violetRoyal.withValues(alpha: 0.72), size: AppSpacing.xxl);
  }
}

class _AccountBadge extends StatelessWidget {
  final String label;
  const _AccountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.violetRoyal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: AppColors.violetRoyal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Subscription Summary ─────────────────────────────────────────────────────

class _SubscriptionSummary extends StatelessWidget {
  final _ProfilePlan plan;
  final int eventsCount;
  final int? maxEvents;

  const _SubscriptionSummary({
    required this.plan,
    required this.eventsCount,
    required this.maxEvents,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlimited = maxEvents == null;
    final progress = isUnlimited ? 0.0 : (eventsCount / maxEvents!).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon abonnement',
            style: AppTypography.textTheme.displaySmall?.copyWith(
              color: AppColors.noirDoux,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.orAfricain.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.orAfricain, size: AppSpacing.lg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Plan ${plan.planLabel}',
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.noirDoux,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!isUnlimited) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppSpacing.sm,
                backgroundColor: AppColors.beigeCremeBase,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violetRoyal),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$eventsCount / $maxEvents événements utilisés',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.violetRoyal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Text(
              '✨ Événements illimités',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.orAfricain,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _GradientButton(
            label: plan.key == 'gratuit' ? '⚡ Voir les offres' : '⚡ Gérer mon abonnement',
            onPressed: () => Navigator.of(context).pushNamed('/subscription'),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Menu ────────────────────────────────────────────────────────────

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SettingsItemData(
        icon: Icons.notifications_none_rounded,
        label: 'Notifications',
        color: AppColors.warning,
        routeKey: 'notifications',
      ),
      const _SettingsItemData(
        icon: Icons.lock_outline_rounded,
        label: 'Sécurité & Mot de passe',
        color: AppColors.violetRoyal,
        routeKey: 'security',
      ),
      const _SettingsItemData(
        icon: Icons.logout_rounded,
        label: 'Se déconnecter',
        color: AppColors.error,
        destructive: true,
        showChevron: false,
      ),
    ];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.cardDecoration.copyWith(
        color: AppColors.blancCasse,
        border: Border.all(color: AppColors.noirDoux.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (final item in items) ...[
            _SettingsTile(data: item),
            if (item != items.last)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.noirDoux.withValues(alpha: 0.06),
                indent: AppSpacing.lg + AppSpacing.xl,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItemData data;
  const _SettingsTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.color, size: AppSpacing.md),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                data.label,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: data.destructive ? AppColors.error : AppColors.noirDoux,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (data.showChevron)
              Icon(Icons.chevron_right_rounded, color: AppColors.noirDoux.withValues(alpha: 0.38), size: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (data.destructive) {
      _signOut(context);
      return;
    }
    if (data.routeKey == 'notifications') {
      pushProtectedRoute(context, const NotificationsScreen());
      return;
    }
    if (data.routeKey == 'security') {
      pushProtectedRoute(context, const SecurityScreen());
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous serez redirigé vers l\'écran de connexion.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String fullName;
  final String username;
  final String bio;
  final String? avatarUrl;

  const _EditProfileSheet({
    required this.fullName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _client = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;

  Uint8List? _newAvatarBytes;
  String? _newAvatarFileName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.fullName);
    _usernameCtrl = TextEditingController(text: widget.username);
    _bioCtrl = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _newAvatarBytes = bytes;
      _newAvatarFileName = file.name;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final userId = _client.auth.currentUser!.id;
      String? avatarUrl;

      // Upload avatar si changé
      if (_newAvatarBytes != null && _newAvatarFileName != null) {
        final path = '$userId/avatar/$_newAvatarFileName';
        await _client.storage.from('event-logos').uploadBinary(
          path, _newAvatarBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
        avatarUrl = _client.storage.from('event-logos').getPublicUrl(path);
      }

      final updates = <String, dynamic>{
        'full_name': name,
        'bio': _bioCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final username = _usernameCtrl.text.trim();
      if (username.isNotEmpty) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _client.from('users').update(updates).eq('id', userId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg, right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.noirDoux.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Modifier le profil',
                  style: AppTypography.textTheme.displaySmall?.copyWith(
                    color: AppColors.noirDoux, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.beigeCremeAlt,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.violetRoyal.withValues(alpha: 0.2), width: 2),
                          ),
                          child: ClipOval(
                            child: _newAvatarBytes != null
                                ? Image.memory(_newAvatarBytes!, fit: BoxFit.cover)
                                : (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: widget.avatarUrl!, fit: BoxFit.cover)
                                    : Icon(Icons.person_rounded, color: AppColors.violetRoyal.withValues(alpha: 0.72), size: AppSpacing.xxl)),
                          ),
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.violetRoyal, shape: BoxShape.circle,
                              border: Border.all(color: AppColors.blancCasse, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppColors.blancCasse, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _field(_nameCtrl, 'Nom complet', Icons.person_outline_rounded, required: true),
                const SizedBox(height: AppSpacing.md),
                _field(_usernameCtrl, 'Nom d\'utilisateur', Icons.alternate_email_rounded),
                const SizedBox(height: AppSpacing.md),
                _field(_bioCtrl, 'Bio', Icons.notes_rounded, maxLines: 3),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.blancCasse,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.blancCasse.withValues(alpha: 0.55),
              child: const Center(child: CircularProgressIndicator(color: AppColors.violetRoyal)),
            ),
          ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, bool required = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTypography.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.violetRoyal),
        fillColor: AppColors.beigeCremeAlt,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.orAfricain.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.violetRoyal, width: 2),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.violetRoyal, borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blancCasse,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _ProfilePlan {
  final String key;
  final String memberLabel;
  final String planLabel;
  final IconData icon;

  const _ProfilePlan({required this.key, required this.memberLabel, required this.planLabel, required this.icon});

  factory _ProfilePlan.from(String value) {
    switch (value.toLowerCase()) {
      case 'flex':
        return const _ProfilePlan(key: 'flex', memberLabel: 'Membre Premium', planLabel: 'Flex', icon: Icons.star_rounded);
      case 'essentiel':
        return const _ProfilePlan(key: 'essentiel', memberLabel: 'Membre Essentiel', planLabel: 'Essentiel', icon: Icons.star_rounded);
      default:
        return const _ProfilePlan(key: 'gratuit', memberLabel: 'Membre Gratuit', planLabel: 'Découverte', icon: Icons.star_rounded);
    }
  }
}

class _SettingsItemData {
  final IconData icon;
  final String label;
  final Color color;
  final bool destructive;
  final bool showChevron;
  final String? routeKey;

  const _SettingsItemData({
    required this.icon,
    required this.label,
    required this.color,
    this.destructive = false,
    this.showChevron = true,
    this.routeKey,
  });
}
