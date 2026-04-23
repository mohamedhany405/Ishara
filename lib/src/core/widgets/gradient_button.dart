import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/ishara_theme.dart';

/// A pill-shaped button with the signature Ishara teal → orange gradient.
///
/// Usage:
/// ```dart
/// GradientButton(
///   label: 'Get Started',
///   onTap: () { ... },
/// )
/// ```
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.height = 52.0,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final double height;
  final double width;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;
  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.loading) return;
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = widget.enabled && !widget.loading;
    final accent = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    final borderColor =
        _focused
            ? accent.withOpacity(0.9)
            : (_hovered ? accent.withOpacity(0.45) : Colors.transparent);

    return Semantics(
      button: true,
      enabled: active,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: active,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        child: ScaleTransition(
          scale: _scale,
          child: SizedBox(
            width: widget.width,
            height: math.max(widget.height, IsharaColors.minTouchTarget),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient:
                    active ? isharaHorizontalGradient(dark: isDark) : null,
                color:
                    active
                        ? null
                        : (isDark
                            ? IsharaColors.darkCard.withOpacity(0.8)
                            : Colors.grey.shade300),
                borderRadius: IsharaColors.pillRadius,
                border: Border.all(color: borderColor, width: _focused ? 2 : 1),
                boxShadow:
                    active
                        ? [
                          BoxShadow(
                            color: accent.withOpacity(_hovered ? 0.45 : 0.35),
                            blurRadius: _hovered ? 22 : 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: IsharaColors.pillRadius,
                child: InkWell(
                  borderRadius: IsharaColors.pillRadius,
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  onTap: active ? widget.onTap : null,
                  splashColor: Colors.white.withOpacity(0.18),
                  highlightColor: Colors.white.withOpacity(0.08),
                  child: Center(
                    child:
                        widget.loading
                            ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  active
                                      ? Colors.white
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.55,
                                      ),
                                ),
                              ),
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color:
                                        active
                                            ? Colors.white
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.55),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  widget.label,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color:
                                        active
                                            ? Colors.white
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.55),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),
          ),
        ),
      ),
    );
  }
}
