import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_feedback.dart';
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
              ? IsharaLoadingState(message: '${s.learnTitle}...')
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
          Tab(
            icon: const Icon(Icons.school_rounded, size: 18),
            text: s.lessons,
          ),
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
      'questions': 'Questions',
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
                  if (state.crudMessage != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            state.crudVerified
                                ? teal.withOpacity(0.12)
                                : theme.colorScheme.errorContainer.withOpacity(
                                  0.45,
                                ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              state.crudVerified
                                  ? teal.withOpacity(0.25)
                                  : theme.colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.crudVerified
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_off_rounded,
                            color:
                                state.crudVerified
                                    ? teal
                                    : theme.colorScheme.error,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.crudMessage!,
                              style: TextStyle(
                                color:
                                    state.crudVerified
                                        ? teal
                                        : theme.colorScheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Search field
                  _SearchField(
                        hint: s.searchLessons,
                        onChanged: controller.setLessonSearchQuery,
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
                                  controller.setCategory(
                                    selected ? null : e.key,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  constraints: const BoxConstraints(
                                    minHeight: IsharaColors.minTouchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 116),
                child: IsharaEmptyState(
                  icon: Icons.school_outlined,
                  title: s.noLessonsFound,
                  message:
                      'Try clearing filters or refresh to fetch latest lessons.',
                  ctaLabel: s.retryConnect,
                  onCtaTap: controller.refresh,
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                          isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                ),
                if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
                  _LearningVideoPlayer(
                    videoUrl: lesson.videoUrl!,
                    isDark: isDark,
                    thumbnailUrl: lesson.thumbnailUrl,
                    durationSeconds: lesson.durationSeconds,
                    autoLoopShortContent: true,
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_disabled_rounded,
                          color: accent,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No video configured for this lesson.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
              onChanged: controller.setDictionarySearchQuery,
              isDark: isDark,
              teal: teal,
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),
        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 116),
              child: IsharaEmptyState(
                icon: Icons.menu_book_outlined,
                title: s.noEntriesFound,
                message:
                    'Try a different search term or refresh dictionary sync.',
                ctaLabel: s.retryConnect,
                onCtaTap: controller.refresh,
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
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (e.videoUrl == null || e.videoUrl!.isEmpty) return;
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: theme.colorScheme.surface
                                .withOpacity(0.98),
                            builder:
                                (_) => _DictionaryVideoSheet(
                                  entry: e,
                                  isDark: isDark,
                                  theme: theme,
                                ),
                          );
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

class _DictionaryVideoSheet extends StatelessWidget {
  const _DictionaryVideoSheet({
    required this.entry,
    required this.isDark,
    required this.theme,
  });

  final DictionaryEntry entry;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.wordAr} · ${entry.wordEn}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (entry.description != null && entry.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (entry.videoUrl != null && entry.videoUrl!.isNotEmpty)
              _LearningVideoPlayer(
                videoUrl: entry.videoUrl!,
                isDark: isDark,
                durationSeconds: 12,
                autoLoopShortContent: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _LearningVideoPlayer extends StatefulWidget {
  const _LearningVideoPlayer({
    required this.videoUrl,
    required this.isDark,
    this.thumbnailUrl,
    this.durationSeconds,
    this.autoLoopShortContent = true,
  });

  final String videoUrl;
  final bool isDark;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final bool autoLoopShortContent;

  @override
  State<_LearningVideoPlayer> createState() => _LearningVideoPlayerState();
}

class _LearningVideoPlayerState extends State<_LearningVideoPlayer> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  late final String? _youtubeId;
  late final bool _isYoutube;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isVisible = false;
  bool _isMuted = true;
  String? _error;

  static const double _playThreshold = 0.6;

  @override
  void initState() {
    super.initState();
    _youtubeId = _extractYoutubeId(widget.videoUrl);
    _isYoutube = _youtubeId != null;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  bool get _shouldLoop {
    if (!widget.autoLoopShortContent) return false;
    final seconds = widget.durationSeconds;
    return seconds == null || seconds <= 25;
  }

  String? _extractYoutubeId(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final parsed = YoutubePlayer.convertUrlToId(trimmed);
    if (parsed != null && parsed.isNotEmpty) return parsed;

    final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idRegex.hasMatch(trimmed)) return trimmed;

    return null;
  }

  Future<void> _initializeIfNeeded() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    if (mounted) setState(() {});

    try {
      if (_isYoutube) {
        final controller = YoutubePlayerController(
          initialVideoId: _youtubeId!,
          flags: YoutubePlayerFlags(
            autoPlay: false,
            mute: true,
            loop: _shouldLoop,
            enableCaption: false,
            controlsVisibleAtStart: true,
          ),
        );

        if (!mounted) {
          controller.dispose();
          return;
        }

        _youtubeController = controller;
      } else {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
        await controller.initialize();
        await controller.setLooping(_shouldLoop);
        await controller.setVolume(0);

        if (!mounted) {
          await controller.dispose();
          return;
        }

        _videoController = controller;
      }

      _isInitialized = true;
      _error = null;

      if (_isVisible) {
        await _play();
      }
    } catch (_) {
      _error = 'Video unavailable. Please try again later.';
    } finally {
      _isInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _play() async {
    if (!_isInitialized) return;

    if (_isYoutube) {
      if (_isMuted) {
        _youtubeController?.mute();
      }
      _youtubeController?.play();
      return;
    }

    final controller = _videoController;
    if (controller == null) return;
    await controller.setVolume(_isMuted ? 0 : 1);
    await controller.play();
  }

  Future<void> _pause() async {
    if (!_isInitialized) return;

    if (_isYoutube) {
      _youtubeController?.pause();
      return;
    }

    final controller = _videoController;
    if (controller == null) return;
    await controller.pause();
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;

    if (_isPlaying) {
      await _pause();
    } else {
      await _play();
    }

    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;

    if (_isYoutube) {
      if (_isMuted) {
        _youtubeController?.mute();
      } else {
        _youtubeController?.unMute();
      }
    } else {
      final controller = _videoController;
      if (controller != null) {
        await controller.setVolume(_isMuted ? 0 : 1);
      }
    }

    if (mounted) setState(() {});
  }

  bool get _isPlaying {
    if (!_isInitialized) return false;
    if (_isYoutube) {
      return _youtubeController?.value.isPlaying ?? false;
    }
    return _videoController?.value.isPlaying ?? false;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction >= _playThreshold;
    if (visible == _isVisible) return;

    _isVisible = visible;

    if (visible) {
      _initializeIfNeeded();
      _play();
    } else {
      _pause();
    }
  }

  double _aspectRatio() {
    if (!_isYoutube &&
        _videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.aspectRatio > 0) {
      return _videoController!.value.aspectRatio;
    }

    final lowered = widget.videoUrl.toLowerCase();
    if (lowered.contains('/shorts/') || lowered.contains('#shorts')) {
      return 9 / 16;
    }

    return 16 / 9;
  }

  Widget _buildVideoSurface(Color teal) {
    if (_isYoutube) {
      final controller = _youtubeController;
      if (controller == null) {
        return _buildLoadingSurface(teal);
      }

      return AspectRatio(
        aspectRatio: _aspectRatio(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: teal,
            progressColors: ProgressBarColors(
              playedColor: teal,
              handleColor: teal,
              bufferedColor: teal.withOpacity(0.3),
              backgroundColor: teal.withOpacity(0.15),
            ),
            onReady: () {
              if (_isMuted) {
                controller.mute();
              }
              if (_isVisible) {
                controller.play();
              }
            },
          ),
        ),
      );
    }

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingSurface(teal);
    }

    return AspectRatio(
      aspectRatio: _aspectRatio(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildLoadingSurface(Color teal) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: CircularProgressIndicator(color: teal)),
    );
  }

  Widget _buildPreviewSurface(Color teal) {
    final thumbnailUrl =
        widget.thumbnailUrl?.trim().isNotEmpty == true
            ? widget.thumbnailUrl!.trim()
            : (_youtubeId != null
                ? 'https://img.youtube.com/vi/$_youtubeId/mqdefault.jpg'
                : null);

    return AspectRatio(
      aspectRatio: _aspectRatio(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                cacheWidth: 480,
                errorBuilder:
                    (_, __, ___) => Container(color: teal.withOpacity(0.1)),
              )
            else
              Container(color: teal.withOpacity(0.1)),
            Container(color: Colors.black.withOpacity(0.18)),
            Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 56,
                color: Colors.white.withOpacity(0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final controller = _videoController;

    return VisibilityDetector(
      key: ValueKey('learning_video_${widget.videoUrl.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        children: [
          if (_error != null)
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal.withOpacity(0.18)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
          else if (!_isInitialized)
            Stack(
              children: [
                _buildPreviewSurface(teal),
                if (_isInitializing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: teal),
                      ),
                    ),
                  ),
              ],
            )
          else
            _buildVideoSurface(teal),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: teal,
                ),
              ),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: teal,
                ),
              ),
              if (!_isYoutube &&
                  controller != null &&
                  controller.value.isInitialized)
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: teal,
                      bufferedColor: teal.withOpacity(0.25),
                      backgroundColor: teal.withOpacity(0.12),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    _isYoutube
                        ? 'Autoplay on visibility • YouTube controls enabled'
                        : 'Autoplay on visibility',
                    style: TextStyle(
                      color: teal.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
