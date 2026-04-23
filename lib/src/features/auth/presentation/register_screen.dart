import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/translations.dart';
import 'login_screen.dart';
import '../../communicate/presentation/communicate_screen.dart'
    show IsharaAuthLogo, AuthFieldsShaker;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  int _shakeKey = 0;
  String _disability = 'hearing';

  static const _disabilityValues = [
    ('hearing', Icons.hearing_rounded),
    ('deaf', Icons.hearing_disabled_rounded),
    ('blind', Icons.visibility_off_rounded),
    ('non-verbal', Icons.record_voice_over_rounded),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _shake() => setState(() => _shakeKey++);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _shake();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    final result = await ref
        .read(authProvider.notifier)
        .register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          disabilityType: _disability,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      context.push(AppRoute.otp, extra: {'email': _emailCtrl.text.trim()});
    } else {
      setState(() => _error = result.message);
      _shake();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);
    final disabilityLabels = {
      'hearing': s.hearing,
      'deaf': s.deaf,
      'blind': s.blind,
      'non-verbal': s.nonVerbal,
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                      child: IsharaAuthLogo(
                        teal: teal,
                        orange: orange,
                        theme: theme,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                    ),

                const SizedBox(height: 28),

                Text(
                  s.createAccount,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                const SizedBox(height: 4),

                Text(
                  s.joinIshara,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

                const SizedBox(height: 28),

                AuthFieldsShaker(
                      shakeKey: _shakeKey,
                      child: Column(
                        children: [
                          AuthField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            hint: s.fullName,
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                            teal: teal,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _emailFocus.requestFocus(),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? s.nameRequired
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          AuthField(
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            hint: s.emailAddress,
                            icon: Icons.email_outlined,
                            isDark: isDark,
                            teal: teal,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return s.emailRequired;
                              }
                              if (!v.contains('@')) return s.invalidEmail;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            hint: s.passwordHint,
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            teal: teal,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _register(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color:
                                    isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight,
                                size: 20,
                              ),
                              onPressed:
                                  () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return s.passwordRequired;
                              }
                              if (v.length < 8) return s.atLeast8;
                              if (!RegExp(
                                r'(?=.*[A-Za-z])(?=.*\d)',
                              ).hasMatch(v)) {
                                return s.letterAndNumber;
                              }
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            AuthErrorBanner(message: _error!, isDark: isDark),
                          ],
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 200.ms),

                const SizedBox(height: 24),

                Text(
                  s.accessibilityProfile,
                  style: TextStyle(
                    color: teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 350.ms),

                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children:
                      _disabilityValues.map((d) {
                        final (value, icon) = d;
                        final label = disabilityLabels[value] ?? value;
                        final selected = _disability == value;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: label,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _disability = value);
                            },
                            child: AnimatedContainer(
                              duration: 200.ms,
                              constraints: const BoxConstraints(
                                minHeight: IsharaColors.minTouchTarget,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? teal : teal.withOpacity(0.07),
                                borderRadius: IsharaColors.cardRadius,
                                border: Border.all(
                                  color:
                                      selected ? teal : teal.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon,
                                    size: 16,
                                    color: selected ? Colors.white : teal,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected ? Colors.white : teal,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                const SizedBox(height: 28),

                GradientAuthButton(
                  label: s.createAccount,
                  loading: _loading,
                  isDark: isDark,
                  onTap: _register,
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.haveAccount, style: theme.textTheme.bodySmall),
                      TextButton(
                        onPressed: _loading ? null : () => context.pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            IsharaColors.minTouchTarget,
                            IsharaColors.minTouchTarget,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: Text(
                          s.signIn,
                          style: TextStyle(
                            color: teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
