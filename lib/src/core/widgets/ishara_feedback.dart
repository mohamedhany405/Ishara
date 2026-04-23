import 'package:flutter/material.dart';

import '../theme/ishara_theme.dart';

class IsharaLoadingState extends StatelessWidget {
  const IsharaLoadingState({super.key, this.message, this.compact = false});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      container: true,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: EdgeInsets.symmetric(
            horizontal: IsharaSpacing.lg,
            vertical: compact ? IsharaSpacing.md : IsharaSpacing.lg,
          ),
          decoration: glassmorphismDecoration(dark: isDark),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: compact ? 26 : 32,
                height: compact ? 26 : 32,
                child: CircularProgressIndicator(
                  strokeWidth: compact ? 2.6 : 3,
                  color: accent,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: IsharaSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class IsharaEmptyState extends StatelessWidget {
  const IsharaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
    this.maxWidth = 360,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Semantics(
      container: true,
      label: title,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.all(IsharaSpacing.lg),
            decoration: glassmorphismDecoration(dark: isDark),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 32),
                ),
                const SizedBox(height: IsharaSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: IsharaSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ),
                if (ctaLabel != null && onCtaTap != null) ...[
                  const SizedBox(height: IsharaSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onCtaTap,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(ctaLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
