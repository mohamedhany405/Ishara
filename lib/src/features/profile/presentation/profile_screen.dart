import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/api/auth_service.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/ishara_feedback.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameCtrl;
  String _selectedDisability = 'deaf';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startEditing(IsharaUser? user) {
    setState(() {
      _isEditing = true;
      _nameCtrl.text = user?.name ?? '';
      _selectedDisability = user?.disabilityType ?? 'deaf';
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final dataService = ref.read(dataServiceProvider);
    await dataService.updateProfile(
      name: _nameCtrl.text.trim(),
      disabilityType: _selectedDisability,
    );
    await ref.read(authProvider.notifier).refreshUser();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(ref).profileUpdated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    final dataService = ref.read(dataServiceProvider);
    final result = await dataService.updateAvatar(xFile.path);
    if (result.success) {
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(ref).avatarUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final s = t(ref);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(s.logout),
            content: Text(s.logoutConfirm),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: Text(s.cancel),
              ),
              TextButton(onPressed: () => ctx.pop(true), child: Text(s.logout)),
            ],
          ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Profile header with avatar ─────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              isDark: isDark,
              theme: theme,
              teal: teal,
              orange: orange,
              user: user,
              onAvatarTap: _pickAvatar,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── User info / edit card ──────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 80.ms,
                  child:
                      _isEditing
                          ? _EditProfileForm(
                            nameCtrl: _nameCtrl,
                            selectedDisability: _selectedDisability,
                            isSaving: _isSaving,
                            teal: teal,
                            isDark: isDark,
                            theme: theme,
                            onDisabilityChanged:
                                (v) => setState(() => _selectedDisability = v),
                            onSave: _saveProfile,
                            onCancel: () => setState(() => _isEditing = false),
                          )
                          : user == null
                          ? _GuestProfilePrompt(
                            teal: teal,
                            onTap: () => context.go(AppRoute.login),
                          )
                          : _UserInfoDisplay(
                            user: user,
                            teal: teal,
                            orange: orange,
                            isDark: isDark,
                            theme: theme,
                            onEdit: () => _startEditing(user),
                          ),
                ),

                const SizedBox(height: 12),

                // ── Appearance ──────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 180.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.palette_outlined,
                        label: s.appearance,
                        teal: teal,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _ThemePill(
                            label: s.light,
                            icon: Icons.light_mode_rounded,
                            selected: settings.themeMode == ThemeMode.light,
                            teal: teal,
                            onTap: () => notifier.setTheme(ThemeMode.light),
                          ),
                          const SizedBox(width: 10),
                          _ThemePill(
                            label: s.dark,
                            icon: Icons.dark_mode_rounded,
                            selected: settings.themeMode == ThemeMode.dark,
                            teal: teal,
                            onTap: () => notifier.setTheme(ThemeMode.dark),
                          ),
                          const SizedBox(width: 10),
                          _ThemePill(
                            label: s.system,
                            icon: Icons.brightness_auto_rounded,
                            selected: settings.themeMode == ThemeMode.system,
                            teal: teal,
                            onTap: () => notifier.setTheme(ThemeMode.system),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Language ───────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 260.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.language_rounded,
                        label: s.language,
                        teal: teal,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _LangChip(
                            label: 'English',
                            selected: settings.language == IsharaLanguage.en,
                            teal: teal,
                            onTap:
                                () => notifier.setLanguage(IsharaLanguage.en),
                          ),
                          const SizedBox(width: 10),
                          _LangChip(
                            label: 'العربية',
                            selected: settings.language == IsharaLanguage.ar,
                            teal: teal,
                            onTap:
                                () => notifier.setLanguage(IsharaLanguage.ar),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Accessibility ──────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 340.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.accessibility_new_rounded,
                        label: s.accessibility,
                        teal: teal,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.accessibilityDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isDark
                                  ? IsharaColors.mutedDark
                                  : IsharaColors.mutedLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.bluetooth_connected_rounded,
                        label: s.pairHardware,
                        subtitle: s.glassesOrCane,
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.hardwarePairing),
                      ),
                      const SizedBox(height: 8),
                      _ActionRow(
                        icon: Icons.accessibility_new_rounded,
                        label: 'Accessibility',
                        subtitle: 'TTS, contrast, dyslexia font, motor mode',
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.accessibility),
                      ),
                      const SizedBox(height: 8),
                      _ActionRow(
                        icon: Icons.contacts_rounded,
                        label: 'Emergency Contacts',
                        subtitle: 'Manage SOS recipients',
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.contacts),
                      ),
                      const SizedBox(height: 8),
                      _ActionRow(
                        icon: Icons.share_rounded,
                        label: 'Social Links',
                        subtitle: 'Instagram, Facebook, Twitter, TikTok…',
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.social),
                      ),
                      const SizedBox(height: 8),
                      _ActionRow(
                        icon: Icons.shopping_bag_rounded,
                        label: 'Shop',
                        subtitle: 'Accessibility products',
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.shop),
                      ),
                      const SizedBox(height: 8),
                      _ActionRow(
                        icon: Icons.smart_toy_rounded,
                        label: 'Assistant',
                        subtitle: 'Ask how to use Ishara',
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.assistant),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── About ──────────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 420.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.info_outline_rounded,
                        label: s.about,
                        teal: teal,
                      ),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.article_outlined,
                        label: s.version,
                        subtitle: s.versionSub,
                        teal: teal,
                        isDark: isDark,
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                // ── Logout ─────────────────────────────────────────────
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(s.logout),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: IsharaColors.cardRadius,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header – large gradient avatar area with real user data
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.isDark,
    required this.theme,
    required this.teal,
    required this.orange,
    required this.user,
    this.onAvatarTap,
  });
  final bool isDark;
  final ThemeData theme;
  final Color teal;
  final Color orange;
  final IsharaUser? user;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF0D2137) : const Color(0xFFE0F7F5),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar with gradient ring
          GestureDetector(
            onTap: onAvatarTap,
            child: Semantics(
              button: onAvatarTap != null,
              label: 'Profile picture',
              hint:
                  onAvatarTap != null ? 'Tap to change profile picture' : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isharaDiagonalGradient(dark: isDark),
                          boxShadow: [
                            BoxShadow(
                              color: teal.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            backgroundColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            backgroundImage:
                                user != null && user!.profilePic.isNotEmpty
                                    ? NetworkImage(user!.profilePic)
                                    : null,
                            child:
                                user == null || user!.profilePic.isEmpty
                                    ? Icon(
                                      Icons.person_rounded,
                                      size: 44,
                                      color: teal,
                                    )
                                    : null,
                          ),
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),
                  if (onAvatarTap != null)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: teal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark
                                  ? const Color(0xFF0D2137)
                                  : const Color(0xFFE0F7F5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Name
          ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback:
                    (b) => LinearGradient(
                      colors: [teal, orange],
                    ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                child: Text(
                  user?.name ?? s.user,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 4),

          // Email / subtitle
          Text(
            user?.email ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── User info display ────────────────────────────────────────────────────────
class _UserInfoDisplay extends ConsumerWidget {
  const _UserInfoDisplay({
    required this.user,
    required this.teal,
    required this.orange,
    required this.isDark,
    required this.theme,
    required this.onEdit,
  });
  final IsharaUser? user;
  final Color teal, orange;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle(
              icon: Icons.person_rounded,
              label: s.profileTitle,
              teal: teal,
            ),
            const Spacer(),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.1),
                  borderRadius: IsharaColors.pillRadius,
                  border: Border.all(color: teal.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: teal),
                    const SizedBox(width: 4),
                    Text(
                      s.edit,
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoTile(
          icon: Icons.badge_outlined,
          label: s.name,
          value: user?.name ?? '—',
          isDark: isDark,
          teal: teal,
        ),
        _InfoTile(
          icon: Icons.email_outlined,
          label: s.email,
          value: user?.email ?? '—',
          isDark: isDark,
          teal: teal,
        ),
        _InfoTile(
          icon: Icons.accessibility_new_rounded,
          label: s.disabilityType,
          value: (user?.disabilityType ?? 'deaf').capitalize(),
          isDark: isDark,
          teal: teal,
        ),
        _InfoTile(
          icon: Icons.verified_outlined,
          label: s.status,
          value: (user?.isVerified ?? false) ? s.verified : s.notVerified,
          isDark: isDark,
          teal: teal,
        ),
      ],
    );
  }
}

class _GuestProfilePrompt extends ConsumerWidget {
  const _GuestProfilePrompt({required this.teal, required this.onTap});

  final Color teal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return IsharaEmptyState(
      icon: Icons.person_outline_rounded,
      title: s.profileTitle,
      message: s.guestMessage,
      ctaLabel: s.guestLogin,
      onCtaTap: onTap,
      maxWidth: 420,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.teal,
  });
  final IconData icon;
  final String label, value;
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit profile form ────────────────────────────────────────────────────────
class _EditProfileForm extends ConsumerWidget {
  const _EditProfileForm({
    required this.nameCtrl,
    required this.selectedDisability,
    required this.isSaving,
    required this.teal,
    required this.isDark,
    required this.theme,
    required this.onDisabilityChanged,
    required this.onSave,
    required this.onCancel,
  });
  final TextEditingController nameCtrl;
  final String selectedDisability;
  final bool isSaving;
  final Color teal;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<String> onDisabilityChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  static const _disabilities = [
    'deaf',
    'blind',
    'non-verbal',
    'other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.edit_rounded,
          label: s.editProfile,
          teal: teal,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: s.fullName,
            prefixIcon: Icon(Icons.badge_outlined, color: teal, size: 20),
            border: OutlineInputBorder(borderRadius: IsharaColors.cardRadius),
            enabledBorder: OutlineInputBorder(
              borderRadius: IsharaColors.cardRadius,
              borderSide: BorderSide(
                color:
                    isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: IsharaColors.cardRadius,
              borderSide: BorderSide(color: teal),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          s.disabilityType,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _disabilities.map((d) {
                final selected = selectedDisability == d;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDisabilityChanged(d);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? teal : teal.withOpacity(0.08),
                      borderRadius: IsharaColors.pillRadius,
                      border: Border.all(
                        color: selected ? teal : teal.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      d[0].toUpperCase() + d.substring(1),
                      style: TextStyle(
                        color: selected ? Colors.white : teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: IsharaColors.cardRadius,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(s.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: IsharaColors.cardRadius,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(s.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section card with animate entrance
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.isDark,
    required this.delay,
  });
  final Widget child;
  final bool isDark;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          decoration: glassmorphismDecoration(dark: isDark),
          padding: const EdgeInsets.all(18),
          child: child,
        )
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideY(begin: 0.15, end: 0, delay: delay, duration: 300.ms);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.teal,
  });
  final IconData icon;
  final String label;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: teal),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: teal,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.teal,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color teal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          decoration: BoxDecoration(
            color: selected ? teal : teal.withOpacity(0.08),
            borderRadius: IsharaColors.cardRadius,
            border: Border.all(color: selected ? teal : teal.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : teal),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.teal,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color teal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(
          minHeight: IsharaColors.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? teal : teal.withOpacity(0.08),
          borderRadius: IsharaColors.pillRadius,
          border: Border.all(color: selected ? teal : teal.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? Colors.white : teal,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.teal,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color teal;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap == null
              ? null
              : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: IsharaColors.minTouchTarget,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: teal, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── String extension ─────────────────────────────────────────────────────────
extension _StringCap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
