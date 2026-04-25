/// Arabic text → Sign clips player.
///
/// Tokenizes input via [SignDictionary], then plays each clip in order using
/// the [video_player] package. When a clip is missing, the slot shows an
/// inline letter card with TTS pronunciation as a graceful fallback.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/tts_service.dart';
import '../data/sign_dictionary_service.dart';

class TextToSignScreen extends ConsumerStatefulWidget {
  const TextToSignScreen({super.key});

  @override
  ConsumerState<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends ConsumerState<TextToSignScreen> {
  final _ctrl = TextEditingController();
  List<SignToken> _playlist = const [];
  int _index = 0;
  VideoPlayerController? _video;
  bool _playing = false;
  bool _muted = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    HapticFeedback.selectionClick();
    final dict = await ref.read(signDictionaryProvider.future);
    final list = dict.tokenize(_ctrl.text.trim());
    setState(() {
      _playlist = list;
      _index = 0;
    });
    if (list.isEmpty) return;
    await _playAt(0);
  }

  Future<void> _playAt(int i) async {
    if (i < 0 || i >= _playlist.length) {
      setState(() => _playing = false);
      return;
    }
    final tok = _playlist[i];
    setState(() {
      _index = i;
      _playing = true;
    });

    // Speak the word/letter (TTS) so blind/low-vision users still get value.
    try {
      await ref.read(ttsServiceProvider).speak(tok.token);
    } catch (_) {}

    if (tok.clip.isEmpty) {
      // Unknown — skip after 600ms.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _playAt(i + 1);
      return;
    }

    await _video?.dispose();
    _video = await _initVideo(tok.clip);
    if (_video == null) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _playAt(i + 1);
      return;
    }
    _video!
      ..setVolume(_muted ? 0 : 1)
      ..addListener(_onTick)
      ..play();
    if (mounted) setState(() {});
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

  void _onTick() {
    final c = _video;
    if (c == null) return;
    if (c.value.position >= c.value.duration && c.value.duration > Duration.zero) {
      c.removeListener(_onTick);
      _playAt(_index + 1);
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _video?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text → Sign'),
        actions: [
          IconButton(
            tooltip: 'Mute',
            icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
            onPressed: _toggleMute,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _ctrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'اكتب جملة بالعربي…',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.translate_rounded),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _build(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _build,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Show signs'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _playlist.isEmpty
                      ? null
                      : () {
                          _video?.dispose();
                          _video = null;
                          setState(() {
                            _playlist = const [];
                            _playing = false;
                          });
                        },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_playlist.isNotEmpty)
              Text(
                'Step ${_index + 1} / ${_playlist.length}: ${_playlist[_index].token}',
                style: theme.textTheme.titleMedium,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: _video != null && _video!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _video!.value.aspectRatio,
                        child: VideoPlayer(_video!),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sign_language_rounded, size: 80, color: theme.colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              _playlist.isEmpty
                                  ? 'Type Arabic text and tap "Show signs"'
                                  : 'Token: ${_playlist[_index].token}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            if (_playlist.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_playlist.length, (i) {
                    final tok = _playlist[i];
                    final selected = i == _index;
                    Color bg;
                    switch (tok.kind) {
                      case SignTokenKind.word:
                        bg = Colors.green.withOpacity(selected ? 0.7 : 0.25);
                        break;
                      case SignTokenKind.letter:
                        bg = Colors.amber.withOpacity(selected ? 0.7 : 0.25);
                        break;
                      case SignTokenKind.unknown:
                        bg = Colors.grey.withOpacity(selected ? 0.7 : 0.25);
                        break;
                    }
                    return InkWell(
                      onTap: () => _playAt(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                        child: Text(tok.token),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
