import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// A smart Rive animation wrapper.
///
/// - If [assetPath] is provided, plays the Rive artboard (optionally driven
///   by [stateMachineName]).
/// - Falls back to a regular [Icon] (via [fallbackIcon]) when no `.riv` file
///   is available — enabling progressive Rive adoption with zero risk.
///
/// **With a `.riv` file:**
/// ```dart
/// RiveIcon(
///   assetPath: 'assets/animations/hand_wave.riv',
///   artboardName: 'HandWave',
///   stateMachineName: 'Idle',
///   size: 80,
/// )
/// ```
///
/// **Icon-only fallback (zero runtime cost):**
/// ```dart
/// RiveIcon(fallbackIcon: Icons.waving_hand, size: 48)
/// ```
class RiveIcon extends StatelessWidget {
  const RiveIcon({
    super.key,
    this.assetPath,
    this.artboardName,
    this.stateMachineName,
    this.fallbackIcon,
    this.fallbackColor,
    this.size = 48.0,
    this.fit = BoxFit.contain,
  });

  /// Path relative to the asset bundle (e.g. `'assets/animations/wave.riv'`).
  final String? assetPath;

  /// Artboard name inside the `.riv` file — null uses the default artboard.
  final String? artboardName;

  /// State machine to activate (optional).
  final String? stateMachineName;

  /// Fallback icon when no `.riv` file is present.
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) return _fallback(context);

    // When we have an asset path, use RiveAnimation.asset which handles
    // loading, error states, and artboard/state-machine selection internally.
    return SizedBox(
      width: size,
      height: size,
      child: RiveAnimation.asset(
        assetPath!,
        artboard: artboardName,
        stateMachines:
            stateMachineName != null ? [stateMachineName!] : const [],
        fit: fit,
        // Render a fallback icon while the .riv file is loading
        placeHolder: _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    if (fallbackIcon == null) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        fallbackIcon,
        size: size * 0.75,
        color: fallbackColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
