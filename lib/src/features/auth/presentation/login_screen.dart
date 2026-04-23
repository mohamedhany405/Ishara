import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/translations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  int _shakeKey = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _shake() => setState(() => _shakeKey++);

  Future<void> _login() async {
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
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      context.go(AppRoute.home);
    } else if (result.fieldErrors?['email'] == 'not_verified' ||
        result.message.toLowerCase().contains('verify')) {
      context.push(AppRoute.otp, extra: {'email': _emailCtrl.text.trim()});
    } else {
      setState(() => _error = result.message);
      _shake();
      HapticFeedback.heavyImpact();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    ref.read(authProvider.notifier).skipAsGuest();
    context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final size = MediaQuery.of(context).size;
    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // ── Logo ──────────────────────────────────────────────
                    _IsharaAuthLogo(teal: teal, orange: orange, theme: theme)
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 8),

                    Text(
                      s.welcomeBack,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: 4),

                    Text(
                      s.signInToContinue,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 32),

                    // ── Fields ─────────────────────────────────────────────
                    _AuthFieldsShaker(
                          shakeKey: _shakeKey,
                          child: Column(
                            children: [
                              AuthField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                hint: s.emailAddress,
                                icon: Icons.email_outlined,
                                isDark: isDark,
                                teal: teal,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted:
                                    (_) => _passwordFocus.requestFocus(),
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
                                hint: s.password,
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                teal: teal,
                                obscure: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _login(),
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
                                      () =>
                                          setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return s.passwordRequired;
                                  }
                                  if (v.length < 6) return s.tooShort;
                                  return null;
                                },
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                AuthErrorBanner(
                                  message: _error!,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: 250.ms,
                          duration: 350.ms,
                        ),

                    const SizedBox(height: 24),

                    GradientAuthButton(
                      label: s.signIn,
                      loading: _loading,
                      isDark: isDark,
                      onTap: _login,
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                    const SizedBox(height: 14),

                    SizedBox(
                      height: IsharaColors.minTouchTarget,
                      child: TextButton(
                        onPressed: _loading ? null : _skip,
                        child: Text(
                          s.skipForNow,
                          style: TextStyle(
                            color:
                                isDark
                                    ? IsharaColors.mutedDark
                                    : IsharaColors.mutedLight,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.noAccount, style: theme.textTheme.bodySmall),
                          TextButton(
                            onPressed:
                                _loading
                                    ? null
                                    : () => context.push(AppRoute.register),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(
                                IsharaColors.minTouchTarget,
                                IsharaColors.minTouchTarget,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                            child: Text(
                              s.signUp,
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED auth widgets — exported for Register & OTP screens
// ─────────────────────────────────────────────────────────────────────────────

class _IsharaAuthLogo extends ConsumerWidget {
  const _IsharaAuthLogo({
    required this.teal,
    required this.orange,
    required this.theme,
  });
  final Color teal, orange;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [teal, orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: teal.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (b) => LinearGradient(
                colors: [teal, orange],
              ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
          child: Text(
            t(ref).ishara,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthFieldsShaker extends StatelessWidget {
  const _AuthFieldsShaker({required this.shakeKey, required this.child});
  final int shakeKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakeKey == 0) return child;
    return child
        .animate(key: ValueKey(shakeKey))
        .shakeX(amount: 6, duration: 400.ms, hz: 4);
  }
}

/// Public so register and otp screens can import it.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.teal,
    required this.validator,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool isDark, obscure;
  final Color teal;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, size: 20, color: teal),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: IsharaColors.cardRadius,
          borderSide: BorderSide(
            color: isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: IsharaColors.cardRadius,
          borderSide: BorderSide(
            color: isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: IsharaColors.cardRadius,
          borderSide: BorderSide(color: teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: IsharaColors.cardRadius,
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: IsharaColors.cardRadius,
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class GradientAuthButton extends StatefulWidget {
  const GradientAuthButton({
    super.key,
    required this.label,
    required this.loading,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final bool loading, isDark;
  final VoidCallback onTap;

  @override
  State<GradientAuthButton> createState() => _GradientAuthButtonState();
}

class _GradientAuthButtonState extends State<GradientAuthButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = !widget.loading;
    final accent =
        widget.isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Semantics(
      button: true,
      enabled: active,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: active,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: 120.ms,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: IsharaColors.minTouchTarget + 4,
            ),
            decoration: BoxDecoration(
              gradient:
                  active ? isharaHorizontalGradient(dark: widget.isDark) : null,
              color:
                  active
                      ? null
                      : (widget.isDark
                          ? IsharaColors.darkCard
                          : Colors.grey.shade200),
              borderRadius: IsharaColors.pillRadius,
              border: Border.all(
                color:
                    _focused
                        ? accent.withOpacity(0.95)
                        : (_hovered
                            ? accent.withOpacity(0.4)
                            : Colors.transparent),
                width: _focused ? 2 : 1,
              ),
              boxShadow:
                  active
                      ? [
                        BoxShadow(
                          color: accent.withOpacity(_hovered ? 0.45 : 0.35),
                          blurRadius: _hovered ? 20 : 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: IsharaColors.pillRadius,
              child: InkWell(
                borderRadius: IsharaColors.pillRadius,
                onTap: active ? widget.onTap : null,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                splashColor: Colors.white.withOpacity(0.18),
                highlightColor: Colors.white.withOpacity(0.08),
                child: Center(
                  child:
                      widget.loading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.isDark,
  });
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: IsharaColors.cardRadius,
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: -0.1, end: 0, duration: 200.ms);
  }
}
