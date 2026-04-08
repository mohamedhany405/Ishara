import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  final _lessonSearchCtrl = TextEditingController();
  final _dictSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Reset both search fields when switching tabs
      if (!_tabController.indexIsChanging) return;
      _lessonSearchCtrl.clear();
      _dictSearchCtrl.clear();
      ref.read(learningControllerProvider.notifier).setLessonSearchQuery('');
      ref.read(learningControllerProvider.notifier).setDictSearchQuery('');
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lessonSearchCtrl.dispose();
    _dictSearchCtrl.dispose();
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
                      searchCtrl: _lessonSearchCtrl,
                      isDark: isDark,
                      teal: teal,
                      orange: orange,
                      theme: theme,
                    ),
                    _DictionaryTab(
                      entries: dictionary,
                      state: state,
                      controller: controller,
                      searchCtrl: _dictSearchCtrl,
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
  Size get preferredSize => const Size.fromHeight(40);

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
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        // Kill the white ripple on tab press
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          Tab(text: s.lessons),
          Tab(text: s.dictionary),
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
    required this.searchCtrl,
    required this.isDark,
    required this.teal,
    required this.orange,
    required this.theme,
  });
  final List<LessonItem> lessons;
  final LearningState state;
  final LearningController controller;
  final TextEditingController searchCtrl;
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
                  // Search field – separate controller for lessons
                  _SearchField(
                        hint: s.searchLessons,
                        textController: searchCtrl,
                        onChanged: controller.setLessonSearchQuery,
                        isDark: isDark,
                        teal: teal,
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 10),

                  // Category chips — deselectable
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
                                  controller.setCategory(
                                    selected ? null : e.key,
                                  );
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

class _LessonCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            onTap: () {
              HapticFeedback.selectionClick();
              _showLessonDetail(context, ref, lesson, accent, s);
            },
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

  void _showLessonDetail(
    BuildContext context,
    WidgetRef ref,
    LessonItem lesson,
    Color accent,
    AppStrings s,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LessonDetailSheet(
        lesson: lesson,
        accent: accent,
        isDark: isDark,
        teal: teal,
        theme: theme,
      ),
    );
  }
}

// ─── Dictionary tab ───────────────────────────────────────────────────────────
class _DictionaryTab extends ConsumerWidget {
  const _DictionaryTab({
    required this.entries,
    required this.state,
    required this.controller,
    required this.searchCtrl,
    required this.isDark,
    required this.teal,
    required this.theme,
  });
  final List<DictionaryEntry> entries;
  final LearningState state;
  final LearningController controller;
  final TextEditingController searchCtrl;
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
              textController: searchCtrl,
              onChanged: controller.setDictSearchQuery,
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
                return _DictionaryCard(
                  entry: e,
                  index: index,
                  isDark: isDark,
                  teal: teal,
                  theme: theme,
                );
              }, childCount: entries.length),
            ),
          ),
      ],
    );
  }
}

class _DictionaryCard extends ConsumerWidget {
  const _DictionaryCard({
    required this.entry,
    required this.index,
    required this.isDark,
    required this.teal,
    required this.theme,
  });
  final DictionaryEntry entry;
  final int index;
  final bool isDark;
  final Color teal;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: glassmorphismDecoration(dark: isDark),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  entry.wordAr.isNotEmpty ? entry.wordAr[0] : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: teal,
                  ),
                ),
              ),
            ),
            title: Text(
              entry.wordAr,
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
              entry.wordEn,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
            ),
            trailing:
                entry.category != null
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
                        entry.category!,
                        style: TextStyle(
                          color: teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    : null,
            onTap: () {
              HapticFeedback.selectionClick();
              _showWordDetail(context, ref, entry, s);
            },
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
  }

  void _showWordDetail(
    BuildContext context,
    WidgetRef ref,
    DictionaryEntry entry,
    AppStrings s,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WordDetailSheet(
        entry: entry,
        isDark: isDark,
        teal: teal,
        theme: theme,
      ),
    );
  }
}

// ─── Word Detail Bottom Sheet ─────────────────────────────────────────────────
class _WordDetailSheet extends ConsumerStatefulWidget {
  const _WordDetailSheet({
    required this.entry,
    required this.isDark,
    required this.teal,
    required this.theme,
  });
  final DictionaryEntry entry;
  final bool isDark;
  final Color teal;
  final ThemeData theme;

  @override
  ConsumerState<_WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends ConsumerState<_WordDetailSheet> {
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    if (widget.entry.videoUrl != null && widget.entry.videoUrl!.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.entry.videoUrl!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          controlsVisibleAtStart: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = t(ref);
    final entry = widget.entry;
    final teal = widget.teal;
    final isDark = widget.isDark;
    final theme = widget.theme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: teal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic word – large
                  Center(
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback:
                          (b) => LinearGradient(
                            colors: [teal, const Color(0xFF8B5CF6)],
                          ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Text(
                        entry.wordAr,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // English translation
                  Center(
                    child: Text(
                      entry.wordEn,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                      ),
                    ),
                  ),
                  if (entry.category != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: teal.withOpacity(0.1),
                          borderRadius: IsharaColors.pillRadius,
                          border: Border.all(color: teal.withOpacity(0.25)),
                        ),
                        child: Text(
                          entry.category!,
                          style: TextStyle(
                            color: teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (entry.description != null &&
                      entry.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: teal.withOpacity(0.06),
                        borderRadius: IsharaColors.cardRadius,
                        border: Border.all(color: teal.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16, color: teal),
                              const SizedBox(width: 6),
                              Text(
                                s.meaning,
                                style: TextStyle(
                                  color: teal,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // YouTube video
                  if (_ytController != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline_rounded,
                            size: 18, color: teal),
                        const SizedBox(width: 6),
                        Text(
                          s.signVideo,
                          style: TextStyle(
                            color: teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: IsharaColors.cardRadius,
                      child: YoutubePlayer(
                        controller: _ytController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: teal,
                        progressColors: ProgressBarColors(
                          playedColor: teal,
                          handleColor: teal,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: IsharaColors.cardRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        s.close,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lesson Detail Bottom Sheet ───────────────────────────────────────────────
class _LessonDetailSheet extends ConsumerStatefulWidget {
  const _LessonDetailSheet({
    required this.lesson,
    required this.accent,
    required this.isDark,
    required this.teal,
    required this.theme,
  });
  final LessonItem lesson;
  final Color accent;
  final bool isDark;
  final Color teal;
  final ThemeData theme;

  @override
  ConsumerState<_LessonDetailSheet> createState() => _LessonDetailSheetState();
}

class _LessonDetailSheetState extends ConsumerState<_LessonDetailSheet> {
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.videoUrl != null && widget.lesson.videoUrl!.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.lesson.videoUrl!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          controlsVisibleAtStart: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = t(ref);
    final lesson = widget.lesson;
    final accent = widget.accent;
    final isDark = widget.isDark;
    final teal = widget.teal;
    final theme = widget.theme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson icon + title
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.06),
                      borderRadius: IsharaColors.cardRadius,
                      border: Border.all(color: accent.withOpacity(0.15)),
                    ),
                    child: Text(
                      lesson.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                  // YouTube video
                  if (_ytController != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline_rounded,
                            size: 18, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          s.signVideo,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: IsharaColors.cardRadius,
                      child: YoutubePlayer(
                        controller: _ytController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: accent,
                        progressColors: ProgressBarColors(
                          playedColor: accent,
                          handleColor: accent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: IsharaColors.cardRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        s.close,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared search field ──────────────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.hint,
    required this.textController,
    required this.onChanged,
    required this.isDark,
    required this.teal,
  });
  final String hint;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final Color teal;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: IsharaColors.cardRadius,
        color: widget.isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        border: Border.all(
          color: _focused
              ? widget.teal.withOpacity(0.6)
              : (widget.isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.1)),
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: widget.teal.withOpacity(0.18),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: IsharaColors.cardRadius,
        child: TextField(
          controller: widget.textController,
          focusNode: _focus,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: widget.isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _focused
                  ? widget.teal
                  : widget.teal.withOpacity(0.6),
              size: 20,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.textController,
              builder: (_, value, __) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: widget.teal, size: 18),
                  onPressed: () {
                    widget.textController.clear();
                    widget.onChanged('');
                  },
                );
              },
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
