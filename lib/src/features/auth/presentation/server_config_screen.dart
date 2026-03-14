import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/ishara_theme.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _ipCtrl = TextEditingController();
  bool _testing = false;
  String? _status; // null=idle, 'success', 'error:<msg>'

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    final existing = prefs.getString('server_url');
    if (existing != null) {
      // Extract just the IP:port from a full URL
      final uri = Uri.tryParse(existing);
      _ipCtrl.text = uri?.host ?? existing;
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;

    setState(() {
      _testing = true;
      _status = null;
    });

    final url = 'http://$ip:5000';
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        // Save URL
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('server_url', url);

        setState(() => _status = 'success');
        HapticFeedback.mediumImpact();

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go(AppRoute.login);
      } else {
        setState(
          () => _status = 'error:Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(
        () => _status = 'error:Could not connect. Check the IP and try again.',
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    final isSuccess = _status == 'success';
    final errorMsg =
        _status != null && _status!.startsWith('error:')
            ? _status!.substring(6)
            : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Icon ────────────────────────────────────────────────────
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
                      Icons.dns_rounded,
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
                'Server Setup',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

              const SizedBox(height: 8),

              Text(
                'Enter the IP address of the computer\nrunning the Ishara backend.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

              const SizedBox(height: 32),

              // ── IP input ────────────────────────────────────────────────
              TextField(
                controller: _ipCtrl,
                keyboardType: TextInputType.url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.25',
                  filled: true,
                  fillColor:
                      isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: IsharaColors.cardRadius,
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? IsharaColors.darkBorder
                              : IsharaColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: IsharaColors.cardRadius,
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? IsharaColors.darkBorder
                              : IsharaColors.lightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: IsharaColors.cardRadius,
                    borderSide: BorderSide(color: teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                onSubmitted: (_) => _testAndSave(),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // ── Status ──────────────────────────────────────────────────
              if (isSuccess)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: IsharaColors.cardRadius,
                    border: Border.all(color: teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Connected successfully!',
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

              if (errorMsg != null)
                Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(
                          0.3,
                        ),
                        borderRadius: IsharaColors.cardRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMsg,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .shakeX(amount: 4, duration: 400.ms),

              const SizedBox(height: 24),

              // ── Connect button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _testing ? null : _testAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: IsharaColors.cardRadius,
                    ),
                    elevation: 0,
                  ),
                  child:
                      _testing
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Connect',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // ── Skip for emulator ───────────────────────────────────────
              TextButton(
                onPressed: () async {
                  // Use default emulator URL
                  final prefs = ref.read(sharedPreferencesProvider);
                  await prefs.setString('server_url', 'http://10.0.2.2:5000');
                  if (mounted) context.go(AppRoute.login);
                },
                child: Text(
                  'Using Android emulator? Skip',
                  style: TextStyle(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                    fontSize: 13,
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
