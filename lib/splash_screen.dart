import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'src/core/api/auth_provider.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/theme/ishara_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Controls the animated gradient shimmer on the title.
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    // Shimmer loop for the gradient title text
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Delay navigation until entrance animations finish
    Future.delayed(const Duration(milliseconds: 2800), _checkAuthStatus);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _checkAuthStatus() async {
    if (!mounted) return;
    try {
      final authService = ref.read(authServiceProvider);
      if (authService.isLoggedIn) {
        final result = await authService.getCurrentUser();
        if (result.success && result.user != null) {
          if (mounted) context.go(AppRoute.home);
          return;
        }
      }
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return Scaffold(
      /// Deep-navy → near-black radial gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [const Color(0xFF0D2137), const Color(0xFF040B14)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo: scale-bounce entrance ──────────────────────────
                Image.asset(
                      'assets/images/ishara_app_logo.png',
                      width: 120,
                      height: 120,
                      filterQuality: FilterQuality.high,
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // ── Brand name: shimmer gradient text ────────────────────
                AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (context, _) {
                        return ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [teal, orange, teal],
                                stops: const [0.0, 0.5, 1.0],
                                begin: Alignment(_shimmerAnim.value - 1, 0),
                                end: Alignment(_shimmerAnim.value + 1, 0),
                              ).createShader(bounds),
                          child: const Text(
                            'Ishara',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        );
                      },
                    )
                    .animate()
                    .slideY(
                      begin: 0.4,
                      end: 0.0,
                      delay: 400.ms,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 10),

                // ── Tagline ──────────────────────────────────────────────
                const Text(
                      'Communicate · Learn · Stay Safe',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white60,
                        letterSpacing: 0.4,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 800.ms,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 60),

                // ── Loading dots ─────────────────────────────────────────
                _LoadingDots(
                  color: teal,
                ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated 3-dot loading indicator.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots({required this.color});
  final Color color;

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final bounce = (t < 0.5 ? t * 2 : 2 - t * 2);
            return Transform.translate(
              offset: Offset(0, -6 * bounce),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
