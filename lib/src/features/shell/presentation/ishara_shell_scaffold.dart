import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/settings/translations.dart';

// ── Tab data ─────────────────────────────────────────────────────────────────
class _TabData {
  const _TabData({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

List<_TabData> _buildTabs(AppStrings s) => [
  _TabData(
    path: '/home',
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: s.talk,
  ),
  _TabData(
    path: '/vision',
    icon: Icons.visibility_outlined,
    activeIcon: Icons.visibility_rounded,
    label: s.vision,
  ),
  _TabData(
    path: '/safety',
    icon: Icons.shield_outlined,
    activeIcon: Icons.shield_rounded,
    label: s.safety,
  ),
  _TabData(
    path: '/learning',
    icon: Icons.school_outlined,
    activeIcon: Icons.school_rounded,
    label: s.learn,
  ),
  _TabData(
    path: '/profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: s.profile,
  ),
];

// ─── Shell Scaffold ────────────────────────────────────────────────────────────
class IsharaShellScaffold extends ConsumerWidget {
  const IsharaShellScaffold({super.key, required this.child});
  final Widget child;

  int _currentIndex(BuildContext context, List<_TabData> tabs) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = _buildTabs(t(ref));
    final current = _currentIndex(context, tabs);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Page content
          child,

          // Floating nav bar at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FloatingNavBar(
                  tabs: tabs,
                  currentIndex: current,
                  isDark: isDark,
                  onTap: (i) {
                    HapticFeedback.selectionClick();
                    context.go(tabs[i].path);
                  },
                )
                .animate()
                .slideY(
                  begin: 1.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// ─── Floating nav bar shell ────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });
  final List<_TabData> tabs;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF1E293B).withOpacity(0.92)
                : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.10),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          // teal glow under the bar
          BoxShadow(
            color: (isDark ? IsharaColors.tealDark : IsharaColors.tealLight)
                .withOpacity(0.08),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (i) {
          return Flexible(
            child: _NavItem(
              tab: tabs[i],
              selected: currentIndex == i,
              isDark: isDark,
              onTap: () => onTap(i),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Individual nav item ──────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final _TabData tab;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1,
      end: 0.82,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        widget.isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 60,
          height: 56,
          decoration: BoxDecoration(
            color:
                widget.selected ? teal.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient on selected state
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                child:
                    widget.selected
                        ? ShaderMask(
                          key: ValueKey('sel_${widget.tab.path}'),
                          blendMode: BlendMode.srcIn,
                          shaderCallback:
                              (b) => LinearGradient(
                                colors: [teal, orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(
                                Rect.fromLTWH(0, 0, b.width, b.height),
                              ),
                          child: Icon(widget.tab.activeIcon, size: 24),
                        )
                        : Icon(
                          key: ValueKey('unsel_${widget.tab.path}'),
                          widget.tab.icon,
                          size: 22,
                          color:
                              widget.isDark
                                  ? IsharaColors.mutedDark
                                  : IsharaColors.mutedLight,
                        ),
              ),

              const SizedBox(height: 3),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w400,
                  color:
                      widget.selected
                          ? teal
                          : (widget.isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight),
                ),
                child: Text(widget.tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
