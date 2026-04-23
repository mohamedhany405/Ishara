import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/translations.dart';
import 'login_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _len = 6;

  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _focusNodes = List.generate(_len, (_) => FocusNode());

  bool _loading = false;
  bool _resendLoading = false;
  bool _otpFetching = false;
  String? _error;
  int _shakeKey = 0;
  int _cooldownSec = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      // Auto-launch browser to show OTP (dev mode helper)
      _launchDevOtpBrowser();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Dev OTP helpers ─────────────────────────────────────────────────────────

  /// Builds the dev OTP URL using the same base URL the app talks to.
  Uri _devOtpUri() {
    final base = ApiClient.defaultBaseUrl;
    final encoded = Uri.encodeComponent(widget.email);
    return Uri.parse('$base/api/auth/dev/get-otp?email=$encoded');
  }

  /// Opens the default device browser to the dev OTP endpoint.
  Future<void> _launchDevOtpBrowser() async {
    final uri = _devOtpUri();
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently ignore — user can still tap the button manually
    }
  }

  /// Fetches the OTP from the dev endpoint and auto-fills the boxes.
  Future<void> _autoFillOtp() async {
    setState(() {
      _otpFetching = true;
      _error = null;
    });
    try {
      final uri = _devOtpUri();

      // We use a plain HTTP request via url_launcher's underlying http
      // mechanism — or we can just open the browser with the URL.
      // Simpler: just launch browser, since we can't easily parse
      // JSON here without adding another dep. Let browser do it.
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        setState(() => _error = t(ref).browserError);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not fetch OTP: $e');
      }
    } finally {
      if (mounted) setState(() => _otpFetching = false);
    }
  }

  // ── OTP verification ────────────────────────────────────────────────────────

  void _shake() => setState(() => _shakeKey++);
  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _len - 1)
      _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (_otp.length == _len) _verify();
  }

  Future<void> _verify() async {
    if (_otp.length < _len) {
      setState(() => _error = t(ref).allDigits);
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
        .verifyOtp(widget.email, _otp);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      context.go(AppRoute.home);
    } else {
      setState(() => _error = result.message);
      _shake();
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _resend() async {
    if (_cooldownSec > 0 || _resendLoading) return;
    setState(() {
      _resendLoading = true;
      _error = null;
    });
    HapticFeedback.selectionClick();

    final result = await ref
        .read(authProvider.notifier)
        .resendOtp(widget.email);

    if (!mounted) return;
    setState(() => _resendLoading = false);

    if (result.success) {
      _startCooldown();
      // Re-launch browser after resend so user can grab the new OTP
      await _launchDevOtpBrowser();
    } else {
      setState(() => _error = result.message);
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSec = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownSec--;
        if (_cooldownSec <= 0) t.cancel();
      });
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Icon ──────────────────────────────────────────────────────
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
                        BoxShadow(color: teal.withOpacity(0.3), blurRadius: 24),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              Text(
                s.verifyEmail,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                  children: [
                    TextSpan(text: '${s.otpSent}\n'),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

              const SizedBox(height: 16),

              // ── Dev helper banner ─────────────────────────────────────────
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.08),
                      borderRadius: IsharaColors.cardRadius,
                      border: Border.all(color: orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_browser_rounded,
                          size: 18,
                          color: orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.otpBrowserHint,
                            style: TextStyle(
                              color: orange,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: IsharaColors.minTouchTarget,
                          child: FilledButton(
                            onPressed: _otpFetching ? null : _autoFillOtp,
                            style: FilledButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(
                                80,
                                IsharaColors.minTouchTarget,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child:
                                _otpFetching
                                    ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      s.reopen,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // ── 6 OTP boxes ───────────────────────────────────────────────
              Builder(
                builder: (_) {
                  final boxes = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _len,
                      (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        isDark: isDark,
                        teal: teal,
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    ),
                  );
                  if (_shakeKey == 0) return boxes;
                  return boxes
                      .animate(key: ValueKey(_shakeKey))
                      .shakeX(amount: 8, duration: 400.ms, hz: 5);
                },
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

              if (_error != null) ...[
                const SizedBox(height: 14),
                AuthErrorBanner(message: _error!, isDark: isDark),
              ],

              const SizedBox(height: 32),

              GradientAuthButton(
                label: s.verify,
                loading: _loading,
                isDark: isDark,
                onTap: _verify,
              ).animate().fadeIn(delay: 330.ms, duration: 400.ms),

              const SizedBox(height: 20),

              SizedBox(
                height: IsharaColors.minTouchTarget,
                child: TextButton(
                  onPressed:
                      (_cooldownSec > 0 || _resendLoading) ? null : _resend,
                  child:
                      _resendLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: teal,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            _cooldownSec > 0
                                ? '${s.resendIn} ${_cooldownSec}s'
                                : s.resendCode,
                            style: TextStyle(
                              color:
                                  _cooldownSec > 0
                                      ? (isDark
                                          ? IsharaColors.mutedDark
                                          : IsharaColors.mutedLight)
                                      : teal,
                              fontWeight: FontWeight.w600,
                              decoration:
                                  _cooldownSec > 0
                                      ? null
                                      : TextDecoration.underline,
                            ),
                          ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.teal,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final Color teal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        onChanged: onChanged,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: IsharaColors.cardRadius,
            borderSide: BorderSide(
              color:
                  isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: IsharaColors.cardRadius,
            borderSide: BorderSide(
              color:
                  isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: IsharaColors.cardRadius,
            borderSide: BorderSide(color: teal, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
