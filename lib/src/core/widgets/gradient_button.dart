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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: (widget.enabled && !widget.loading) ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient:
                (widget.enabled && !widget.loading)
                    ? isharaHorizontalGradient(dark: isDark)
                    : null,
            color:
                (!widget.enabled || widget.loading)
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                    : null,
            borderRadius: IsharaColors.pillRadius,
            boxShadow:
                widget.enabled && !widget.loading
                    ? [
                      BoxShadow(
                        color: (isDark
                                ? IsharaColors.tealDark
                                : IsharaColors.tealLight)
                            .withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child:
                widget.loading
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
          ),
        ).animate().fadeIn(duration: 200.ms),
      ),
    );
  }
}
