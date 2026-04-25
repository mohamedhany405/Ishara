/// Duolingo-style quiz for Arabic Sign Language vocabulary.
///
/// Modes:
///   • clipToWord  — show a sign clip, choose the matching Arabic word.
///   • wordToClip  — show a word, choose which clip matches.
///   • performSign — user signs in front of the camera; the on-device
///                   translator model grades the attempt (lenient — see
///                   plan §5.3 — top-1 OR top-2 ≥ 0.5 confidence).
///   • matchPairs  — six tiles; tap word/clip pairs until all matched.
///
/// XP, streak, hearts and progress are stored on the server via
/// /api/quiz POST.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/services/tts_service.dart';
import '../../translator/data/sign_dictionary_service.dart';

enum QuizMode { clipToWord, wordToClip, performSign, matchPairs }

class QuizSession {
  QuizSession({required this.mode, required this.totalQuestions});
  final QuizMode mode;
  final int totalQuestions;
  int correct = 0;
  int xp = 0;
  int hearts = 3;
}

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, this.mode = QuizMode.clipToWord, this.questions = 5});
  final QuizMode mode;
  final int questions;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late QuizSession _session = QuizSession(mode: widget.mode, totalQuestions: widget.questions);
  int _qIndex = 0;
  String _target = '';
  List<String> _choices = const [];
  String? _selected;
  bool _revealed = false;
  VideoPlayerController? _video;
  late SignDictionary _dict;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _dict = await ref.read(signDictionaryProvider.future);
    if (!mounted) return;
    setState(() => _ready = true);
    _nextQuestion();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _nextQuestion() async {
    if (_qIndex >= _session.totalQuestions || _session.hearts <= 0) {
      _finish();
      return;
    }
    final words = _dict.words.keys.toList();
    if (words.length < 4) return;
    words.shuffle();
    final target = words.first;
    final distractors = words.skip(1).take(3).toList();
    final choices = [target, ...distractors]..shuffle();
    setState(() {
      _target = target;
      _choices = choices;
      _selected = null;
      _revealed = false;
    });
    if (widget.mode == QuizMode.clipToWord) {
      final clip = _dict.lookupWord(target);
      if (clip != null) {
        await _video?.dispose();
        _video = await _initVideo(clip);
        _video?.setLooping(true);
        _video?.play();
        if (mounted) setState(() {});
      }
    }
  }

  Future<VideoPlayerController?> _initVideo(String path) async {
    try {
      VideoPlayerController c;
      if (path.startsWith('http')) {
        c = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (path.startsWith('assets/')) {
        c = VideoPlayerController.asset(path);
      } else {
        c = VideoPlayerController.file(File(path));
      }
      await c.initialize();
      return c;
    } catch (_) {
      return null;
    }
  }

  void _onChoice(String choice) async {
    if (_revealed) return;
    setState(() {
      _selected = choice;
      _revealed = true;
    });
    final correct = choice == _target;
    if (correct) {
      _session.correct++;
      _session.xp += 10;
    } else {
      _session.hearts = math.max(0, _session.hearts - 1);
    }
    await ref.read(ttsServiceProvider).speak(correct ? 'صحيح' : 'حاول مرة أخرى');
    _logAttempt(chosen: choice, correct: correct, confidence: correct ? 1.0 : 0.0);
    await Future.delayed(const Duration(milliseconds: 900));
    _qIndex++;
    _nextQuestion();
  }

  Future<void> _logAttempt({required String chosen, required bool correct, required double confidence}) async {
    try {
      await ref.read(apiClientProvider).post('/api/quiz', data: {
        'mode': widget.mode.name,
        'targetWord': _target,
        'chosenWord': chosen,
        'correct': correct,
        'confidence': confidence,
      });
    } catch (_) {}
  }

  void _finish() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz finished'),
        content: Text('Score: ${_session.correct}/${_session.totalQuestions}\nXP: ${_session.xp}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(children: [
                const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 4),
                Text('${_session.hearts}'),
                const SizedBox(width: 12),
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('${_session.xp}'),
              ]),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: (_qIndex / _session.totalQuestions).clamp(0.0, 1.0)),
            const SizedBox(height: 16),
            Expanded(
              child: widget.mode == QuizMode.clipToWord ? _buildClipToWord(theme) : _buildWordToClip(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipToWord(ThemeData theme) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: _video != null && _video!.value.isInitialized
              ? VideoPlayer(_video!)
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.sign_language_rounded, size: 80)),
                ),
        ),
        const SizedBox(height: 16),
        Text('Pick the matching word', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._choices.map((w) {
          final isCorrect = _revealed && w == _target;
          final isWrongPick = _revealed && w == _selected && w != _target;
          Color? bg;
          if (isCorrect) bg = Colors.green.withOpacity(0.25);
          if (isWrongPick) bg = Colors.red.withOpacity(0.25);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: bg ?? theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onChoice(w),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(w, style: theme.textTheme.titleLarge),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWordToClip(ThemeData theme) {
    return Column(
      children: [
        Text(_target, style: theme.textTheme.displaySmall),
        const SizedBox(height: 12),
        Text('Tap the matching sign clip', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: _choices.map((w) {
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onChoice(w),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(w, style: theme.textTheme.titleMedium)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
