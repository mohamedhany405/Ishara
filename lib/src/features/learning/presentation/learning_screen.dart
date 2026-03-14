import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../domain/learning_models.dart';
import 'learning_controller.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final state = ref.watch(learningControllerProvider);
    final controller = ref.read(learningControllerProvider.notifier);
    final lessons = ref.watch(filteredLessonsProvider);
    final dictionary = ref.watch(filteredDictionaryProvider);

    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body:
          state.isLoading
              ? Center(child: CircularProgressIndicator(color: teal))
              : NestedScrollView(
                physics: const ClampingScrollPhysics(),
                headerSliverBuilder:
                    (context, _) => [
                      // ── Compact fixed header (no stretch) ─────────────────────
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF0D1E37)
                                    : const Color(0xFFEAF0FF),
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    isDark
                                        ? IsharaColors.darkBorder
                                        : IsharaColors.lightBorder,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  MediaQuery.of(context).padding.top + 12,
                                  20,
                                  2,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback:
                                          (b) => LinearGradient(
                                            colors: [teal, orange],
                                          ).createShader(
                                            Rect.fromLTWH(
                                              0,
                                              0,
                                              b.width,
                                              b.height,
                                            ),
                                          ),
                                      child: Text(
                                        s.learnTitle,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.learnSub,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDark
                                                ? IsharaColors.mutedDark
                                                : IsharaColors.mutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _GradientTabBar(
                                controller: _tabController,
                                teal: teal,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _LessonsTab(
                      lessons: lessons,
                      state: state,
                      controller: controller,
                      isDark: isDark,
                      teal: teal,
                      orange: orange,
                      theme: theme,
                    ),
                    _DictionaryTab(
                      entries: dictionary,
                      state: state,
                      controller: controller,
                      isDark: isDark,
                      teal: teal,
                      theme: theme,
                    ),
                  ],
                ),
              ),
    );
  }
}

// ─── Custom gradient tab bar ──────────────────────────────────────────────────
class _GradientTabBar extends ConsumerWidget implements PreferredSizeWidget {
  const _GradientTabBar({
    required this.controller,
    required this.teal,
    required this.isDark,
  });
  final TabController controller;
  final Color teal;
  final bool isDark;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      color: Colors.transparent,
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: IsharaColors.pillRadius,
          color: teal.withOpacity(0.15),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: teal,
        unselectedLabelColor:
            isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: [
          Tab(icon: const Icon(Icons.school_rounded, size: 18), text: s.lessons),
          Tab(
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            text: s.dictionary,
          ),
        ],
      ),
    );
  }
}

// ─── Lessons tab ─────────────────────────────────────────────────────────────
class _LessonsTab extends ConsumerWidget {
  const _LessonsTab({
    required this.lessons,
    required this.state,
    required this.controller,
    required this.isDark,
    required this.teal,
    required this.orange,
    required this.theme,
  });
  final List<LessonItem> lessons;
  final LearningState state;
  final LearningController controller;
  final bool isDark;
  final Color teal, orange;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final categories = {
      'beginner': s.beginner,
      'daily': s.daily,
      'emergency': s.emergency,
    };
    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: teal,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field
                  _SearchField(
                        hint: s.searchLessons,
                        onChanged: controller.setSearchQuery,
                        isDark: isDark,
                        teal: teal,
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 10),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          categories.entries.map((e) {
                            final selected = state.selectedCategory == e.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  controller.setCategory(selected ? null : e.key);
                                },
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? teal
                                            : teal.withOpacity(0.08),
                                    borderRadius: IsharaColors.pillRadius,
                                    border: Border.all(
                                      color:
                                          selected
                                              ? teal
                                              : teal.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      color: selected ? Colors.white : teal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (lessons.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: teal.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.noLessonsFound,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final lesson = lessons[index];
                  return _LessonCard(
                    lesson: lesson,
                    index: index,
                    isDark: isDark,
                    teal: teal,
                    orange: orange,
                    theme: theme,
                  );
                }, childCount: lessons.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.isDark,
    required this.teal,
    required this.orange,
    required this.theme,
  });
  final LessonItem lesson;
  final int index;
  final bool isDark;
  final Color teal, orange;
  final ThemeData theme;

  // Colour cycle for lesson avatars
  static const _colors = [
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _colors[index % _colors.length];
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: glassmorphismDecoration(dark: isDark),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: accent,
                size: 26,
              ),
            ),
            title: Text(
              lesson.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              lesson.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: IsharaColors.pillRadius,
              ),
              child: Text(
                lesson.category,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () => HapticFeedback.selectionClick(),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * index), duration: 350.ms)
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 60 * index),
          duration: 300.ms,
        );
  }
}

// ─── Dictionary tab ───────────────────────────────────────────────────────────
class _DictionaryTab extends ConsumerWidget {
  const _DictionaryTab({
    required this.entries,
    required this.state,
    required this.controller,
    required this.isDark,
    required this.teal,
    required this.theme,
  });
  final List<DictionaryEntry> entries;
  final LearningState state;
  final LearningController controller;
  final bool isDark;
  final Color teal;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _SearchField(
              hint: s.searchDictionary,
              onChanged: controller.setSearchQuery,
              isDark: isDark,
              teal: teal,
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),
        if (entries.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: teal.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.noEntriesFound,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final e = entries[index];
                return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: glassmorphismDecoration(dark: isDark),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          e.wordAr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            foreground:
                                Paint()
                                  ..shader = LinearGradient(
                                    colors: [teal, const Color(0xFF8B5CF6)],
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 120, 24),
                                  ),
                          ),
                        ),
                        subtitle: Text(
                          e.wordEn,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isDark
                                    ? IsharaColors.mutedDark
                                    : IsharaColors.mutedLight,
                          ),
                        ),
                        trailing:
                            e.category != null
                                ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: teal.withOpacity(0.1),
                                    borderRadius: IsharaColors.pillRadius,
                                    border: Border.all(
                                      color: teal.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    e.category!,
                                    style: TextStyle(
                                      color: teal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 40 * index),
                      duration: 300.ms,
                    )
                    .slideX(
                      begin: 0.08,
                      end: 0,
                      delay: Duration(milliseconds: 40 * index),
                      duration: 280.ms,
                    );
              }, childCount: entries.length),
            ),
          ),
      ],
    );
  }
}

// ─── Shared search field ──────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hint,
    required this.onChanged,
    required this.isDark,
    required this.teal,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassmorphismDecoration(dark: isDark),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search_rounded, color: teal, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
