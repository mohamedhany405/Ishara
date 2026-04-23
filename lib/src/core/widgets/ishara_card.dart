import 'package:flutter/material.dart';

import '../theme/ishara_theme.dart';

/// A glassmorphism-style card with a frosted background, gradient border,
/// and a subtle teal glow shadow.
///
/// Usage:
/// ```dart
/// IsharaCard(
///   child: Text('Hello'),
/// )
/// ```
class IsharaCard extends StatelessWidget {
  const IsharaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? IsharaColors.cardRadius;

    final decoration = glassmorphismDecoration(
      dark: isDark,
    ).copyWith(borderRadius: br);

    Widget card = Container(
      margin: margin,
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          borderRadius: br,
          child: InkWell(
            onTap: onTap,
            borderRadius: br,
            mouseCursor: SystemMouseCursors.click,
            splashColor: (isDark
                    ? IsharaColors.tealDark
                    : IsharaColors.tealLight)
                .withOpacity(0.1),
            highlightColor: (isDark
                    ? IsharaColors.tealDark
                    : IsharaColors.tealLight)
                .withOpacity(0.04),
            child: card,
          ),
        ),
      );
    }

    return card;
  }
}

/// Lightweight horizontal info row used inside `IsharaCard`.
class IsharaCardRow extends StatelessWidget {
  const IsharaCardRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultIcon = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (iconColor ?? defaultIcon).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? defaultIcon, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
